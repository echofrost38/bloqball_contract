// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './utils/Context.sol';
import './access/Ownable.sol';
import './interfaces/IERC20.sol';
import './interfaces/IUniswapV2Factory.sol';
import './interfaces/IUniswapV2Router02.sol';
import './interfaces/IBloqBallFactory.sol';
import './interfaces/IBloqBallRouter02.sol';
import './libraries/SafeMath.sol';
import './libraries/SafeToken.sol';

interface IOwnedDistributor {
    function totalShares() external view returns (uint);

    function recipients(address)
        external
        view
        returns (
            uint shares,
            uint lastShareIndex,
            uint credit
        );

    function editRecipient(address account, uint shares) external;
}

contract LiquidityGenerator is Ownable {
    using SafeMath for uint256;
    using SafeToken for address;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    
    IBloqBallRouter02 public bloqballRouter;
    address public bloqballPair;
    
    address public immutable bloqball;
    address public immutable distributor;

    address public reservesManager = address(0x2C4C168A2fE4CaB8E32d1B2A119d4Aa8BdA377e7);
    uint public  periodBegin;
    uint public  periodEnd;
    
    uint public periodDuration = 30 minutes; // 3 days;    // Period to deposit FTM

    uint public unlockTimestamp;
    uint public lockedPeriod = 30 minutes; //90 days;    // Period to be able to withdraww LP tokens from LiquidityGenertor to reservesManager
    bool public finalized = false;
    bool public delivered = false;
    
    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);
    event Finalized(uint amountbloqball, uint amountETH);
    event Deposit(
        address indexed sender,
        uint amount,
        uint distributorTotalShares,
        uint newShares
    );
    event PostponeUnlockTimestamp(uint prevUnlockTimestamp, uint unlockTimestamp);
    event Delivered(uint amountPair);

    constructor(
        address bloqball_,
        address distributor_,
        uint periodBegin_

    ) {
        // SpiritRouter address in ftm mainnet
//      uniswapV2Router = IUniswapV2Router02(0x16327e3fbdaca3bcf7e38f5af2599d2ddc33ae52);

        // SpiritRouter address in ftm testnet
        uniswapV2Router = IUniswapV2Router02(0x2Ee8FD4E67F2ab5990aB6ddb4F71016D31D3A3cd);

        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .getPair(bloqball_, uniswapV2Router.WETH());

        if (uniswapV2Pair == address(0)) {
            uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
                .createPair(bloqball_, uniswapV2Router.WETH());
        }

        // BloqballRouter address in ftm mainnet
//      bloqballRouter = IBloqBallRouter02(0x16327e3fbdaca3bcf7e38f5af2599d2ddc33ae52);

        // BloqballRouter address in ftm testnet
        bloqballRouter = IBloqBallRouter02(0xae50e11352F5D6B00d17b7222F402EA5b3DDbAfE);

        bloqballPair = IBloqBallFactory(bloqballRouter.factory())
            .getPair(bloqball_, bloqballRouter.WFTM());

        if (bloqballPair == address(0)) {
            bloqballPair = IBloqBallFactory(bloqballRouter.factory())
                .createPair(bloqball_, bloqballRouter.WFTM());
        }

        bloqball = bloqball_;
        distributor = distributor_;
        
        periodBegin = periodBegin_;
        periodEnd = periodBegin_.add(periodDuration);
    }

    /**
     * @notice Update the uniswap router
     */
    function updateUniswapV2Router(address _newAddress) public onlyOwner {
        require(_newAddress != address(0), "LiquidityGenerator: Wrong address");
        require(_newAddress != address(uniswapV2Router), "LiquidityGenerator: The router already has that address");

        emit UpdateUniswapV2Router(_newAddress, address(uniswapV2Router));

        uniswapV2Router = IUniswapV2Router02(_newAddress);

        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .getPair(bloqball, uniswapV2Router.WETH());

        if (uniswapV2Pair == address(0)) {
            uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
                .createPair(bloqball, uniswapV2Router.WETH());
        }
    }

    function distributorTotalShares() public view returns (uint totalShares) {
        return IOwnedDistributor(distributor).totalShares();
    }

    function distributorRecipients(address account)
        public
        view
        returns (
            uint shares,
            uint lastShareIndex,
            uint credit
        )
    {
        return IOwnedDistributor(distributor).recipients(account);
    }

    function postponeUnlockTimestamp(uint newUnlockTimestamp) public onlyOwner {

        require(newUnlockTimestamp > unlockTimestamp, "LiquidityGenerator: INVALID_UNLOCK_TIMESTAMP");
        uint prevUnlockTimestamp = unlockTimestamp;
        unlockTimestamp = newUnlockTimestamp;
        emit PostponeUnlockTimestamp(prevUnlockTimestamp, unlockTimestamp);
    }

    function deliverLiquidityToReservesManager() public onlyOwner {
        require(!delivered, "LiquidityGenerator: ALREADY_DELIVERED");
        require(finalized, "LiquidityGenerator: NOT_FINALIZED");
        
        uint blockTimestamp = getBlockTimestamp();
        require(blockTimestamp >= unlockTimestamp, "LiquidityGenerator: STILL_LOCKED");
        
        uint _amountPair = IERC20(uniswapV2Pair).balanceOf(address(this));
        uniswapV2Pair.safeTransfer(reservesManager, _amountPair);
        
        _amountPair = IERC20(bloqballPair).balanceOf(address(this));
        bloqballPair.safeTransfer(reservesManager, _amountPair);
        
        delivered = true;
        emit Delivered(_amountPair);
    }
    
    function finalize() public onlyOwner {
        require(!finalized, "LiquidityGenerator: FINALIZED");
        uint blockTimestamp = getBlockTimestamp();
        require(blockTimestamp >= periodEnd, "LiquidityGenerator: TOO_SOON");
        uint _amountBQBInSpirit = bloqball.myBalance().div(2);
        uint _amountFTMInSpirit = address(this).balance.div(2);
        
        uint _amountBQBInBloqBall = bloqball.myBalance().sub(_amountBQBInSpirit);
        uint _amountFTMInBloqBall = address(this).balance.sub(_amountFTMInSpirit);

        bloqball.safeApprove(address(uniswapV2Router), _amountBQBInSpirit);
        IUniswapV2Router01(uniswapV2Router).addLiquidityETH{value: _amountFTMInSpirit}(
            bloqball,
            _amountBQBInSpirit,
            0,
            0,
            address(this),
            blockTimestamp
        );
        
        bloqball.safeApprove(address(bloqballRouter), _amountBQBInBloqBall);
        IBloqBallRouter01(bloqballRouter).addLiquidityFTM{value: _amountFTMInBloqBall}(
            bloqball,
            _amountBQBInBloqBall,
            0,
            0,
            address(this),
            blockTimestamp
        );
        
        unlockTimestamp = blockTimestamp.add(lockedPeriod);
        
        finalized = true;
        emit Finalized(_amountBQBInSpirit, _amountFTMInSpirit);
        emit Finalized(_amountBQBInBloqBall, _amountFTMInBloqBall);
    }

    function deposit() external payable {
        uint blockTimestamp = getBlockTimestamp();
        require(blockTimestamp >= periodBegin, "LiquidityGenerator: TOO_SOON");
        require(blockTimestamp < periodEnd, "LiquidityGenerator: TOO_LATE");
        require(msg.value >= 1e17, "LiquidityGenerator: INVALID_VALUE");        // minium is 0.1 FTM
        require(msg.value <= 1e22, "LiquidityGenerator: INVALID_VALUE");        // maxium is 10K FTM
        
        (uint _prevShares, , ) = IOwnedDistributor(distributor).recipients(msg.sender);
        uint _newShares = _prevShares.add(msg.value);
        IOwnedDistributor(distributor).editRecipient(msg.sender, _newShares);
        
        emit Deposit(
            msg.sender,
            msg.value,
            distributorTotalShares(),
            _newShares
        );
    }

    receive() external payable {
        revert("LiquidityGenerator: BAD_CALL");
    }

    function getBlockTimestamp() public view virtual returns (uint) {
        return block.timestamp;
    }
    
    function setLockedPeriod(uint256 _period) public onlyOwner {
        lockedPeriod = _period;
    }
    
    function withdrawFTM() public onlyOwner {
        require(address(this).balance > 0, "LiquidityGenerator : No balance of FTM.");
        require(payable(msg.sender).send(address(this).balance));
    } 

    function withdrawBloqBall() public onlyOwner {
        require(IERC20(bloqball).balanceOf(address(this)) > 0, "LiquidityGenerator : No balance of BloqBall.");
        IERC20(bloqball).transfer(msg.sender, IERC20(bloqball).balanceOf(address(this)));
    } 
}