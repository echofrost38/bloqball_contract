// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './utils/Context.sol';
import './access/Ownable.sol';
import './libraries/SafeMath.sol';
import './interfaces/IERC20.sol';

contract OwnedDistributor is Ownable{
    using SafeMath for uint;

    address public immutable bloqball;
    
    uint public totalShares;
    
    uint public vestingAmount = 1100_000 * 10 ** 18;      // Initial vesting amount for users who deposit FTM

    uint public vestingBegin;
    uint public vestingEnd;
    
    uint public vestingPeriod = 120 days;

    struct Recipient {
        uint shares;
        uint lastDeliverTime;
        uint credit;
    }
    
    mapping(address => Recipient) public recipients;

    event UpdateCredit(address indexed account, uint credit);
    event Claim(address indexed account, uint amount);
    event EditRecipient(address indexed account, uint shares, uint totalShares);
    event SetAdmin(address newAdmin);

    // Prevents a contract from calling itself, directly or indirectly.
    bool internal _notEntered = true;

    modifier nonReentrant() {
        require(_notEntered, "Distributor: REENTERED");
        _notEntered = false;
        _;
        _notEntered = true;
    }
    
    constructor(address bloqball_, uint vestingBegin_) {
        bloqball = bloqball_;
        vestingBegin = vestingBegin_;
        vestingEnd = vestingBegin.add(vestingPeriod);
    }
    
    function calculateCredit(address account) public view returns (uint credit)
    {
        if (block.timestamp < vestingBegin) return 0;
        if (totalShares == 0) return 0;
        if (recipients[account].shares == 0) return 0;
        
        uint intervalTimeStamp = vestingPeriod.div(4);
        uint interval = (block.timestamp - vestingBegin).div(intervalTimeStamp);
        uint prevInterval = 0;
        
        if (recipients[account].lastDeliverTime != 0)
            prevInterval = (recipients[account].lastDeliverTime - vestingBegin).div(intervalTimeStamp);

        credit = vestingAmount.mul(recipients[account].shares).div(totalShares);
        
        if (credit <= recipients[account].credit)
            return 0;
        
        if (block.timestamp >= vestingEnd)
            credit = credit - recipients[account].credit;
        else
        {
            credit = credit.mul(interval - prevInterval).div(4);  
        }
    }

    function updateCredit(address account) public returns (uint credit) {
        credit = calculateCredit(account);
        emit UpdateCredit(account, credit);
    }

    function claimInternal(address account) internal virtual returns (uint amount) {
        amount = updateCredit(account);
        
        if (amount > 0) {
            recipients[account].credit += amount;
            IERC20(bloqball).transfer(account, amount);
            
            recipients[account].lastDeliverTime = block.timestamp;
            emit Claim(account, amount);
        }
    }

    function claim() external virtual returns (uint amount) {
        return claimInternal(msg.sender);
    }

    function editRecipientInternal(address account, uint shares) internal {
        Recipient storage recipient = recipients[account];
        uint prevShares = recipient.shares;
        uint _totalShares = shares > prevShares
            ? totalShares.add(shares - prevShares)
            : totalShares.sub(prevShares - shares);
        totalShares = _totalShares;
        recipient.shares = shares;
        emit EditRecipient(account, shares, _totalShares);
    }
    
    function editRecipient(address account, uint shares) public virtual onlyOwner {

        editRecipientInternal(account, shares);
    }
}
