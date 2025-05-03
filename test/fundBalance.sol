// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test, console} from "forge-std/Test.sol";

abstract contract fundBalance is Test {

    modifier vmDeal(address _user) {
        vm.deal(_user, 100 ether);
        _;
    }

    function testNothing() public pure {}

}