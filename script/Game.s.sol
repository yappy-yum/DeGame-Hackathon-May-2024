// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Script} from "forge-std/Script.sol";
import {STKM_S} from "script/STKM.s.sol";

import {Game} from "src/Game.sol";
import {STKM} from "src/factory/STKM.sol";
import {ISTKM} from "src/Interface/ISTKM.sol";

contract Game_S is Script {

    STKM public s_STKM;
    Game public game;

    address Owner = makeAddr("Owner");

    function run() public returns(Game) {

        STKM_S STKM_s = new STKM_S();
        s_STKM = STKM_s.run();

        _deployContract();
        _transferOwnership();

        return game;

    }

    function _deployContract() private {

        vm.startBroadcast(Owner);
        game = new Game(ISTKM(s_STKM));
        vm.stopBroadcast();

    }

    function _transferOwnership() private {

        vm.startBroadcast(Owner);
        s_STKM.transferOwnership(address(game));
        vm.stopBroadcast();

    }

}