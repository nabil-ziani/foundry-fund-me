// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    address internal constant SEPOLIA_ADDRESS =
        0x694AA1769357215DE4FAC081bf1f309aDC325306;
    address internal constant ZKSYNC_ADDRESS =
        0xfEefF7c3fB57d18C5C6Cdd71e45D2D0b4F9377bF;

    function getPrice(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();

        // ETH/USD rate in 18 digit
        return uint256(answer * 1e10);
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        // 1 ETH = 2000_000000000000000000
        uint256 ethPrice = getPrice(priceFeed);

        // (2000_000000000000000000 * 1_000000000000000000) / 1e18
        // $2000 = 1 ETH
        return (ethPrice * ethAmount) / 1e18;
    }
}
