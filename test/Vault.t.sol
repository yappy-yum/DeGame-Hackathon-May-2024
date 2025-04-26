// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import {Test, console} from "forge-std/Test.sol";
import {Vault} from "../src/Vault.sol";

contract VaultTest is Test {

    Vault vault;
    Hi hi;

    address Owner = makeAddr("Owner");
    address Alice = makeAddr("Alice");
    address Bob = makeAddr("Bob");
    
    function setUp() public {
        vm.startPrank(Owner);

        vault = new Vault();
        hi = new Hi();

        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                         failed caller attempts
    //////////////////////////////////////////////////////////////*/

    function test_contract_cannot_call_buySTKM() public {
        vm.deal(address(hi), 1 ether);

        vm.expectRevert();
        
        vm.prank(address(hi));
        vault.buySTKM{value: 1 ether}();
    }

    function test_only_owner_can_call_giveSTKM() public {
        // contract being caller
        vm.prank(address(hi));
        vm.expectRevert();
        vault.giveSTKM(address(hi), 1 ether);

        // other people (not owner) being caller
        vm.prank(Alice);
        vm.expectRevert();
        vault.giveSTKM(address(hi), 1 ether);

        // owner being caller
        vm.prank(Owner);
        vault.giveSTKM(address(hi), 1 ether);
    }

    /*//////////////////////////////////////////////////////////////
                          Zero Mint & Address
    //////////////////////////////////////////////////////////////*/

    function test_cannot_buy_Zero_STKM() public {
        vm.expectRevert(Vault.Vault__MintZero.selector);
        vm.prank(Bob);
        vault.buySTKM();
    }    

    function test_owner_cannot_give_zero_STKM() public {
        vm.expectRevert(Vault.Vault__MintZero.selector);
        vm.prank(Owner);
        vault.giveSTKM(Alice, 0);
    }

    function test_owner_cannot_give_STKM_to_zero_address() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors.ERC20InvalidReceiver.selector, 
                address(0)
            )
        );
        vm.prank(Owner);
        vault.giveSTKM(address(0), 1 ether);
    }

    /*//////////////////////////////////////////////////////////////
                          test user owns STKM
    //////////////////////////////////////////////////////////////*/

    modifier moreThanZero(uint _amount) {
        vm.assume(_amount > 0);
        _;
    }

    function test_owner_give_STKM(uint _amount) public moreThanZero(_amount) {
        vm.prank(Owner);
        vault.giveSTKM(Alice, _amount);

        assertEq(
            vault.userBalance(Alice), 
            _amount
        );
    }

    function test_Bob_buys_STKM(uint _amount) public moreThanZero(_amount) {
        vm.deal(Bob, _amount);

        // initially Bob has no STKM
        assertEq(
            vault.userBalance(Bob), 
            0
        );

        // Bob buys STKM
        vm.prank(Bob);
        vault.buySTKM{value: _amount}();

        assertEq(
            vault.userBalance(Bob), 
            _amount
        );
    }    

    /*//////////////////////////////////////////////////////////////
                         test interest accrued
    //////////////////////////////////////////////////////////////*/

    modifier vmDeal() {
        vm.deal(Alice, 10 ether);
        vm.deal(Bob, 10 ether);
        _;
    }

    function test_accrueing_interest() public vmDeal {
        uint AliceBuysAmount = 2 ether;
        
        // 1. Alice buys 2 ether STKM
        vm.prank(Alice);
        vault.buySTKM{value: AliceBuysAmount}();

        // 2. Checks Alice has bought 2 ether STKM
        assertEq(
            vault.userBalance(Alice), 
            AliceBuysAmount
        );

        skip(1 days);

        // 3. after 1 days, Alice should have more STKM
        assertGt(
            vault.userBalance(Alice), 
            AliceBuysAmount
        );
        console.log("Alice total STKM before 1 days: ", AliceBuysAmount);
        console.log("Alice total STKM after 1 days: ", vault.userBalance(Alice));
    }
   

}

contract Hi {}