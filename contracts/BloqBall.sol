
// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import './interfaces/IBloqBallFactory.sol';
import './interfaces/IBloqBallRouter02.sol';
import './libraries/Address.sol';
import './libraries/SafeMath.sol';
import './utils/Context.sol';
import './access/Ownable.sol';
import './interfaces/IERC20.sol';
import './interfaces/IERC20Metadata.sol';
import './interfaces/ERC20.sol';

interface MasterChef {
    function sendDividends(uint256 amount) external;
}

interface BloqBallLottery {
    function checkLotteryState() external;
    function getOperator() external view returns (address);
}

interface BloqBallTreasury {
    function depositTreasury(uint256 _amount) external;
    function getOperator() external returns (address);
    function buyback() external;
    function isEnableBuyback() external view returns (bool);
}

// BQBToken with Governance.
contract BloqBall is ERC20, Ownable {
    using SafeMath for uint256;

    // The operator
    address private _operator;

    // Tax rate in basis points.
    uint256 public transferTaxRate = 100;    // 1%
    uint256 public burnRate = 0;             // 0% of transferTaxRate for burn tax
    uint256 public liquidityRate = 0;        // 0% of transferTaxRate for liquidity tax
    uint256 public stakingRate = 10000;      // 100% of transferTaxRate for staking tax

    // exlcude from fees and max transaction amount
    mapping (address => bool) private _isExcludedFromFees;
    
    // Max transfer tax rate: 10%.
    uint16 public constant MAXIMUM_TRANSFER_TAX_RATE = 1000;
    
    // Burn address
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    uint256 public initialSupply = 10_000_000 * (10 ** 18);         // 10M BQB

    uint256 public swapAndSendTokensAtAmount = 1_000 * (10**18);    // 1000 BQB
    
    // Max transfer amount rate in basis points. (default is 0.5% of total supply)
    uint16 public maxTransferAmountRate = 50;
    
    // Addresses that excluded from antiWhale
    mapping(address => bool) private _excludedFromAntiWhale;
    
    mapping(address => bool) public _bqbHolderInfo;
    uint256  public totalCountofBQBHolders;

    mapping(address => bool) public _isBlacklisted;

    // The swap router, modifiable. Will be changed to BloqBall's router when our own AMM release
    IBloqBallRouter02 public bloqballRouter;
    address public bloqballPair;
    
    // In swap and liquify
    bool private swapping;

    // Parameters to mint tokens to developer
    address private _developer = address(0x2C4C168A2fE4CaB8E32d1B2A119d4Aa8BdA377e7);
    uint256 private lastMinttoDev;
    uint256 private totalMintedBQBofDev;
    uint256 constant MAXIMUM_TRANSFER_TO_DEVELOPER = 10_000_000 * 10 ** 18;        // 10M BQB for developer
    uint256 constant MAXIMUM_TRANSFER_TO_DEVELOPER_MONTHLY = 200_000 * 10 ** 18;   // 200K BQB

    // Masterchef address
    address public bloqballMasterchef;
    
    // Lottery address
    address public bloqballlottery;
    uint256 public lotteryPrizeReserve = 10_000_000 * 10 ** 18;                    // 10M BQB for lottery    

    // Treasury address
    address public bloqballTreasury; 
    uint256 public lastBuyBack;
    uint256 private intervalForBuyBack = 1 hours;
    uint256 public limitRateForTreasury;

    // updatable count for different contracts
    uint8 constant private MAXIMUM_UPDATE_CONTRACT = 100;
    uint8 private _updateRouterCount;
    uint8 private _updateMasterchefCount;
    uint8 private _updateLotteryCount;
    uint8 private _updateTreasuryCount;

    // Events
    event OperatorTransferred(address indexed previousOperator, address indexed newOperator);
    event TransferTaxRateUpdated(address indexed operator, uint256 previousRate, uint256 newRate);
    event BurnRateUpdated(address indexed operator, uint256 previousRate, uint256 newRate);
    event MaxTransferAmountRateUpdated(address indexed operator, uint256 previousRate, uint256 newRate);
    event SwapAndLiquifyEnabledUpdated(address indexed operator, bool enabled);
    event MinAmountToLiquifyUpdated(address indexed operator, uint256 previousAmount, uint256 newAmount);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);

    event BloqBallRouterUpdated(address indexed operator, address indexed router, address indexed pair);
    event BloqBallMasterchefUpdated(address indexed operator, address indexed masterchef);
    event BloqBallLotteryUpdated(address indexed operator, address indexed lottery);
    event BloqBallTreasuryUpdated(address indexed operator, address indexed treasury);

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);

    modifier onlyOperator() {
        require(_operator == msg.sender, "operator: caller is not the operator");
        _;
    }

    modifier onlyOperatorOrDeveloper() {
        require(_operator == msg.sender || _developer == msg.sender, 
            "operator: caller is not the operator or developer");
        _;
    }

    modifier antiWhale(address sender, address recipient, uint256 amount) {
        if (maxTransferAmount() > 0) {
            if (
                _excludedFromAntiWhale[sender] == false
                && _excludedFromAntiWhale[recipient] == false
            ) {
                require(amount <= maxTransferAmount(), 
                        "BloqBall::antiWhale: Transfer amount exceeds the maxTransferAmount");
            }
        }
        _;
    }

    modifier transferTaxFree {
        uint256 _transferTaxRate = transferTaxRate;
        transferTaxRate = 0;
        _;
        transferTaxRate = _transferTaxRate;
    }

    /**
     * @notice Constructs the BloqBall contract.
     */
