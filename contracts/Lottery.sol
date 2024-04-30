
// File: @openzeppelin/contracts/utils/Context.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    constructor() {
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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol

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

    constructor() {
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

// File: @openzeppelin/contracts/utils/Address.sol

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

// File: contracts/IRandomNumberGenerator.sol

interface IRandomNumberGenerator {
    /**
     * Requests randomness from a user-provided seed
     */
    function getRandomNumber(uint256 _seed) external;

    /**
     * View latest lotteryId numbers
     */
    function viewLatestLotteryId() external view returns (uint256);

    /**
     * Views random result
     */
    function viewRandomResult() external view returns (uint32);
}

// File: contracts/interfaces/IBloqBallSwapLottery.sol

interface IBloqBallSwapLottery {
    /**
     * @notice Buy tickets for the current lottery
     * @param _lotteryId: lotteryId
     * @param _ticketNumbers: array of ticket numbers between 1,000,000 and 1,999,999
     * @dev Callable by users
     */
    function buyTickets(uint256 _lotteryId, uint256[] calldata _ticketNumbers) external;

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
    ) external;

    /**
     * @notice Close lottery
     * @param _lotteryId: lottery id
     * @dev Callable by operator
     */
    function closeLottery(uint256 _lotteryId) external;

    /**
     * @notice Draw the final number, calculate reward in BQB per group, and make lottery claimable
     * @param _lotteryId: lottery id
     * @param _autoInjection: reinjects funds into next lottery (vs. withdrawing all)
     * @dev Callable by operator
     */
    function drawFinalNumberAndMakeLotteryClaimable(uint256 _lotteryId, bool _autoInjection) external;

    /**
     * @notice Inject funds
     * @param _lotteryId: lottery id
     * @param _amount: amount to inject in BQB token
     * @dev Callable by operator
     */
    function injectFunds(uint256 _lotteryId, uint256 _amount) external;

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
        uint256[6] calldata _rewardsBreakdown,
        uint256 _treasuryFee
    ) external;

    /**
     * @notice View current lottery id
     */
    function viewCurrentLotteryId() external returns (uint256);
}


interface BQBToken {
    function mint(address _to, uint256 _amount) external;
    function transferTaxRate() external returns (uint256);
}

interface RandomNumberGenerator {
    function setLotteryAddress(address _bloqballSwapLottery) external;
    function setFee(uint256 _fee) external;
    function setKeyHash(bytes32 _keyHash) external;
}

// File: contracts/BloqBallSwapLottery.sol

pragma abicoder v2;

/** @title BloqBallSwap Lottery.
 * @notice It is a contract for a lottery system using
 * randomness provided externally.
 */
