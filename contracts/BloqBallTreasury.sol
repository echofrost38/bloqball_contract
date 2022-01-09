// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

// File @openzeppelin/contracts/utils/Context.sol@v3.4.1

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


// File @openzeppelin/contracts/access/Ownable.sol@v3.4.1

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


// File @openzeppelin/contracts/utils/ReentrancyGuard.sol@v3.4.1

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


// File @openzeppelin/contracts/token/ERC20/IERC20.sol@v3.4.1

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
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
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
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
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


// File @openzeppelin/contracts/math/SafeMath.sol@v3.4.1

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


// File @openzeppelin/contracts/utils/Address.sol@v3.4.1

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}


// File @openzeppelin/contracts/token/ERC20/SafeERC20.sol@v3.4.1


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity >=0.5.0;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}


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
    ) external payable returns (uint amountToken, uint amountFTM, uint liquidity);
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
    function getReservesOfLiquidity(address tokenA, address tokenB)  external view returns (uint256, uint256); 
}

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

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

contract BloqBallTreasury is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public operatorAddress;

    address public bloqball;
    address public bloqballRouter;
    address public WFTM;
    address public lpToken;
    address public treasuryToken;
    address public uniswapRouter;

    AggregatorV3Interface internal priceFeedOfTreasuryToken;
    AggregatorV3Interface internal priceFeedOfFTM;

    uint256 private discountRate = 1000;      // 10%
    uint256 private buybackRate = 1000;       // 10%

    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    uint256 private decimal = 10 ** 18;

    uint256[4] public allocPoints;

    // Info of each pool.
    struct PoolInfo {
        IERC20 token;                       // Address of token contract.
        uint256 discountRate;               // discount rate
        uint256 totalDepositBQB;            // total count of deposited tokens
        uint256 totalPurchasedBQB;          // total count of purchased tokens
        uint256 remainedBQB;                // total count of remained tokens
    }

    PoolInfo[] public poolInfo;

   // Info of each Purchase.
    struct PurchasedInfo {
        uint256 pid;                        // Pool ID
        uint256 sellAmount;                 // count of sell-token
        uint256 buyAmount;                  // count of buy-token
        uint256 lockupPeriod;
    }

    mapping (address=> mapping(uint=>PurchasedInfo[])) public purchasedInfo;

    modifier onlyOperator() {
        require(msg.sender == operatorAddress, "Not operator");
        _;
    }

    event depositBQB(uint256 amount0, uint256 amount1, uint256 amount2, uint256 amount3);
    event TokensPurchased(address receiver, address token, uint256 amount, uint256 rate);
    event TokensClaimed(address receiver, uint256 amount);
    event buyBack(address sellToken, uint sellAmount, uint buyAmount);
    event burnBQB(address token, uint256 amount);
    event UpdateUniswapRouter(address newAddress, address oldAddress);
    event UpdateTreasuryToken(address newAddress, address oldAddress);
    event NewOperatorAddresses(address newAddress);

    /**
     * Network: FANTOM
     * Aggregator: FTM/USD
     * Address: 0xe04676B9A9A2973BCb0D1478b5E1E9098BBB7f3D in testnet    
     * address: 0xf4766552D15AE4d256Ad41B6cf2933482B0680dc in mainnet
     */

    /**
     * Network: FANTOM
     * Aggregator: DAI/USD
     * Address: no in testnet    
     * address: 0x91d5DEFAFfE2854C7D02F50c80FA1fdc8A721e52 in mainnet
     */

    constructor(
        address _bloqball,
        address _treasuryToken,
        address _priceFeedOfTreasurytoken,
        address _uniswapRouter,
        address _bloqballRouter,
        address _bloqballPair
    ) public {
        bloqball = _bloqball;
        treasuryToken = _treasuryToken;
        priceFeedOfTreasuryToken = AggregatorV3Interface(_priceFeedOfTreasurytoken);
        uniswapRouter = _uniswapRouter;
        bloqballRouter = _bloqballRouter;
        lpToken = _bloqballPair;

        WFTM = IBloqBallRouter01(bloqballRouter).WFTM();
        priceFeedOfFTM = AggregatorV3Interface(0xe04676B9A9A2973BCb0D1478b5E1E9098BBB7f3D);

        allocPoints[0] = 2500;
        allocPoints[1] = 2500;
        allocPoints[2] = 2500;
        allocPoints[3] = 2500;

        operatorAddress = msg.sender;
    }

    receive() external payable {
    }

    // Add a new token to the pool. Can only be called by the owner.
    function add(IERC20 _token, uint16 _discountRate) public onlyOwner {
        require(address(_token) != address(this), "token : Wrong address");
        poolInfo.push(PoolInfo({
            token: _token,
            discountRate: _discountRate,
            totalDepositBQB: 0,
            totalPurchasedBQB: 0,
            remainedBQB: 0
        }));
    }

    function set(uint _pid, IERC20 _token, uint16 _discountRate, uint256 _totalDespositBQB, 
                uint256 _totalPurchasedBQB, uint256 _remainedBQB) public onlyOwner {
        require(address(_token) != address(this), "token : Wrong address");
        poolInfo[_pid].token = _token;
        poolInfo[_pid].discountRate = _discountRate;
        poolInfo[_pid].totalDepositBQB = _totalDespositBQB;
        poolInfo[_pid].totalPurchasedBQB = _totalPurchasedBQB;
        poolInfo[_pid].remainedBQB = _remainedBQB;
    }

    function setAllocpoint(uint256[4] memory _allocPoints) public onlyOwner {
        require(
            (_allocPoints[0] +
                _allocPoints[1] +
                _allocPoints[2] +
                _allocPoints[3]) == 10000,
            "Rewards must equal 10000"
        );

        allocPoints = _allocPoints;
    }

    function depositTreasury(uint256 _amount) external onlyOperator {
        uint256[4] memory amount;

        amount[0] = _amount.mul(allocPoints[0]).div(10000);
        amount[1] = _amount.mul(allocPoints[1]).div(10000);
        amount[2] = _amount.mul(allocPoints[2]).div(10000);
        amount[3] = _amount.sub(amount[0]).sub(amount[1]).sub(amount[2]);

        swapTokensForFTM(amount[0]);
        swapTokensForTreasuryToken(amount[1]);

        poolInfo[0].totalDepositBQB = amount[2];
        poolInfo[0].remainedBQB = amount[2];

        poolInfo[1].totalDepositBQB = amount[3];
        poolInfo[1].remainedBQB = amount[2];

        // emit an event when tokens are deposited
        emit depositBQB(amount[0], amount[1], amount[2], amount[3]);
    }

    function swapTokensForFTM(uint256 _bloqballAmount) private {
        address[] memory path = new address[](2);
        path[0] = bloqball;
        path[1] = WFTM;

        // make the swap
        IERC20(bloqball).approve(bloqballRouter, _bloqballAmount);
        IBloqBallRouter02(bloqballRouter).swapExactTokensForFTMSupportingFeeOnTransferTokens(
          _bloqballAmount,
          0, // accept any amount of ETH
          path,
          address(this),
          block.timestamp
        );
    }

    function swapTokensForTreasuryToken(uint256 _bloqballAmount) private {
        address[] memory path = new address[](3);
        path[0] = bloqball;
        path[1] = IUniswapV2Router01(uniswapRouter).WETH();
        path[2] = treasuryToken;

        // make the swap
        IERC20(bloqball).approve(uniswapRouter, _bloqballAmount);
        IUniswapV2Router02(uniswapRouter).swapExactTokensForTokensSupportingFeeOnTransferTokens(
          _bloqballAmount,
          0,
          path,
          address(this),
          block.timestamp
        );
    }

    function buyBQBWithFTM(uint256 _lockupPeriod) public payable {
        require(msg.value > 0, "Insufficient value");

        uint rate = calculateRateFTM2BQB();
        uint tokenAmount = msg.value.mul(rate).div(decimal);
        tokenAmount = tokenAmount.add(tokenAmount.mul(poolInfo[0].discountRate).div(10000));

        // check if the contract has enough tokens
        require(poolInfo[0].remainedBQB >= tokenAmount, "Available BQB not sufficient to complete buying");

        poolInfo[0].totalPurchasedBQB = poolInfo[0].totalPurchasedBQB.add(tokenAmount);
        poolInfo[0].remainedBQB = poolInfo[0].remainedBQB.sub(tokenAmount);

        purchasedInfo[msg.sender][0].push(PurchasedInfo({
            pid: 0,
            sellAmount: msg.value,
            buyAmount: tokenAmount,
            lockupPeriod:block.timestamp.add(_lockupPeriod)
        }));

        // emit an event when tokens are purchased
        emit TokensPurchased(msg.sender, bloqball, tokenAmount, rate);
    }

    function buyBQBWithLP(uint256 _amount, uint256 _lockupPeriod) public {
        uint rate = calculateRateLP2BQB();
        uint tokenAmount = _amount.mul(rate).div(decimal);
        tokenAmount = tokenAmount.add(tokenAmount.mul(poolInfo[1].discountRate).div(10000));

        // check if the contract has enough tokens
        require(poolInfo[1].remainedBQB >= tokenAmount, "Available BQB not sufficient to complete buying");

        poolInfo[1].totalPurchasedBQB = poolInfo[1].totalPurchasedBQB.add(tokenAmount);
        poolInfo[1].remainedBQB = poolInfo[1].remainedBQB.sub(tokenAmount);

        purchasedInfo[msg.sender][1].push(PurchasedInfo({
            pid: 1,
            sellAmount: _amount,
            buyAmount: tokenAmount,
            lockupPeriod:block.timestamp.add(_lockupPeriod)
        }));

        IERC20(poolInfo[1].token).safeTransferFrom(msg.sender, address(this), _amount);

        // emit an event when tokens are purchased
        emit TokensPurchased(msg.sender, bloqball, tokenAmount, rate);
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
        uint256 totalClaimable = pendingBQB(_pid, msg.sender);

        if (totalClaimable > 0) {
            IERC20(bloqball).safeTransfer(msg.sender, totalClaimable);
        }

        // Remove purchased info in the array
        removeAmountFromPurchased(msg.sender, _pid, totalClaimable, block.timestamp);
        removeEmptyPurchased(msg.sender, _pid);

        // emit an event when tokens are claimed
        emit TokensClaimed(msg.sender, totalClaimable);
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

    function calculateRateFTM2BQB() public view returns (uint256){
        address[] memory path = new address[](2);
        path[0] = WFTM;
        path[1] = bloqball;

        uint256 amountIn = 1 * decimal;
        uint[] memory amounts = IBloqBallRouter01(bloqballRouter).getAmountsOut(amountIn, path);

        return amounts[1];
    }

    function calculateRateBQB2FTM() public view returns (uint256){
        address[] memory path = new address[](2);
        path[0] = bloqball;
        path[1] = WFTM;

        uint256 amountIn = 1 * decimal;
        uint[] memory amounts = IBloqBallRouter01(bloqballRouter).getAmountsOut(amountIn, path);

        return amounts[1];
    }

    function calculateRateLP2BQB() public view returns (uint256){
        (uint256 amountBQB, uint256 amountFTM) = 
                IBloqBallRouter01(bloqballRouter).getReservesOfLiquidity(bloqball, WFTM);

        uint256 rate = calculateRateFTM2BQB();
        amountBQB = amountBQB.add(amountFTM.mul(rate).div(decimal));

        return amountBQB.mul(decimal).div(IERC20(lpToken).totalSupply()); 
    }

    function calculatePriceOfLP() public view returns (uint256){
        uint256 amountBQB = calculateRateLP2BQB();

        (, int price, , , ) = priceFeedOfFTM.latestRoundData();

        uint256 rate = calculateRateBQB2FTM();
        uint256 currentPriceOfBQB = uint256(price).mul(rate).div(decimal);

        return currentPriceOfBQB.mul(amountBQB).div(decimal);
    }
    
    function calculatBackingPrice() public view returns (uint256){
        uint256 totalTreasuryBalance = treasuryBalance();
        uint256 totalSupply = (IERC20(bloqball).totalSupply()).sub(10000000 * decimal);        // sub amount of bqb in lottery

        return totalTreasuryBalance.mul(decimal).div(totalSupply);
    }

    function treasuryBalance() public view returns (uint256){
       // Calculate the total price of FTM
        uint256 balanceOfToken;
        balanceOfToken = balanceOfFTM();

        (, int price, , , ) = priceFeedOfFTM.latestRoundData();

        uint256 totalPrice = balanceOfToken.mul(uint256(price)).div(decimal);

        // Calculate the total price of treasury token
        balanceOfToken = balanceOfTreasuryToken();

        (, int price1, , , ) = priceFeedOfTreasuryToken.latestRoundData();

        totalPrice = totalPrice.add(balanceOfToken.mul(uint256(price1)).div(decimal));

        // Calculate the total price of LP token
        balanceOfToken = balanceOfLP();
        uint256 priceLP = calculatePriceOfLP();

        return totalPrice.add(balanceOfToken.mul(uint256(priceLP)).div(decimal));        
    }

    function isEnableBuyback() public view returns (bool){
        (, int price, , , ) = priceFeedOfFTM.latestRoundData();

        uint256 rate = calculateRateBQB2FTM();

        uint256 currentPriceOfBQB = uint256(price).mul(rate).div(decimal);

        uint256 backingPrice = calculatBackingPrice();

        return (currentPriceOfBQB < backingPrice);
    }

    function comparePriceAndBuyback() public onlyOperator{
        bool enableBuyBack = isEnableBuyback();

        if (enableBuyBack) {
            uint256 amount = balanceOfFTM();
            amount = amount.mul(buybackRate).div(uint(10000));
            buybackBQBwithFTMfromRouter(amount);

            amount = balanceOfLP();
            amount = amount.mul(buybackRate).div(uint(10000));
            buybackBQBwithLPfromRouter(amount);

            amount = balanceOfTreasuryToken();
            amount = amount.mul(buybackRate).div(uint(10000));
            buybackBQBwithTreasuryTokenfromRouter(amount);
        }
    }

    function buybackBQBwithFTMfromRouter(uint256 _amountofFTM) private {
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

        emit buyBack(WFTM, _amountofFTM, newBalance.sub(oldBalance));
    }

    function buybackBQBwithTreasuryTokenfromRouter(uint256 _amountofTreasuryToken) private {
        require(_amountofTreasuryToken <= balanceOfTreasuryToken(), "Insufficient value");

        address[] memory path = new address[](3);
        path[0] = treasuryToken;
        path[1] = IUniswapV2Router01(uniswapRouter).WETH();
        path[2] = bloqball;

        uint256 oldBalance = IERC20(bloqball).balanceOf(address(this));

        IERC20(treasuryToken).approve(uniswapRouter, _amountofTreasuryToken);
        IUniswapV2Router02(uniswapRouter).swapExactTokensForTokensSupportingFeeOnTransferTokens(
          _amountofTreasuryToken,
          0,
          path,
          address(this),
          block.timestamp
        );

        uint256 newBalance = IERC20(bloqball).balanceOf(address(this));

        emit buyBack(treasuryToken, _amountofTreasuryToken, newBalance.sub(oldBalance));
    }

    function buybackBQBwithLPfromRouter(uint256 _amountofLP) private {
        require(_amountofLP <= balanceOfLP(), "Insufficient value");

        uint256 oldBalance = IERC20(bloqball).balanceOf(address(this));

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

        emit buyBack(lpToken, _amountofLP, newBalance.sub(oldBalance));
    }

    function buybackBQBWithFTMfromUser(uint256 _amountofBQB) public {
        bool enableBuyBack = isEnableBuyback();
        require(enableBuyBack, "BuyBack is not available.");

        uint rate = calculateRateBQB2FTM();
        uint tokenAmount = _amountofBQB.mul(rate).div(decimal);
        tokenAmount = tokenAmount.add(tokenAmount.mul(discountRate).div(uint(10000)));

        require(address(this).balance >= tokenAmount, "Available FTM not sufficient to complete buying");
        require(payable(msg.sender).send(tokenAmount));

        IERC20(bloqball).safeTransferFrom(msg.sender, address(this), _amountofBQB);

        // emit an event when tokens are purchased
        emit TokensPurchased(msg.sender, WFTM, tokenAmount, rate);
    }

    function buybackBQBWithTreasuryTokenfromUser(uint256 _amountofBQB) public {
        bool enableBuyBack = isEnableBuyback();
        require(enableBuyBack, "BuyBack is not available.");

        (, int price, , , ) = priceFeedOfFTM.latestRoundData();

        uint256 rate = calculateRateBQB2FTM();
        uint256 currentPriceOfBQB = uint256(price).mul(rate).div(decimal);

        (, int currentPriceOfTreasuryToken, , , ) = priceFeedOfTreasuryToken.latestRoundData();

        uint tokenAmount = _amountofBQB.mul(currentPriceOfBQB).
                                        div(uint256(currentPriceOfTreasuryToken));
        tokenAmount = tokenAmount.add(tokenAmount.mul(discountRate).div(uint(10000)));

        require(IERC20(treasuryToken).balanceOf(address(this)) >= tokenAmount, 
                "Available Treasury token not sufficient to complete buying");

        IERC20(bloqball).safeTransferFrom(msg.sender, address(this), _amountofBQB);
        IERC20(treasuryToken).transfer(msg.sender, tokenAmount);

        // emit an event when tokens are purchased
        emit TokensPurchased(msg.sender, treasuryToken, tokenAmount, rate);
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

    function balanceOfTreasuryToken() public view returns (uint256) {
        return IERC20(treasuryToken).balanceOf(address(this));
    }

    function balanceOfLP() public view returns (uint256) {
        return IERC20(lpToken).balanceOf(address(this));
    }

    function updateUniswapRouter(address _newAddress) public onlyOwner {
        require(
          _newAddress != address(uniswapRouter),
          "uniswapRouter: The router already has that address"
        );
        emit UpdateUniswapRouter(_newAddress, address(uniswapRouter));
        uniswapRouter = _newAddress;
    }

    function updateTreasuryToken(address _newAddress, address _priceFeed) public onlyOwner {
        require(_newAddress != address(0), "Token Cannot be zero address");
        require(_priceFeed != address(0), "Price Feed Cannot be zero address");

        priceFeedOfTreasuryToken = AggregatorV3Interface(_priceFeed);

        emit UpdateTreasuryToken(_newAddress, treasuryToken);

        treasuryToken = _newAddress;
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

    function getOperator() external view returns (address){
        return operatorAddress;
    }

    /**
     * @dev It allows the admin to withdraw FTM sent to the contract by the users, 
     * only callable by owner.
     */
    function withdrawFTM() public onlyOwner {
        require(address(this).balance > 0, "No balance of ETH.");
        require(payable(msg.sender).send(address(this).balance));
    } 

    /**
     * @dev It allows the admin to withdraw BQB sent to the contract by the users, 
     * only callable by owner.
     */
    function withdrawBQB() public onlyOwner {
        uint256 amount = balanceOfBQB();
        require(amount > 0, "No balance of BQB.");
        IERC20(bloqball).safeTransfer(msg.sender, amount);
    }      

    /**
     * @dev It allows the admin to withdraw LP token sent to the contract by the users, 
     * only callable by owner.
     */
    function withdrawLP() public onlyOwner {
        uint256 amount = balanceOfLP();
        require(amount > 0, "No balance of LP.");
        IERC20(lpToken).safeTransfer(msg.sender, amount);
    }    

    /**
     * @dev It allows the admin to withdraw treasury token sent to the contract by the users, 
     * only callable by owner.
     */
    function withdrawTreasuryToken() public onlyOwner {
        uint256 amount = balanceOfTreasuryToken();
        require(amount > 0, "No balance of Treasury token.");
        IERC20(treasuryToken).safeTransfer(msg.sender, amount);
    }    

    /**
     * @dev It allows the admin to withdraw all tokens sent to the contract by the users, 
     * only callable by owner.
     */
    function withdrawAllTreasury() public onlyOwner {
        withdrawFTM();
        withdrawBQB();
        withdrawLP();
        withdrawTreasuryToken();
    }
}