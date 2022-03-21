// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import './interfaces/IBloqBallFactory.sol';
import './libraries/TransferHelper.sol';
import './interfaces/IBloqBallRouter01.sol';
import './interfaces/IBloqBallRouter02.sol';
import './interfaces/IBloqBallPair.sol';
import './libraries/BloqBallLibrary.sol';
import './libraries/SafeMath.sol';
import './interfaces/IERC20.sol';
import './interfaces/IWFTM.sol';

contract BloqBallRouter is IBloqBallRouter02 {
    using SafeMath for uint;

    address public immutable override factory;
    address public immutable override WFTM;
    
    bool    private enableLiquidity = true;
    address private owner;

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'BloqBallRouter: EXPIRED');
        _;
    }

    constructor(address _factory, address _WFTM) public {
        factory = _factory;
        WFTM = _WFTM;
    
        owner = msg.sender;
    }

    receive() external payable {
        assert(msg.sender == WFTM); // only accept FTM via fallback from the WFTM contract
    }

    function setEnableLiquidity(bool bEnable) external {
        require(msg.sender == owner, "You are not the owner");
        enableLiquidity = bEnable;
    }

    // **** ADD LIQUIDITY ****
    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin
    ) internal virtual returns (uint amountA, uint amountB) {
        // create the pair if it doesn't exist yet
        if (IBloqBallFactory(factory).getPair(tokenA, tokenB) == address(0)) {
            IBloqBallFactory(factory).createPair(tokenA, tokenB);
        }
        (uint reserveA, uint reserveB) = BloqBallLibrary.getReserves(factory, tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
            
        } else {
            uint amountBOptimal = BloqBallLibrary.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, 'BloqBallRouter: INSUFFICIENT_B_AMOUNT');
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint amountAOptimal = BloqBallLibrary.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, 'BloqBallRouter: INSUFFICIENT_A_AMOUNT');
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }
    
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint amountA, uint amountB, uint liquidity) {
        require(enableLiquidity == true, 'BloqBallRouter: DISABLE ADDING LIQUIDITY');
        
        (amountA, amountB) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
        address pair = BloqBallLibrary.pairFor(factory, tokenA, tokenB);
        TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);
        liquidity = IBloqBallPair(pair).mint(to);
    }
    
    function addLiquidityFTM(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountFTMMin,
        address to,
        uint deadline
    ) external virtual override  payable ensure(deadline) returns (uint amountToken, uint amountFTM, uint liquidity) {
        require(enableLiquidity == true, 'BloqBallRouter: DISABLE ADDING LIQUIDITY');
         
        (amountToken, amountFTM) = _addLiquidity(
            token,
            WFTM,
            amountTokenDesired,
            msg.value,
            amountTokenMin,
            amountFTMMin
        );
        
        address pair = BloqBallLibrary.pairFor(factory, token, WFTM);
        
        TransferHelper.safeTransferFrom(token, msg.sender, pair, amountToken);
        IWFTM(WFTM).deposit{value: amountFTM}();
        assert(IWFTM(WFTM).transfer(pair, amountFTM));
        liquidity = IBloqBallPair(pair).mint(to);
        // refund dust FTM, if any
        if (msg.value > amountFTM) 
            TransferHelper.safeTransferFTM(msg.sender, msg.value - amountFTM);
    }

    // **** REMOVE LIQUIDITY ****
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountA, uint amountB) {
        require(enableLiquidity == true, 'BloqBallRouter: DISABLE REMOVING LIQUIDITY');
        
        address pair = BloqBallLibrary.pairFor(factory, tokenA, tokenB);
        
        IBloqBallPair(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        (uint amount0, uint amount1) = IBloqBallPair(pair).burn(to);
        (address token0,) = BloqBallLibrary.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        require(amountA >= amountAMin, 'BloqBallRouter: INSUFFICIENT_A_AMOUNT');
        require(amountB >= amountBMin, 'BloqBallRouter: INSUFFICIENT_B_AMOUNT');
    }
    
    function removeLiquidityFTM(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountFTMMin,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountToken, uint amountFTM) {
        require(enableLiquidity == true, 'BloqBallRouter: DISABLE REMOVING LIQUIDITY');
        
        (amountToken, amountFTM) = removeLiquidity(
            token,
            WFTM,
            liquidity,
            amountTokenMin,
            amountFTMMin,
            address(this),
            deadline
        );
        
        TransferHelper.safeTransfer(token, to, amountToken);
        IWFTM(WFTM).withdraw(amountFTM);
        TransferHelper.safeTransferFTM(to, amountFTM);
    }
    
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual override returns (uint amountA, uint amountB) {
        require(enableLiquidity == true, 'BloqBallRouter: DISABLE REMOVING LIQUIDITY');
        
        address pair = BloqBallLibrary.pairFor(factory, tokenA, tokenB);
        uint value = approveMax ? uint(-1) : liquidity;
        IBloqBallPair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountA, amountB) = removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline);
    }
    function removeLiquidityFTMWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountFTMMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual override returns (uint amountToken, uint amountFTM) {
        require(enableLiquidity == true, 'BloqBallRouter: DISABLE ADDING LIQUIDITY');
        
        address pair = BloqBallLibrary.pairFor(factory, token, WFTM);
        uint value = approveMax ? uint(-1) : liquidity;
        IBloqBallPair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountToken, amountFTM) = removeLiquidityFTM(token, liquidity, amountTokenMin, amountFTMMin, to, deadline);
    }
    


    // **** REMOVE LIQUIDITY (supporting fee-on-transfer tokens) ****
    function removeLiquidityFTMSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountFTMMin,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountFTM) {
        require(enableLiquidity == true, 'BloqBallRouter: DISABLE REMOVING LIQUIDITY');
        
        (, amountFTM) = removeLiquidity(
            token,
            WFTM,
            liquidity,
            amountTokenMin,
            amountFTMMin,
            address(this),
            deadline
        );
        TransferHelper.safeTransfer(token, to, IERC20(token).balanceOf(address(this)));
        IWFTM(WFTM).withdraw(amountFTM);
        TransferHelper.safeTransferFTM(to, amountFTM);
    }
    function removeLiquidityFTMWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountFTMMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual override returns (uint amountFTM) {
        require(enableLiquidity == true, 'BloqBallRouter: DISABLE REMOVING LIQUIDITY');
        
        address pair = BloqBallLibrary.pairFor(factory, token, WFTM);
        uint value = approveMax ? uint(-1) : liquidity;
        IBloqBallPair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        amountFTM = removeLiquidityFTMSupportingFeeOnTransferTokens(
            token, liquidity, amountTokenMin, amountFTMMin, to, deadline
        );
    }

    // **** SWAP ****
    // requires the initial amount to have already been sent to the first pair
    function _swap(uint[] memory amounts, address[] memory path, address _to) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = BloqBallLibrary.sortTokens(input, output);
            uint amountOut = amounts[i + 1];
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            address to = i < path.length - 2 ? BloqBallLibrary.pairFor(factory, output, path[i + 2]) : _to;
            
            IBloqBallPair(BloqBallLibrary.pairFor(factory, input, output)).swap(
                amount0Out, amount1Out, to, new bytes(0)
            );
        }
    }
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
        amounts = BloqBallLibrary.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'BloqBallRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, BloqBallLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, to);
    }
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
        amounts = BloqBallLibrary.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, 'BloqBallRouter: EXCESSIVE_INPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, BloqBallLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, to);
    }
    
    function swapExactFTMForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        payable
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[0] == WFTM, 'BloqBallRouter: INVALID_PATH');
        amounts = BloqBallLibrary.getAmountsOut(factory, msg.value, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'BloqBallRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        IWFTM(WFTM).deposit{value: amounts[0]}();
        assert(IWFTM(WFTM).transfer(BloqBallLibrary.pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to);
    }
    
    function swapTokensForExactFTM(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[path.length - 1] == WFTM, 'BloqBallRouter: INVALID_PATH');
        amounts = BloqBallLibrary.getAmountsIn(factory, amountOut, path);
        
        require(amounts[0] <= amountInMax, 'BloqBallRouter: EXCESSIVE_INPUT_AMOUNT');
        
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, BloqBallLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, address(this));
        
        IWFTM(WFTM).withdraw(amounts[amounts.length - 1]); 
        TransferHelper.safeTransferFTM(to, amounts[amounts.length - 1]);
    }
    function swapExactTokensForFTM(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[path.length - 1] == WFTM, 'BloqBallRouter: INVALID_PATH');
        amounts = BloqBallLibrary.getAmountsOut(factory, amountIn, path);
        
        require(amounts[amounts.length - 1] >= amountOutMin, 'BloqBallRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, BloqBallLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        
        _swap(amounts, path, address(this));

        IWFTM(WFTM).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferFTM(to, amounts[amounts.length - 1]);
    }
    
    function swapFTMForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        payable
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[0] == WFTM, 'BloqBallRouter: INVALID_PATH');
        amounts = BloqBallLibrary.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= msg.value, 'BloqBallRouter: EXCESSIVE_INPUT_AMOUNT');
        
        IWFTM(WFTM).deposit{value: amounts[0]}();
        
        assert(IWFTM(WFTM).transfer(BloqBallLibrary.pairFor(factory, path[0], path[1]), amounts[0]));
        
        _swap(amounts, path, to);
        // refund dust FTM, if any
        if (msg.value > amounts[0]) TransferHelper.safeTransferFTM(msg.sender, msg.value - amounts[0]);
    }

    // **** SWAP (supporting fee-on-transfer tokens) ****
    // requires the initial amount to have already been sent to the first pair
    function _swapSupportingFeeOnTransferTokens(address[] memory path, address _to) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = BloqBallLibrary.sortTokens(input, output);
            IBloqBallPair pair = IBloqBallPair(BloqBallLibrary.pairFor(factory, input, output));
            uint amountInput;
            uint amountOutput;
            { // scope to avoid stack too deep errors
            (uint reserve0, uint reserve1,) = pair.getReserves();
            (uint reserveInput, uint reserveOutput) = input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
            amountInput = IERC20(input).balanceOf(address(pair)).sub(reserveInput);
            amountOutput = BloqBallLibrary.getAmountOut(amountInput, reserveInput, reserveOutput);
            }
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOutput) : (amountOutput, uint(0));
            address to = i < path.length - 2 ? BloqBallLibrary.pairFor(factory, output, path[i + 2]) : _to;
            pair.swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) {
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, BloqBallLibrary.pairFor(factory, path[0], path[1]), amountIn
        );
        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
        require(
            IERC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
            'BloqBallRouter: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }

    function swapExactFTMForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        virtual
        override
        payable
        ensure(deadline)
    {
        require(path[0] == WFTM, 'BloqBallRouter: INVALID_PATH');
        uint amountIn = msg.value;
        IWFTM(WFTM).deposit{value: amountIn}();
        assert(IWFTM(WFTM).transfer(BloqBallLibrary.pairFor(factory, path[0], path[1]), amountIn));
        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
        require(
            IERC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
            'BloqBallRouter: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }


    function swapExactTokensForFTMSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        virtual
        override
        ensure(deadline)
    {
        require(path[path.length - 1] == WFTM, 'BloqBallRouter: INVALID_PATH');
        
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, BloqBallLibrary.pairFor(factory, path[0], path[1]), amountIn
        );
        _swapSupportingFeeOnTransferTokens(path, address(this));
        uint amountOut = IERC20(WFTM).balanceOf(address(this));
        require(amountOut >= amountOutMin, 'BloqBallRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        IWFTM(WFTM).withdraw(amountOut);
        TransferHelper.safeTransferFTM(to, amountOut);
    }
    
    // **** LIBRARY FUNCTIONS ****
    function quote(uint amountA, uint reserveA, uint reserveB) 
        public 
        pure 
        virtual 
        override 
        returns (uint amountB) 
    {
        return BloqBallLibrary.quote(amountA, reserveA, reserveB);
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut)
        public
        pure
        virtual
        override
        returns (uint amountOut)
    {
        return BloqBallLibrary.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut)
        public
        pure
        virtual
        override
        returns (uint amountIn)
    {
        return BloqBallLibrary.getAmountIn(amountOut, reserveIn, reserveOut);
    }

    function getAmountsOut(uint amountIn, address[] memory path)
        public
        view
        virtual
        override
        returns (uint[] memory amounts)
    {
        return BloqBallLibrary.getAmountsOut(factory, amountIn, path);
    }

    function getAmountsIn(uint amountOut, address[] memory path)
        public
        view
        virtual
        override
        returns (uint[] memory amounts)
    {
        return BloqBallLibrary.getAmountsIn(factory, amountOut, path);
    }
}