
// SPDX-License-Identifier: MIT

pragma solidity >= 0.5.16;

interface ERC20Interface {
    function balanceOf(address user) external view returns (uint256);
}

library SafeToken {
    function myBalance(address token) internal view returns (uint256) {
        return ERC20Interface(token).balanceOf(address(this));
    }

    function balanceOf(address token, address user) internal view returns (uint256) {
        return ERC20Interface(token).balanceOf(user);
    }

    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeApprove");
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeTransfer");
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeTransferFrom");
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "!safeTransferETH");
    }
}

// File: contracts/libraries/SafeMath.sol



pragma solidity >=0.5.16;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}
// File: contracts/interfaces/IBloqBallRouter01.sol



pragma solidity >= 0.6.0;

interface IBloqBallRouter01 {
    function factory() external pure returns (address);
    function WFTM() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityFTM(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountFTMMin,
        address to,
        uint deadline
    ) external  payable returns (uint amountToken, uint amountFTM, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityFTM(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountFTMMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountFTM);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityFTMWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountFTMMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountFTM);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactFTMForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactFTM(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForFTM(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapFTMForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}
// File: contracts/interfaces/IBloqBallRouter02.sol



pragma solidity >= 0.6.0;


interface IBloqBallRouter02 is IBloqBallRouter01 {
    function removeLiquidityFTMSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountFTMMin,
        address to,
        uint deadline
    ) external returns (uint amountFTM);
    function removeLiquidityFTMWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountFTMMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountFTM);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactFTMForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForFTMSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
// File: contracts/interfaces/IBloqBallFactory.sol



pragma solidity >= 0.5.16;

interface IBloqBallFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}
// File: contracts/interfaces/IUniswapV2Router01.sol



pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// File: contracts/interfaces/IUniswapV2Router02.sol



pragma solidity >=0.6.2;


interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// File: contracts/interfaces/IUniswapV2Factory.sol



pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// File: contracts/interfaces/IERC20.sol



pragma solidity >= 0.5.16;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/utils/Context.sol



pragma solidity >=0.6.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal pure virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: contracts/access/Ownable.sol



pragma solidity >=0.6.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts/LiquidityGenerator.sol



pragma solidity ^0.8.0;










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

    address public reservesManager = address(0x1c62e6f7dD3BD5ef0999080056c289d600Ee31Ec);
    uint public  periodBegin;
    uint public  periodEnd;
    
    uint public periodDuration = 3 days;    // Period to deposit FTM

    uint public unlockTimestamp;
    uint public lockedPeriod =  90 days;    // Period to be able to withdraww LP tokens from LiquidityGenertor to reservesManager
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