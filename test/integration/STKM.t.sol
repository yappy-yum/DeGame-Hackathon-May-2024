// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {fundBalance} from "../fundBalance.sol";
import {STKM_S} from "script/STKM.s.sol";
import {STKM} from "src/factory/STKM.sol";
import {Test, console} from "forge-std/Test.sol";

import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

contract STKM_T is Test, fundBalance {

    STKM public s_STKM;

    address Owner = makeAddr("Owner");
    address Alice = makeAddr("Alice");
    address Bob = makeAddr("Bob");

    function setUp() public {
        STKM_S s = new STKM_S();
        s_STKM = s.run();
    }

    /*//////////////////////////////////////////////////////////////
                         get and withdraw STKM
    //////////////////////////////////////////////////////////////*/

    function test_Bob_gets_STKM() public {
        // current timestamp
        uint currentTimeStamp = block.timestamp;

        // balanceOf && lastUpdate checks
        s_STKM.updateInterest(Bob);
        assertEq(s_STKM.balanceOf(Bob), 0 ether);
        assertEq(s_STKM.checkInterestLastUpdate(Bob), 0);

        // get Bob some STKM
        vm.prank(Owner);
        s_STKM.buySTKM(Bob, 5 ether);

        // balanceOf && lastUpdate checks
        s_STKM.updateInterest(Bob);
        assertEq(s_STKM.balanceOf(Bob), 5 ether);
        assertEq(s_STKM.checkInterestLastUpdate(Bob), currentTimeStamp);

        // get Bob another STKMs
        vm.prank(Owner);
        s_STKM.giveSTKM(Bob, 5 ether);

        // balanceOf && lastUpdate checks
        s_STKM.updateInterest(Bob);
        assertEq(s_STKM.balanceOf(Bob), 10 ether);
        assertEq(s_STKM.checkInterestLastUpdate(Bob), currentTimeStamp);

        // after some times (within 1 day)
        skip(5 hours);

        // balanceOf && lastUpdate checks
        s_STKM.updateInterest(Bob);
        assertEq(s_STKM.balanceOf(Bob), 10 ether);
        assertEq(s_STKM.checkInterestLastUpdate(Bob), currentTimeStamp);

        // after few days
        skip(5 days);
        uint timeStampAfterFewDays = block.timestamp;

        // balanceOf && lastUpdate checks
        s_STKM.updateInterest(Bob);
        assertGt(s_STKM.balanceOf(Bob), 10 ether);
        assertEq(s_STKM.checkInterestLastUpdate(Bob), timeStampAfterFewDays);
    }    

    function test_Alice_gets_and_withdraw_STKM() public {
        // current timestamp
        uint currentTimeStamp = block.timestamp;

        // balanceOf && lastUpdate checks
        s_STKM.updateInterest(Alice);
        assertEq(s_STKM.balanceOf(Alice), 0 ether);
        assertEq(s_STKM.checkInterestLastUpdate(Alice), 0);

        // get Alice some STKM
        vm.prank(Owner);
        s_STKM.buySTKM(Alice, 5 ether);

        // balanceOf && lastUpdate checks
        s_STKM.updateInterest(Alice);
        assertEq(s_STKM.balanceOf(Alice), 5 ether);
        assertEq(s_STKM.checkInterestLastUpdate(Alice), currentTimeStamp);

        // get Alice another STKMs
        vm.prank(Owner);
        s_STKM.giveSTKM(Alice, 5 ether);

        // balanceOf && lastUpdate checks
        s_STKM.updateInterest(Alice);
        assertEq(s_STKM.balanceOf(Alice), 10 ether);
        assertEq(s_STKM.checkInterestLastUpdate(Alice), currentTimeStamp);

        // ALice withdraws
        vm.prank(Owner);
        s_STKM.withdrawSTKM(Alice, 8 ether);

        // balanceOf && lastUpdate checks
        s_STKM.updateInterest(Alice);
        assertEq(s_STKM.balanceOf(Alice), 2 ether);
        assertEq(s_STKM.checkInterestLastUpdate(Alice), currentTimeStamp);

        // an attempt to withdraw exceeding balance
        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors.ERC20InsufficientBalance.selector, 
                Alice, // address
                2 ether, // balance amount
                2 ether + 1 // amount to withdraw
            )
        );

        vm.prank(Owner);
        s_STKM.withdrawSTKM(Alice, 2 ether + 1);
    }

    /*//////////////////////////////////////////////////////////////
                             transfer STKM
    //////////////////////////////////////////////////////////////*/

    function test_transfer_STKM() public {
        // get Alice some STKM
        vm.prank(Owner);
        s_STKM.buySTKM(Alice, 5 ether);

        // Alice transfer to Bob
        vm.prank(Alice);
        s_STKM.transfer(Bob, 2 ether);

        assertEq(s_STKM.balanceOf(Alice), 3 ether);
        assertEq(s_STKM.balanceOf(Bob), 2 ether);

        // after some days, their balance should increased
        skip(5 days);

        s_STKM.updateInterest(Alice);
        s_STKM.updateInterest(Bob);
        assertGt(s_STKM.balanceOf(Alice), 3 ether);
        assertGt(s_STKM.balanceOf(Bob), 2 ether);

        // after at least a day, their balance should increased as well
        skip(1 days);

        vm.prank(Owner);
        s_STKM.withdrawSTKM(Alice, 3 ether);

        assert(
            s_STKM.balanceOf(Alice) > 0 ether && 
            s_STKM.balanceOf(Alice) < 1 ether
        );
    }    

    function test_TransferFrom() public {
        // get Alice some STKM
        vm.prank(Owner);
        s_STKM.buySTKM(Alice, 5 ether);

        // Owner transfer ALice funds to Bob
        vm.prank(Alice);
        s_STKM.approve(Owner, 2 ether);
        

        // check allowance
        assertEq(s_STKM.allowance(Alice, Owner), 2 ether);

        // Owner transfer ALice funds to Bob
        vm.prank(Owner);
        s_STKM.transferFrom(Alice, Bob, 2 ether);

        s_STKM.updateInterest(Alice);
        s_STKM.updateInterest(Bob);
        s_STKM.updateInterest(Owner);

        assertEq(s_STKM.checkInterestLastUpdate(Alice), block.timestamp);
        assertEq(s_STKM.checkInterestLastUpdate(Bob), block.timestamp);
        assertEq(s_STKM.checkInterestLastUpdate(Owner), 0);

        assertEq(s_STKM.balanceOf(Alice), 3 ether);
        assertEq(s_STKM.balanceOf(Bob), 2 ether);
        assertEq(s_STKM.balanceOf(Owner), 0 ether);

        skip(3 days);

        s_STKM.updateInterest(Alice);
        s_STKM.updateInterest(Bob);
        s_STKM.updateInterest(Owner);

        assertEq(s_STKM.checkInterestLastUpdate(Alice), block.timestamp);
        assertEq(s_STKM.checkInterestLastUpdate(Bob), block.timestamp);
        assertEq(s_STKM.checkInterestLastUpdate(Owner), 0);

        // check balance
        assertGt(s_STKM.balanceOf(Alice), 3 ether);
        assertGt(s_STKM.balanceOf(Bob), 2 ether);
        assertEq(s_STKM.balanceOf(Owner), 0 ether);

        // allowance wont increases, only user balance will
        assertEq(s_STKM.allowance(Alice, Owner), 0 ether);
    }

}