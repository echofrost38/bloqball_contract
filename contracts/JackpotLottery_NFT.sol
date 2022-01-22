
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


/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    
    
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);
    
    function createrOf(uint256 tokenId) external view returns (address);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// File: contracts/JackpotLottery.sol

/** @title Jackpot Lottery.
 * @notice It is a contract for a lottery system using
 * randomness provided externally.
 */
contract JackpotLottery is ReentrancyGuard, Ownable {

    enum Status {
        Open,
        Purchased,
        Claimed
    }

    struct Reward {
        address nftAddress;
        uint256 tokenId;
        uint256 lastClaimableTime;
        address buyer;
        Status status;
        int purchasedIndex;
    }

    struct PurchasedInfo {
        address owner;
        uint8 number;
        uint256 rewardIndex;
    }
    
    mapping(address=> mapping(uint8 => uint256)) public userInfo;
    mapping(uint8 => Reward[]) public nftinfo;
    mapping(uint8 => address) public nftAddress;

    PurchasedInfo[] public purchasedInfo;

    uint256 public cost = 5 ether;
    uint256 public maxClaimableLimitTime = 10 minutes;
    uint256 public constant MAX_REARRANGE_REWARDS_PEROID = 1 days;
    uint256 public lastRearrangeTime;

    modifier notContract() {
        require(!_isContract(msg.sender), "Contract not allowed");
        require(msg.sender == tx.origin, "Proxy contract not allowed");
        _;
    }
    
    event SetNFTAddress(uint8 _number, address _nftAddress);
    event AddNFT(uint8 _number, address _nftAddress, uint256 _tokenId);
    event BuyTicket(uint8 _number, address buyer, uint256 price);
    event ClaimNFT(uint8 _number, address _nftAddress, uint256 _tokenId, address newOwner);
    event UpdateNFT(uint8 _number);
    event RemoveClaimedRewardInfo(uint8 _number);
    
    constructor() {
    }

    receive() external payable {
    }

    function setCost(uint _cost) public onlyOwner {
        cost = _cost;
    }

    function setNFTAddress(uint8 _number, address _nftAddress) public onlyOwner {
        require(_number > 0 && _number < 10, "Wrong number");
        require(_isContract(_nftAddress), "The NFT Address should be a contract");

        nftAddress[_number] = _nftAddress;

        emit SetNFTAddress(_number, _nftAddress);
    }

    function addNFT(uint8 _number, address _nftAddress, uint256 _tokenId) public {
        require(_number > 0 && _number < 10, "Wrong number");
        require(nftAddress[_number] == _nftAddress, "Wrong NFT address");

        IERC721 nftRegistry = _requireERC721(_nftAddress);

        // Check msg sender is the asset owner
        address assetOwner = nftRegistry.ownerOf(_tokenId);
        require(assetOwner == msg.sender, "Only the asset owner can add assets");

        nftRegistry.approve(address(this), _tokenId);
        nftRegistry.transferFrom(assetOwner, address(this), _tokenId);

        nftinfo[_number].push(Reward({
            nftAddress: _nftAddress,
            tokenId: _tokenId,
            lastClaimableTime: 0,
            buyer: address(this),
            status: Status.Open,
            purchasedIndex: -1
        }));

        emit AddNFT(_number, _nftAddress, _tokenId);
    }

    function hasNFTforRewards(uint8 _number) public view returns (bool) {
        require(_number > 0 && _number < 10, "Wrong number");
        require(nftAddress[_number] != address(0), "Wrong NFT address");

        if (nftinfo[_number].length == 0)
            return false;

        uint256 index = getPurchableRewardIndex(_number);
        if (index == nftinfo[_number].length)
            return false;

        return true;
    }

    function buyTicket(uint8 _number) public payable {
        require(_number > 0 && _number < 10, "Wrong number");
        require(nftAddress[_number] != address(0), "Wrong NFT address");
        require(msg.value > cost, "Insufficient value");
        require(userInfo[msg.sender][_number] == 0, "You have already puchased a NFT.");

        updateNFT(_number);
        generateTicketNumber(_number);

        emit BuyTicket(_number, msg.sender, msg.value);
    }

    /**
     * @notice Generate tickets number for the current player
     */
    function generateTicketNumber(uint8 _number) public{
        uint itemNumber;
        uint ticketNumber;
        
        for (uint i = 0; i < 5; i++) {
            itemNumber = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, i))) % 9 + 1;
            
            ticketNumber += itemNumber * uint256(10)**i;
        }
        
        drawRewards(_number, ticketNumber);
    }
    
    function drawRewards(uint8 _number, uint256 ticketNumber) public {
        (bool bEqualAll, uint8 equalNumber) = getBracketOfMatchingFromTicketNumber(ticketNumber);

        if (bEqualAll) {
            require(nftinfo[equalNumber].length > 0, "No more NFTs available to Win");

            uint256 index = getPurchableRewardIndex(equalNumber);
            require(index < nftinfo[equalNumber].length, "No purchable reward");

            Reward memory reward = nftinfo[equalNumber][index];

            require(reward.buyer == address(this) 
                    && reward.status == Status.Open, 
                    "The NFT was already reserved for another user");

            reward.lastClaimableTime = block.timestamp + maxClaimableLimitTime;
            reward.buyer = msg.sender;
            reward.status = Status.Purchased;
            reward.purchasedIndex = int(purchasedInfo.length);

            nftinfo[equalNumber][index] = reward;

            purchasedInfo.push(PurchasedInfo({
                owner: msg.sender,
                number: _number,
                rewardIndex: index
            }));

            userInfo[msg.sender][_number] = purchasedInfo.length;
        }
    }

    function getPurchableRewardIndex(uint8 _number) public view returns (uint256) {
        uint256 length = nftinfo[_number].length;
        uint256 i = 0;
        for (i=0; i<length; i++) {
            if (nftinfo[_number][i].status == Status.Open)
                return i;
        }

        return i;
    }

    /**
     * @notice Calculate the bracket of the ticket number.
     */
    function getBracketOfMatchingFromTicketNumber(uint256 _ticketNumber)
        public
        pure
        returns (bool bEqualAll, uint8 equalNumber)
    {
        uint userTicketNumber = _ticketNumber;
        
        uint prevNumber = 0;
        uint number;
        bEqualAll = true;
        
        for (uint i = 0; i < 5; i++) {
            number = userTicketNumber / (10 ** ((5-i-1)));
            userTicketNumber = userTicketNumber - number * (10 ** ((5-i-1)));

            if (bEqualAll) {
                if (prevNumber > 0 && prevNumber != number)
                    bEqualAll = false;

                if (prevNumber == 0 && bEqualAll)
                    prevNumber = number;
            }
        }

        if (bEqualAll)
            equalNumber = uint8(number);
    }

    function claimNFT(uint8 _number) external notContract nonReentrant
    {
        require(_number > 0 && _number < 10, "Wrong number");

        updateNFT(_number);

        uint256 purchasedIndex = userInfo[msg.sender][_number];
        require(purchasedIndex > 0, "No purchased reward");

        uint256 rewardIndex = purchasedInfo[purchasedIndex-1].rewardIndex;

        Reward memory reward = nftinfo[_number][rewardIndex];

        require(reward.buyer == msg.sender, "Unauthorized sender");
        require(reward.status == Status.Purchased, "Wrong purchased");

        // Transfer NFT asset
        IERC721(reward.nftAddress).transferFrom(
            address(this),
            msg.sender,
            reward.tokenId
        );

        nftinfo[_number][rewardIndex].status = Status.Claimed;

        removePuchasedInfo(purchasedIndex-1);
        delete userInfo[msg.sender][_number];

        emit ClaimNFT(_number, reward.nftAddress, reward.tokenId, msg.sender);
    }

    function updateNFT(uint8 _number) public {
        uint length = purchasedInfo.length;
        uint256 rewardIndex;

        for (uint i=0; i<length; i++) {
            rewardIndex = purchasedInfo[i].rewardIndex;
            Reward memory reward = nftinfo[_number][rewardIndex];

            if (reward.lastClaimableTime < block.timestamp 
                    && reward.status == Status.Purchased
                    && reward.buyer != address(this)) {
                reward.buyer = address(this);
                reward.status = Status.Open;

                nftinfo[_number][rewardIndex] = reward;
            }
        }

        if (block.timestamp > lastRearrangeTime) {
            removeClaimedRewardInfo(_number);
            lastRearrangeTime = block.timestamp + MAX_REARRANGE_REWARDS_PEROID;
        }

        emit UpdateNFT(_number);
    }

    function removePuchasedInfo(uint256 index) public {
        if (index >= purchasedInfo.length)
            return;

        for (uint256 i = index; i<purchasedInfo.length-1; i++){
            purchasedInfo[i] = purchasedInfo[i+1];
            uint8 number = purchasedInfo[i].number;
            address owner = purchasedInfo[i].owner;
            userInfo[owner][number] = userInfo[owner][number] - 1; 
        }

        purchasedInfo.pop();
    }

    function removeClaimedRewardInfo(uint8 _number) public {
        require(_number > 0 && _number < 10, "Wrong number");

        for (uint i=0; i<nftinfo[_number].length; i++) {
            while(nftinfo[_number].length > 0 && nftinfo[_number][i].status == Status.Claimed) {
                for (uint j = i; j<nftinfo[_number].length-1; j++) {
                    nftinfo[_number][j] = nftinfo[_number][j+1];

                    int purchasedIndex = nftinfo[_number][j].purchasedIndex;
                    if (purchasedIndex >= 0)
                        purchasedInfo[i].rewardIndex = purchasedInfo[i].rewardIndex - 1;
                }
                nftinfo[_number].pop();
            }
        }

        emit RemoveClaimedRewardInfo(_number);
    }

    function setMaxClaimableLimitTime (uint256 _limitTime) public onlyOwner {
        maxClaimableLimitTime = _limitTime;
    }

    function getNFTInfo(uint8 _number) public view returns (Reward[] memory) {
        require(_number > 0 && _number < 10, "Wrong number");

        return nftinfo[_number];
    }

    /**
     * @notice Get the information of the user.
     */
    function getUserInfo(address _account, uint8 _number) public view returns (uint256){
        return userInfo[_account][_number];
    }

    /**
     * @notice Get the purchased information of the user.
     */
    function getPurchaedInfo() public view returns (PurchasedInfo[] memory){
        return purchasedInfo;
    }

    function _requireERC721(address _nftAddress) internal view returns (IERC721) {
        require(_isContract(_nftAddress), "The NFT Address should be a contract");
        // require(
        //     IERC721(_nftAddress).supportsInterface(_INTERFACE_ID_ERC721),
        //     "The NFT contract has an invalid ERC721 implementation"
        // );
        return IERC721(_nftAddress);
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

    /**
     * @dev It allows the admin to withdraw FTM sent to the contract by the users, 
     * only callable by owner.
     */
    function withdrawFTM() public onlyOwner {
        require(address(this).balance > 0, "No balance of ETH.");
        require(payable(msg.sender).send(address(this).balance));
    }
}