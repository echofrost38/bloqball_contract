
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

interface BQBToken {
    function mint(address _to, uint256 _amount) external;
    function transferTaxRate() external returns (uint256);
}

interface RandomNumberGenerator {
    function setLotteryAddress(address _bloqballSwapLottery) external;
    function setFee(uint256 _fee) external;
    function setKeyHash(bytes32 _keyHash) external;
}

// File: contracts/JackpotLottery.sol

/** @title Jackpot Lottery.
 * @notice It is a contract for a lottery system using
 * randomness provided externally.
 */
contract JackpotLottery is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    IRandomNumberGenerator public randomGenerator;
    bool    private enableChainlinkRandomGenerator = false;
    
    BQBToken public bqbToken;
    
    uint256 private constant MAX_PRIZERESERVE = 500000 * 10 ** 18;                      // 500k BQB
    uint256 private prizeReserve = 500000 * 10 ** 18;                                   // 500k BQB
    
    uint256 private constant MIN_PRICE_ELIGIBILITY = 10000 * 10 ** 18;                  // 10k BQB
    
    uint256 private minPrizeReserve = 1000 * 10 ** 18;                                  // 1k BQB
    
    uint256 private amountForEligibility = 10 * 10 ** 18;                                // 10 BQB
    
    uint256 public ticketNumber;
    
    struct User {
        uint256 _lastClaimDay;
        uint256 _userCountOfJackboxLottery;
        uint256 _userRewards;
    }
    
    mapping(address => User) private userInfo;

    modifier notContract() {
        require(!_isContract(msg.sender), "Contract not allowed");
        require(msg.sender == tx.origin, "Proxy contract not allowed");
        _;
    }
    
    event NewRandomGenerator(address indexed randomGenerator);
    event TicketsClaim(address indexed claimer, uint256 amount);
    event NewOperator(address operator);
    event LotteryInjection(uint256 injectedAmount);
    
    /**
     * @notice Constructor
     * @param _BQBTokenAddress: address of the BQB token
     */
    constructor(address _BQBTokenAddress) {
        bqbToken = BQBToken(_BQBTokenAddress);
    }
     
    /**
     * @notice Check lottery state
     * @dev Callable by operator
     */
    function checkEligibility(uint256 _amount) external view returns (bool bEnable){
        bEnable = false;
        
        if (prizeReserve < minPrizeReserve)
            return bEnable;
        
        if (_amount >= amountForEligibility)
        {
            bEnable = true;
        }
        else
        {
            uint256 bqbAmount = IERC20(address(bqbToken)).balanceOf(msg.sender);
            if (bqbAmount > MIN_PRICE_ELIGIBILITY && block.timestamp - userInfo[msg.sender]._lastClaimDay > 1 days)
            {
                bEnable = true;
            }
            else
            {
                if (userInfo[msg.sender]._userCountOfJackboxLottery > 0)
                {
                    bEnable = true;
                }
            }
        }
    }
    
    /**
     * @notice Generate tickets number for the current buyer
     */
    function generateTicketNumber(uint256 _amount) public{
        uint _itemNumber;
        
        for (uint i = 0; i < 5; i++)
        {
            if (enableChainlinkRandomGenerator)
            {
                // Request a random number from the generator based on a seed
                randomGenerator.getRandomNumber(uint256(keccak256(abi.encodePacked(i, i))));
                
                // Calculate the finalNumber based on the randomResult generated by ChainLink's fallback
                _itemNumber = randomGenerator.viewRandomResult() % 9 + 1;                   
            }
            else
                _itemNumber = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, i))) % 9 + 1;
            
            ticketNumber += _itemNumber * uint256(10)**i;
        }
        
        drawRewards(_amount);
    }
    
    function drawRewards(uint256 _amount) private {
        uint256 bracket = getBracketOfMatchingFromTicketNumber(ticketNumber);
        uint256 reward = calculateBQBFromBracket(bracket);
        
        if (_amount * (10 ** 18) >= amountForEligibility)
        {
            userInfo[msg.sender]._userRewards += reward;
    
            prizeReserve -= reward;
        }
        else
        {
            uint256 bqbAmount = IERC20(address(bqbToken)).balanceOf(msg.sender);
            if (bqbAmount > MIN_PRICE_ELIGIBILITY && block.timestamp - userInfo[msg.sender]._lastClaimDay > 1 days)
            {
                userInfo[msg.sender]._userCountOfJackboxLottery = bqbAmount / MIN_PRICE_ELIGIBILITY;
                userInfo[msg.sender]._lastClaimDay = block.timestamp;
            }

            if (userInfo[msg.sender]._userCountOfJackboxLottery > 0)
            {
                userInfo[msg.sender]._userCountOfJackboxLottery --;
            }
            
            userInfo[msg.sender]._userRewards += reward;
        
            prizeReserve -= reward;  
        }
    }
    
    /**
     * @notice Get the rewards of the user.
     */
    function getUserReward(address _account) public view returns (uint256){
        return userInfo[_account]._userRewards;
    }
    
    /**
     * @notice Calculate the bracket of the ticket number.
     */
    function getBracketOfMatchingFromTicketNumber(uint256 _ticketNumber)
        public
        pure
        returns (uint32)
    {
        uint32 equal = 0;
        uint userTicketNumber = _ticketNumber;
        
        uint number;
        
        for (uint i = 0; i < 5; i++) {
            number = userTicketNumber / (10 ** ((5-i-1)));
            userTicketNumber = userTicketNumber - number * (10 ** ((5-i-1)));
            
            if (number == 7)
                equal++;
        }

        return equal;
    }
    
    /**
     * @notice Calculate the bracket of the ticket number.
     */
    function calculateBQBFromBracket(uint256 bracket)
        public
        view
        returns (uint256)
    {
        uint256 amount;
        
        if (bracket == 5)                           // 10% of prize reserve
            amount = prizeReserve / 10;
        else if (bracket == 4)                      // 1% of prize reserve
            amount = prizeReserve / 100;
        else if (bracket == 3)
            amount = prizeReserve * 2 / 1000;       // 0.2% of prize reserve
        
        return amount;
    }
    
    /**
     * @notice Claim a set of winning tickets for a lottery
     * @dev Callable by users only, not contract!
     */
    function claimTickets() external notContract nonReentrant {
        if (userInfo[msg.sender]._userRewards == 0)
            return;
        
        // Transfer money to msg.sender
        IERC20(address(bqbToken)).safeTransfer(msg.sender, userInfo[msg.sender]._userRewards);
        
        userInfo[msg.sender]._userRewards = 0;
                
        emit TicketsClaim(msg.sender, userInfo[msg.sender]._userRewards);
    }
    
    /**
     * @notice Get the info of user
     */
    function getUserInfo(address account) external view returns (User memory) {
        return userInfo[account];
    }
    
    /**
     * @notice Set the price of Swap for the  Eligibility of Jackpot
     * @dev Callable by operator
     */
    function setJackpotAmountForEligibility(uint256 _amount) external onlyOwner {
        amountForEligibility = _amount;
    }
    
    /**
     * @notice Change the random generator
     * @dev The calls to functions are used to verify the new generator implements them properly.
     * It is necessary to wait for the VRF response before starting a round.
     * Callable only by the contract owner
     * @param _randomGeneratorAddress: address of the random generator
     */
    function changeRandomGenerator(address _randomGeneratorAddress, uint i, uint j) external onlyOwner {
        // Request a random number from the generator based on a seed
        IRandomNumberGenerator(_randomGeneratorAddress).getRandomNumber(
            uint256(keccak256(abi.encodePacked(i, j)))
        );

        // Calculate the finalNumber based on the randomResult generated by ChainLink's fallback
        IRandomNumberGenerator(_randomGeneratorAddress).viewRandomResult();

        randomGenerator = IRandomNumberGenerator(_randomGeneratorAddress);

        emit NewRandomGenerator(_randomGeneratorAddress);
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
     * @notice Inject funds
     * @param _amount: amount to inject in BQB token
     * @dev Callable by owner or injector address
     */
    function injectFunds(uint256 _amount) external onlyOwner 
    {
        require(prizeReserve + _amount <= MAX_PRIZERESERVE, "Prize Reserve too high");
        
        IERC20(address(bqbToken)).safeTransferFrom(address(msg.sender), address(this), _amount);
        
        uint256 taxrate = bqbToken.transferTaxRate();
        _amount = _amount * (10000 - taxrate) / uint256(10000);
        
        prizeReserve += _amount;

        emit LotteryInjection(_amount);
    }

    /**
     * @notice Set minium value of pending injection next lottery and prize reserve
     * @dev Only callable by owner
     * @param _minPrizeReserve: maximum value of a prize reserve
     */
    function setMinPrizeReserve(uint256 _minPrizeReserve) external onlyOwner
    {
        require(_minPrizeReserve <= MAX_PRIZERESERVE, "Prize Reserve too high");
        
        minPrizeReserve = _minPrizeReserve;
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