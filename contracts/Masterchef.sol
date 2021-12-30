
pragma solidity ^0.8.4;

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

    constructor () {
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

interface IBloqBallReferral {
    /**
     * @dev Record referral.
     */
    function recordReferral(address user, address referrer) external;

    /**
     * @dev Record referral commission.
     */
    function recordReferralCommission(address referrer, uint256 commission) external;

    /**
     * @dev Get the referrer address that referred the user.
     */
    function getReferrer(address user) external view returns (address);
}



// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
        assembly {
            size := extcodesize(account)
        }
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
        (bool success, ) = recipient.call{value: amount}("");
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: value}(data);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol

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
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


// File: @openzeppelin/contracts/math/SafeMath.sol
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

// File: @openzeppelin/contracts/utils/Context.sol

// SPDX-License-Identifier: MIT

/*
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

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol

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
    constructor () {
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

interface BQBToken {
    function mint(address _to, uint256 _amount) external;
    function transferTaxRate() external returns (uint256);
    function swapTokensForFTMFrom(uint256 tokenAmount, address _from, address _to) external;
    function transferOwnership(address newOwner) external;
    function operator() external view returns (address) ;
}

interface BlogBallRouter {
    function getAmountsOutFromExactTokensForFTM(uint amountIn, address _path) external view returns (uint[] memory amounts);
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

   // Info of each Deposit.
    struct DepositInfo {
        uint256 pid;
        uint256 amount;
        uint256 lockupPeriod;
        uint256 nextWithdraw;
        uint256 accBloqBallPerShare;
        uint256 taxAmount;
    }

    mapping (address=> mapping(uint=>DepositInfo[])) public depositInfo;

    // Info of each user.
    struct UserInfo {
        uint256 amount;             // How many LP tokens the user has provided.
        uint256 nextHarvestUntil;   // When can the user harvest again.
        uint256 nextHarvestFTMUntil;
        uint256 totalEarnedBQB;
        uint256 totalEarnedFTM;
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
    BQBToken public BloqBall;
    BlogBallRouter public BQBRouter;
    
    // The count of BQB transfered from transaction fees.
    uint256 private totalAmountFromFee = 0;

    // The count of BQB transfered from reward fees.
    uint256 private totalAmountFromFeeByRewards = 0;
    
    struct TopBalance {
        uint balance;
        address addr;
    }
    
    TopBalance[] public topbalanceusers;

    // Deposit Fee address
    address public feeAddress;

    // BQB tokens created per block.
    uint256 public BQBPerBlock = 1 * 10**18;

    // Bonus muliplier for early BQB makers.
    uint256 public constant BONUS_MULTIPLIER = 1;

    // First day and default harvest interval
    uint256 public constant DEFAULT_HARVEST_INTERVAL = 1 minutes;
    uint256 public constant MAX_HARVEST_INTERVAL = 1 days;
    
    // Max top user count who can have FTM rewards from fee
    uint256 private limitofTopUserCountforFTMRewards = 100;

    // Info of each pool.
    PoolInfo[] public poolInfo;

    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;

    // The block number when BQB mining starts.
    uint256 public startBlock;

    // BQB referral contract address.
    IBloqBallReferral public BloqBallReferral;
    
    struct amountRewardAtTime {
        uint timestamp;
        uint256 totalAmountFromFee;
    }
    mapping(uint256 => amountRewardAtTime) private currentFeeIdofRewardAtTime;
    uint private currentFeeID;

    // Referral commission rate in basis points.
    uint16 public referralCommissionRate = 100;
    
    // Max referral commission rate: 10%.
    uint16 public constant MAXIMUM_REFERRAL_COMMISSION_RATE = 1000;
    
    bool public enableStaking = true;
    bool public enableStartBQBReward = false;
    
    uint256 public limitDaysOfRewardTax = 50;
    
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmissionRateUpdated(address indexed caller, uint256 previousAmount, uint256 newAmount);
    event ReferralCommissionPaid(address indexed user, address indexed referrer, uint256 commissionAmount);

    constructor (
        BQBToken _BloqBall,
        BlogBallRouter _BQBRouter
    ) {
        BloqBall = _BloqBall;
        BQBRouter = _BQBRouter;

        feeAddress = msg.sender;
    }

    function addTransferFee(uint256 amount) public {
        if (!enableStaking)
            return;
        
        totalAmountFromFee += amount;

        currentFeeIdofRewardAtTime[currentFeeID].timestamp = block.timestamp;
        currentFeeIdofRewardAtTime[currentFeeID].totalAmountFromFee = totalAmountFromFee;
        
        currentFeeID ++;
    }
    
    function getRewardsFTMofDay() external view returns (uint256) {
        uint yesterday = block.timestamp - 1 days;
        uint256 amountofDay;
        uint256 amountofYesterday;
        
        if (currentFeeID < 1) {
            return 0;
        }
        
        for (uint i=currentFeeID-1; i>= 0; i--) {
            if (currentFeeIdofRewardAtTime[currentFeeID].timestamp < yesterday) {
                amountofYesterday = currentFeeIdofRewardAtTime[currentFeeID].totalAmountFromFee;
                break;
            }
        }
        
        amountofDay = totalAmountFromFee - amountofYesterday;
        require(amountofDay >= 0, "Fee: invalid transaction fee in masterchef");
        
        uint[] memory amounts;

        amounts = BQBRouter.getAmountsOutFromExactTokensForFTM(amountofDay, address(BloqBall));
        
        return amounts[1];
    }
    
    function setEnableStaking(bool bEnable) external onlyOwner {
        enableStaking = bEnable;
    }
    
    function getTotalAmountofFTMFromFee() external view returns (uint) {
        if (totalAmountFromFee == 0) {
            return 0;
        }
            
        uint[] memory amounts;

        amounts = BQBRouter.getAmountsOutFromExactTokensForFTM(totalAmountFromFee, address(BloqBall));
        return amounts[1];
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
    function set(uint256 _pid, uint256 _allocPoint, uint16 _depositFeeBP, bool _withUpdate) public onlyOwner {
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
    
    // set to start the BQB rewards per block
    function setStartBQBReward() public {
        enableStartBQBReward = true;
        
        startBlock = block.number;
        uint256 length = poolInfo.length;
        
        for (uint256 pid = 0; pid < length; ++pid) {
            poolInfo[pid]. lastRewardBlock = block.number > poolInfo[pid].lastRewardBlock ? block.number : poolInfo[pid].lastRewardBlock;
        }
    }
    
    // Return total reward multiplier over the given _from to _to block.
    function getTotalBQBRewardFromBlock() public view returns (uint256) {
        if (!enableStartBQBReward) {
            return 0;
        }
            
        uint256 multiplier;
        uint256 bloqBallReward = 0;
        uint256 initialBQBPerBlock = 10 * 10 ** 18;        // 10 BQB until 10 days
        
        uint256 midBlock = startBlock + 10 days;            // 10 days from start day

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
    function getBQBRewardFromBlock(uint256 _pid) private view returns (uint256) {
        if (!enableStartBQBReward) {
            return 0;
        }
            
        PoolInfo storage pool = poolInfo[_pid];    
            
        uint256 multiplier;
        uint256 bloqBallReward = 0;
        uint256 initialBQBPerBlock = 10 * 10 ** 18;             // 10 BQB until 10 days
        
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
    function pendingBloqBall(uint256 _pid, address _user, bool bAll) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];

        uint256 accBloqBallPerShare = pool.accBloqBallPerShare;
        uint256 lpSupply = pool.totalStakedTokens; //pool.lpToken.balanceOf(address(this));

        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 bloqBallReward = getBQBRewardFromBlock(_pid).mul(pool.allocPoint).div(totalAllocPoint);

            if (address(pool.lpToken) == address(BloqBall)) {
                bloqBallReward = bloqBallReward.add(totalAmountFromFeeByRewards);
            }

            accBloqBallPerShare = accBloqBallPerShare.add(bloqBallReward.mul(1e12).div(lpSupply));
        }

        (uint totalPending, uint256 claimablePending, ) = 
            availableRewardsForHarvest(_pid, _user, accBloqBallPerShare);
            
        if (bAll) {
            return totalPending;
        }
        else {
            return claimablePending;
        }
    }

    // View function to see pending FTMs on frontend.
    function pendingFTM(address _user) external view returns (uint256) {
        uint256[] memory accountRewardFromFee = getUserFTMRewardFromFee(_user);

        return accountRewardFromFee[1];
    }
    
    function harvestFTM(uint256 _pid, address _user) external returns (uint256) {
        require(enableStaking == true, 'Harvest FTM: DISABLE');
        
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        
        if (canHarvestFTM(_pid, _user)) {
            uint256[] memory accountRewardFromFee = getUserFTMRewardFromFee(_user);
            uint256 pending = accountRewardFromFee[1];

            if (pending > 0) {
                safeFTMTransfer(_user, accountRewardFromFee[0]);
                totalAmountFromFee = totalAmountFromFee.sub(accountRewardFromFee[0]);
                
                user.nextHarvestFTMUntil = block.timestamp.add(pool.harvestInterval);

                user.totalEarnedFTM = user.totalEarnedFTM.add(accountRewardFromFee[1]);
            }
    
            return accountRewardFromFee[1];
        }
        else {
            return uint256(0);
        }
    }
    
    // View function to see if user can harvest BloqBalls.
    function canHarvest(uint256 _pid, address _user) public view returns (bool) {
        UserInfo storage user = userInfo[_pid][_user];
        return block.timestamp >= user.nextHarvestUntil;
    }
    
    // View function to see if user can harvest BloqBalls.
    function canHarvestFTM(uint256 _pid, address _user) public view returns (bool) {
        UserInfo storage user = userInfo[_pid][_user];
        return block.timestamp >= user.nextHarvestFTMUntil;
    }

    // View function to see user's deposit list.
    function getDepositInfo(uint256 _pid, address _user) public view returns (DepositInfo[] memory) {
        return depositInfo[_user][_pid];
    }
    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        require(enableStaking == true, 'Update: DISABLE');
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        require(enableStaking == true, 'Deposite: DISABLE DEPOSITING');
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
               
        BloqBall.mint(address(this), bloqBallReward);
        
        if (address(pool.lpToken) == address(BloqBall)) {
            bloqBallReward = bloqBallReward.add(totalAmountFromFeeByRewards);
            totalAmountFromFeeByRewards = 0;
        }

        pool.accBloqBallPerShare = pool.accBloqBallPerShare.add(bloqBallReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // Update reward variables of the given pool to be up-to-date.
    function rearrangeTopX(address addr, uint currentValue) public {
        uint i = 0;
        
        // find addr from the array
        for(i; i < topbalanceusers.length; i++) {
            if(topbalanceusers[i].addr == addr) {
                /** shift the array of position (getting rid of the last element) **/
                uint j;
                for(j = i; j < topbalanceusers.length-1; j++) {
                    topbalanceusers[j].balance = topbalanceusers[j + 1].balance;
                    topbalanceusers[j].addr = topbalanceusers[j + 1].addr;
                }
                // initialize the last position
                topbalanceusers[topbalanceusers.length-1].balance = 0;
                topbalanceusers[topbalanceusers.length-1].addr = address(0);
            }
        }
        
        if (i == topbalanceusers.length) {
            TopBalance memory lastuser;
            lastuser.balance = 0;
            lastuser.addr = address(0);
            topbalanceusers.push(lastuser);
        }
        
        i = 0;
        /** get the index of the current max element **/
        for(i; i < topbalanceusers.length; i++) {
            if(topbalanceusers[i].balance < currentValue) {
                break;
            }
        }
        
        /** shift the array of position (getting rid of the last element) **/
        for(uint j = topbalanceusers.length-1; j > i; j--) {
            topbalanceusers[j].balance = topbalanceusers[j - 1].balance;
            topbalanceusers[j].addr = topbalanceusers[j - 1].addr;
        }
                
        /** update the new max element **/
        topbalanceusers[i].balance = currentValue;
        topbalanceusers[i].addr = addr;
    }
    
    function getUserFTMRewardFromFee(address addr) public view returns (uint[] memory) {
        uint i = 0;
        uint toplevel = limitofTopUserCountforFTMRewards;
        uint256 rewardsfromfee = 0;
        uint[] memory accountfromfee = new uint[](2);
        
        if (topbalanceusers.length <= limitofTopUserCountforFTMRewards) {
            accountfromfee[0] = 0;
            accountfromfee[1] = 0;
            
            return accountfromfee;
        }
       
        for(i; i < toplevel; i++) {
            if(topbalanceusers[i].addr == addr) {
                if (i < 10) {
                    rewardsfromfee = totalAmountFromFee.mul(40).div(100).div(10);       // 40% of total transaction fee for 10 users
                    break;
                }
                else if (i < 50) {
                    rewardsfromfee = totalAmountFromFee.mul(35).div(100).div(40);       // 35% of total transaction fee for 40 users
                    break;
                }
                else if (i < 100) {
                    rewardsfromfee = totalAmountFromFee.mul(25).div(100).div(50);       // 60% of total transaction fee for 50users
                    break;
                }
            }
        }
        
        if (rewardsfromfee == 0) {
            accountfromfee[0] = 0;
            accountfromfee[1] = 0;
        }
        else {
            // get WFTM count for the BQBs from fee
            accountfromfee = BQBRouter.getAmountsOutFromExactTokensForFTM(rewardsfromfee, address(BloqBall));
        }
        
        return accountfromfee;
    }

    // Deposit LP tokens to MasterChef for BQB allocation.
    function deposit(uint256 _pid, uint256 _amount, address _referrer) public nonReentrant {
        require(enableStaking == true, 'Deposite: DISABLE DEPOSITING');
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

        if (address(pool.lpToken) == address(BloqBall)) {
            uint256 transferTax = _amount.mul(BloqBall.transferTaxRate()).div(10000);
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

        if (user.nextHarvestFTMUntil == 0) {
            user.nextHarvestFTMUntil = block.timestamp.add(MAX_HARVEST_INTERVAL);
        }

        emit Deposit(msg.sender, _pid, _amount);
        
        // calculate user level in BQB staking
        if (address(pool.lpToken) == address(BloqBall)) {
            rearrangeTopX(msg.sender, user.amount);
        }
    }

    // Harvest rewards.
    function harvest(uint256 _pid) public nonReentrant {
        require(enableStaking == true, 'Deposite: DISABLE DEPOSITING');

        updatePool(_pid);
        payOrLockupPendingBQB(_pid);
    }

    function availableRewardsForHarvest(uint256 _pid, address _user, uint256 accPerShare) 
            private view returns (uint totalRewardAmount, uint rewardAmount, uint taxAmount) {
        uint256 totalRewards;
        uint256 rewardRate;
        uint256 rewardDebt;
        uint256 totalRrewardDebt;

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        DepositInfo[] memory myDeposits =  depositInfo[_user][_pid];

        if (address(pool.lpToken) == address(BloqBall)) {
            accPerShare = accPerShare.sub(user.taxAmount.mul(1e12).div(pool.totalStakedTokens));
        }

        for(uint i=0; i< myDeposits.length; i++) {
            if (myDeposits[i].nextWithdraw < block.timestamp) {
                rewardRate = calculateRewardRate(_pid, _user, i);               
                rewardDebt = (myDeposits[i].amount).mul(myDeposits[i].accBloqBallPerShare).div(1e12);
                totalRrewardDebt = totalRrewardDebt.add(rewardDebt);
                totalRewards = (myDeposits[i].amount).mul(accPerShare).div(1e12);
                totalRewards = totalRewards.sub(rewardDebt);            

                rewardAmount = rewardAmount.add(totalRewards.mul(rewardRate).div(10000));
                taxAmount = taxAmount.add(totalRewards.sub(totalRewards.mul(rewardRate).div(10000)));
            }
        }

        totalRewardAmount = user.amount.mul(accPerShare).div(1e12).sub(totalRrewardDebt);
    }

    function updateDepositInfo(uint _pid, address _user) private {
        PoolInfo storage pool = poolInfo[_pid];
        DepositInfo[] memory myDeposits =  depositInfo[_user][_pid];

        for(uint i=0; i< myDeposits.length; i++) {
            if(myDeposits[i].nextWithdraw < block.timestamp) {
                depositInfo[_user][_pid][i].accBloqBallPerShare = pool.accBloqBallPerShare;
            }
        }
    }

    function calculateRewardRate(uint _pid, address _user, uint _depositIndex) 
            private view returns (uint256 rewardRate) {
        DepositInfo storage myDeposit =  depositInfo[_user][_pid][_depositIndex];

        if (myDeposit.nextWithdraw > block.timestamp) {
            return 0;
        }
        
        uint elapsedTime = block.timestamp.sub(myDeposit.nextWithdraw);
        
        if (elapsedTime > limitDaysOfRewardTax.mul(MAX_HARVEST_INTERVAL)) {
            rewardRate = 9900;          // 99%
        }
        else {
            uint interval = elapsedTime.div(MAX_HARVEST_INTERVAL);
            rewardRate = (uint(10000)).sub((limitDaysOfRewardTax.sub(interval)).mul(uint(100)));
        }
    }

    function availableForWithdraw(address _user, uint _pid) public view returns (uint totalAmount) {
        totalAmount = 0;
        DepositInfo[] memory myDeposits =  depositInfo[_user][_pid];
        for(uint i=0; i< myDeposits.length; i++) {
            if(myDeposits[i].nextWithdraw < block.timestamp) {
                totalAmount = totalAmount.add(myDeposits[i].amount);
            }
        }
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public nonReentrant {
        require(enableStaking == true, 'Withdraw: DISABLE WITHDRAWING');
        
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
        
        // calculate user level
        if (address(pool.lpToken) == address(BloqBall)) {
            rearrangeTopX(msg.sender, user.amount);
        }
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public nonReentrant {
        require(enableStaking == true, 'Withdraw: DISABLE WITHDRAWING');
        
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
    function payOrLockupPendingBQB(uint256 _pid) internal {
        require(enableStaking == true, 'Withdraw: DISABLE WITHDRAWING');
        
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        (, uint256 claimablePending, uint256 taxPpending) = 
            availableRewardsForHarvest(_pid, msg.sender, pool.accBloqBallPerShare);

        if (canHarvest(_pid, msg.sender)) {
            if (claimablePending > 0) {
                totalAmountFromFeeByRewards = totalAmountFromFeeByRewards.add(taxPpending);
                user.nextHarvestUntil = block.timestamp.add(pool.harvestInterval);

                // send BQB rewards
                safeBQBTransfer(msg.sender, claimablePending);
                payReferralCommission(msg.sender, claimablePending);

                user.totalEarnedBQB = user.totalEarnedBQB.add(claimablePending);
                user.taxAmount = taxPpending;
                updateDepositInfo(_pid, msg.sender);
            }
        }
    }
    
    // Safe BQB transfer function, just in case if rounding error causes pool to not have enough BloqBalls.
    function safeBQBTransfer(address _to, uint256 _amount) internal {
        require(enableStaking == true, 'Deposite: DISABLE DEPOSITING');
        
        uint256 BloqBallBal = IERC20(address(BloqBall)).balanceOf(address(this));
        if (_amount > BloqBallBal) {
            IERC20(address(BloqBall)).transfer(_to, BloqBallBal);
        } else {
            IERC20(address(BloqBall)).transfer(_to, _amount);
        }
    }
    
    // Safe FTM transfer function, just in case if rounding error causes pool to not have enough BloqBalls.
    function safeFTMTransfer(address _to, uint256 _amount) internal {
        require(enableStaking == true, 'Deposite: DISABLE DEPOSITING');
        
         // generate the BloqBall pair path of token -> wftm
        BloqBall.swapTokensForFTMFrom(_amount, address(this), _to);
    }

    function setFeeAddress(address _feeAddress) public {
        require(msg.sender == feeAddress, "setFeeAddress: FORBIDDEN");
        require(_feeAddress != address(0), "setFeeAddress: ZERO");
        feeAddress = _feeAddress;
    }

    function setMaxCountofTopUserForFTMRewards(uint amount) external onlyOwner{
        limitofTopUserCountforFTMRewards = amount;
    }
    
    function setLimitPeriodOfRewardTax(uint _limit) public onlyOwner {
        require(_limit <= 100, 'Limit Period: can not over 100 days');
        limitDaysOfRewardTax = _limit;
    }

    function removeAmountFromDeposits(address _user, uint _pid, uint _amount, uint _time) private {
        uint length =  depositInfo[_user][_pid].length;

        for(uint i=0; i< length; i++) {
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

    function removeEmptyDeposits(address user, uint _pid) private {
        for (uint i=0; i<depositInfo[user][_pid].length; i++) {
            while(depositInfo[user][_pid].length > 0 && depositInfo[user][_pid][i].amount  == 0) {
                for (uint j = i; j<depositInfo[user][_pid].length-1; j++) {
                    depositInfo[user][_pid][j] = depositInfo[user][_pid][j+1];
                }
                depositInfo[user][_pid].pop();
            }
        }
    }

    // BQB has to add hidden dummy pools in order to alter the emission, here we make it simple and transparent to all.
    function updateEmissionRate(uint256 _BloqBallPerBlock) public onlyOwner {
        require(enableStaking == true, 'Deposite: DISABLE DEPOSITING');
        
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
                BloqBall.mint(referrer, commissionAmount);
                BloqBallReferral.recordReferralCommission(referrer, commissionAmount);
                emit ReferralCommissionPaid(_user, referrer, commissionAmount);
            }
        }
    }

    function transferOwnershipOfbloqball() public onlyOwner {
        BloqBall.transferOwnership(msg.sender);
    }
}