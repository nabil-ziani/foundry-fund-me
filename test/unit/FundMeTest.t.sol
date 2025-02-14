//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "lib/forge-std/src/Test.sol";
import {FundMe} from "src/FundMe.sol";
import {DeployFundMe} from "script/DeployFundMe.s.sol";
import {ZkSyncChainChecker} from "lib/foundry-devops/src/ZkSyncChainChecker.sol";
import {FoundryZkSyncChecker} from "lib/foundry-devops/src/FoundryZkSyncChecker.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    address USER  = makeAddr("user");
    uint256 constant  SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;

    // first function that will run
    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    // ---- Modifiers ----
    modifier funded() {
        // create fake address to make the transactions (works only in tests and in foundry)
        vm.prank(USER); // = the next TX will be sent by USER.
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    // ---- Tests ----
    function testMinimumDollarIsFive() public view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public view {
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testFundFailsWithoutEngoughEth() public {
        vm.expectRevert();
        fundMe.fund(); // send 0 value
    }

    function testFundUpdatesFundedDataStructure() public funded {
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public funded {
        address funder = fundMe.getFunder(0);
        assertEq(USER, funder);
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert(); // this works on the next TX, so next line (vm..) is ignored
        vm.prank(USER);
        fundMe.withdraw();
    }

    function testWithdrawWithASingleFunder() public funded {
        // Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        // uint256 gasStart = gasleft(); // let's assume we sent 1000 gas
        vm.txGasPrice(GAS_PRICE);
        vm.prank(fundMe.getOwner()); 
        fundMe.withdraw(); // cost was for ex. 200 gas

        // uint256 gasEnd = gasleft(); // there is 800 gas left
        // uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        // console.log(gasUsed);

        // Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;


        assertEq(endingOwnerBalance, (startingOwnerBalance + startingFundMeBalance));
        assertEq(endingFundMeBalance, 0);
    }

    function testWithdrawFromMultipleFunders() public funded {
        // Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIdx = 1;

        for (uint160 i = startingFunderIdx; i < numberOfFunders; i++) {
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        // Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;

        assert(endingOwnerBalance == (startingOwnerBalance + startingFundMeBalance));
        assert(endingFundMeBalance == 0);
    }

    function testWithdrawFromMultipleFundersCheaper() public funded {
        // Arrange - optimalization
        uint160 numberOfFunders = 10;
        uint160 startingFunderIdx = 1;

        for (uint160 i = startingFunderIdx; i < numberOfFunders; i++) {
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        vm.prank(fundMe.getOwner());
        fundMe.cheaperWithdraw();

        // Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;

        assert(endingOwnerBalance == (startingOwnerBalance + startingFundMeBalance));
        assert(endingFundMeBalance == 0);
    }

    // ----- Personal Notes -----
    // When no chain is specified, foundry will spin up a local chain (anvil) and close it after
    // --fork-url and --rpc-url do the same..abi
    // -------------------
    // What can we do to work with addresses outside our system?
    // 1. Unit
    //    - Testing a specific part of our code
    // 2. Integration
    //    - Testing how our code works with other parts of our code
    // 3. Forked
    //    - Testing our code in a simulated real environment
    // 4. Staging
    //    - Testing our code in a real environment that is not PROD
    function testPriceFeedVersionIsAccurate() public view {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }
}
