
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './utils/Context.sol';
import './access/Ownable.sol';
import './security/ReentrancyGuard.sol';
import './interfaces/IERC20.sol';
import './libraries/Address.sol';
import './utils/SafeERC20.sol';
import './interfaces/IRandomNumberGenerator.sol';
import './interfaces/IBloqBallLottery.sol';

interface BloqBall {
    function transferTaxRate() external returns (uint256);
}

interface RandomNumberGenerator {
    function setLotteryAddress(address _bloqballSwapLottery) external;
}

pragma abicoder v2;

/** @title BloqBallSwap Lottery.
 * @notice It is a contract for a lottery system using
 * randomness provided externally.
 */
contract BloqBallLottery is ReentrancyGuard, IBloqBallLottery, Ownable {
    using SafeERC20 for IERC20;

    address public bloqball;

    address public operatorAddress;
    
    // Burn address
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    uint256 public currentLotteryId;
    uint256 public currentTicketId;

    uint256 public maxNumberTicketsPerBuyOrClaim = 100;

    uint256 public maxPriceTicketInBQB = 500 ether;                                     // 500 BQB
    uint256 public minPriceTicketInBQB = 1 ether;                                       // 1 BQB
    uint256 public priceTicketInBQB = 50 ether;                                         // 50 BQB;

    uint256 public pendingInjectionNextLottery;
    uint256 public prizeReserve = 10_000_000 ether;                                     // 10M BQB

    uint256 public constant MIN_DISCOUNT_DIVISOR = 0;                                   // 300 : 3%;
    uint256 public constant MIN_LENGTH_LOTTERY = 20 minutes; //24 hours - 5 minutes;                  // 1 hours
    uint256 public constant MAX_LENGTH_LOTTERY = 7 days - 5 minutes;                    // 7 days

    uint256 public constant MAX_TREASURY_FEE = 500;                                     // 5%
    
    bool    private enableChainlinkRandomGenerator = false;
    IRandomNumberGenerator public randomGenerator;
    
    uint256 private minPendingInjectionNextLottery = 50_000 ether;                      // 50k BQB
    uint256 private minPrizeReserve = 75_000 ether;                                     // 75k BQB
    
    uint256 private minPendingInjectionNextLotteryForWeeklyLottery = 100_000 ether;     // 100k BQB
    uint256 private minPrizeReserveForWeeklyLottery = 150_000 ether;                    // 150k BQB

    uint256 public maxRewardPerClaim = 5_000 ether;                                     // 5k BQB
    uint256 public maxClaimablePeriod = 10 minutes; //1 weeks;

    bool private weeklyLottery = false;
    
    bool private emergencyPauseLottery = false;

    enum Status {
        Pending,
        Open,
        Close,
        Claimable
    }

    struct Lottery {
        Status status;
        uint256 startTime;
        uint256 endTime;
        uint256 priceTicketInBQB;
        uint256 discountDivisor;
        uint256[6] rewardsBreakdown;        // 0: 1 matching number, 5: 6 matching numbers
        uint256 treasuryFee;                // 500: 5% // 200: 2% // 50: 0.5%
        uint256[6] BQBPerBracket;           // 5->5000 : 50%, 4->2500 : 25%, 3->1500 : 15%, 2->1000 : 10%, 1->0, 0->0
        uint256[6] countWinnersPerBracket;
        uint256 firstTicketId;
        uint256 firstTicketIdNextLottery;
        uint256 amountCollectedInBQB;
        uint256 finalNumber;
        uint256 amountOfPurchasedPeople;
    }

    struct Ticket {
        uint256 number;
        address owner;
    }

    struct UserInfo {
        uint256 rewardAmount;             // How many LP tokens the user has provided.
        uint256 nextHarvestUntil;   // When can the user harvest again.
        uint256 remainedRewards;
    }

    // Mapping are cheaper than arrays
    mapping(uint256 => Lottery) private _lotteries;
    mapping(uint256 => Ticket) private _tickets;

    // Keep track of user ticket ids for a given lotteryId
    mapping(address => mapping(uint256 => uint256[])) public _userTicketIdsPerLotteryId;
    
   // Keep track of user wining rewards for a given lotteryId
    mapping(address => mapping(uint256 => uint256)) public _userWiningRewardsPerLotteryId;

   // Keep track of user remainded wining rewards for a given lotteryId
    mapping(address => mapping(uint256 => UserInfo)) public _userRewardsInfoPerLotteryId;

    // keep track of generating ticket numbers
    mapping(uint256 => bool) private _numberInfos; 

    modifier notContract() {
        require(!_isContract(msg.sender), "Contract not allowed");
        require(msg.sender == tx.origin, "Proxy contract not allowed");
        _;
    }

    modifier onlyOperator() {
        require(msg.sender == operatorAddress, "Not operator");
        _;
    }

    modifier onlyOperatorOrOwner() {
        require(msg.sender == operatorAddress || msg.sender == owner(), "Not operator or owner");
        _;
    }

    event AdminTokenRecovery(address token, uint256 amount);
    event LotteryClose(uint256 indexed lotteryId, uint256 firstTicketIdNextLottery);
    event LotteryInjection(uint256 indexed lotteryId, uint256 injectedAmount);
    event LotteryOpen(
        uint256 indexed lotteryId,
        uint256 startTime,
        uint256 endTime,
        uint256 priceTicketInBQB,
        uint256 firstTicketId,
        uint256 injectedAmount
    );
    event LotteryNumberDrawn(uint256 indexed lotteryId, uint256 finalNumber, uint256 countWinningTickets);
    event NewOperatorAddresses(address operator);
    event NewRandomGenerator(address indexed randomGenerator);
    event TicketsPurchase(address indexed buyer, uint256 indexed lotteryId, uint256 numberTickets);
    event TicketsClaim(address indexed claimer, uint256 amount, uint256 indexed lotteryId, uint256 numberTickets);

    /**
     * @notice Constructor
     * @dev RandomNumberGenerator must be deployed prior to this contract
     * @param _bloqball: address of the BloqBall token
     */
    constructor(address _bloqball) {
        bloqball = _bloqball;

        operatorAddress = msg.sender;
    }
    
    /**
     * @notice Generate tickets number for the current buyer
     */
    function generateTicketNumber() private returns (uint256) {
        uint256 ticketNumber;
        uint256 _itemNumber;
        uint256[] memory arraynumber = new uint256[](6);
        bool bEqual;
        uint256 index;
        
        for (uint8 i=0; i<6; i++) {
            bEqual = true;
            while (bEqual) {
                if (enableChainlinkRandomGenerator) {
                    // Request a random number from the generator based on a seed
                    randomGenerator.getRandomNumber(uint256(keccak256(abi.encodePacked(currentLotteryId, currentTicketId + index + i))));
                    require(currentLotteryId == randomGenerator.viewLatestLotteryId(), "Numbers not drawn");
                    
                    // Calculate the finalNumber based on the randomResult generated by ChainLink's fallback
                    _itemNumber = randomGenerator.viewRandomResult() % 49 + 1;                   
                }
                else {
                    _itemNumber = uint256(keccak256(abi.encodePacked(block.difficulty, 
                                block.timestamp * index, index + i))) % 49 + 1;
                }
                
                if (_numberInfos[_itemNumber]) {
                    bEqual = true;
                }
                else {
                    bEqual = false;
                    _numberInfos[_itemNumber] = true;
                }
                
                index++;
            }
            
            arraynumber[i] = _itemNumber;
            ticketNumber += _itemNumber * uint256(10)**(i*2);
        }

        // init map data for each numbers
        for (uint8 i=0; i<6; i++) {
            _numberInfos[arraynumber[i]] = false;
        }
        
        return ticketNumber;
    }
    
    /**
     * @param _randomGeneratorAddress: address of the RandomGenerator contract used to work with ChainLink VRF
     * @dev Callable by operator
     */
    function setRandomGenerator(address _randomGeneratorAddress) public onlyOwner {
        randomGenerator = IRandomNumberGenerator(_randomGeneratorAddress);
        RandomNumberGenerator(_randomGeneratorAddress).setLotteryAddress(address(this));
        
        enableChainlinkRandomGenerator = true;
    }

    /**
     * @notice Buy tickets for the current lottery
     * @param _lotteryId: lotteryId
     * @param _ticketNumbers: array of ticket numbers between 1,000,000 and 1,999,999
     * @dev Callable by users
     */
    function buyTickets(uint256 _lotteryId, uint256[] memory _ticketNumbers)
        external
        override
        notContract
        nonReentrant {
        require(emergencyPauseLottery == false, "Current Lottery paused");
        require(_ticketNumbers.length != 0, "No ticket specified");
        require(_ticketNumbers.length <= maxNumberTicketsPerBuyOrClaim, "Too many tickets");

        require(_lotteries[_lotteryId].status == Status.Open, "Lottery is not open");
        require(block.timestamp < _lotteries[_lotteryId].endTime, "Lottery is over");

        // Calculate number of BQB to this contract
        uint256 amountBQBToTransfer = _calculateTotalPriceForBulkTickets(
            _lotteries[_lotteryId].discountDivisor,
            _lotteries[_lotteryId].priceTicketInBQB,
            _ticketNumbers.length
        );

        // Transfer BQB tokens to this contract
        IERC20(bloqball).safeTransferFrom(address(msg.sender), address(this), amountBQBToTransfer);

        // Increment the total amount collected for the lottery round
        uint256 taxrate = BloqBall(bloqball).transferTaxRate();
        amountBQBToTransfer = amountBQBToTransfer * (10000 - taxrate) / uint256(10000);
        _lotteries[_lotteryId].amountCollectedInBQB += amountBQBToTransfer;
        
        if (_userTicketIdsPerLotteryId[msg.sender][_lotteryId].length == 0)
            _lotteries[_lotteryId].amountOfPurchasedPeople ++;

        for (uint256 i = 0; i < _ticketNumbers.length; i++) {
            uint256 thisTicketNumber = _ticketNumbers[i];

            _userTicketIdsPerLotteryId[msg.sender][_lotteryId].push(currentTicketId);

            _tickets[currentTicketId] = Ticket({number: thisTicketNumber, owner: msg.sender});

            // Increase lottery ticket number
            currentTicketId++;
        }

        emit TicketsPurchase(msg.sender, _lotteryId, _ticketNumbers.length);
    }
    
    /**
     * @notice Get the total players of the total lotteris.
     * @dev Callable by users
     */
    function getTotalPlayersOfLottery() public view returns (uint256) {
        uint256 _amount;
        for (uint256 i=1; i<currentLotteryId+1; i++) {
            _amount += _lotteries[i].amountOfPurchasedPeople;
        }
        
        return _amount;
    }
    
    /**
     * @notice Get the total winning prize of the total lotteris.
     * @dev Callable by users
     */
    function getTotalWinningPrizeOfLotteries() public view returns (uint256) {
        uint256 _amount;
        for (uint256 i=1; i<currentLotteryId+1; i++) {
            _amount += _lotteries[i].amountCollectedInBQB;
        }
        
        return _amount;
    }
    
    /**
     * @notice Calculate the count of winning players in the lottery.
     */
    function calculateWinningPlayersCountInBracket(uint256 _lotteryId, uint256 _winningNumber) private {
        uint256 bracket;
        uint256 winningNumber = _winningNumber;
        uint256 ticketNumber;
        
        for (uint256 i=_lotteries[_lotteryId].firstTicketId; i<_lotteries[_lotteryId].firstTicketIdNextLottery; i++ ) {
            ticketNumber = _tickets[i].number;
            bracket = getBracketOfMatchingFromTicketNumber(ticketNumber, winningNumber);
            _lotteries[_lotteryId].countWinnersPerBracket[bracket] ++;
        }
    }

    /**
     * @notice Calculate the bracket of the ticket number.
     */
    function getBracketOfMatchingFromTicketNumber(uint256 _ticketNumber, uint256 _winningNumber)
        private
        pure
        returns (uint32)
    {
        uint32 equal;
        uint256 ticketNumber = _ticketNumber;
        uint256 winningNumber;
        
        uint256 number1;
        uint256 number2;
        
        for (uint8 i = 0; i < 6; i++) {
            number1 = ticketNumber / 10 ** ((5-i)*2);
            ticketNumber = ticketNumber % 10 ** ((5-i)*2);
            
            winningNumber = _winningNumber;
            for (uint8 j = 0; j < 6; j++) {
                number2 = winningNumber / 10 ** ((5-j)*2);
                winningNumber = winningNumber % 10 ** ((5-j)*2);
                
                if (number1 == number2) {
                    equal++;
                    break;
                }
            }
        }
        
        if (equal > 0)
            equal --;
        
        return equal;
    }
    
    /**
     * @notice Calculate the total bracket of the player in the lottery.
     * @dev Callable by users
     */
    function getBracketsOfMatching(
        uint256 _lotteryId, address _account
    )
        external
        view
        returns (uint256[] memory new_ticketIds, uint256[] memory new_brackets, uint256 pendingRewards)
    {
        require(_lotteries[_lotteryId].status == Status.Claimable, "Lottery not claimable");
        
        uint256[] memory _ticketIds = _userTicketIdsPerLotteryId[_account][_lotteryId];
        
        uint256 ticketLength = _userTicketIdsPerLotteryId[_account][_lotteryId].length;
        
        uint32[] memory _brackets = new uint32[](ticketLength);
        uint256[] memory ticketNumbers;
        bool[] memory ticketStatus;
        
        uint256 _winningNumber = _lotteries[_lotteryId].finalNumber;
        
        (ticketNumbers, ticketStatus) = viewNumbersAndStatusesForTicketIds(_ticketIds);

        // Loops through all wimming numbers
        uint32 equalCount;
        uint256 index;
        for (uint i = 0; i < ticketLength; i++) {
            if (ticketStatus[i] == true) {
                _brackets[i] = 0;        // 0%
                continue;
            }
            
            equalCount = getBracketOfMatchingFromTicketNumber(ticketNumbers[i], _winningNumber);
            
            if (equalCount > 1)
                index++;
                
             _brackets[i] = equalCount;
        }
        
        new_brackets = new uint256[](index);
        new_ticketIds = new uint256[](index);
        
        index = 0;
        for (uint256 i = 0; i < ticketLength; i++) {
            if (_brackets[i] == 0 || _brackets[i] == 1)
                continue;

            new_brackets[index] = _brackets[i];
            new_ticketIds[index] = _ticketIds[i];
            index++;
            
            pendingRewards += _lotteries[_lotteryId].BQBPerBracket[_brackets[i]];
        }

        pendingRewards += _userRewardsInfoPerLotteryId[_account][_lotteryId].remainedRewards;
    }
        
    /**
     * @notice Get the lottery ids that the player attended.
     * @dev Callable by users
     */
    function getUserLotteryIds(address _account) public view returns (uint256[] memory) {
        uint256 index = 0;
        for (uint256 i=1; i<currentLotteryId + 1; i++) {
            if (_userTicketIdsPerLotteryId[_account][i].length > 0) {
                index ++;
            }
        }
        
        uint256[] memory lotteryIds = new uint256[](index);
        index = 0;
        for (uint256 i=1; i<currentLotteryId + 1; i++) {
            if (_userTicketIdsPerLotteryId[_account][i].length > 0) {
                lotteryIds[index] = i;
                index++;
            }
        }        
        
        return lotteryIds;
    }
    
    /**
     * @notice Claim a set of winning tickets for a lottery
     * @param _lotteryId: lottery id
     * @param _ticketIds: array of ticket ids
     * @param _brackets: array of brackets for the ticket ids
     * @dev Callable by users only, not contract!
     */
    function claimTickets(
        uint256 _lotteryId,
        uint256[] calldata _ticketIds,
        uint32[] calldata _brackets
    ) external override notContract nonReentrant {
        require(emergencyPauseLottery == false, "Current Lottery paused");
        require(_ticketIds.length == _brackets.length, "Not same length");
        require(_ticketIds.length <= maxNumberTicketsPerBuyOrClaim, "Too many tickets");
        require(_lotteries[_lotteryId].status == Status.Claimable, "Lottery not claimable");

        // Initializes the rewardInBQBToTransfer
        uint256 rewardInBQBToTransfer;

        for (uint256 i = 0; i < _ticketIds.length; i++) {
            require(_brackets[i] < 6, "Bracket out of range"); // Must be between 0 and 5

            uint256 thisTicketId = _ticketIds[i];

            require(_lotteries[_lotteryId].firstTicketIdNextLottery > thisTicketId, "TicketId too high");
            require(_lotteries[_lotteryId].firstTicketId <= thisTicketId, "TicketId too low");
            require(msg.sender == _tickets[thisTicketId].owner, "Not the owner");

            // Update the lottery ticket owner to 0x address
            _tickets[thisTicketId].owner = address(0);

            uint256 rewardForTicketId;
            if (_brackets[i] == 0 || _brackets[i] == 1)
                continue;
            
            rewardForTicketId = _lotteries[_lotteryId].BQBPerBracket[_brackets[i]];
            
            // Check user is claiming the correct bracket
            require(rewardForTicketId != 0, "No prize for this bracket");

            // Increment the reward to transfer
            rewardInBQBToTransfer += rewardForTicketId;
        }

        if (rewardInBQBToTransfer > maxRewardPerClaim || 
                (rewardInBQBToTransfer == 0 
                    && _userRewardsInfoPerLotteryId[msg.sender][_lotteryId].remainedRewards > 0)) {
            if (rewardInBQBToTransfer > maxRewardPerClaim) {
                _userRewardsInfoPerLotteryId[msg.sender][_lotteryId] = 
                                UserInfo({rewardAmount: rewardInBQBToTransfer / 10,
                                          nextHarvestUntil: 0,
                                          remainedRewards: rewardInBQBToTransfer});
            }

            require(_userRewardsInfoPerLotteryId[msg.sender][_lotteryId].nextHarvestUntil <= block.timestamp, 
                "Claim Too Earlier");

            UserInfo memory userInfo = _userRewardsInfoPerLotteryId[msg.sender][_lotteryId];
            uint256 rewards;

            if (userInfo.rewardAmount > userInfo.remainedRewards) {
                rewards = userInfo.remainedRewards;
            }
            else {
                rewards = userInfo.rewardAmount;
            }

            IERC20(bloqball).safeTransfer(msg.sender, rewards);

            _userRewardsInfoPerLotteryId[msg.sender][_lotteryId].remainedRewards -= rewards;
            _userRewardsInfoPerLotteryId[msg.sender][_lotteryId].nextHarvestUntil = block.timestamp + maxClaimablePeriod;

            _userWiningRewardsPerLotteryId[msg.sender][_lotteryId] += rewards;

            emit TicketsClaim(msg.sender, rewards, _lotteryId, _ticketIds.length);
        }
        else if (rewardInBQBToTransfer > 0 && rewardInBQBToTransfer < maxRewardPerClaim) {
            // Transfer money to msg.sender
            IERC20(bloqball).safeTransfer(msg.sender, rewardInBQBToTransfer);

            _userWiningRewardsPerLotteryId[msg.sender][_lotteryId] += rewardInBQBToTransfer;

            emit TicketsClaim(msg.sender, rewardInBQBToTransfer, _lotteryId, _ticketIds.length);
        }
    }

    /**
     * @notice Close lottery
     * @param _lotteryId: lottery id
     * @dev Callable by operator
     */
    function closeLottery(uint256 _lotteryId) public override onlyOperatorOrOwner nonReentrant {
        require(emergencyPauseLottery == false, "Current Lottery paused");
        require(_lotteries[_lotteryId].status == Status.Open, "Lottery not open");
        require(block.timestamp > _lotteries[_lotteryId].endTime, "Lottery not over");
        _lotteries[_lotteryId].firstTicketIdNextLottery = currentTicketId;

        _lotteries[_lotteryId].status = Status.Close;

        emit LotteryClose(_lotteryId, currentTicketId);
    }
    
    /**
     * @notice Check lottery state
     * @dev Callable by operator
     */
    function checkLotteryState() external onlyOperatorOrOwner {
        if (emergencyPauseLottery)
            return;
        if (currentLotteryId == 0)
            return;
            
        if (block.timestamp >= _lotteries[currentLotteryId].endTime 
        && _lotteries[currentLotteryId].status == Status.Open) {
            closeLottery(currentLotteryId);
            drawFinalNumberAndMakeLotteryClaimable(currentLotteryId, false);
      
            uint256 _endTime;
            if (!weeklyLottery) {
                _endTime = block.timestamp + MIN_LENGTH_LOTTERY + 5 minutes;
            }
            else {
                _endTime = block.timestamp + MAX_LENGTH_LOTTERY + 5 minutes;
            }
            
            startLottery(_endTime, priceTicketInBQB, _lotteries[currentLotteryId].discountDivisor, 
                        _lotteries[currentLotteryId].rewardsBreakdown, _lotteries[currentLotteryId].treasuryFee);
        }
    }
     
    /**
     * @notice Draw the final number, calculate reward in BQB per group, and make lottery claimable
     * @param _lotteryId: lottery id
     * @param _autoInjection: reinjects funds into next lottery (vs. withdrawing all)
     * @dev Callable by operator
     */
     
    function drawFinalNumberAndMakeLotteryClaimable(uint256 _lotteryId, bool _autoInjection)
        public
        override
        onlyOperatorOrOwner
        nonReentrant
    {
        require(emergencyPauseLottery == false, "Current Lottery paused");
        require(_lotteries[_lotteryId].status == Status.Close, "Lottery not close");
        
        uint256 finalNumber;

        finalNumber = generateTicketNumber();

        // Initialize a number to count addresses in the previous bracket
        uint256 numberAddressesInPreviousBracket;

        // Calculate the amount to share post-treasury fee
        uint256 amountToShareToWinners = (
          ((_lotteries[_lotteryId].amountCollectedInBQB) * (10000 - _lotteries[_lotteryId].treasuryFee))
        ) / 10000;

        // Initializes the amount to withdraw to treasury
        uint256 amountToWithdrawToTreasury;

        calculateWinningPlayersCountInBracket(_lotteryId, finalNumber);
        
        // Calculate prizes in BQB for each bracket by starting from the highest one
        for (uint32 i = 0; i < 6; i++) {

            // A. If number of users for this _bracket number is superior to 0
            if (_lotteries[_lotteryId].countWinnersPerBracket[i] !=0) {
                // B. If rewards at this bracket are > 0, calculate, else, report the numberAddresses from previous bracket
                if (_lotteries[_lotteryId].rewardsBreakdown[i] !=0) {
                    _lotteries[_lotteryId].BQBPerBracket[i] =
                        (_lotteries[_lotteryId].rewardsBreakdown[i] * amountToShareToWinners) / 
                            _lotteries[_lotteryId].countWinnersPerBracket[i] / 10000;
                }
                // A. No BQB to distribute, they are added to the amount to withdraw to treasury address
            } else {
                _lotteries[_lotteryId].BQBPerBracket[i] = 0;
                
                // If no winner in this brancket, send 75% of the rewards for this bracket to the next winning pool and 25% to the prize reserver.
                pendingInjectionNextLottery += (_lotteries[_lotteryId].rewardsBreakdown[i] * amountToShareToWinners) * 7500 /
                    (10000 * 10000);
                prizeReserve += (_lotteries[_lotteryId].rewardsBreakdown[i] * amountToShareToWinners) * 2500 /
                    (10000 * 10000);
            }
        }

        // Update internal statuses for lottery
        _lotteries[_lotteryId].finalNumber = finalNumber;
        _lotteries[_lotteryId].status = Status.Claimable;

        if (_autoInjection) {
          pendingInjectionNextLottery = amountToWithdrawToTreasury;
          amountToWithdrawToTreasury = 0;
        }

        emit LotteryNumberDrawn(currentLotteryId, finalNumber, numberAddressesInPreviousBracket);
    }
    
    /**
     * @notice Change the random generator
     * @dev The calls to functions are used to verify the new generator implements them properly.
     * It is necessary to wait for the VRF response before starting a round.
     * Callable only by the contract owner
     * @param _randomGeneratorAddress: address of the random generator
     */
    function changeRandomGenerator(address _randomGeneratorAddress) external onlyOwner {
        require(_lotteries[currentLotteryId].status == Status.Claimable, "Lottery not in claimable");

        // Request a random number from the generator based on a seed
        IRandomNumberGenerator(_randomGeneratorAddress).getRandomNumber(
            uint256(keccak256(abi.encodePacked(currentLotteryId, currentTicketId)))
        );

        // Calculate the finalNumber based on the randomResult generated by ChainLink's fallback
        IRandomNumberGenerator(_randomGeneratorAddress).viewRandomResult();

        randomGenerator = IRandomNumberGenerator(_randomGeneratorAddress);

        emit NewRandomGenerator(_randomGeneratorAddress);
    }

    /**
     * @notice Start the lottery
     * @dev Callable by operator
     * @param _endTime: endTime of the lottery
     * @param _priceTicketInBQB: price of a ticket in BQB
     * @param _discountDivisor: the divisor to calculate the discount magnitude for bulks
     * @param _rewardsBreakdown: breakdown of rewards per bracket (must sum to 10,000)
     * @param _treasuryFee: treasury fee (10,000 = 100%, 100 = 1%)
     */
    function startLottery(
        uint256 _endTime,
        uint256 _priceTicketInBQB,
        uint256 _discountDivisor,
        uint256[6] memory _rewardsBreakdown,
        uint256 _treasuryFee
    ) public override onlyOperatorOrOwner {
        require(emergencyPauseLottery == false, "Current Lottery paused");
        require(
            (currentLotteryId == 0) || (_lotteries[currentLotteryId].status == Status.Claimable),
            "Not time to start lottery"
        );

        require(
            ((_endTime - block.timestamp) >= MIN_LENGTH_LOTTERY) && ((_endTime - block.timestamp) <= MAX_LENGTH_LOTTERY),
            "Lottery length outside of range"
        );

        require(
            (_priceTicketInBQB >= minPriceTicketInBQB) && (_priceTicketInBQB <= maxPriceTicketInBQB),
            "Outside of limits"
        );
 
        require(_discountDivisor >= MIN_DISCOUNT_DIVISOR, "Discount divisor too low");
        require(_treasuryFee <= MAX_TREASURY_FEE, "Treasury fee too high");

        require(
            (_rewardsBreakdown[0] +
                _rewardsBreakdown[1] +
                _rewardsBreakdown[2] +
                _rewardsBreakdown[3] +
                _rewardsBreakdown[4] +
                _rewardsBreakdown[5]) == 10000,
            "Rewards must equal 10000"               // 50%, 25%, 15%, 10%
        );
      
        currentLotteryId++;
        
        // daily lottery : minPendingInjectionNextLottery = 50000 * 10 ** 18 (50K BQB), minPrizeReserve = 15000  * 10 ** 18 (15K BQB)
        // Weekly bumper lottery : minPendingInjectionNextLotteryForWeeklyLottery = 100000 * 10 ** 18 (100K BQB), minPrizeReserveForWeeklyLottery = 30000  * 10 ** 18 (30K BQB)
        if (!weeklyLottery) {
            if (pendingInjectionNextLottery < minPendingInjectionNextLottery) {
                if (prizeReserve > minPrizeReserve) {
                    pendingInjectionNextLottery += minPrizeReserve;
                    prizeReserve -= minPrizeReserve;
                }
            }
        }
        else {
            if (pendingInjectionNextLottery < minPendingInjectionNextLotteryForWeeklyLottery) {
                if (prizeReserve > minPrizeReserveForWeeklyLottery) {
                    pendingInjectionNextLottery += minPrizeReserveForWeeklyLottery;
                    prizeReserve -= minPrizeReserveForWeeklyLottery;
                }
            }   
        }

        _lotteries[currentLotteryId] = Lottery({
            status: Status.Open,
            startTime: block.timestamp,
            endTime: _endTime,
            priceTicketInBQB: _priceTicketInBQB,
            discountDivisor: _discountDivisor,
            rewardsBreakdown: _rewardsBreakdown,
            treasuryFee: _treasuryFee,
            BQBPerBracket: [uint256(0), uint256(0), uint256(0), uint256(0), uint256(0), uint256(0)],
            countWinnersPerBracket: [uint256(0), uint256(0), uint256(0), uint256(0), uint256(0), uint256(0)],
            firstTicketId: currentTicketId,
            firstTicketIdNextLottery: currentTicketId,
            amountCollectedInBQB: pendingInjectionNextLottery,
            finalNumber: 0,
            amountOfPurchasedPeople:0
        });
            
        emit LotteryOpen(
            currentLotteryId,
            block.timestamp,
            _endTime,
            _priceTicketInBQB,
            currentTicketId,
            pendingInjectionNextLottery
        );

        pendingInjectionNextLottery = 0;
        priceTicketInBQB = _priceTicketInBQB;
    }

    /**
     * @notice It allows the admin to recover wrong tokens sent to the contract
     * @param _tokenAddress: the address of the token to withdraw
     * @param _tokenAmount: the number of token amount to withdraw
     * @dev Only callable by owner.
     */
    function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
        require(_tokenAddress != bloqball, "Cannot be BQB token");

        IERC20(_tokenAddress).safeTransfer(address(msg.sender), _tokenAmount);

        emit AdminTokenRecovery(_tokenAddress, _tokenAmount);
    }
    
    /**
     * @notice Set minium value of pending injection next lottery and prize reserve
     * @dev Only callable by owner
     * @param _minPendingInjectionNextLottery: minimum value of a pending injection next lottery
     * @param _minPrizeReserve: maximum value of a prize reserve
     */
    function setMinPendingInjectionNextLotteryAndPrizeReserve
        (uint256 _minPendingInjectionNextLottery, uint256 _minPrizeReserve)
        external
        onlyOwner {
        minPendingInjectionNextLottery = _minPendingInjectionNextLottery;
        minPrizeReserve = _minPrizeReserve;
    }
    
    /**
     * @notice Set minium value of pending injection next lottery and prize reserve for weekly lottery
     * @dev Only callable by owner
     * @param _minPendingInjectionNextLottery: minimum value of a pending injection next lottery
     * @param _minPrizeReserve: maximum value of a prize reserve
     */
    function setMinPendingInjectionNextLotteryAndPrizeReserveForWeeklyLottery
        (uint256 _minPendingInjectionNextLottery, uint256 _minPrizeReserve)
        external
        onlyOwner {
        minPendingInjectionNextLotteryForWeeklyLottery = _minPendingInjectionNextLottery;
        minPrizeReserveForWeeklyLottery = _minPrizeReserve;
    }

    /**
     * @notice Set BQB price ticket upper/lower limit
     * @dev Only callable by owner
     * @param _minPriceTicketInBQB: minimum price of a ticket in BQB
     * @param _maxPriceTicketInBQB: maximum price of a ticket in BQB
     */
    function setMinAndMaxTicketPriceInBQB(uint256 _minPriceTicketInBQB, uint256 _maxPriceTicketInBQB)
        external
        onlyOwner {
        require(_minPriceTicketInBQB <= _maxPriceTicketInBQB, "minPrice must be < maxPrice");

        minPriceTicketInBQB = _minPriceTicketInBQB;
        maxPriceTicketInBQB = _maxPriceTicketInBQB;
    }
    
    /**
     * @notice Set BQB price ticket
     * @dev Only callable by owner
     * @param _priceTicketInBQB: price of a ticket in BQB
     */
    function setPriceInBQB(uint256 _priceTicketInBQB)
        external
        onlyOwner {
        require(_priceTicketInBQB >= minPriceTicketInBQB, "minPrice must be > minPrice");
        require(_priceTicketInBQB <= maxPriceTicketInBQB, "minPrice must be < maxPrice");

        priceTicketInBQB = _priceTicketInBQB;
    }

    /**
     * @notice Set max number of tickets
     * @dev Only callable by owner
     */
    function setMaxNumberTicketsPerBuy(uint256 _maxNumberTicketsPerBuy) external onlyOwner {
        require(_maxNumberTicketsPerBuy != 0, "Must be > 0");
        maxNumberTicketsPerBuyOrClaim = _maxNumberTicketsPerBuy;
    }

    /**
     * @notice Set operator addresses
     * @dev Only callable by owner
     * @param _operatorAddress: address of the operator
     */
    function setOperator(address _operatorAddress) external onlyOwner {
        require(_operatorAddress != address(0), "Cannot be zero address");

        operatorAddress = _operatorAddress;

        emit NewOperatorAddresses(_operatorAddress);
    }
    
    function getOperator() external view returns (address) {
        return operatorAddress;
    }
    
    /**
     * @notice Set weekly lottery
     * @dev Only callable by owner
     */
    function setWeeklyLottery(bool enable, uint256 _priceTicketInBQB) external onlyOwner {
        weeklyLottery = enable;
        priceTicketInBQB = _priceTicketInBQB;
    }
     
    /**
     * @notice Calculate price of a set of tickets
     * @param _discountDivisor: divisor for the discount
     * @param _priceTicket price of a ticket (in BQB)
     * @param _numberTickets number of tickets to buy
     */
    function calculateTotalPriceForBulkTickets(
        uint256 _discountDivisor,
        uint256 _priceTicket,
        uint256 _numberTickets
    ) external pure returns (uint256) {
        require(_discountDivisor >= MIN_DISCOUNT_DIVISOR, "Must be >= MIN_DISCOUNT_DIVISOR");
        require(_numberTickets != 0, "Number of tickets must be > 0");

        return _calculateTotalPriceForBulkTickets(_discountDivisor, _priceTicket, _numberTickets);
    }

    /**
     * @notice View current lottery id
     */
    function viewCurrentLotteryId() external view override returns (uint256) {
        return currentLotteryId;
    }

    /**
     * @notice View lottery information
     * @param _lotteryId: lottery id
     */
    function viewLottery(uint256 _lotteryId) external view returns (Lottery memory) {
        return _lotteries[_lotteryId];
    }

    /**
     * @notice View ticker statuses and numbers for an array of ticket ids
     * @param _ticketIds: array of _ticketId
     */
    function viewNumbersAndStatusesForTicketIds(uint256[] memory _ticketIds)
        public
        view
        returns (uint256[] memory, bool[] memory)
    {
        uint256 length = _ticketIds.length;
        uint256[] memory ticketNumbers = new uint256[](length);
        bool[] memory ticketStatuses = new bool[](length);

        for (uint256 i = 0; i < length; i++) {
            ticketNumbers[i] = _tickets[_ticketIds[i]].number;
            if (_tickets[_ticketIds[i]].owner == address(0)) {
                ticketStatuses[i] = true;
            } else {
                ticketStatuses[i] = false;
            }
        }

        return (ticketNumbers, ticketStatuses);
    }

    /**
     * @notice View rewards for a given ticket, providing a bracket, and lottery id
     * @dev Computations are mostly offchain. This is used to verify a ticket!
     * @param _lotteryId: lottery id
     * @param _ticketId: ticket id
     * @param _bracket: bracket for the ticketId to verify the claim and calculate rewards
     */
    function viewRewardsForTicketId(
        uint256 _lotteryId,
        uint256 _ticketId,
        uint32 _bracket
    ) external view returns (uint256) {
        // Check lottery is in claimable status
        if (_lotteries[_lotteryId].status != Status.Claimable) {
            return 0;
        }

        // Check ticketId is within range
        if (
            (_lotteries[_lotteryId].firstTicketIdNextLottery < _ticketId) &&
            (_lotteries[_lotteryId].firstTicketId >= _ticketId)
        ) {
            return 0;
        }

        return _lotteries[_lotteryId].BQBPerBracket[_bracket];
    }

    /**
     * @notice View user ticket ids, numbers, and statuses of user for a given lottery
     * @param _user: user address
     * @param _lotteryId: lottery id
     * @param _cursor: cursor to start where to retrieve the tickets
     * @param _size: the number of tickets to retrieve
     */
    function viewUserInfoForLotteryId(
        address _user,
        uint256 _lotteryId,
        uint256 _cursor,
        uint256 _size
    )
        external
        view
        returns (
            uint256[] memory,
            uint256[] memory,
            bool[] memory,
            uint256
        )
    {
        uint256 length = _size;
        uint256 numberTicketsBoughtAtLotteryId = _userTicketIdsPerLotteryId[_user][_lotteryId].length;

        if (length > (numberTicketsBoughtAtLotteryId - _cursor)) {
            length = numberTicketsBoughtAtLotteryId - _cursor;
        }

        uint256[] memory lotteryTicketIds = new uint256[](length);
        uint256[] memory ticketNumbers = new uint256[](length);
        bool[] memory ticketStatuses = new bool[](length);

        for (uint256 i = 0; i < length; i++) {
            lotteryTicketIds[i] = _userTicketIdsPerLotteryId[_user][_lotteryId][i + _cursor];
            ticketNumbers[i] = _tickets[lotteryTicketIds[i]].number;

            // True = ticket claimed
            if (_tickets[lotteryTicketIds[i]].owner == address(0)) {
                ticketStatuses[i] = true;
            } else {
                // ticket not claimed (includes the ones that cannot be claimed)
                ticketStatuses[i] = false;
            }
        }

        return (lotteryTicketIds, ticketNumbers, ticketStatuses, _cursor + length);
    }

    /**
     * @notice Calculate final price for bulk of tickets
     * @param _discountDivisor: divisor for the discount (the smaller it is, the greater the discount is)
     * @param _priceTicket: price of a ticket
     * @param _numberTickets: number of tickets purchased
     */
    function _calculateTotalPriceForBulkTickets(
        uint256 _discountDivisor,
        uint256 _priceTicket,
        uint256 _numberTickets
    ) internal pure returns (uint256) {
        uint256 amount;
        
        if (_discountDivisor > 0) {
            require(_discountDivisor >= _numberTickets - 1, "discountDivisor must be >= _numberTickets - 1");
            amount = (_priceTicket * _numberTickets * (_discountDivisor + 1 - _numberTickets)) / _discountDivisor;
        }
        else
            amount = _priceTicket * _numberTickets;
            
        return amount;
    }
    
    /**
     * @notice close the lotttery, EMERGENCY ONLY.
     * @dev Only callable by owner
     */
    function setEmergencyPauseLottery(bool lotteryPause) external onlyOwner
    {
        if (lotteryPause) {
            operatorAddress = _msgSender();
            
            _lotteries[currentLotteryId].firstTicketIdNextLottery = currentTicketId;
            _lotteries[currentLotteryId].status = Status.Close;
            
            prizeReserve = 0;
            pendingInjectionNextLottery = 0;
            
            uint256 balanceBQB = IERC20(bloqball).balanceOf(address(this));
            IERC20(bloqball).transfer(BURN_ADDRESS, balanceBQB);
        }
        else {
            _lotteries[currentLotteryId].status = Status.Claimable;
            _lotteries[currentLotteryId].amountCollectedInBQB = 0;
            
            for (uint8 i=0; i<6; i++) {
                _lotteries[currentLotteryId].BQBPerBracket[i] = 0;
            }
        }
        
        emergencyPauseLottery = lotteryPause;
    }

    function setMaxRewardPerClaim(uint256 _amount) external onlyOwner {
        maxRewardPerClaim = _amount;
    }

    function setMaxClaimablePeriod(uint256 _period) external onlyOwner {
        maxClaimablePeriod = _period;
    }

    /**
     * @notice Check if an address is a contract
     */
    
    function _isContract(address _addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }

        return size > 0;
    }
}