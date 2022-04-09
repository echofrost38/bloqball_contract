// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
* @title ReserveToken is a basic ERC20 Token
*/
contract ReserveToken is ERC20, Ownable{

    /**
    * @dev assign totalSupply to account creating this contract
    */
    constructor()  ERC20("ReserveToken","RST"){
        _mint(msg.sender, 1000);
    }
}