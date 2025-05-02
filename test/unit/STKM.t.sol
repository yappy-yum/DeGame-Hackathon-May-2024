// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {fundBalance} from "../fundBalance.sol";
import {STKM_S} from "script/STKM.s.sol";
import {STKM} from "src/factory/STKM.sol";
import {Test, console} from "forge-std/Test.sol";

import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

contract STKM_T is Test, fundBalance {

    STKM s_STKM;

    address Owner = makeAddr("Owner");
    address Alice = makeAddr("Alice");
    address Bob = makeAddr("Bob");

    function setUp() public {
        STKM_S s = new STKM_S();
        s_STKM = s.run();
    }

    /*//////////////////////////////////////////////////////////////
                                buySTKM
    //////////////////////////////////////////////////////////////*/    

    function test_onlyOwner_can_buySTKM() public {
        vm.expectRevert();
        s_STKM.buySTKM(Alice, 5 ether);
    }    

    function test_buySTKM_cannot_to_zero_address() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors.ERC20InvalidReceiver.selector, 
                address(0)
            )
        );

        vm.prank(Owner);
        s_STKM.buySTKM(address(0), 5 ether);
    }

    function test_cannot_buySTKM_zero_amount() public {
        vm.expectRevert(STKM.STKM__MintZero.selector);

        vm.prank(Owner);
        s_STKM.buySTKM(Alice, 0);
    }

    function test_can_buySTKM_to_Alice() public {
        vm.prank(Owner);
        s_STKM.buySTKM(Alice, 5 ether);
        assert(s_STKM.balanceOf(Alice) == 5 ether);
    }

    /*//////////////////////////////////////////////////////////////
                                giveSTKM
    //////////////////////////////////////////////////////////////*/

    function test_onlyOwner_can_giveSTKM() public {
        vm.expectRevert();
        s_STKM.giveSTKM(Bob, 5 ether);
    }    

    function test_cannot_giveSTKM_to_zero_address() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors.ERC20InvalidReceiver.selector, 
                address(0)
            )
        );

        vm.prank(Owner);
        s_STKM.giveSTKM(address(0), 5 ether);
    }

    function test_cannot_giveSTKM_to_zero_amount() public {
        vm.expectRevert(STKM.STKM__MintZero.selector);

        vm.prank(Owner);
        s_STKM.giveSTKM(Bob, 0);
    }

    function test_can_giveSTKM_to_Bob() public {
        vm.prank(Owner);
        s_STKM.giveSTKM(Bob, 5 ether);
        assert(s_STKM.balanceOf(Bob) == 5 ether);
    }

    /*//////////////////////////////////////////////////////////////
                              withdrawSTKM
    //////////////////////////////////////////////////////////////*/

    function test_onlyOwner_can_withdrawSTKM() public {
        vm.expectRevert();
        s_STKM.withdrawSTKM(Alice, 5 ether);
    }    

    function test_withdrawSTKM_cannot_to_zero_address() public {
        vm.prank(Owner);
        s_STKM.buySTKM(Alice, 5 ether);
        
        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors.ERC20InvalidSender.selector, 
                address(0)
            )
        );

        vm.prank(Owner);
        s_STKM.withdrawSTKM(address(0), 5 ether);
    }

    function test_withdrawSTKM_zero_amount() public {
        vm.expectRevert(STKM.STKM__BurnZero.selector);
        vm.prank(Owner);
        s_STKM.withdrawSTKM(Alice, 0);
    }

    function test_can_withdrawSTKM() public {
        vm.prank(Owner);
        s_STKM.buySTKM(Alice, 5 ether);

        assert(s_STKM.balanceOf(Alice) == 5 ether);

        vm.prank(Owner);
        s_STKM.withdrawSTKM(Alice, 5 ether);

        assert(s_STKM.balanceOf(Alice) == 0);
    }

    /*//////////////////////////////////////////////////////////////
                                transfer
    //////////////////////////////////////////////////////////////*/

    function test_cannot_transfer_to_zero_address() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors.ERC20InvalidReceiver.selector, 
                address(0)
            )
        );
        
        s_STKM.transfer(address(0), 100);
    }  

    /// @notice hypothethically impossible
    function test_cannot_transfer_from_zero_address() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors.ERC20InvalidSender.selector, 
                address(0)
            )
        );
        
        vm.prank(address(0));
        s_STKM.transfer(Alice, 100);
    }

    function test_cannot_transfer_zero_amount() public {
        vm.expectRevert(STKM.STKM__transferZero.selector);
        s_STKM.transfer(Alice, 0);
    }

    function test_can_transfer() public {
        // 1. owner gets her 5 ether
        vm.prank(Owner);
        s_STKM.buySTKM(Alice, 5 ether);

        // 2. balance checks
        assertEq(s_STKM.balanceOf(Alice), 5 ether);
        assertEq(s_STKM.balanceOf(Bob), 0 ether);

        // 3. Alice -> Bob
        vm.prank(Alice);
        s_STKM.transfer(Bob, 2 ether);

        // 4. balance checks
        assertEq(s_STKM.balanceOf(Alice), 3 ether);
        assertEq(s_STKM.balanceOf(Bob), 2 ether);
    }

    /*//////////////////////////////////////////////////////////////
                                approve
    //////////////////////////////////////////////////////////////*/

    function test_cannot_approve_zero_address_spender() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors.ERC20InvalidSpender.selector, 
                address(0)
            )
        );

        s_STKM.approve(address(0), 100);
    }

    /// @notice hypothethically impossible
    function test_address_zero_cannot_approve() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors.ERC20InvalidApprover.selector, 
                address(0)
            )
        );

        vm.prank(address(0));
        s_STKM.approve(Alice, 100);
    }    

    function test_cannot_approve_zero_amount() public {
        vm.expectRevert(STKM.STKM__ApprovingZero.selector);
        s_STKM.approve(Alice, 0);
    }

    /// @notice no balance checks required
    function test_can_do_approve() public {
        vm.prank(Bob);
        s_STKM.approve(Alice, 6 ether);

        assert(s_STKM.allowance(Bob, Alice) == 6 ether);
    }

    /*//////////////////////////////////////////////////////////////
                              transferFrom
    //////////////////////////////////////////////////////////////*/

    function test_cannot_transferFrom_to_zero_address() public {
        vm.prank(Alice);
        s_STKM.approve(address(this), 100);

        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors.ERC20InvalidReceiver.selector, 
                address(0)
            )
        );
        
        s_STKM.transferFrom(Alice, address(0), 100);
    }    

    function test_cannot_transferFrom_zero_amount() public {
        vm.expectRevert(STKM.STKM__transferZero.selector);
        s_STKM.transferFrom(Alice, Bob, 0);
    }

    /*//////////////////////////////////////////////////////////////
                             updateInterest
    //////////////////////////////////////////////////////////////*/

    function test_no_updateInterest_on_balance_zero() public {
        assertEq(s_STKM.balanceOf(Alice), 0);

        s_STKM.updateInterest(Alice);
        assertEq(s_STKM.balanceOf(Alice), 0);

        skip(5 days);

        s_STKM.updateInterest(Alice);
        assertEq(s_STKM.balanceOf(Alice), 0);
    }    

    function test_no_updateInterest_within_1_day_since_last_update() public {
        vm.prank(Owner);
        s_STKM.buySTKM(Alice, 5 ether);

        assertEq(s_STKM.balanceOf(Alice), 5 ether);

        // remain 5 ether
        s_STKM.updateInterest(Alice);
        assertEq(s_STKM.balanceOf(Alice), 5 ether);

        skip(20 hours);

        // still remain 5 ether cuz it's still wintin a day
        s_STKM.updateInterest(Alice);
        assertEq(s_STKM.balanceOf(Alice), 5 ether);
    }

    function test_can_updateInterest_after_1_day_since_last_update() public {
        uint buySTKMAmount = 5 ether;

        // get STKM
        vm.prank(Owner);
        s_STKM.buySTKM(Alice, buySTKMAmount);

        assertEq(s_STKM.balanceOf(Alice), buySTKMAmount);
        console.log("Amount STKM has:", buySTKMAmount);

        // after 1 days
        skip(1 days);

        uint balAfterOneDay = s_STKM.balanceOf(Alice);
        console.log("STKM balance after 1 days:", balAfterOneDay);

        s_STKM.updateInterest(Alice);
        assertGt(balAfterOneDay, 5 ether);

        // after some days
        skip(2 days);

        uint balAfterSomeDays = s_STKM.balanceOf(Alice);
        console.log("STKM balance after some days:", balAfterSomeDays);

        s_STKM.updateInterest(Alice);
        assertGt(balAfterSomeDays, balAfterOneDay);
    }

    /*//////////////////////////////////////////////////////////////
                        checkInterestLastUpdate
    //////////////////////////////////////////////////////////////*/

    function test_can_updateInterestTime_for_first_receive() public {
        assertEq(s_STKM.checkInterestLastUpdate(Alice), 0);

        skip(1 hours);

        vm.prank(Owner);
        s_STKM.buySTKM(Bob, 5 ether);

        uint timestampAfterOneHour = block.timestamp;
        assertEq(s_STKM.checkInterestLastUpdate(Bob), timestampAfterOneHour);

        // should still be the same, since it's still within 1 day
        skip(10 hours);
        s_STKM.updateInterest(Bob);
        assertEq(s_STKM.checkInterestLastUpdate(Bob), timestampAfterOneHour);
    }

    function test_noInterestUpdate_within_1_days_since_last_update() public {
        vm.prank(Owner);
        s_STKM.buySTKM(Alice, 5 ether);

        uint currentTimeStamp = block.timestamp;
        s_STKM.updateInterest(Alice);
        assertEq(s_STKM.checkInterestLastUpdate(Alice), currentTimeStamp);

        // inc time
        skip(10 hours);

        s_STKM.updateInterest(Alice);
        assertEq(s_STKM.checkInterestLastUpdate(Alice), currentTimeStamp);
    } 

    function test_can_have_interestUpdateTime_after_1_days() public {
        vm.prank(Owner);
        s_STKM.buySTKM(Bob, 5 ether);

        s_STKM.updateInterest(Bob);
        assertEq(s_STKM.checkInterestLastUpdate(Bob), block.timestamp, "1");

        // inc time
        skip(1 days);
        s_STKM.updateInterest(Bob);
        assertEq(s_STKM.checkInterestLastUpdate(Bob), block.timestamp, "2");

        skip(10 days);
        s_STKM.updateInterest(Bob);
        assertEq(s_STKM.checkInterestLastUpdate(Bob), block.timestamp, "3");
    }   

    

}