// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

interface IWFTM {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}