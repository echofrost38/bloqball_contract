// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './utils/Context.sol';
import './access/Ownable.sol';
import './security/ReentrancyGuard.sol';
import './interfaces/IERC20.sol';
import './libraries/SafeMath.sol';
import './libraries/Address.sol';
import './utils/SafeERC20.sol';
import './interfaces/IBloqBallPair.sol';
import './interfaces/IBloqBallFactory.sol';
import './interfaces/IBloqBallRouter02.sol';
import './interfaces/AggregatorV3Interface.sol';


contract BloqBallTreasury is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public operatorAddress;

    address public bloqball;
    address public bloqballRouter;
    address public WFTM;
    address public lpToken;

    AggregatorV3Interface internal priceFeedOfFTM;

    uint256 private discountRate = 1000;      // 10%
    uint256 private buybackRate = 1000;       // 10%

    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    uint256 private decimal = 10 ** 18;

    uint256[2] public allocPoints;

    // Info of each pool.
    struct PoolInfo {
        IERC20 token;                       // Address of token contract.
        uint256 totalDepositBQB;            // total count of deposited tokens
        uint256 totalPurchasedBQB;          // total count of purchased tokens
        uint256 remainedBQB;                // total count of remained tokens
        uint256 totalFund;                  // total count of fund tokens
    }

    PoolInfo[] public poolInfo;

   // Info of each Purchase.
    struct PurchasedInfo {
        uint256 pid;                        // Pool ID
        uint256 sellAmount;                 // count of sell-token
        uint256 buyAmount;                  // count of buy-token
        uint256 lockupPeriod;               // lockup period
        uint256 discountRate;               // discount percent
    }

    mapping (address=> mapping(uint=>PurchasedInfo[])) public purchasedInfo;

    // Info of each user.
    struct UserInfo {
        uint256 totalSelledToken;           // total count of selled FTM for buying BQB
        uint256 totalPhurchasedBQB;         // total count of earned BQB by selling FTM
        uint256 totalEarnedBQB;             // total count of earned BQB by selling FTM/BQB
        uint256 totalSelledBQB;             // total count of selled BQB for buybacking FTM or FTM/BQB
        uint256 totalEarnedToken;           // total count of earned FTM by selling BQB
    }

    mapping (address=> mapping(uint=> UserInfo)) public userInfo;

    modifier onlyOperator() {
        require(msg.sender == operatorAddress, "Not operator");
        _;
    }

    event depositBQB(uint256 amount0, uint256 amount1);
    event TokensPurchased(address receiver, address token, uint256 amount, uint256 rate);
    event TokensClaimed(address receiver, uint256 amount);
    event buyBack(address sellToken, uint sellAmount, uint buyAmount);
    event burnBQB(address token, uint256 amount);
    event NewOperatorAddresses(address newAddress);

    /**
     * Network: FANTOM
     * Aggregator: FTM/USD
     * Address: 0xe04676B9A9A2973BCb0D1478b5E1E9098BBB7f3D in testnet    
     * address: 0xf4766552D15AE4d256Ad41B6cf2933482B0680dc in mainnet
     */

    constructor(
        address _bloqball,
        address _bloqballRouter
    ) {
        bloqball = _bloqball;
        bloqballRouter = _bloqballRouter;

        WFTM = IBloqBallRouter01(bloqballRouter).WFTM();
        lpToken = IBloqBallFactory(IBloqBallRouter01(bloqballRouter).factory())
            .getPair(bloqball, WFTM);

        priceFeedOfFTM = AggregatorV3Interface(0xe04676B9A9A2973BCb0D1478b5E1E9098BBB7f3D);
//      priceFeedOfFTM = AggregatorV3Interface(0xf4766552D15AE4d256Ad41B6cf2933482B0680dc);

        allocPoints[0] = 5000;
        allocPoints[1] = 5000;

        operatorAddress = msg.sender;
    }

    receive() external payable {
    }

    // Add a new token to the pool. Can only be called by the owner.
    function add(IERC20 _token) public onlyOwner {
        require(address(_token) != address(this), "token : Wrong address");
        poolInfo.push(PoolInfo({
            token: _token,
            totalDepositBQB: 0,
            totalPurchasedBQB: 0,
            remainedBQB: 0,
            totalFund: 0
        }));
    }

    function set(uint _pid, IERC20 _token, uint256 _totalDespositBQB, 
                uint256 _totalPurchasedBQB, uint256 _remainedBQB) public onlyOwner {
        require(address(_token) != address(this), "token : Wrong address");
        poolInfo[_pid].token = _token;
        poolInfo[_pid].totalDepositBQB = _totalDespositBQB;
        poolInfo[_pid].totalPurchasedBQB = _totalPurchasedBQB;
        poolInfo[_pid].remainedBQB = _remainedBQB;
    }

    function setAllocpoint(uint256[2] memory _allocPoints) public onlyOwner {
        require(
            (_allocPoints[0] +
                _allocPoints[1]) == 10000,
            "Rewards must equal 10000"
        );

        allocPoints = _allocPoints;
    }

    function depositTreasury(uint256 _amount) external onlyOperator {
        uint256[2] memory amount;

        amount[0] = _amount.mul(allocPoints[0]).div(10000);
        amount[1] = _amount.mul(allocPoints[1]).div(10000);

        poolInfo[0].totalDepositBQB = poolInfo[0].totalDepositBQB.add(amount[0]);
        poolInfo[0].remainedBQB = poolInfo[0].remainedBQB.add(amount[0]);

        poolInfo[1].totalDepositBQB = poolInfo[1].totalDepositBQB.add(amount[1]);
        poolInfo[1].remainedBQB = poolInfo[1].remainedBQB.add(amount[1]);

        // emit an event when tokens are deposited
        emit depositBQB(amount[0], amount[1]);
    }

    function buyBQBWithFTM(uint256 _lockupPeriod) public payable {
        require(msg.value > 0, "Insufficient value");

        uint256 rate = calculateRateFTM2BQB();
        uint256 tokenAmount = msg.value.mul(rate).div(decimal);

        uint256 _discountRate = _lockupPeriod.mul(uint256(100));            // 5 days -> add 5%
        tokenAmount = tokenAmount.add(tokenAmount.mul(_discountRate).div(10000));

        // check if the contract has enough tokens
        require(poolInfo[0].remainedBQB >= tokenAmount, "Available BQB not sufficient to complete buying");

        poolInfo[0].totalPurchasedBQB = poolInfo[0].totalPurchasedBQB.add(tokenAmount);
        poolInfo[0].remainedBQB = poolInfo[0].remainedBQB.sub(tokenAmount);
        poolInfo[0].totalFund = poolInfo[0].totalFund.add(msg.value);

        userInfo[msg.sender][0].totalSelledToken = userInfo[msg.sender][0].totalSelledToken.add(msg.value);
        userInfo[msg.sender][0].totalPhurchasedBQB = userInfo[msg.sender][0].totalPhurchasedBQB.add(tokenAmount);

        purchasedInfo[msg.sender][0].push(PurchasedInfo({
            pid: 0,
            sellAmount: msg.value,
            buyAmount: tokenAmount,
            lockupPeriod:block.timestamp.add(_lockupPeriod.mul(86400)),
            discountRate: _discountRate
        }));

        // emit an event when tokens are purchased
        emit TokensPurchased(msg.sender, bloqball, tokenAmount, rate);
    }

    function buyBQBWithLP(uint256 _amount, uint256 _lockupPeriod) public {
        uint256 rate = calculateRateLP2BQB();
        uint256 tokenAmount = _amount.mul(rate).div(decimal);

        uint256 _discountRate = _lockupPeriod.mul(uint(100));            // 5 days -> add 5%
        tokenAmount = tokenAmount.add(tokenAmount.mul(_discountRate).div(10000));

        // check if the contract has enough tokens
        require(poolInfo[1].remainedBQB >= tokenAmount, "Available BQB not sufficient to complete buying");

        poolInfo[1].totalPurchasedBQB = poolInfo[1].totalPurchasedBQB.add(tokenAmount);
        poolInfo[1].remainedBQB = poolInfo[1].remainedBQB.sub(tokenAmount);
        poolInfo[1].totalFund = poolInfo[1].totalFund.add(_amount);

        userInfo[msg.sender][1].totalSelledToken = userInfo[msg.sender][1].totalSelledToken.add(_amount);
        userInfo[msg.sender][1].totalPhurchasedBQB = userInfo[msg.sender][1].totalPhurchasedBQB.add(tokenAmount);

        purchasedInfo[msg.sender][1].push(PurchasedInfo({
            pid: 1,
            sellAmount: _amount,
            buyAmount: tokenAmount,
            lockupPeriod:block.timestamp.add(_lockupPeriod.mul(86400)),
            discountRate: _discountRate
        }));

        IERC20(poolInfo[1].token).safeTransferFrom(msg.sender, address(this), _amount);

        // emit an event when tokens are purchased
        emit TokensPurchased(msg.sender, bloqball, tokenAmount, rate);
    }

    // View function to see user's purchased info.
    function getPurchasedInfo(uint256 _pid, address _user) 
        public view returns (PurchasedInfo[] memory) {
        return purchasedInfo[_user][_pid];
    }

    // View function to see pending BQBs on frontend.
    function pendingBQB(uint256 _pid, address _user) public view returns (uint) {
        uint256 totalClaimable;

        PurchasedInfo[] memory myPurchased =  purchasedInfo[_user][_pid];

        for (uint i=0; i< myPurchased.length; i++) {
            if (myPurchased[i].lockupPeriod < block.timestamp) {
                totalClaimable = totalClaimable.add(myPurchased[i].buyAmount);
            }
        }

        return totalClaimable;
    }

    function claimBQB(uint256 _pid) public {
        uint256 amount = pendingBQB(_pid, msg.sender);

        require(balanceOfBQB() >= amount, "BQB not sufficient to claim");

        if (amount > 0) {
            IERC20(bloqball).safeTransfer(msg.sender, amount);
        }

        userInfo[msg.sender][_pid].totalEarnedBQB = userInfo[msg.sender][_pid].totalEarnedBQB.add(amount);

        // Remove purchased info in the array
        removeAmountFromPurchased(msg.sender, _pid, amount, block.timestamp);
        removeEmptyPurchased(msg.sender, _pid);

        // emit an event when tokens are claimed
        emit TokensClaimed(msg.sender, amount);
    }

    function removeAmountFromPurchased(address _user, uint _pid, uint _amount, uint _time) private {
        uint length =  purchasedInfo[_user][_pid].length;

        for(uint i=0; i< length; i++) {
            if(purchasedInfo[_user][_pid][i].lockupPeriod < _time) {
                if (purchasedInfo[_user][_pid][i].buyAmount <= _amount) {
                    _amount = _amount.sub(purchasedInfo[_user][_pid][i].buyAmount);
                    purchasedInfo[_user][_pid][i].buyAmount = 0;
                }
                else {
                    purchasedInfo[_user][_pid][i].buyAmount = purchasedInfo[_user][_pid][i].buyAmount.sub(_amount);
                    _amount = 0;
                }
            }

            if (_amount == 0) {
                break;
            }
        }
    }

    function removeEmptyPurchased(address user, uint _pid) private {
        for (uint i=0; i<purchasedInfo[user][_pid].length; i++) {
            while(purchasedInfo[user][_pid].length > 0 && purchasedInfo[user][_pid][i].buyAmount  == 0) {
                for (uint j = i; j<purchasedInfo[user][_pid].length-1; j++) {
                    purchasedInfo[user][_pid][j] = purchasedInfo[user][_pid][j+1];
                }
                purchasedInfo[user][_pid].pop();
            }
        }
    }

    function calculateRateFTM2BQB() public view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = WFTM;
        path[1] = bloqball;

        uint256 amountIn = 1 * decimal;
        uint[] memory amounts = IBloqBallRouter01(bloqballRouter).getAmountsOut(amountIn, path);

        return amounts[1];
    }

    function calculateRateBQB2FTM() public view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = bloqball;
        path[1] = WFTM;

        uint256 amountIn = 1 * decimal;
        uint[] memory amounts = IBloqBallRouter01(bloqballRouter).getAmountsOut(amountIn, path);

        return amounts[1];
    }

    function calculateRateLP2BQB() public view returns (uint256) {
        (uint256 amountBQB, uint256 amountFTM, ) = 
                IBloqBallPair(lpToken).getReserves();

        uint256 rate = calculateRateFTM2BQB();
        amountBQB = amountBQB.add(amountFTM.mul(rate).div(decimal));

        return amountBQB.mul(decimal).div(IERC20(lpToken).totalSupply()); 
    }

    function calculatePriceOfLP() public view returns (uint256) {
        uint256 amountBQB = calculateRateLP2BQB();

        (, int price, , , ) = priceFeedOfFTM.latestRoundData();

        uint256 rate = calculateRateBQB2FTM();
        uint256 currentPriceOfBQB = uint256(price).mul(rate).div(decimal);

        return currentPriceOfBQB.mul(amountBQB).div(decimal);
    }

    function calculatePriceOfBQB() public view returns (uint256) {
        (, int price, , , ) = priceFeedOfFTM.latestRoundData();

        uint256 rate = calculateRateBQB2FTM();

        return uint256(price).mul(rate).div(decimal);
    }
    
    function calculatBackingPriceOfBQB() public view returns (uint256) {
        uint256 totalTreasuryBalance = treasuryBalance();
        uint256 totalSupply = (IERC20(bloqball).totalSupply()).sub(10000000 * decimal);        // sub amount of bqb in lottery

        return totalTreasuryBalance.mul(decimal).div(totalSupply);
    }

    function treasuryBalance() public view returns (uint256) {
       // Calculate the total price of FTM
        uint256 balanceOfToken;
        balanceOfToken = balanceOfFTM();

        (, int price, , , ) = priceFeedOfFTM.latestRoundData();

        uint256 totalPrice = balanceOfToken.mul(uint256(price)).div(decimal);

        // Calculate the total price of LP token
        balanceOfToken = balanceOfLP();
        uint256 priceLP = calculatePriceOfLP();

        return totalPrice.add(balanceOfToken.mul(uint256(priceLP)).div(decimal));        
    }

    function isEnableBuyback() public view returns (bool) {
        (, int price, , , ) = priceFeedOfFTM.latestRoundData();

        uint256 rate = calculateRateBQB2FTM();

        uint256 currentPriceOfBQB = uint256(price).mul(rate).div(decimal);

        uint256 backingPrice = calculatBackingPriceOfBQB();

        return (currentPriceOfBQB < backingPrice);
    }

    function buyback() public onlyOperator {
        bool enableBuyBack = isEnableBuyback();
        require(enableBuyBack, "BuyBack is not available.");

        uint256 amount = balanceOfFTM();
        amount = amount.mul(buybackRate).div(uint(10000));
        buybackBQBforFTMbyRouter(amount);

        amount = balanceOfLP();
        amount = amount.mul(buybackRate).div(uint(10000));
        buybackBQBforLPbyRouter(amount);
    }

    function buybackBQBforFTMbyRouter(uint256 _amountofFTM) private {
        require(_amountofFTM <= balanceOfFTM(), "Insufficient value");

        address[] memory path = new address[](2);
        path[0] = WFTM;
        path[1] = bloqball;

        uint256 oldBalance = IERC20(bloqball).balanceOf(address(this));

        IBloqBallRouter02(bloqballRouter).
            swapExactFTMForTokensSupportingFeeOnTransferTokens{value: _amountofFTM} (
                0,
                path,
                address(this),
                block.timestamp
            );

        uint256 newBalance = IERC20(bloqball).balanceOf(address(this));
        uint256 difference = newBalance.sub(oldBalance);

        poolInfo[0].totalDepositBQB = poolInfo[0].totalDepositBQB.add(difference);
        poolInfo[0].remainedBQB = poolInfo[0].remainedBQB.add(difference);
        poolInfo[0].totalFund = poolInfo[1].totalFund.sub(_amountofFTM);

        emit buyBack(WFTM, _amountofFTM, difference);
    }

    function buybackBQBforLPbyRouter(uint256 _amountofLP) private {
        require(_amountofLP <= balanceOfLP(), "Insufficient value");

        uint256 oldBalance = IERC20(bloqball).balanceOf(address(this));
        uint256 oldBalanceOfFTM = address(this).balance;

        IERC20(lpToken).approve(bloqballRouter, _amountofLP);

        IBloqBallRouter02(bloqballRouter).removeLiquidityFTMSupportingFeeOnTransferTokens(
          bloqball,
          _amountofLP,
          0,
          0,
          address(this),
          block.timestamp
        );

        uint256 newBalance = IERC20(bloqball).balanceOf(address(this));
        uint256 newBalanceOfFTM = address(this).balance;

        uint256 difference = newBalance.sub(oldBalance);
        uint256 differenceOfFTM = newBalanceOfFTM.sub(oldBalanceOfFTM);

        poolInfo[1].totalDepositBQB = poolInfo[1].totalDepositBQB.add(difference);
        poolInfo[1].remainedBQB = poolInfo[1].remainedBQB.add(difference);
        poolInfo[1].totalFund = poolInfo[1].totalFund.sub(_amountofLP);
        poolInfo[0].totalFund = poolInfo[1].totalFund.add(differenceOfFTM);

        emit buyBack(lpToken, _amountofLP, newBalance.sub(oldBalance));
    }

    function buybackBQBforFTMbyUser(uint256 _amountofBQB) public {
        bool enableBuyBack = isEnableBuyback();
        require(enableBuyBack, "BuyBack is not available.");

        uint rate = calculateRateBQB2FTM();
        uint tokenAmount = _amountofBQB.mul(rate).div(decimal);
        tokenAmount = tokenAmount.add(tokenAmount.mul(discountRate).div(uint(10000)));

        require(address(this).balance >= tokenAmount, "Available FTM not sufficient to complete buying");
        require(payable(msg.sender).send(tokenAmount));

        uint256 oldBalance = IERC20(bloqball).balanceOf(msg.sender);
        IERC20(bloqball).safeTransferFrom(msg.sender, address(this), _amountofBQB);

        uint256 newBalance = IERC20(bloqball).balanceOf(msg.sender);
        uint256 difference = oldBalance.sub(newBalance);

        userInfo[msg.sender][0].totalSelledBQB = userInfo[msg.sender][0].totalSelledBQB.add(_amountofBQB);
        userInfo[msg.sender][0].totalEarnedToken = userInfo[msg.sender][0].totalEarnedToken.add(tokenAmount);

        poolInfo[0].totalDepositBQB = poolInfo[0].totalDepositBQB.add(difference);
        poolInfo[0].remainedBQB = poolInfo[0].remainedBQB.add(difference);
        poolInfo[0].totalFund = poolInfo[0].totalFund.sub(tokenAmount);

        // emit an event when tokens are purchased
        emit TokensPurchased(msg.sender, WFTM, tokenAmount, rate);
    }

    function setDiscountRateforBuyBackBQB(uint256 _rate) public onlyOwner {
        require(_rate < 10000, "Discount Rate can not be over 100%");
        discountRate = _rate;
    }

    function setSwapAmountRateforBuyBackBQB(uint256 _rate) public onlyOwner {
        require(_rate < 10000, "BuyBack Rate can not be over 100%");
        buybackRate = _rate;
    }

    function burnBQb(uint256 _amount) public onlyOwner {
        IERC20(bloqball).transfer(BURN_ADDRESS, _amount);

        emit burnBQB(bloqball, _amount);
    }

    function balanceOfBQB() public view returns (uint256) {
        return IERC20(bloqball).balanceOf(address(this));
    }

    function balanceOfFTM() public view returns (uint256) {
        return address(this).balance;
    }

    function balanceOfLP() public view returns (uint256) {
        return IERC20(lpToken).balanceOf(address(this));
    }

    function setOperator(address _newAddress) external onlyOwner {
        require(_newAddress != address(0), "Cannot be zero address");

        operatorAddress = _newAddress;

        emit NewOperatorAddresses(_newAddress);
    }

    function setBloqBallPair(address _newAddress) external onlyOwner {
        require(_newAddress != address(0), "Cannot be zero address");

        lpToken = _newAddress;
    }

    function getOperator() external view returns (address) {
        return operatorAddress;
    }

    /**
     * @dev It allows the admin to withdraw FTM sent to the contract by the users, 
     * only callable by owner.
     */
    function withdrawFTM() public onlyOwner {
        require(address(this).balance > 0, "No balance of ETH.");
        require(payable(msg.sender).send(address(this).balance));

        poolInfo[0].totalFund = 0;
    } 

    /**
     * @dev It allows the admin to withdraw BQB sent to the contract by the users, 
     * only callable by owner.
     */
    function withdrawBQB() public onlyOwner {
        uint256 amount = balanceOfBQB();
        require(amount > 0, "No balance of BQB.");
        IERC20(bloqball).safeTransfer(msg.sender, amount);

        poolInfo[0].remainedBQB = 0;
        poolInfo[1].remainedBQB = 0;
    }      

    /**
     * @dev It allows the admin to withdraw LP token sent to the contract by the users, 
     * only callable by owner.
     */
    function withdrawLP() public onlyOwner {
        uint256 amount = balanceOfLP();
        require(amount > 0, "No balance of LP.");
        IERC20(lpToken).safeTransfer(msg.sender, amount);

        poolInfo[1].totalFund = 0;
    }    


    /**
     * @dev It allows the admin to withdraw all tokens sent to the contract by the users, 
     * only callable by owner.
     */
    function withdrawAllTreasury() public onlyOwner {
        withdrawFTM();
        withdrawBQB();
        withdrawLP();
    }
}