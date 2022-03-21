// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './interfaces/AggregatorV3Interface.sol';

contract PriceConsumerV3 {

    AggregatorV3Interface internal priceFeed;

    /**
     * Network: FANTOM
     * Aggregator: FTM/USD
     * Address: 0xe04676B9A9A2973BCb0D1478b5E1E9098BBB7f3D      // testnet   
     * Address: 0xf4766552D15AE4d256Ad41B6cf2933482B0680dc      // mainnet
     */
    constructor() {
        priceFeed = AggregatorV3Interface(0xe04676B9A9A2973BCb0D1478b5E1E9098BBB7f3D);
    }

    /**
     * Returns the latest price
     */
    function getLatestPrice() external view returns (int) {
        (, int price, , , ) = priceFeed.latestRoundData();
        return price;
    }
}