contract BloqBallLottery is ReentrancyGuard, IBloqBallSwapLottery, Ownable {
    using SafeERC20 for IERC20;

    address public injectorAddress;
    address public operatorAddress;
    address public treasuryAddress;
    
    // Burn address
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    uint256 public currentLotteryId;
    uint256 public currentTicketId;

    uint256 public maxNumberTicketsPerBuyOrClaim = 100;

    uint256 public maxPriceTicketInBQB = 500 * 10 ** 18;        // 500 BQB
    uint256 public minPriceTicketInBQB = 1 * 10 ** 18;          // 1 BQB
    uint256 public priceTicketInBQB = 50 * 10 ** 18;            // 50 BQB;

    uint256 public pendingInjectionNextLottery;
    uint256 public prizeReserve = 10000000 * 10 ** 18;            // 10M BQB

    uint256 public constant MIN_DISCOUNT_DIVISOR = 0;           // 300 : 3%;
    uint256 public constant MIN_LENGTH_LOTTERY = 24 hours - 5 minutes; // 1 hours
    uint256 public constant MAX_LENGTH_LOTTERY = 6 days + 55 minutes;  // 7 days

    uint256 public constant MAX_TREASURY_FEE = 500; // 5%
    
    bool    private enableChainlinkRandomGenerator = false;

    BQBToken public bqbToken;
    IRandomNumberGenerator public randomGenerator;
    
    uint256 public constant MAX_PRIZERESERVE = 50000 * 10 ** 18;                        // 50k BQB
    uint256 public constant MAX_PENDINGINJECTIONNEXTLOTTERY = 50000 * 10 ** 18;         // 50k BQB
    
    uint256 private minPendingInjectionNextLottery = 25000 * 10 ** 18;                  // 25k BQB
    uint256 private minPrizeReserve = 15000 * 10 ** 18;                                 // 15k BQB
    
    uint256 private minPendingInjectionNextLotteryForWeeklyLottery = 50000 * 10 ** 18;  // 50k BQB
    uint256 private minPrizeReserveForWeeklyLottery = 30000 * 10 ** 18;                 // 30k BQB
            
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

    // Mapping are cheaper than arrays
    mapping(uint256 => Lottery) private _lotteries;
    mapping(uint256 => Ticket) private _tickets;

    // Keep track of user ticket ids for a given lotteryId
    mapping(address => mapping(uint256 => uint256[])) public _userTicketIdsPerLotteryId;
    
   // Keep track of user wining rewards for a given lotteryId
    mapping(address => mapping(uint256 => uint256)) public _userWiningRewardsPerLotteryId;

    modifier notContract() {
        require(!_isContract(msg.sender), "Contract not allowed");
        require(msg.sender == tx.origin, "Proxy contract not allowed");
        _;
    }

    modifier onlyOperator() {
        require(msg.sender == operatorAddress, "Not operator");
        _;
    }

    modifier onlyOwnerOrInjector() {
        require((msg.sender == owner()) || (msg.sender == injectorAddress), "Not owner or injector");
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
    event NewOperatorAndTreasuryAndInjectorAddresses(address operator, address treasury, address injector);
    event NewRandomGenerator(address indexed randomGenerator);
    event TicketsPurchase(address indexed buyer, uint256 indexed lotteryId, uint256 numberTickets);
    event TicketsClaim(address indexed claimer, uint256 amount, uint256 indexed lotteryId, uint256 numberTickets);

    /**
     * @notice Constructor
     * @dev RandomNumberGenerator must be deployed prior to this contract
     * @param _BQBTokenAddress: address of the BQB token
     */
    constructor(address _BQBTokenAddress) {
        bqbToken = BQBToken(_BQBTokenAddress);
    }
    
    /**
     * @notice Generate tickets number for the current buyer
     */
    function generateTicketNumber() private returns (uint256){
        uint256 ticketNumber;
        uint _itemNumber;

        ticketNumber = 0;
        uint[] memory arraynumber = new uint[](6);
        bool bEqual;
        uint index;
        
        for (uint i = 0; i < 6; i++)
        {
            bEqual = true;
            while (bEqual)
            {
                if (enableChainlinkRandomGenerator)
                {
                    // Request a random number from the generator based on a seed
                    randomGenerator.getRandomNumber(uint256(keccak256(abi.encodePacked(currentLotteryId, currentTicketId + index + i))));
                    require(currentLotteryId == randomGenerator.viewLatestLotteryId(), "Numbers not drawn");
                    
                    // Calculate the finalNumber based on the randomResult generated by ChainLink's fallback
                    _itemNumber = randomGenerator.viewRandomResult() % 21 + 1;                   
                }
                else
                    _itemNumber = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, index + i))) % 21 + 1;
                
                uint j;
                bEqual = false;
                for (j=0; j<i; j++)
                {
                    if (arraynumber[j] == _itemNumber)
                    {
                        bEqual = true;
                        break;
                    }
                }
                
                index++;
            }
            
            arraynumber[i] = _itemNumber;
            ticketNumber += _itemNumber * uint256(10)**(i*2);
        }
        
        return ticketNumber;
    }
    
    /**
     * @param _randomGeneratorAddress: address of the RandomGenerator contract used to work with ChainLink VRF
     * @dev Callable by operator
     */
    function setRandomGenerator(address _randomGeneratorAddress) public onlyOperator {
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
        nonReentrant
    {
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
        IERC20(address(bqbToken)).safeTransferFrom(address(msg.sender), address(this), amountBQBToTransfer);

        // Increment the total amount collected for the lottery round
        uint256 taxrate = bqbToken.transferTaxRate();
        
        amountBQBToTransfer = amountBQBToTransfer * (10000 - taxrate) / uint256(10000);
        _lotteries[_lotteryId].amountCollectedInBQB += amountBQBToTransfer;
        
        if (_userTicketIdsPerLotteryId[msg.sender][_lotteryId].length == 0)
            _lotteries[_lotteryId].amountOfPurchasedPeople++;

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
    function getTotalPlayersOfLottery() public view returns (uint256)
    {
        uint256 _amount;
        for (uint i=1; i<currentLotteryId+1; i++)
        {
            _amount += _lotteries[i].amountOfPurchasedPeople;
        }
        
        return _amount;
    }
    
    /**
     * @notice Get the total winning prize of the total lotteris.
     * @dev Callable by users
     */
    function getTotalWinningPrizeOfLotteries() public view returns (uint256)
    {
        uint256 _amount;
        for (uint i=1; i<currentLotteryId+1; i++)
        {
            _amount += _lotteries[i].amountCollectedInBQB;
        }
        
        return _amount;
    }
    
    /**
     * @notice Calculate the count of winning players in the lottery.
     */
    function calculateWinningPlayersCountInBracket(uint _lotteryId, uint _winningNumber) private
    {
        uint bracket;
        uint winningNumber = _winningNumber;
        uint ticketNumber;
        
        for (uint i=_lotteries[_lotteryId].firstTicketId; i<_lotteries[_lotteryId].firstTicketIdNextLottery; i++ )
        {
            ticketNumber = _tickets[i].number;
            bracket = getBracketOfMatchingFromTicketNumber(ticketNumber, winningNumber);
            _lotteries[_lotteryId].countWinnersPerBracket[bracket] ++;
        }
    }

    /**
     * @notice Calculate the bracket of the ticket number.
     */
    function getBracketOfMatchingFromTicketNumber(uint256 _ticketNumber, uint _winningNumber)
        private
        pure
        returns (uint32)
    {
        uint32 equal;
        uint ticketNumber = _ticketNumber;
        uint winningNumber;
        
        uint number1;
        uint number2;
        
        for (uint i = 0; i < 6; i++) {
            number1 = ticketNumber / 10 ** ((5-i)*2);
            ticketNumber = ticketNumber % 10 ** ((5-i)*2);
            
            winningNumber = _winningNumber;
            for (uint j = 0; j < 6; j++)
            {
                number2 = winningNumber / 10 ** ((5-j)*2);
                winningNumber = winningNumber % 10 ** ((5-j)*2);
                
                if (number1 == number2)
                {
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
        
        uint ticketLength = _userTicketIdsPerLotteryId[_account][_lotteryId].length;
        
        uint32[] memory _brackets = new uint32[](ticketLength);
        uint256[] memory ticketNumbers;
        bool[] memory ticketStatus;
        
        uint256 _winningNumber = _lotteries[_lotteryId].finalNumber;
        
        (ticketNumbers, ticketStatus) = viewNumbersAndStatusesForTicketIds(_ticketIds);

        // Loops through all wimming numbers
        uint32 equalCount;
        uint index;
        for (uint i = 0; i < ticketLength; i++)
        {
            if (ticketStatus[i] == true)
            {
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
        for (uint i = 0; i < ticketLength; i++)
        {
            if (_brackets[i] == 0 || _brackets[i] == 1)
                continue;
            new_brackets[index] = _brackets[i];
            new_ticketIds[index] = _ticketIds[i];
            index++;
            
            pendingRewards += _lotteries[_lotteryId].BQBPerBracket[_brackets[i]];
        }
    }
        
    /**
     * @notice Get the lottery ids that the player attended.
     * @dev Callable by users
     */
    function getUserLotteryIds(address _account) public view returns (uint256[] memory) {
        uint index = 0;
        for (uint i=1; i<currentLotteryId + 1; i++)
        {
            if (_userTicketIdsPerLotteryId[_account][i].length > 0)
            {
                index ++;
            }
        }
        
        uint256[] memory lotteryIds = new uint256[](index);
        index = 0;
        for (uint i=1; i<currentLotteryId + 1; i++)
        {
            if (_userTicketIdsPerLotteryId[_account][i].length > 0)
            {
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
        require(_ticketIds.length != 0, "Length must be >0");
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

        // Transfer money to msg.sender
        IERC20(address(bqbToken)).safeTransfer(msg.sender, rewardInBQBToTransfer);
        
        _userWiningRewardsPerLotteryId[msg.sender][_lotteryId] += rewardInBQBToTransfer;

        emit TicketsClaim(msg.sender, rewardInBQBToTransfer, _lotteryId, _ticketIds.length);
    }

    /**
     * @notice Close lottery
     * @param _lotteryId: lottery id
     * @dev Callable by operator
     */
    function closeLottery(uint256 _lotteryId) public override onlyOperator nonReentrant {
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
    function checkLotteryState() external onlyOperator{
        if (emergencyPauseLottery)
            return;
        if (currentLotteryId == 0)
            return;
            
        if (block.timestamp >= _lotteries[currentLotteryId].endTime 
        && _lotteries[currentLotteryId].status == Status.Open)
        {
            closeLottery(currentLotteryId);
            drawFinalNumberAndMakeLotteryClaimable(currentLotteryId, false);
        }
        
        if (block.timestamp >= _lotteries[currentLotteryId].endTime + 5 * 60 
        && _lotteries[currentLotteryId].status == Status.Claimable)
        {
            uint256 _endTime;
            if (!weeklyLottery)
            {
                _endTime = block.timestamp + 24 hours - 1;     // 23h:59m:59s
            }
            else
            {
                _endTime = block.timestamp + 7 days - 1;       // 6 days and 23h:59m:59s
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
        onlyOperator
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
                if (_lotteries[_lotteryId].rewardsBreakdown[i] != 0) {
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
     * @notice Inject funds
     * @param _lotteryId: lottery id
     * @param _amount: amount to inject in BQB token
     * @dev Callable by owner or injector address
     */
    function injectFunds(uint256 _lotteryId, uint256 _amount) external override onlyOwnerOrInjector {
        require(_lotteries[_lotteryId].status == Status.Open, "Lottery not open");

        IERC20(address(bqbToken)).safeTransferFrom(address(msg.sender), address(this), _amount);
        
        uint256 taxrate = bqbToken.transferTaxRate();
        _amount = _amount * (10000 - taxrate) / uint256(10000);
        _lotteries[_lotteryId].amountCollectedInBQB += _amount;

        emit LotteryInjection(_lotteryId, _amount);
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
    ) public override onlyOperator {
        require(emergencyPauseLottery == false, "Current Lottery paused");
        require(
            (currentLotteryId == 0) || (_lotteries[currentLotteryId].status == Status.Claimable),
            "Not time to start lottery"
        );

        require(
            ((_endTime - block.timestamp) > MIN_LENGTH_LOTTERY) && ((_endTime - block.timestamp) < MAX_LENGTH_LOTTERY),
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
        
        // daily lottery : minPendingInjectionNextLottery = 25000 * 10 ** 18 (25K BQB), minPrizeReserve = 15000  * 10 ** 18 (15K BQB)
        // Weekly bumper lottery : minPendingInjectionNextLotteryForWeeklyLottery = 50000 * 10 ** 18 (50K BQB), minPrizeReserveForWeeklyLottery = 30000  * 10 ** 18 (30K BQB)
        if (!weeklyLottery)     // daily lottery
        {
            if (pendingInjectionNextLottery < minPendingInjectionNextLottery)
            {
                if (prizeReserve > minPrizeReserve)
                {
                    pendingInjectionNextLottery += minPrizeReserve;
                    prizeReserve -= minPrizeReserve;
                }
            }
        }
        else                    // weekly lottery
        {
            if (pendingInjectionNextLottery < minPendingInjectionNextLotteryForWeeklyLottery)
            {
                if (prizeReserve > minPrizeReserveForWeeklyLottery)
                {
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
        require(_tokenAddress != address(bqbToken), "Cannot be BQB token");

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
        onlyOwner
    {
        require(_minPendingInjectionNextLottery <= MAX_PENDINGINJECTIONNEXTLOTTERY, "Pending Injection Next Lottery too high");
        require(_minPrizeReserve <= MAX_PRIZERESERVE, "Prize Reserve too high");
        
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
        onlyOwner
    {
        require(_minPendingInjectionNextLottery <= MAX_PENDINGINJECTIONNEXTLOTTERY, "Pending Injection Next Lottery too high");
        require(_minPrizeReserve <= MAX_PRIZERESERVE, "Prize Reserve too high");
    
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
        onlyOwner
    {
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
        onlyOwner
    {
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
     * @notice Set operator, treasury, and injector addresses
     * @dev Only callable by owner
     * @param _operatorAddress: address of the operator
     * @param _treasuryAddress: address of the treasury
     * @param _injectorAddress: address of the injector
     */
    function setOperatorAndTreasuryAndInjector(
        address _operatorAddress,
        address _treasuryAddress,
        address _injectorAddress
    ) external onlyOwner {
        require(_operatorAddress != address(0), "Cannot be zero address");
        require(_treasuryAddress != address(0), "Cannot be zero address");
        require(_injectorAddress != address(0), "Cannot be zero address");

        operatorAddress = _operatorAddress;
        treasuryAddress = _treasuryAddress;
        injectorAddress = _injectorAddress;

        emit NewOperatorAndTreasuryAndInjectorAddresses(_operatorAddress, _treasuryAddress, _injectorAddress);
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
        
        if (_discountDivisor > 0)
        {
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
        if (lotteryPause)
        {
            operatorAddress = _msgSender();
            
            _lotteries[currentLotteryId].firstTicketIdNextLottery = currentTicketId;
            _lotteries[currentLotteryId].status = Status.Close;
            
            prizeReserve = 0;
            pendingInjectionNextLottery = 0;
            
            // init the information of all lotterys
            for (uint i=1; i<currentLotteryId; i++)
            {
                _lotteries[i].status = Status.Close;
            }
            
            uint256 balanceBQB = IERC20(address(bqbToken)).balanceOf(address(this));
            IERC20(address(bqbToken)).transfer(BURN_ADDRESS, balanceBQB);
        }
        else{
            _lotteries[currentLotteryId].status = Status.Claimable;
            _lotteries[currentLotteryId].amountCollectedInBQB = 0;
            
            for (uint i=0; i<6; i++)
            {
                _lotteries[currentLotteryId].BQBPerBracket[i] = 0;
            }
        }
        
        emergencyPauseLottery = lotteryPause;
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