//  constructor() public ERC20("BQB Token", "BQB") {
    constructor() ERC20("testball", "tqb") {
        _operator = _msgSender();
        emit OperatorTransferred(address(0), _operator);

        _excludedFromAntiWhale[_operator] = true;
        _excludedFromAntiWhale[address(0)] = true;
        _excludedFromAntiWhale[address(this)] = true;
        _excludedFromAntiWhale[BURN_ADDRESS] = true;

        // exclude from paying fees or having max transaction amount
        excludeFromFees(_operator, true);
        excludeFromFees(address(0), true);
        excludeFromFees(address(this), true);
        excludeFromFees(BURN_ADDRESS, true);

        _mint(_operator, initialSupply);

        // update the token holder
        totalCountofBQBHolders++;
        _bqbHolderInfo[_operator] = true;
    }

    /**
     * @dev Returns the address of the current operator.
     */
    function operator() public view returns (address) {
        return _operator;
    }

    /**
     * @dev Transfers operator of the contract to a new account (`newOperator`).
     * Can only be called by the current operator.
     */
    function transferOperator(address newOperator) public onlyOperator {
        require(newOperator != address(0), "BloqBall::transferOperator: new operator is the zero address");
        emit OperatorTransferred(_operator, newOperator);

        _operator = newOperator;

        _excludedFromAntiWhale[_operator] = true;
        excludeFromFees(_operator, true);
    }
    
    function mintToDeveloper(uint256 _amount) external {
        require(_developer == msg.sender, "developer: caller is not the operator or developer");
        require(_amount <= MAXIMUM_TRANSFER_TO_DEVELOPER_MONTHLY, "BloqBall::transfer: too much amount monthly");
        require(block.timestamp - lastMinttoDev > 30 days, 'Need to wait 1 month');
        require(totalMintedBQBofDev < MAXIMUM_TRANSFER_TO_DEVELOPER, 'BloqBall::transfer: too much amount');

        if (_amount > (MAXIMUM_TRANSFER_TO_DEVELOPER - totalMintedBQBofDev))
            _amount = MAXIMUM_TRANSFER_TO_DEVELOPER - totalMintedBQBofDev;
        
        totalMintedBQBofDev += _amount;
        
        lastMinttoDev = block.timestamp;
        
        _mint(_developer, _amount);
    }

    /**
     * @dev Update the swap router.
     * Can only be called by the current operator.
     */
    function updateBloqBallRouter(address _router) public onlyOperator {
        require(_router != address(0), "Update router: Wrong address.");
        
        _updateRouterCount++;
        
        require(_updateRouterCount <= MAXIMUM_UPDATE_CONTRACT, "Update BloqballRouter: too much updating BloqballRouter.");
        
        bloqballRouter = IBloqBallRouter02(_router);
        bloqballPair = IBloqBallFactory(bloqballRouter.factory()).getPair(address(this), bloqballRouter.WFTM());

        excludeFromFees(_router, true);

        emit BloqBallRouterUpdated(msg.sender, address(bloqballRouter), bloqballPair);
    }

    function setBurnRate(uint256 value) external onlyOperator{
        burnRate = value;
    }

    function setLiquidityRate(uint256 value) external onlyOperator{
        liquidityRate = value;
    }

    function setStakingRate(uint256 value) external onlyOperator{
        stakingRate = value;
    }

    function excludeFromFees(address account, bool excluded) public onlyOperator {
        require(_isExcludedFromFees[account] != excluded, "BQB: Account is already the value of 'excluded'");
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function excludeMultipleAccountsFromFees(address[] memory accounts, bool excluded) public onlyOperator {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }

        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function blacklistAddress(address account, bool value) external onlyOwner {
        _isBlacklisted[account] = value;
    }

    /// @notice Creates `_amount` token to `_to`. Must only be called by the owner.
    function mint(address _to, uint256 _amount) external onlyOwner {
        _mint(_to, _amount);
        _moveDelegates(address(0), _delegates[_to], _amount);
    }

    /// @dev overrides transfer function to meet tokenomics of BQB
    function _transfer(address sender, address recipient, uint256 amount) 
        internal 
        virtual 
        override 
        antiWhale(sender, recipient, amount) {
        if (recipient == BURN_ADDRESS || transferTaxRate == 0) {
            super._transfer(sender, recipient, amount);
        } else {
            require(sender != address(0), "BloqBall: transfer from the zero address");
            require(recipient != address(0), "BloqBall: transfer to the zero address");
            require(!_isBlacklisted[sender] && !_isBlacklisted[recipient], 'BloqBall: Blacklisted address');

            if(amount == 0) {
                super._transfer(sender, recipient, 0);
                return;
            }

            uint256 contractTokenBalance = balanceOf(address(this));

            bool canSwapAndSendFee = contractTokenBalance >= swapAndSendTokensAtAmount;

            // swap and liquify, send fee to masterchef.
            if (
                canSwapAndSendFee == true
                && !swapping
                && address(bloqballRouter) != address(0)
                && bloqballPair != address(0)
                && sender != address(bloqballRouter)
                && recipient != address(bloqballRouter)
                && sender != bloqballPair
                && recipient != bloqballPair
                && sender != owner()
                && sender != _operator
            ) {
                swapping = true;

                uint256 totalFeeRate = burnRate.add(liquidityRate).add(stakingRate);
                require(totalFeeRate == 10000, "BloqBall: Total Fee Rate is wrong");  // total Fee Rate must be 100%.

                uint256 burnAmount = contractTokenBalance.mul(burnRate).div(10000);
                uint256 liquidityAmount = contractTokenBalance.mul(liquidityRate).div(10000);
                uint256 stakeAmount =  contractTokenBalance.sub(burnAmount).sub(liquidityAmount);

                // Burn token
                if (burnAmount > 0)
                    super._transfer(address(this), BURN_ADDRESS, burnAmount);

                // Send fee for liquidity
                if (liquidityAmount > 0)
                    swapAndLiquify(liquidityAmount);

                // send fee for staking 
                if (stakeAmount > 0 && bloqballMasterchef != address(0)) {
                    swapAndSendDividends(stakeAmount);
                }

                swapping = false;
            }

            bool takeFee = !swapping;

            // if any account belongs to _isExcludedFromFee account then remove the fee
            if(_isExcludedFromFees[sender] || _isExcludedFromFees[recipient]) {
                takeFee = false;
            }
            
            if(takeFee) {
                uint256 taxAmount = amount.mul(transferTaxRate).div(10000);
                super._transfer(sender, address(this), taxAmount);

                amount = amount.sub(taxAmount);
            }

            super._transfer(sender, recipient, amount);
            
            // calculate the bqb holder
            updateHolders(sender, recipient);
            
            // check the status of lottery
            if (
                bloqballlottery != address(0) 
                && sender != bloqballlottery 
                && recipient != bloqballlottery 
                && BloqBallLottery(bloqballlottery).getOperator() == address(this)
                ) {
                BloqBallLottery(bloqballlottery).checkLotteryState();
            }

            // check the current price of BQB for treasury when swapping
            if (
                (bloqballPair != address(0) && (sender == bloqballPair || recipient == bloqballPair)) 
                && bloqballTreasury != address(0) 
                && sender != bloqballTreasury 
                && recipient != bloqballTreasury 
                && limitRateForTreasury > 0 
                && BloqBallTreasury(bloqballTreasury).getOperator() == address(this)) {
                checkTreasuryState();
            }
        }
    }

    function setSwapAndSendTokensAtAmount(uint256 _amount) public onlyOperator {
        swapAndSendTokensAtAmount = _amount;
    }

    function updateHolders(address _from, address _to) private {
        uint256 balance = IERC20(address(this)).balanceOf(_from);

        if (balance == 0 
            && _bqbHolderInfo[_from] == true) {
            totalCountofBQBHolders --;
            _bqbHolderInfo[_from] = false;            
        }

        balance = IERC20(address(this)).balanceOf(_to);
        if (balance > 0 
            && _bqbHolderInfo[_to] == false 
            && !_isContract(_to)) {
            totalCountofBQBHolders ++;
            _bqbHolderInfo[_to] = true;
        }
    }

    /// @dev Swap and liquify
    function swapAndLiquify(uint256 tokens) private {
       // split the contract balance into halves
        uint256 half = tokens.div(2);
        uint256 otherHalf = tokens.sub(half);

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForFTM(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    /// @dev Swap tokens for FTM
    function swapTokensForFTM(uint256 tokenAmount) private {
        // generate the BloqBall pair path of token -> wftm
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = bloqballRouter.WFTM();

        _approve(address(this), address(bloqballRouter), tokenAmount);

        // make the swap
        bloqballRouter.swapExactTokensForFTMSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of FTM
            path,
            address(this),
            block.timestamp
        );
    }

    /// @dev Add liquidity
    function addLiquidity(uint256 tokenAmount, uint256 ftmAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(bloqballRouter), tokenAmount);
        
        // add the liquidity
        bloqballRouter.addLiquidityFTM{value: ftmAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            operator(),
            block.timestamp
        );
    }

    function swapAndSendDividends(uint256 tokens) private{
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForFTM(tokens);

        // how much ETH did we just swap into?
        uint256 dividends = address(this).balance.sub(initialBalance);

        (bool success,) = address(payable(bloqballMasterchef)).call{value: dividends}("");

        if (success) {
            MasterChef(bloqballMasterchef).sendDividends(dividends);
        }
    }

    /**
     * @dev Returns the max transfer amount.
     */
    function maxTransferAmount() public view returns (uint256) {
        return totalSupply().mul(maxTransferAmountRate).div(10000);
    }

    /**
     * @dev Returns the address is excluded from antiWhale or not.
     */
    function isExcludedFromAntiWhale(address _account) public view returns (bool) {
        return _excludedFromAntiWhale[_account];
    }

    /**
     * @dev Exclude or include an address from antiWhale.
     * Can only be called by the current operator.
     */
    function setExcludedFromAntiWhale(address _account, bool _excluded) public onlyOperator {
        _excludedFromAntiWhale[_account] = _excluded;
    }

    receive() external payable {}

    /**
     * @dev Update the transfer tax rate.
     * Can only be called by the current operator.
     */
    function updateTransferTaxRate(uint16 _transferTaxRate) public onlyOperator {
        require(_transferTaxRate <= MAXIMUM_TRANSFER_TAX_RATE, "BloqBall::updateTransferTaxRate: Transfer tax rate must not exceed the maximum rate.");
        emit TransferTaxRateUpdated(msg.sender, transferTaxRate, _transferTaxRate);
        transferTaxRate = _transferTaxRate;
    }
    
    /**
     * @dev Update the burn rate.
     * Can only be called by the current operator.
     */
    function updateBurnRate(uint16 _burnRate) public onlyOperator {
        require(_burnRate <= 100, "BloqBall::updateBurnRate: Burn rate must not exceed the maximum rate.");
        emit BurnRateUpdated(msg.sender, burnRate, _burnRate);
        burnRate = _burnRate;
    }

    /**
     * @dev Update the max transfer amount rate.
     * Can only be called by the current operator.
     */
    function updateMaxTransferAmountRate(uint16 _maxTransferAmountRate) public onlyOperator {
        require(_maxTransferAmountRate <= 10000, "BloqBall::updateMaxTransferAmountRate: Max transfer amount rate must not exceed the maximum rate.");
        emit MaxTransferAmountRateUpdated(msg.sender, maxTransferAmountRate, _maxTransferAmountRate);
        maxTransferAmountRate = _maxTransferAmountRate;
    }
    
    /**
     * @dev Update the masterchef.
     * Can only be called by the current operator.
     */
    function updateMasterchef(address _masterchef) public onlyOperator {
        require(_masterchef != address(0), "Update masterchef: Wrong address.");
        
        _updateMasterchefCount ++;
        
        require(_updateMasterchefCount <= MAXIMUM_UPDATE_CONTRACT, "Update Masterchef: too much updating Masterchef.");
        
        bloqballMasterchef = _masterchef;
        
        emit BloqBallMasterchefUpdated(msg.sender, bloqballMasterchef);
    }

    /**
     * @dev Update the lottery and mint BQB to lottery prize reserve.
     * Can only be called by the current operator.
     */
    function updateLottery(address _toLottery) external onlyOperator {
        require(_toLottery != address(0), "Update Lottery: Wrong address.");
        
        _updateLotteryCount ++;
        
        require(_updateLotteryCount <= MAXIMUM_UPDATE_CONTRACT, "Update Lottery: too much updating lottery.");
        
        bloqballlottery = _toLottery;
        
        _mint(_toLottery, lotteryPrizeReserve);      // mint 10M BQB to lottery for prize reserve.

        emit BloqBallLotteryUpdated(msg.sender, bloqballlottery);
    }

    /**
     * @dev Update the treasury.
     * Can only be called by the current operator.
     */
    function updateTreasury(address _treasury) public onlyOperator {
        require(_treasury != address(0), "Update treasury: Wrong address.");

        _updateTreasuryCount ++;

        require(_updateTreasuryCount <= MAXIMUM_UPDATE_CONTRACT, "Update Treasury: too much updating lottery.");
      
        bloqballTreasury = _treasury;
        
        emit BloqBallTreasuryUpdated(msg.sender, bloqballTreasury);
    }

    /**
     * @dev Set the limit price for minting BQB to treasury.
     * Can only be called by the current operator.
     */
    function setlimitPriceForTreasury(uint256 _limitRateForTreasury) public onlyOperator {
        limitRateForTreasury = _limitRateForTreasury;
    }

    /**
     * @dev Set the interval for checking buyback.
     * Can only be called by the current operator.
     */
    function setIntervalForBuyBack(uint256 _interval) public onlyOperator {
        intervalForBuyBack = _interval;
    }

    /**
     * @dev check the price of BQB and trigger treasury process.
     */
    function checkTreasuryState() private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = bloqballRouter.WFTM();

        uint256 amountIn = 1 * 10 ** 18;
        uint[] memory amounts = IBloqBallRouter01(bloqballRouter).getAmountsOut(amountIn, path);
        uint256 rate = amounts[1];

        if (rate == 0)
            return;

        if (rate > limitRateForTreasury.mul(120).div(100)) {
            uint mintAmount;
            mintAmount = (totalSupply().sub(lotteryPrizeReserve)).div(1000);      // 0.1% of total supply except for lottery

            _mint(bloqballTreasury, mintAmount);
            BloqBallTreasury(bloqballTreasury).depositTreasury(mintAmount);

            limitRateForTreasury = rate;
        }

        if (block.timestamp > lastBuyBack + intervalForBuyBack) {
            if (BloqBallTreasury(bloqballTreasury).isEnableBuyback()) {
                BloqBallTreasury(bloqballTreasury).buyback();
                lastBuyBack = block.timestamp;
            }
        }
    }

    // Copied and modified from YAM code:
    // https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernanceStorage.sol
    // https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernance.sol
    // Which is copied and modified from COMPOUND:
    // https://github.com/compound-finance/compound-protocol/blob/master/contracts/Governance/Comp.sol

    /// @dev A record of each accounts delegate
    mapping (address => address) internal _delegates;

    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint256 votes;
    }

    /// @notice A record of votes checkpoints for each account, by index
    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping (address => uint32) public numCheckpoints;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    /// @notice A record of states for signing / validating signatures
    mapping (address => uint) public nonces;

      /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegator The address to get delegatee for
     */
    function delegates(address delegator)
        external
        view
        returns (address)
    {
        return _delegates[delegator];
    }

   /**
    * @notice Delegate votes from `msg.sender` to `delegatee`
    * @param delegatee The address to delegate votes to
    */
    function delegate(address delegatee) external {
        return _delegate(msg.sender, delegatee);
    }


    /**
     * @notice Delegates votes from signatory to `delegatee`
     * @param delegatee The address to delegate votes to
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function delegateBySig(
        address delegatee,
        uint nonce,
        uint expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
    {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(name())),
                getChainId(),
                address(this)
            )
        );

        bytes32 structHash = keccak256(
            abi.encode(
                DELEGATION_TYPEHASH,
                delegatee,
                nonce,
                expiry
            )
        );

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                structHash
            )
        );

        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "BloqBall::delegateBySig: invalid signature");
        require(nonce == nonces[signatory]++, "BloqBall::delegateBySig: invalid nonce");
        require(block.timestamp <= expiry, "BloqBall::delegateBySig: signature expired");
        return _delegate(signatory, delegatee);
    }

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account)
        external
        view
        returns (uint256)
    {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint blockNumber)
        external
        view
        returns (uint256)
    {
        require(blockNumber < block.number, "BloqBall::getPriorVotes: not yet determined");

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    function _delegate(address delegator, address delegatee)
        internal
    {
        address currentDelegate = _delegates[delegator];
        uint256 delegatorBalance = balanceOf(delegator); // balance of underlying BQBs (not scaled);
        _delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _moveDelegates(address srcRep, address dstRep, uint256 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                // decrease old representative
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint256 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint256 srcRepNew = srcRepOld.sub(amount);
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                // increase new representative
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint256 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint256 dstRepNew = dstRepOld.add(amount);
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(
        address delegatee,
        uint32 nCheckpoints,
        uint256 oldVotes,
        uint256 newVotes
    )
        internal
    {
        uint32 blockNumber = safe32(block.number, "BloqBall::_writeCheckpoint: block number exceeds 32 bits");

        if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function getChainId() internal view returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
    
    function _isContract(address _addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }
}