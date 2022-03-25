// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './utils/Context.sol';
import './access/Ownable.sol';
import './security/ReentrancyGuard.sol';
import './interfaces/IBloqBallReferral.sol';
import './interfaces/IERC20.sol';
import './interfaces/IBloqBallFactory.sol';
import './interfaces/IBloqBallRouter02.sol';
import './libraries/Address.sol';
import './utils/SafeERC20.sol';
import './libraries/SafeMath.sol';
import './BloqBallStakingDividendTracker.sol';

interface BloqBall {
    function mint(address _to, uint256 _amount) external;
    function transferTaxRate() external returns (uint256);
    function transferOwnership(address newOwner) external;
}

// MasterChef is the master of BQB. He can make BQB and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once BQB is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract MasterChef is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // The operator
    address private _operator;

    BloqBallStakingDividendTracker public dividendTracker;

   // Info of each Deposit.
    struct DepositInfo {
        uint256 pid;
        uint256 amount;
        uint256 lockupPeriod;
        uint256 nextWithdraw;
        uint256 accBloqBallPerShare;
        uint256 taxAmount;
    }

    mapping (address=> mapping(uint256=>DepositInfo[])) public depositInfo;

    // Info of each user.
    struct UserInfo {
        uint256 amount;             // How many LP tokens the user has provided.
        uint256 nextHarvestUntil;   // When can the user harvest again.
        uint256 totalEarnedBQB;
        uint256 taxAmount;
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. BQBs to distribute per block.
        uint256 lastRewardBlock;  // Last block number that BQBs distribution occurs.
        uint256 accBloqBallPerShare;   // Accumulated BQBs per share, times 1e12. See below.
        uint16 depositFeeBP;      // Deposit fee in basis points
        uint256 harvestInterval;  // Harvest interval in seconds
        uint256 totalStakedTokens;  // total count of staked tokens
    }
    
    // The BQB TOKEN!
    address public bloqball;

    // The count of BQB transfered from reward fees.
    uint256 private totalAmountFromFeeByRewards = 0;

    // Deposit Fee address
    address public feeAddress;

    // BQB tokens created per block.
    uint256 public BQBPerBlock = 1 * 10**18;
    uint256 public initialBQBPerBlock = 10 * 10 ** 18;          // 10 BQB until first 10 days

    // Bonus muliplier for early BQB makers.
    uint256 public constant BONUS_MULTIPLIER = 1;

    // First day and default harvest interval
    uint256 public constant DEFAULT_HARVEST_INTERVAL = 1 minutes;
    uint256 public constant MAX_HARVEST_INTERVAL = 20 minutes;  //1 days;
    uint256 public lockUpTaxRate = 50;                          // 50%

    // Info of each pool.
    PoolInfo[] public poolInfo;

    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;

    // BQB referral contract address.
    IBloqBallReferral public BloqBallReferral;
    
    // Referral commission rate in basis points.
    uint16 public referralCommissionRate = 100;
    
    // Max referral commission rate: 10%.
    uint16 public constant MAXIMUM_REFERRAL_COMMISSION_RATE = 1000;
    
    // The block number and timestamp when BQB mining starts.
    bool public enableStartBQBReward = false;
    uint256 public startBlock;

    mapping(uint8 => bool) public enableStaking;

    // Informations to get daily FTM reward for calculating APR of FTM rewards in staking BQB
    struct FTMRewardInfo {
        uint256 timestamp;
        uint256 totalAmountFromFee;
    }
    mapping(uint256 => FTMRewardInfo) public ftmRewardInfoAtId;
    uint public currentFTMRewardID;
    
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmissionRateUpdated(address indexed caller, uint256 previousAmount, uint256 newAmount);
    event ReferralCommissionPaid(address indexed user, address indexed referrer, uint256 commissionAmount);
    event OperatorTransferred(address indexed previousOperator, address indexed newOperator);
    event SendDividends(uint256 tokensamount);
    event ProcessedDividendTracker(
        uint256 iterations,
        uint256 claims,
        uint256 lastProcessedIndex,
        bool indexed automatic,
        uint256 gas,
        address indexed processor
    );

    modifier onlyOperator() {
        require(_operator == msg.sender, "operator: caller is not the operator");
        _;
    }

    constructor (address _bloqball) {
        dividendTracker = new BloqBallStakingDividendTracker();
        
        bloqball = _bloqball;

        feeAddress = msg.sender;
        _operator = _bloqball;
    }

    receive() external payable {
    }

    function setEnableStaking(uint8 _pid, bool _bEnable) external onlyOwner {
        enableStaking[_pid] = _bEnable;
    }

    // set to start the BQB rewards per block
    function setStartBQBReward() public onlyOwner {
        enableStartBQBReward = true;
        
        startBlock = block.number;
        uint256 length = poolInfo.length;
        
        for (uint256 pid = 0; pid < length; ++pid) {
            poolInfo[pid].lastRewardBlock = 
                block.number > poolInfo[pid].lastRewardBlock ? block.number : poolInfo[pid].lastRewardBlock;
        }
    }

    /**
     * @dev Set operator of the contract to a new account (`newOperator`).
     * Can only be called by the current operator.
     */
    function setOperator(address newOperator) public onlyOwner {
        require(newOperator != address(0), "BloqBall::transferOperator: new operator is the zero address");
        emit OperatorTransferred(_operator, newOperator);

        _operator = newOperator;
    }
    
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(uint256 _allocPoint, IERC20 _lpToken, uint16 _depositFeeBP, bool _withUpdate) public onlyOwner {
        require(_depositFeeBP <= 10000, "add: invalid deposit fee basis points");
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accBloqBallPerShare: 0,
            depositFeeBP: _depositFeeBP,
            harvestInterval: DEFAULT_HARVEST_INTERVAL,
            totalStakedTokens:0
        }));
    }

    // Update the given pool's BQB allocation point and deposit fee. Can only be called by the owner.
    function set(uint8 _pid, uint256 _allocPoint, uint16 _depositFeeBP, bool _withUpdate) public onlyOwner {
        require(_depositFeeBP <= 10000, "set: invalid deposit fee basis points");
        
        if (_withUpdate) {
            massUpdatePools();
        }

        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].depositFeeBP = _depositFeeBP;
        poolInfo[_pid].harvestInterval = DEFAULT_HARVEST_INTERVAL;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public pure returns (uint256) {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }
    
    // Return total reward multiplier over the given _from to _to block.
    function getTotalBQBRewardFromBlock() public view returns (uint256) {
        if (!enableStartBQBReward) {
            return 0;
        }
            
        uint256 multiplier;
        uint256 bloqBallReward = 0;

        uint256 midBlock = startBlock + 10 days;           // 10 days from start day

        if (midBlock < block.number) {
            multiplier = getMultiplier(startBlock, midBlock);
            bloqBallReward = multiplier.mul(initialBQBPerBlock);
            
            multiplier = getMultiplier(midBlock, block.number);
            bloqBallReward.add(multiplier.mul(BQBPerBlock));
        }
        else {
            multiplier = getMultiplier(startBlock, block.number);
            bloqBallReward = multiplier.mul(initialBQBPerBlock);
        }
        
        return bloqBallReward;
    }
    
    // Return reward multiplier over the given _from to _to block.
    function getBQBRewardFromBlock(uint8 _pid) private view returns (uint256) {
        if (!enableStartBQBReward) {
            return 0;
        }
            
        PoolInfo storage pool = poolInfo[_pid];    
            
        uint256 multiplier;
        uint256 bloqBallReward = 0;
        
        uint256 midBlock = startBlock + 10 days;                // 10 days from start day
        if (pool.lastRewardBlock > midBlock) {
            multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            bloqBallReward = multiplier.mul(BQBPerBlock);
        }
        else {
            if (midBlock < block.number) {
                multiplier = getMultiplier(pool.lastRewardBlock, midBlock);
                bloqBallReward = multiplier.mul(initialBQBPerBlock);
                
                multiplier = getMultiplier(midBlock, block.number);
                bloqBallReward.add(multiplier.mul(BQBPerBlock));
            }
            else {
                multiplier = getMultiplier(pool.lastRewardBlock, block.number);
                bloqBallReward = multiplier.mul(initialBQBPerBlock);
            }
        }
        
        return bloqBallReward;
    }

    // View function to see pending BQBs on frontend.
    function pendingBloqBall(uint8 _pid, address _user, bool bAll) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];

        uint256 accBloqBallPerShare = pool.accBloqBallPerShare;
        uint256 lpSupply = pool.totalStakedTokens; //pool.lpToken.balanceOf(address(this));

        if (lpSupply == 0)
            return 0;

        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 bloqBallReward = getBQBRewardFromBlock(_pid).mul(pool.allocPoint).div(totalAllocPoint);

            if (address(pool.lpToken) == bloqball) {
                bloqBallReward = bloqBallReward.add(totalAmountFromFeeByRewards);
            }

            accBloqBallPerShare = accBloqBallPerShare.add(bloqBallReward.mul(1e12).div(lpSupply));
        }

        (uint256 totalPending, uint256 claimablePending, ) = 
            availableRewardsForHarvest(_pid, _user, accBloqBallPerShare);
            
        if (bAll) {
            return totalPending;
        }
        else {
            return claimablePending;
        }
    }

    // View function to see if user can harvest BloqBalls.
    function canHarvest(uint8 _pid, address _user) public view returns (bool) {
        UserInfo storage user = userInfo[_pid][_user];
        return block.timestamp >= user.nextHarvestUntil;
    }
    
    // View function to see user's deposit info.
    function getDepositInfo(uint8 _pid, address _user) public view returns (DepositInfo[] memory) {
        return depositInfo[_user][_pid];
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint8 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint8 _pid) public {
        require(enableStaking[_pid] == true, 'Deposite: DISABLE DEPOSITING');

        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.totalStakedTokens; //pool.lpToken.balanceOf(address(this));

        if (lpSupply == 0 || pool.allocPoint == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }

        uint256 bloqBallReward = getBQBRewardFromBlock(_pid).mul(pool.allocPoint).div(totalAllocPoint);
               
        BloqBall(bloqball).mint(address(this), bloqBallReward);
        
        if (address(pool.lpToken) == bloqball) {
            bloqBallReward = bloqBallReward.add(totalAmountFromFeeByRewards);
            totalAmountFromFeeByRewards = 0;
        }

        pool.accBloqBallPerShare = pool.accBloqBallPerShare.add(bloqBallReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to MasterChef for BQB allocation.
    function deposit(uint8 _pid, uint256 _amount, address _referrer) public nonReentrant {
        require(enableStaking[_pid] == true, 'Deposite: DISABLE DEPOSITING');
        require(_amount > 0, 'Deposite: DISABLE DEPOSITING');
        
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        updatePool(_pid);

        if (address(BloqBallReferral) != address(0) 
                && _referrer != address(0) 
                && _referrer != msg.sender) {
            BloqBallReferral.recordReferral(msg.sender, _referrer);
        }

        pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);

        if (address(pool.lpToken) == bloqball) {
            uint256 transferTax = _amount.mul(BloqBall(bloqball).transferTaxRate()).div(10000);
            _amount = _amount.sub(transferTax);
        }

        pool.totalStakedTokens = pool.totalStakedTokens.add(_amount);

        if (pool.depositFeeBP > 0) {
            uint256 depositFee = _amount.mul(pool.depositFeeBP).div(10000);
            pool.lpToken.safeTransfer(feeAddress, depositFee);
            pool.totalStakedTokens -= depositFee;
            user.amount = user.amount.add(_amount).sub(depositFee);
        }
        else {
            user.amount = user.amount.add(_amount);
        }

        depositInfo[msg.sender][_pid].push(DepositInfo({
            pid: _pid,
            amount: _amount,
            lockupPeriod:MAX_HARVEST_INTERVAL,
            nextWithdraw: block.timestamp.add(MAX_HARVEST_INTERVAL),
            accBloqBallPerShare: pool.accBloqBallPerShare,
            taxAmount: 0
        }));

        if (user.nextHarvestUntil == 0) {
            user.nextHarvestUntil = block.timestamp.add(MAX_HARVEST_INTERVAL);
        }

        emit Deposit(msg.sender, _pid, _amount);
        
        if (address(pool.lpToken) == bloqball) {
            try dividendTracker.setBalance(payable(msg.sender), user.amount) {} catch {}
        }
    }

    // Harvest rewards.
    function harvest(uint8 _pid) public nonReentrant {
        require(enableStaking[_pid] == true, 'Deposite: DISABLE DEPOSITING');

        updatePool(_pid);
        payOrLockupPendingBQB(_pid);
    }

    function availableRewardsForHarvest(uint8 _pid, address _user, uint256 accPerShare) 
            private view returns (uint256 totalRewardAmount, uint256 rewardAmount, uint256 taxAmount) {
        uint256 totalRewards;
        uint256 rewardRate;
        uint256 rewardDebt;
        uint256 totalRewardDebt;

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        DepositInfo[] memory myDeposits =  depositInfo[_user][_pid];

        if (address(pool.lpToken) == bloqball) {
            accPerShare = accPerShare.sub(user.taxAmount.mul(1e12).div(pool.totalStakedTokens));
        }

        for(uint256 i=0; i< myDeposits.length; i++) {
                      
            rewardDebt = (myDeposits[i].amount).mul(myDeposits[i].accBloqBallPerShare).div(1e12);
            totalRewardDebt = totalRewardDebt.add(rewardDebt);

            totalRewards = (myDeposits[i].amount).mul(accPerShare).div(1e12);
            totalRewards = totalRewards.sub(rewardDebt);          

            rewardRate = calculateRewardRate(_pid, _user, i);     
            taxAmount = taxAmount.add(totalRewards.mul(rewardRate).div(10000));
            rewardAmount = rewardAmount.add(totalRewards.sub(totalRewards.mul(rewardRate).div(10000)));
        }

        totalRewardAmount = user.amount.mul(accPerShare).div(1e12).sub(totalRewardDebt);
    }

    function updateDepositInfo(uint8 _pid, address _user) private {
        PoolInfo storage pool = poolInfo[_pid];
        DepositInfo[] memory myDeposits =  depositInfo[_user][_pid];

        for(uint256 i=0; i< myDeposits.length; i++) {
            if(myDeposits[i].nextWithdraw < block.timestamp) {
                depositInfo[_user][_pid][i].accBloqBallPerShare = pool.accBloqBallPerShare;
            }
        }
    }

    function calculateRewardRate(uint8 _pid, address _user, uint256 _depositIndex) 
            private view returns (uint256 rewardRate) {
        DepositInfo storage myDeposit =  depositInfo[_user][_pid][_depositIndex];

        if (myDeposit.nextWithdraw > block.timestamp) {
            return lockUpTaxRate;
        }
        
        uint256 elapsedTime = block.timestamp.sub(myDeposit.nextWithdraw);

        uint256 interval = elapsedTime.div(MAX_HARVEST_INTERVAL);
        rewardRate = lockUpTaxRate.sub((interval.add(1)).mul(100));
    }

    function availableForWithdraw(address _user, uint8 _pid) public view returns (uint256 totalAmount) {
        totalAmount = 0;
        DepositInfo[] memory myDeposits =  depositInfo[_user][_pid];
        for(uint256 i=0; i< myDeposits.length; i++) {
            if(myDeposits[i].nextWithdraw < block.timestamp) {
                totalAmount = totalAmount.add(myDeposits[i].amount);
            }
        }
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint8 _pid, uint256 _amount) public nonReentrant {
        require(enableStaking[_pid] == true, 'Withdraw: DISABLE WITHDRAWING');
        
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        require(user.amount >= _amount, "withdraw: not good");

        uint256 availableAmount = availableForWithdraw(msg.sender, _pid);
        require(availableAmount > 0, "withdraw: no available amount");

        if (availableAmount < _amount) {
            _amount = availableAmount;
        }

        updatePool(_pid);
        payOrLockupPendingBQB(_pid);

        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
            pool.totalStakedTokens -= _amount;
        }

        // Remove desosit info in the array
        removeAmountFromDeposits(msg.sender, _pid, _amount, block.timestamp);
        removeEmptyDeposits(msg.sender, _pid);
        
        emit Withdraw(msg.sender, _pid, _amount);

        if (address(pool.lpToken) == bloqball) {
            try dividendTracker.setBalance(payable(msg.sender), user.amount) {} catch {}
        }
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint8 _pid) public nonReentrant {
        require(enableStaking[_pid] == true, 'Withdraw: DISABLE WITHDRAWING');
        
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.nextHarvestUntil = 0;
        pool.lpToken.safeTransfer(address(msg.sender), amount);
        pool.totalStakedTokens -= amount;
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    // Pay or lockup pending BloqBalls.
    function payOrLockupPendingBQB(uint8 _pid) internal {
        require(enableStaking[_pid] == true, 'Withdraw: DISABLE WITHDRAWING');
        
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        (, uint256 claimablePending, uint256 taxPending) = 
            availableRewardsForHarvest(_pid, msg.sender, pool.accBloqBallPerShare);

        if (canHarvest(_pid, msg.sender)) {
            if (claimablePending > 0) {
                totalAmountFromFeeByRewards = totalAmountFromFeeByRewards.add(taxPending);
                user.nextHarvestUntil = block.timestamp.add(pool.harvestInterval);

                // send BQB rewards
                safeBQBTransfer(msg.sender, claimablePending);
                payReferralCommission(msg.sender, claimablePending);

                user.totalEarnedBQB = user.totalEarnedBQB.add(claimablePending);
                user.taxAmount = taxPending;
                updateDepositInfo(_pid, msg.sender);
            }
        }
    }
    
    // Safe BQB transfer function, just in case if rounding error causes pool to not have enough BloqBalls.
    function safeBQBTransfer(address _to, uint256 _amount) internal {   
        uint256 BloqBallBal = IERC20(bloqball).balanceOf(address(this));
        if (_amount > BloqBallBal) {
            IERC20(bloqball).transfer(_to, BloqBallBal);
        } else {
            IERC20(bloqball).transfer(_to, _amount);
        }
    }

    function sendDividends(uint256 amount) public onlyOperator {
        require(amount < address(this).balance, 'sendDividends: Insufficient balance');

        (bool success,) = address(payable(dividendTracker)).call{value: amount}("");

        if (success) {
            dividendTracker.distributeDividends(amount);
            emit SendDividends(amount);

            ftmRewardInfoAtId[currentFTMRewardID].timestamp = block.timestamp;
            ftmRewardInfoAtId[currentFTMRewardID].totalAmountFromFee = dividendTracker.totalDividendsDistributed();
            
            currentFTMRewardID ++;
        }
    }

    function getRewardsFTMofPeriod(uint256 period) external view returns (uint256) {
        uint oldDay = block.timestamp - period * 1 days;
        uint256 newFTMReward;
        uint256 ftmRewardOfOldDay;
        
        if (currentFTMRewardID < 1) {
            return 0;
        }
        
        for (uint i=currentFTMRewardID-1; i>= 0; i--) {
            if (ftmRewardInfoAtId[currentFTMRewardID].timestamp < oldDay) {
                ftmRewardOfOldDay = ftmRewardInfoAtId[currentFTMRewardID].totalAmountFromFee;
                break;
            }
        }

        uint256 totalFTMReward = dividendTracker.totalDividendsDistributed();
        newFTMReward = totalFTMReward - ftmRewardOfOldDay;
        
        return newFTMReward;
    }

    function setFeeAddress(address _feeAddress) public {
        require(msg.sender == feeAddress, "setFeeAddress: FORBIDDEN");
        require(_feeAddress != address(0), "setFeeAddress: ZERO");
        feeAddress = _feeAddress;
    }
    
    function setLockUpTaxRate(uint256 _limit) public onlyOwner {
        require(_limit <= 100, 'Limit Period: can not over 100%');
        lockUpTaxRate = _limit;
    }

    function removeAmountFromDeposits(address _user, uint8 _pid, uint256 _amount, uint256 _time) private {
        uint256 length =  depositInfo[_user][_pid].length;

        for(uint256 i=0; i< length; i++) {
            if(depositInfo[_user][_pid][i].nextWithdraw < _time) {
                if (depositInfo[_user][_pid][i].amount <= _amount) {
                    _amount = _amount.sub(depositInfo[_user][_pid][i].amount);
                    depositInfo[_user][_pid][i].amount = 0;
                }
                else {
                    depositInfo[_user][_pid][i].amount = depositInfo[_user][_pid][i].amount.sub(_amount);
                    _amount = 0;
                }
            }

            if (_amount == 0) {
                break;
            }
        }
    }

    function removeEmptyDeposits(address user, uint8 _pid) private {
        for (uint256 i=0; i<depositInfo[user][_pid].length; i++) {
            while(depositInfo[user][_pid].length > 0 && depositInfo[user][_pid][i].amount  == 0) {
                for (uint256 j = i; j<depositInfo[user][_pid].length-1; j++) {
                    depositInfo[user][_pid][j] = depositInfo[user][_pid][j+1];
                }
                depositInfo[user][_pid].pop();
            }
        }
    }

    // BQB has to add hidden dummy pools in order to alter the emission, here we make it simple and transparent to all.
    function updateEmissionRate(uint256 _BloqBallPerBlock) public onlyOwner {
        massUpdatePools();
        emit EmissionRateUpdated(msg.sender, BQBPerBlock, _BloqBallPerBlock);
        BQBPerBlock = _BloqBallPerBlock;
    }

    // Update the BQB referral contract address by the owner
    function setBQBReferral(IBloqBallReferral _BloqBallReferral) public onlyOwner {
        BloqBallReferral = _BloqBallReferral;
    }

    // Update referral commission rate by the owner
    function setReferralCommissionRate(uint16 _referralCommissionRate) public onlyOwner {
        require(_referralCommissionRate <= MAXIMUM_REFERRAL_COMMISSION_RATE, "setReferralCommissionRate: invalid referral commission rate basis points");
        referralCommissionRate = _referralCommissionRate;
    }

    // Pay referral commission to the referrer who referred this user.
    function payReferralCommission(address _user, uint256 _pending) internal {
        if (address(BloqBallReferral) != address(0) && referralCommissionRate > 0) {
            address referrer = BloqBallReferral.getReferrer(_user);
            uint256 commissionAmount = _pending.mul(referralCommissionRate).div(10000);

            if (referrer != address(0) && commissionAmount > 0) {
                BloqBall(bloqball).mint(referrer, commissionAmount);
                BloqBallReferral.recordReferralCommission(referrer, commissionAmount);
                emit ReferralCommissionPaid(_user, referrer, commissionAmount);
            }
        }
    }

    function transferOwnershipOfBloqBall() public onlyOwner {
        BloqBall(bloqball).transferOwnership(msg.sender);
    }


    //====================================== Dividend Distribute ========================================//

    /**
     * @notice Get the total amount of dividend distributed
     */ 
    function getTotalDividendsDistributed() external view returns (uint256) {
        return dividendTracker.totalDividendsDistributed();
    }

    /**
     * @notice View the amount of dividend in wei that an address can withdraw.
     */ 
    function withdrawableDividendOf(address account) public view returns(uint256) {
        return dividendTracker.withdrawableDividendOf(account);
    }

    /**
     * @notice View the amount of dividend in wei that an address has earned in total.
     */ 
    function withdrawnDividendOf(address account) public view returns(uint256) {
        return dividendTracker.withdrawnDividendOf(account);
    }

    /**
     * @notice Get the dividend token balancer in account
     */ 
    function dividendTokenBalanceOf(address account) public view returns (uint256) {
        return dividendTracker.balanceOf(account);
    }

    /**
     * @notice Exclude from receiving dividends
     */ 
    function excludeFromDividends(address account) external onlyOwner{
        dividendTracker.excludeFromDividends(account);
    }

    /**
     * @notice Get the dividend infor for account
     */ 
    function getAccountDividendsInfo(address account)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
        return dividendTracker.getAccount(account);
    }

    /**
     * @notice Get the indexed dividend infor
     */ 
    function getAccountDividendsInfoAtIndex(uint256 index)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
        return dividendTracker.getAccountAtIndex(index);
    }

    /**
     * @notice Withdraws the token distributed to all token holders
     */
    function processDividendTracker() external {
        (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) = dividendTracker.process();
        emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, false, 0, tx.origin);

    }

    /**
     * @notice Withdraws the token distributed to the sender.
     */
    function claim() external {
        dividendTracker.processAccount(payable(msg.sender), false, true);
    }

    /**
     * @notice Get the last processed info in dividend tracker
     */
    function getLastProcessedIndex() external view returns(uint256) {
        return dividendTracker.getLastProcessedIndex();
    }

    /**
     * @notice Get the number of dividend token holders
     */
    function getNumberOfDividendTokenHolders() external view returns(uint256) {
        return dividendTracker.getNumberOfTokenHolders();
    }
}