// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Script} from "forge-std/Script.sol";
import {STKM} from "src/factory/STKM.sol";

contract STKM_S is Script {

    STKM public s_STKM;
    address Owner = makeAddr("Owner");

    function run() public returns(STKM) {
        vm.startBroadcast(Owner);
        s_STKM = new STKM();
        vm.stopBroadcast();

        return s_STKM;
    }

}