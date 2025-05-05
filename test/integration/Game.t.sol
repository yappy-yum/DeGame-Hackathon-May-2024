// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test, console} from "forge-std/Test.sol";
import {Game_S} from "script/Game.s.sol";
import {fundBalance} from "test/fundBalance.sol";

import {Game} from "src/Game.sol";
import {ISTKM} from "src/Interface/ISTKM.sol";
import {STKM} from "src/factory/STKM.sol";
import {NFT} from "src/factory/NFT.sol";
import {INFT} from "src/Interface/INFT.sol";

import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

contract Game_T is Test, fundBalance {

    Game game;

    address Owner = makeAddr("Owner");
    address Alice = makeAddr("Alice");
    address Meow = makeAddr("Meow");
    address Bob = makeAddr("Bob");
    
    function setUp() public vmDeal(Owner) {
        Game_S G = new Game_S();
        game = G.run();

        vm.prank(Owner);
        (bool done, ) = address(game).call{value: 1 ether}("");
        require(done, "Game Transaction Failed");

    }

    /*//////////////////////////////////////////////////////////////
                             Test Scenario
    //////////////////////////////////////////////////////////////*/

    /**
     * 1. Alice, Bob and Meow buy 2 ether STKM
     *
     * 2. Alice buy NFT-5 and NFT-10
     *    - Alice: NFT-5, NFT-10
     *
     * 3. Bob buy NFT-20
     *    - Bob: NFT-20
     *    - Alice: NFT-5, NFT-10
     *
     * 4. Meow buy NFT-13 and NFT-7
     *    - Meow: NFT-13, NFT-7
     *    - Alice: NFT-5, NFT-10
     *    - Bob: NFT-20
     *
     * 5. Alice trade her NFT-5 with Bob NFT-20
     *
     * 6. Bob rejects the trade
     *
     * 7. Bob trades his NFT-20 with Meow NFT-13
     *
     * 8. Meow accepts the trade
     *    - Bob: NFT-13
     *    - Meow: NFT-20, NFT-7
     *    - Alice: NFT-5, NFT-10
     *
     * 9. Alice resell her NFT-5
     *
     * 10. Alice remove the resell, and resell her NFT-10
     *
     * 11. Meow buy the resell NFT-10
     *     - Meow: NFT-10, NFT-20, NFT-7
     *     - Alice: NFT-5
     *     - Bob: NFT-13
     *
     */
    function test_scenario() public {
        // 1. Alice, Bob and Meow buy 2 ether STKM
        vm.deal(Alice, 2 ether);
        vm.deal(Bob, 2 ether);
        vm.deal(Meow, 2 ether);

        vm.startPrank(Alice);
        game.buySTKM{value: 2 ether}();
        assertEq(game.STKMBalanceOf(), 2 ether);
        vm.stopPrank();

        vm.startPrank(Bob);
        game.buySTKM{value: 2 ether}();
        assertEq(game.STKMBalanceOf(), 2 ether);
        vm.stopPrank();

        vm.startPrank(Meow);
        game.buySTKM{value: 2 ether}();
        assertEq(game.STKMBalanceOf(), 2 ether);
        vm.stopPrank();

        // 2. Alice buy NFT-5 and NFT-10
        vm.startPrank(Alice);
        game.BuyNFT(5);
        game.BuyNFT(10);
        assertEq(game.NFTOwnerOf(5), Alice);
        assertEq(game.NFTOwnerOf(10), Alice);
        assertEq(game.STKMBalanceOf(), 0 ether);
        vm.stopPrank();

        // 3. Bob buy NFT-20
        vm.startPrank(Bob);
        game.BuyNFT(20);
        assertEq(game.NFTOwnerOf(20), Bob);
        assertEq(game.STKMBalanceOf(), 1 ether);
        vm.stopPrank();

        // 4. Meow buy NFT-13 and NFT-7
        vm.startPrank(Meow);
        game.BuyNFT(13);
        game.BuyNFT(7);
        assertEq(game.NFTOwnerOf(13), Meow);
        assertEq(game.NFTOwnerOf(7), Meow);
        assertEq(game.STKMBalanceOf(), 0 ether);
        vm.stopPrank();

        // 5. Alice trade her NFT-5 with Bob NFT-20
        vm.prank(Alice);
        game.StartTrade(Bob, 5, 20);

        INFT.Trade memory trade = game.getPastTradeHistory(0);
        assertEq(trade._ownerA, Alice);
        assertEq(trade._ownerB, Bob);
        assertEq(trade._tokenIdA, 5);
        assertEq(trade._tokenIdB, 20);
        assertEq(trade._approvedA, true);
        assertEq(trade._approvedB, false);

        // 6. Bob rejects the trade
        vm.prank(Bob);
        game.RejectTrade(0, 20);

        trade = game.getPastTradeHistory(0);
        assertEq(trade._ownerA, Alice);
        assertEq(trade._ownerB, Bob);
        assertEq(trade._tokenIdA, 5);
        assertEq(trade._tokenIdB, 20);
        assertEq(trade._approvedA, true);
        assertEq(trade._approvedB, false);

        // 7. Bob trades his NFT-20 with Meow NFT-13
        vm.prank(Bob);
        game.StartTrade(Meow, 20, 13);

        trade = game.getPastTradeHistory(1);
        assertEq(trade._ownerA, Bob);
        assertEq(trade._ownerB, Meow);
        assertEq(trade._tokenIdA, 20);
        assertEq(trade._tokenIdB, 13);
        assertEq(trade._approvedA, true);
        assertEq(trade._approvedB, false);

        // 8. Meow accepts the trade
        vm.prank(Meow);
        game.AcceptTrade(1, 13);

        assertEq(game.NFTOwnerOf(13), Bob);
        assertEq(game.NFTOwnerOf(20), Meow);
        assertEq(game.NFTOwnerOf(5), Alice);
        assertEq(game.NFTOwnerOf(10), Alice);

        trade = game.getPastTradeHistory(1);
        assertEq(trade._ownerA, Bob);
        assertEq(trade._ownerB, Meow);
        assertEq(trade._tokenIdA, 20);
        assertEq(trade._tokenIdB, 13);
        assertEq(trade._approvedA, true);
        assertEq(trade._approvedB, true);

        // 9. Alice resells her NFT-5
        skip(4 days);
        uint FirstTimestamp = block.timestamp;

        vm.prank(Alice);
        game.ResellNFT(5, 3 ether);

        INFT.reSell memory resell = game.getCurrentResellNFT(5);
        assertEq(resell.owner, Alice);
        assertEq(resell.buyer, address(0));
        assertEq(resell.sellingPrice, 3 ether);
        assertEq(resell.tokenId, 5);
        assertEq(resell.timeListed, FirstTimestamp);
        assertEq(resell.timeSold, 0);

        // 10. Alice remove the resell, and resell her NFT-10
        skip(1 days);
        uint SecondTimestamp = block.timestamp;

        vm.prank(Alice);
        game.RevokeResellNFT(5);
        
        resell = game.getCurrentResellNFT(5);
        assertEq(resell.owner, address(0));
        assertEq(resell.buyer, address(0));
        assertEq(resell.sellingPrice, 0 ether);
        assertEq(resell.tokenId, 0);
        assertEq(resell.timeListed, 0);
        assertEq(resell.timeSold, 0);

        vm.prank(Alice);
        game.ResellNFT(10, 5 ether);

        resell = game.getCurrentResellNFT(10);
        assertEq(resell.owner, Alice);
        assertEq(resell.buyer, address(0));
        assertEq(resell.sellingPrice, 5 ether);
        assertEq(resell.tokenId, 10);
        assertEq(resell.timeListed, SecondTimestamp);
        assertEq(resell.timeSold, 0);

        // 11. Meow buy the resell NFT-10
        skip(7 hours);
        uint ThirdTimestamp = block.timestamp;

        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors.ERC20InsufficientBalance.selector, 
                Meow,
                0 ether, // Meow balance
                5 ether // Meow needed
            )
        );
        vm.prank(Meow);
        game.BuyResellNFT(10);

        vm.deal(Meow, 5 ether);
        vm.startPrank(Meow);
        game.buySTKM{value: 5 ether}();
        game.BuyResellNFT(10);
        vm.stopPrank();

        resell = game.getCurrentResellNFT(10);
        assertEq(resell.owner, address(0));
        assertEq(resell.buyer, address(0));
        assertEq(resell.sellingPrice, 0);
        assertEq(resell.tokenId, 0);
        assertEq(resell.timeListed, 0);
        assertEq(resell.timeSold, 0);

        resell = game.getPastReSellHistory(0);
        assertEq(resell.owner, Alice);
        assertEq(resell.buyer, Meow);
        assertEq(resell.sellingPrice, 5 ether);
        assertEq(resell.tokenId, 10);
        assertEq(resell.timeListed, SecondTimestamp);
        assertEq(resell.timeSold, ThirdTimestamp);

        assertEq(game.NFTOwnerOf(10), Meow);
        assertEq(game.NFTOwnerOf(7), Meow);
        assertEq(game.NFTOwnerOf(20), Meow);
        assertEq(game.NFTOwnerOf(5), Alice);
        assertEq(game.NFTOwnerOf(13), Bob);        
        
    }    

}