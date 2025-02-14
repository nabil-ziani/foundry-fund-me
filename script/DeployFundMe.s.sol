//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "../lib/forge-std/src/Script.sol";
import {FundMe} from "../src/FundMe.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployFundMe is Script {
    function run() external returns (FundMe) {
        // Before startBroadcast -> not a "real" tx (simulation)
        HelperConfig helperConfig = new HelperConfig();
        address ethUsdPriceFeed = helperConfig.activeNetworkConfig();

        // After broadcast -> real tx!
        vm.startBroadcast();
        // Mock the priceFeed
        FundMe fundMe = new FundMe(ethUsdPriceFeed);
        vm.stopBroadcast();

        return fundMe;
    }
}
