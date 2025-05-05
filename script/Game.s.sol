// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Script} from "forge-std/Script.sol";
import {STKM_S} from "script/STKM.s.sol";
import {NFT_S} from "script/NFT.s.sol";

import {Game} from "src/Game.sol";
import {STKM} from "src/factory/STKM.sol";
import {ISTKM} from "src/Interface/ISTKM.sol";
import {NFT} from "src/factory/NFT.sol";
import {INFT} from "src/Interface/INFT.sol";

contract Game_S is Script {

    STKM_S STKM_s;
    NFT_S NFT_s;

    STKM s_STKM;
    NFT s_NFT;
    Game game;

    address Owner = makeAddr("Owner");

    function run() public returns(Game) {

        STKM_s = new STKM_S();
        NFT_s = new NFT_S();

        s_STKM = STKM_s.run();
        s_NFT = NFT_s.run();

        _deployGame();

        _STKMTransferOwnership();
        _NFTTransferOwnership();

        return game;

    }

    function _deployGame() internal {
        vm.broadcast(Owner);
        game = new Game(s_STKM, s_NFT);
    }

    function _STKMTransferOwnership() internal {
        vm.broadcast(Owner);
        s_STKM.transferOwnership(address(game));
    }

    function _NFTTransferOwnership() internal {
        vm.broadcast(Owner);
        s_NFT.transferOwnership(address(game));
    }

}