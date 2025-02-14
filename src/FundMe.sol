// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";

error FundMe__NotOwner();
error FundMe__CallFailed();
error FundMe__NotEnoughEth();

contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 5e18;
    AggregatorV3Interface private s_priceFeed;

    address[] private s_funders;
    mapping(address funder => uint256 amountFunded) private s_addressToAmountFunded;

    address private immutable i_owner;

    // https://docs.chain.link/data-feeds/price-feeds/addresses
    constructor(address priceFeed) {
        i_owner = msg.sender; // deployer of the contract
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    // Handle when someone sends this contract ETH without calling the fund function (receive, fallback)
    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    function fund() public payable {
        // 1. How do we send ETH to this contract?
        // https://eth-converter.com
        if (!(msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD)) {
            // msg.value returns 18 digits (1 ETH = 1e18 WEI)
            revert FundMe__NotEnoughEth();
        }

        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] += msg.value;
    }

    function cheaperWithdraw() public onlyOwner {
        uint256 fundersLength = s_funders.length;

        for (uint256 i = 0;i < fundersLength;i++) {
            address funder = s_funders[i];
            s_addressToAmountFunded[funder] = 0;
        }

        s_funders = new address[](0);

        (bool callSuccess,) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        
        if (!callSuccess) {
            revert FundMe__CallFailed();
        }
    }

    function withdraw() public onlyOwner {
        // 1. Reset fundedAmounts
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }

        // 2. Reset the funders array
        s_funders = new address[](0);

        // 3. Actually withdraw funds (three ways)

        // -- transfer (capped at 2300 gas and throws error if more...) -- reverts on fail
        // payable(msg.sender).transfer(address(this).balance);

        // -- send (capped at 2300 gas and returns bool if more...) -- does not revert on fail, need to add manually
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");

        // -- call
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        if (!callSuccess) {
            revert FundMe__CallFailed();
        }
    }

    function getVersion() public view returns (uint256) {
        return s_priceFeed.version();
    }

    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner(); // gas optimalizations (instead of require(...))
        }
        _; // = continue in the function
    }

    /**
     * Getters (view/pure functions)
     */
    function getAddressToAmountFunded(address fundingAddress) external view returns (uint256) {
        return s_addressToAmountFunded[fundingAddress];
    }

    function getFunder(uint256 idx) external view returns (address) {
        return s_funders[idx];
    }

    function getOwner() external view returns(address) {
        return i_owner;
    }
}
