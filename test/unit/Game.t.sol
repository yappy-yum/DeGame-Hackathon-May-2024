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

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

contract Game_T is Test, fundBalance {
    using Strings for uint256;

    Game game;
    string baseURI = "ipfs://bafybeie5ztgmhxv2gyx3nwzdj3c36vbyqfuxsw4vahnke4j2aik27dd7s4";

    address Owner = makeAddr("Owner");
    address Alice = makeAddr("Alice");
    address Meow = makeAddr("Meow");
    address Bob = makeAddr("Bob");
    
    function setUp() public {
        Game_S G = new Game_S();
        game = G.run();
    }

    /*//////////////////////////////////////////////////////////////
                             Token Setting
    //////////////////////////////////////////////////////////////*/

    function test_setting_baseURI() public view {
        assertEq(game.getBaseURI(), baseURI);

        for (uint i = 0; i < 10000; i++) {
            if (i == 0 || i > 23) {
                assertEq(game.getTokenURI(i), "");
            } else {
                assertEq(
                    game.getTokenURI(i), 
                    string.concat(
                        baseURI, 
                        "/", 
                        i.toString(), 
                        ".json"
                    )
                );
            }
        }
    }     

    /*//////////////////////////////////////////////////////////////
                                buySTKM
    //////////////////////////////////////////////////////////////*/

    function test_no_contract_caller() public {
        vm.expectRevert();
        game.buySTKM();
    }

    function test_cannot_send_zeroFunds_to_buySTKM() public {
        vm.expectRevert(STKM.STKM__MintZero.selector);

        vm.prank(Bob);
        game.buySTKM();
    }

    function test_can_buySTKM() public vmDeal(Alice) {
        vm.prank(Alice);
        game.buySTKM{value: 1 ether}();

        vm.prank(Alice);
        assertEq(game.STKMBalanceOf(), 1 ether);
        assertEq(address(game).balance, 1 ether);
    }

    /*//////////////////////////////////////////////////////////////
                             OwnerGiveSTKM
    //////////////////////////////////////////////////////////////*/

    function test_onlyOwner_can_giveSTKM() public {
        vm.expectRevert();
        game.OwnerGiveSTKM(Alice, 1 ether);
    }    

    function test_cannot_send_to_zeroAddress() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors.ERC20InvalidReceiver.selector, 
                address(0)
            )
        );

        vm.prank(Owner);
        game.OwnerGiveSTKM(address(0), 1 ether);
    }

    function test_cannot_send_zeroAmount() public {
        vm.expectRevert(STKM.STKM__MintZero.selector);

        vm.prank(Owner);
        game.OwnerGiveSTKM(Alice, 0);
    }

    function test_owner_can_giveSTKM() public {
        vm.prank(Owner);
        game.OwnerGiveSTKM(Bob, 190);

        vm.prank(Bob);
        assertEq(game.STKMBalanceOf(), 190);
    }

    /*//////////////////////////////////////////////////////////////
                              withdrawSTKM
    //////////////////////////////////////////////////////////////*/

    function test_onlyEOA_can_withdrawSTKM() public {
        vm.expectRevert();
        game.withdrawSTKM(1 ether);
    }    

    function test_cannot_withdraw_zero() public {
        vm.expectRevert(STKM.STKM__BurnZero.selector);

        vm.prank(Alice);
        game.withdrawSTKM(0);
    }

    function test_can_withdrawSTKM() public vmDeal(Bob) {
        assertEq(Bob.balance, 100 ether);

        vm.startPrank(Bob);
        game.buySTKM{value: 5 ether}();

        assertEq(game.STKMBalanceOf(), 5 ether);
        assertEq(Bob.balance, 95 ether);

        game.withdrawSTKM(3 ether);

        assertEq(game.STKMBalanceOf(), 2 ether);
        assertEq(address(game).balance, 2 ether);
        assertEq(Bob.balance, 98 ether);

        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                           MintAccruedRewards
    //////////////////////////////////////////////////////////////*/

    function test_no_contract_caller_MintAccruedRewards() public {
        vm.expectRevert();
        game.MintAccruedRewards();
    }

    function test_MintAccruedRewards_only_after_days_with_balance() public vmDeal(Bob) {
        // 1. Bob has no balance
        vm.startPrank(Bob);
        assertEq(game.STKMBalanceOf(), 0);

        // 2. without balance (0 balance), no daily rewards
        skip(2 days);
        game.MintAccruedRewards();
        assertEq(game.STKMBalanceOf(), 0);
        assertEq(game.CheckRewardsLatestUpdateTime(), 0);

        // 3. get some STKM to Bob
        game.buySTKM{value: 5 ether}();

        // 4. Bob has balance
        assertEq(game.STKMBalanceOf(), 5 ether);

        // 5. mint rewards
        skip(2 days);
        assertGt(game.STKMBalanceOf(), 5 ether);
        game.MintAccruedRewards();
        assertEq(game.CheckRewardsLatestUpdateTime(), block.timestamp);

        vm.stopPrank();
    }

    function test_AccrueingRewards() public vmDeal(Bob) {
        // 1. Bob has no balance
        vm.startPrank(Bob);
        assertEq(game.STKMBalanceOf(), 0);

        game.buySTKM{value: 3029187462819302817}();
        console.log("total STKM bought:", game.STKMBalanceOf());

        uint currentTimeStamp = block.timestamp;
        game.MintAccruedRewards();
        assertEq(game.CheckRewardsLatestUpdateTime(), currentTimeStamp);

        skip(1 days);
        console.log("total STKM after 1 day:", game.STKMBalanceOf());

        skip(2 days + 5 hours);
        console.log("total STKM after some days:", game.STKMBalanceOf());

        uint newTimeStamp = block.timestamp;
        game.MintAccruedRewards();
        assertEq(game.CheckRewardsLatestUpdateTime(), newTimeStamp);

        skip(55 hours);
        console.log("total STKM after some days:", game.STKMBalanceOf());
        assertEq(game.CheckRewardsLatestUpdateTime(), newTimeStamp);

        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                                 BuyNFT
    //////////////////////////////////////////////////////////////*/

    function test_no_contract_caller_buyNFT() public {
        vm.expectRevert();
        game.BuyNFT(1);
    }    

    function test_must_have_enough_balance_to_buy_NFT() public vmDeal(Meow) {
        vm.startPrank(Meow);

        game.buySTKM{value: 500}();
        assertEq(game.STKMBalanceOf(), 500);

        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors.ERC20InsufficientBalance.selector, 
                Meow,
                500, 
                1 ether // lets assume that one NFT == one ether
            )
        );
        game.BuyNFT(1);

        vm.stopPrank();
    }

    function test_can_BuyNFT() public vmDeal(Meow) {
        vm.startPrank(Meow);

        game.buySTKM{value: 20 ether}();
        assertEq(game.STKMBalanceOf(), 20 ether);

        game.BuyNFT(1);
        game.BuyNFT(20);

        assertEq(game.NFTOwnerOf(1), Meow);
        assertEq(game.NFTOwnerOf(20), Meow);

        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                               ResellNFT
    //////////////////////////////////////////////////////////////*/

    function test_no_contract_caller_resellNFT() public {
        vm.expectRevert();
        game.ResellNFT(1, 1 ether);
    }    

    function test_ResellPrice_must_be_more_than_BuyPrice() public vmDeal(Alice) {
        vm.startPrank(Alice);

        game.buySTKM{value: 20 ether}();
        assertEq(game.STKMBalanceOf(), 20 ether);

        game.BuyNFT(1);
        assertEq(game.NFTOwnerOf(1), Alice);

        vm.expectRevert(Game.Game__MustMoreThanNFTPrice.selector);
        game.ResellNFT(1, 1 ether - 1);

        vm.expectRevert(Game.Game__MustMoreThanNFTPrice.selector);
        game.ResellNFT(1, 1 ether);        

        vm.stopPrank();
    }

    function test_can_ResellNFT() public vmDeal(Bob) {
        vm.startPrank(Bob);

        game.buySTKM{value: 20 ether}();
        assertEq(game.STKMBalanceOf(), 20 ether);

        skip(10 days);
        assertGt(game.STKMBalanceOf(), 20 ether);

        game.BuyNFT(1);
        game.ResellNFT(1, 2 ether);
        assertEq(game.NFTOwnerOf(1), Bob);

        INFT.reSell memory resellNFT = game.getCurrentResellNFT(1);
        assertEq(resellNFT.owner, Bob);
        assertEq(resellNFT.buyer, address(0));
        assertEq(resellNFT.sellingPrice, 2 ether);
        assertEq(resellNFT.tokenId, 1);
        assertEq(resellNFT.timeListed, block.timestamp);
        assertEq(resellNFT.timeSold, 0);

        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                            RevokeResellNFT
    //////////////////////////////////////////////////////////////*/

    function test_no_contract_caller_RevokeResellNFT() public {
        vm.expectRevert();
        game.RevokeResellNFT(1);
    }    

    function test_cannot_Revoke_not_resellNFT() public vmDeal(Bob) {
        vm.startPrank(Bob);

        game.buySTKM{value: 20 ether}();
        assertEq(game.STKMBalanceOf(), 20 ether);

        vm.expectRevert(NFT.NFT__ListingNotFound.selector);
        game.RevokeResellNFT(1);

        game.BuyNFT(5);
        assertEq(game.NFTOwnerOf(5), Bob);
        assertEq(game.STKMBalanceOf(), 19 ether);
        
        vm.expectRevert(NFT.NFT__ListingNotFound.selector);
        game.RevokeResellNFT(5);

        vm.stopPrank();
    }

    function test_can_RevokeResellNFT() public vmDeal(Alice) {
        vm.startPrank(Alice);

        game.buySTKM{value: 20 ether}();
        assertEq(game.STKMBalanceOf(), 20 ether);

        game.BuyNFT(5);
        game.BuyNFT(10);
        assertEq(game.NFTOwnerOf(5), Alice);
        assertEq(game.NFTOwnerOf(10), Alice);

        assertEq(game.STKMBalanceOf(), 18 ether);

        game.ResellNFT(5, 5 ether);

        INFT.reSell memory resellNFT = game.getCurrentResellNFT(5);
        assertEq(resellNFT.owner, Alice);
        assertEq(resellNFT.buyer, address(0));
        assertEq(resellNFT.sellingPrice, 5 ether);
        assertEq(resellNFT.tokenId, 5);
        assertEq(resellNFT.timeListed, block.timestamp);
        assertEq(resellNFT.timeSold, 0);

        game.RevokeResellNFT(5);

        resellNFT = game.getCurrentResellNFT(5);
        assertEq(resellNFT.owner, address(0));
        assertEq(resellNFT.buyer, address(0));
        assertEq(resellNFT.sellingPrice, 0 ether);
        assertEq(resellNFT.tokenId, 0);
        assertEq(resellNFT.timeListed, 0);
        assertEq(resellNFT.timeSold, 0);

        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                              BuyResellNFT
    //////////////////////////////////////////////////////////////*/

    function test_no_contract_caller_BuyResellNFT() public {
        vm.expectRevert();
        game.BuyResellNFT(1);
    }    

    function test_cannot_BuyResellNFT_out_of_nothing() public vmDeal(Bob) {
        vm.startPrank(Bob);

        game.buySTKM{value: 20 ether}();
        assertEq(game.STKMBalanceOf(), 20 ether);

        vm.expectRevert(NFT.NFT__ListingNotFound.selector);
        game.BuyResellNFT(5);

        game.BuyNFT(5);
        assertEq(game.NFTOwnerOf(5), Bob);
        assertEq(game.STKMBalanceOf(), 19 ether);
        
        vm.expectRevert(NFT.NFT__ListingNotFound.selector);
        game.BuyResellNFT(5);

        vm.stopPrank();

        vm.expectRevert(NFT.NFT__ListingNotFound.selector);
        vm.prank(Alice);
        game.BuyResellNFT(5);
    }

    function test_can_BuyResellNFT() public vmDeal(Alice) vmDeal(Meow) {
        vm.startPrank(Alice);

        // Alice buy STKM
        game.buySTKM{value: 20 ether}();
        assertEq(game.STKMBalanceOf(), 20 ether);

        // Alice buy NFT
        game.BuyNFT(5);
        game.BuyNFT(10);
        assertEq(game.NFTOwnerOf(5), Alice);
        assertEq(game.NFTOwnerOf(10), Alice);

        assertEq(game.STKMBalanceOf(), 18 ether);

        // Alice resell NFT
        game.ResellNFT(5, 5 ether);

        uint FirstTimestamp = block.timestamp;

        INFT.reSell memory resellNFT = game.getCurrentResellNFT(5);
        assertEq(resellNFT.owner, Alice);
        assertEq(resellNFT.buyer, address(0));
        assertEq(resellNFT.sellingPrice, 5 ether);
        assertEq(resellNFT.tokenId, 5);
        assertEq(resellNFT.timeListed, FirstTimestamp);
        assertEq(resellNFT.timeSold, 0);

        vm.stopPrank();

        skip(5 days);
        uint SecondTimestamp = block.timestamp;

        vm.startPrank(Meow);

        // Meow buy STKM 
        game.buySTKM{value: 20 ether}();
        assertEq(game.STKMBalanceOf(), 20 ether);

        // Meow buy resell NFT
        game.BuyResellNFT(5);

        resellNFT = game.getCurrentResellNFT(5);
        assertEq(resellNFT.owner, address(0));
        assertEq(resellNFT.buyer, address(0));
        assertEq(resellNFT.sellingPrice, 0 ether);
        assertEq(resellNFT.tokenId, 0);
        assertEq(resellNFT.timeListed, 0);
        assertEq(resellNFT.timeSold, 0);

        resellNFT = game.getPastReSellHistory(0);
        assertEq(resellNFT.owner, Alice);
        assertEq(resellNFT.buyer, Meow);
        assertEq(resellNFT.sellingPrice, 5 ether);
        assertEq(resellNFT.tokenId, 5);
        assertEq(resellNFT.timeListed, FirstTimestamp);
        assertEq(resellNFT.timeSold, SecondTimestamp);

        vm.stopPrank();

        vm.prank(Alice);
        assertGt(game.STKMBalanceOf(), ((5 ether * 90) / 100) + 18 ether);

        assertEq(game.NFTOwnerOf(5), Meow); 
        assertNotEq(game.NFTOwnerOf(5), Alice);

        vm.prank(Meow);
        assertEq(game.STKMBalanceOf(), 20 ether - 5 ether);
    }

    /*//////////////////////////////////////////////////////////////
                               StartTrade
    //////////////////////////////////////////////////////////////*/

    function test_no_contract_caller_StartTrade() public {
        vm.expectRevert();
        game.StartTrade(Bob, 1, 1);
    }

    function test_cannot_StartTrade_out_of_nothing() public {
        vm.expectRevert(NFT.NFT__SomethingWentWrong.selector);

        vm.prank(Alice);
        game.StartTrade(Bob, 1, 2);
    }

    function test_can_startTrade() public vmDeal(Alice) vmDeal(Bob) {
        vm.startPrank(Alice);

        // Alice buy NFT-5
        game.buySTKM{value: 20 ether}();
        assertEq(game.STKMBalanceOf(), 20 ether);

        game.BuyNFT(5);
        assertEq(game.NFTOwnerOf(5), Alice);

        vm.stopPrank();

        vm.startPrank(Bob);

        // Bob buy NFT-10
        game.buySTKM{value: 20 ether}();
        assertEq(game.STKMBalanceOf(), 20 ether);

        game.BuyNFT(10);
        assertEq(game.NFTOwnerOf(10), Bob);

        vm.stopPrank();

        // Alice start trade
        vm.startPrank(Alice);
        game.StartTrade(Bob, 5, 10);

        INFT.Trade memory trade = game.getPastTradeHistory(0);
        assertEq(trade._ownerA, Alice);
        assertEq(trade._ownerB, Bob);
        assertEq(trade._tokenIdA, 5);
        assertEq(trade._tokenIdB, 10);
        assertEq(trade._approvedA, true);
        assertEq(trade._approvedB, false);

        vm.stopPrank();

    }

    /*//////////////////////////////////////////////////////////////
                              AcceptTrade
    //////////////////////////////////////////////////////////////*/

    function test_no_contract_caller_AcceptTrade() public {
        vm.expectRevert();
        game.AcceptTrade(0, 1);
    }    

    function test_cannot_AcceptTrade_out_of_nothing() public {
        vm.expectRevert(NFT.NFT__NFTNotOnQueue.selector);

        vm.prank(Alice);
        game.AcceptTrade(0, 1);
    }

    function test_cannot_AcceptTrade_with_incorrectInformation() public vmDeal(Alice) vmDeal(Bob) {
        vm.startPrank(Alice);

        // Alice buy NFT-5 and NFT-10
        game.buySTKM{value: 20 ether}();
        assertEq(game.STKMBalanceOf(), 20 ether);

        game.BuyNFT(5);
        game.BuyNFT(10);
        assertEq(game.NFTOwnerOf(5), Alice);
        assertEq(game.NFTOwnerOf(10), Alice);

        vm.stopPrank();

        vm.startPrank(Bob);

        // Bob buy NFT-20
        game.buySTKM{value: 20 ether}();
        assertEq(game.STKMBalanceOf(), 20 ether);

        game.BuyNFT(20);
        assertEq(game.NFTOwnerOf(20), Bob); 

        vm.stopPrank();

        // Alice trade her NFT-5 with Bob NFT-20
        vm.startPrank(Alice);
        game.StartTrade(Bob, 5, 20);

        INFT.Trade memory trade = game.getPastTradeHistory(0);
        assertEq(trade._ownerA, Alice);
        assertEq(trade._ownerB, Bob);
        assertEq(trade._tokenIdA, 5);
        assertEq(trade._tokenIdB, 20);
        assertEq(trade._approvedA, true);
        assertEq(trade._approvedB, false);

        vm.stopPrank();

        vm.expectRevert(NFT.NFT__NFTNotOnQueue.selector);
        vm.prank(Bob);
        game.AcceptTrade(0, 21);

        vm.expectRevert(NFT.NFT__TradeNotFound.selector);
        vm.prank(Alice);
        game.AcceptTrade(0, 20);

        vm.expectRevert(NFT.NFT__TradeNotFound.selector);
        vm.prank(Bob);
        game.AcceptTrade(1, 20);
    }

    function test_can_AcceptTrade() public vmDeal(Alice) vmDeal(Bob) {
        vm.startPrank(Alice);

        // Alice buy NFT-5 and NFT-10
        game.buySTKM{value: 20 ether}();
        assertEq(game.STKMBalanceOf(), 20 ether);

        game.BuyNFT(5);
        game.BuyNFT(10);
        assertEq(game.NFTOwnerOf(5), Alice);
        assertEq(game.NFTOwnerOf(10), Alice);

        vm.stopPrank();

        vm.startPrank(Bob);

        // Bob buy NFT-20
        game.buySTKM{value: 20 ether}();
        assertEq(game.STKMBalanceOf(), 20 ether);

        game.BuyNFT(20);
        assertEq(game.NFTOwnerOf(20), Bob); 

        vm.stopPrank();

        // Alice trade her NFT-5 with Bob NFT-20
        vm.startPrank(Alice);
        game.StartTrade(Bob, 5, 20);

        INFT.Trade memory trade = game.getPastTradeHistory(0);
        assertEq(trade._ownerA, Alice);
        assertEq(trade._ownerB, Bob);
        assertEq(trade._tokenIdA, 5);
        assertEq(trade._tokenIdB, 20);
        assertEq(trade._approvedA, true);
        assertEq(trade._approvedB, false);

        vm.stopPrank();

        vm.prank(Bob);
        game.AcceptTrade(0, 20);

        trade = game.getPastTradeHistory(0);
        assertEq(trade._ownerA, Alice);
        assertEq(trade._ownerB, Bob);
        assertEq(trade._tokenIdA, 5);
        assertEq(trade._tokenIdB, 20);
        assertEq(trade._approvedA, true);
        assertEq(trade._approvedB, true);

        assertEq(game.NFTOwnerOf(5), Bob);
        assertEq(game.NFTOwnerOf(20), Alice);
    }

    /*//////////////////////////////////////////////////////////////
                              RejectTrade
    //////////////////////////////////////////////////////////////*/

    function test_no_contract_caller_RejectTrade() public vmDeal(Alice) vmDeal(Bob) {
        vm.expectRevert();
        game.RejectTrade(0, 1);
    }    

    function test_cannot_RejectTrade_with_incorrectInformation() public vmDeal(Alice) vmDeal(Bob) {
        vm.startPrank(Alice);

        // Alice buy NFT-5 and NFT-10
        game.buySTKM{value: 20 ether}();
        assertEq(game.STKMBalanceOf(), 20 ether);

        game.BuyNFT(5);
        game.BuyNFT(10);
        assertEq(game.NFTOwnerOf(5), Alice);
        assertEq(game.NFTOwnerOf(10), Alice);

        vm.stopPrank();

        vm.startPrank(Bob);

        // Bob buy NFT-20
        game.buySTKM{value: 20 ether}();
        assertEq(game.STKMBalanceOf(), 20 ether);

        game.BuyNFT(20);
        assertEq(game.NFTOwnerOf(20), Bob); 

        vm.stopPrank();

        // Alice trade her NFT-5 with Bob NFT-20
        vm.startPrank(Alice);
        game.StartTrade(Bob, 5, 20);

        INFT.Trade memory trade = game.getPastTradeHistory(0);
        assertEq(trade._ownerA, Alice);
        assertEq(trade._ownerB, Bob);
        assertEq(trade._tokenIdA, 5);
        assertEq(trade._tokenIdB, 20);
        assertEq(trade._approvedA, true);
        assertEq(trade._approvedB, false);

        vm.stopPrank();

        vm.expectRevert(NFT.NFT__NFTNotOnQueue.selector);
        vm.prank(Bob);
        game.RejectTrade(0, 21);    

        vm.expectRevert(NFT.NFT__TradeNotFound.selector);
        vm.prank(Alice);
        game.RejectTrade(1, 20);
    }

    function test_can_RejectTrade() public vmDeal(Alice) vmDeal(Bob) {
        vm.startPrank(Alice);

        // Alice buy NFT-5 and NFT-10
        game.buySTKM{value: 20 ether}();
        assertEq(game.STKMBalanceOf(), 20 ether);

        game.BuyNFT(5);
        game.BuyNFT(10);
        assertEq(game.NFTOwnerOf(5), Alice);
        assertEq(game.NFTOwnerOf(10), Alice);

        vm.stopPrank();

        vm.startPrank(Bob);

        // Bob buy NFT-20
        game.buySTKM{value: 20 ether}();
        assertEq(game.STKMBalanceOf(), 20 ether);

        game.BuyNFT(20);
        assertEq(game.NFTOwnerOf(20), Bob); 

        vm.stopPrank();

        // Alice trade her NFT-5 with Bob NFT-20
        vm.startPrank(Alice);
        game.StartTrade(Bob, 5, 20);

        INFT.Trade memory trade = game.getPastTradeHistory(0);
        assertEq(trade._ownerA, Alice);
        assertEq(trade._ownerB, Bob);
        assertEq(trade._tokenIdA, 5);
        assertEq(trade._tokenIdB, 20);
        assertEq(trade._approvedA, true);
        assertEq(trade._approvedB, false);

        vm.stopPrank();

        vm.prank(Bob);
        game.RejectTrade(0, 20);    

        trade = game.getPastTradeHistory(0);
        assertEq(trade._ownerA, Alice);
        assertEq(trade._ownerB, Bob);
        assertEq(trade._tokenIdA, 5);
        assertEq(trade._tokenIdB, 20);
        assertEq(trade._approvedA, true);
        assertEq(trade._approvedB, false);
    }



}