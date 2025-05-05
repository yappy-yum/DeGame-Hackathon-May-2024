// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {NFT} from "src/factory/NFT.sol";
import {Test, console} from "forge-std/Test.sol";
import {NFT_S} from "script/NFT.s.sol";
import {INFT} from "src/Interface/INFT.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract NFT_T is Test {

    NFT s_NFT;
    string baseURI = "ipfs://bafybeie5ztgmhxv2gyx3nwzdj3c36vbyqfuxsw4vahnke4j2aik27dd7s4";

    address Owner = makeAddr("Owner");
    address Alice = makeAddr("Alice");
    address Meow = makeAddr("Meow");
    address Bob = makeAddr("Bob");

    function setUp() public {
        NFT_S nft_s = new NFT_S();
        s_NFT = nft_s.run();
    }

    /**
     * 1. mint NFT
     *    - Owner: 5 
     *    - Alice: 10
     *    - Bob: 15
     *
     * 2. Owner transfers his NFT to Bob
     *    - Bob: 5, 15
     *    - Alice: 10
     *
     * 3. Alice create a trades to trade her NFT-10 with Bob NFT-15
     *
     * 4. Bob reject the trades
     *
     * 5. Bob create a trades to trade his NFT-5 with Alice NFT-10
     *
     * 6. Alice accept the trades
     *    - Alice: 5
     *    - Bob: 10, 15
     *
     * 7. Bob re-sell his NFT-15
     * 
     * 8. Meow buys it
     *    - Meow: 15
     *    - Bob: 10
     *    - Alice: 5
     *
     * 9. all of them do safeTransferFrom to Owner
     *    - owner: 5, 10, 15
     */
    function test_Big_Huge_NFT_Test() public {
        uint tradeId = 0;
        vm.startPrank(Owner);

        // 1. mint NFT
        s_NFT.mint(Owner, 5);
        s_NFT.mint(Alice, 10);
        s_NFT.mint(Bob, 15);

        assertEq(s_NFT.ownerOf(5), Owner);
        assertEq(s_NFT.ownerOf(10), Alice);
        assertEq(s_NFT.ownerOf(15), Bob);

        assertEq(s_NFT.isTokenOnQueue(5), false);
        assertEq(s_NFT.isTokenOnQueue(10), false);
        assertEq(s_NFT.isTokenOnQueue(15), false);

        // 2. Owner transfers his NFT to Bob
        s_NFT.transferFrom(Owner, Bob, 5);

        assertEq(s_NFT.isTokenOnQueue(5), false);
        assertEq(s_NFT.isTokenOnQueue(10), false);
        assertEq(s_NFT.isTokenOnQueue(15), false);

        assertEq(s_NFT.ownerOf(5), Bob);
        assertEq(s_NFT.ownerOf(10), Alice);
        assertEq(s_NFT.ownerOf(15), Bob);

        // 3. Alice create a trades to trade her NFT-10 with Bob NFT-15
        tradeId = s_NFT.createTrade(Alice, Bob, 10, 15);
        assertEq(tradeId, 0);

        assertEq(s_NFT.isTokenOnQueue(5), false);
        assertEq(s_NFT.isTokenOnQueue(10), true);
        assertEq(s_NFT.isTokenOnQueue(15), true);

        // 4. Bob reject the trades
        s_NFT.rejectTrade(Bob, 15, tradeId);

        assertEq(s_NFT.isTokenOnQueue(5), false);
        assertEq(s_NFT.isTokenOnQueue(10), false);
        assertEq(s_NFT.isTokenOnQueue(15), false);

        // 5. Bob create a trades to trade his NFT-5 with Alice NFT-10
        tradeId = s_NFT.createTrade(Bob, Alice, 5, 10);
        assertEq(tradeId, 1);

        assertEq(s_NFT.isTokenOnQueue(5), true);
        assertEq(s_NFT.isTokenOnQueue(10), true);
        assertEq(s_NFT.isTokenOnQueue(15), false);

        // 6. Alice accept the trades
        s_NFT.acceptTrade(Alice, 10, tradeId);

        assertEq(s_NFT.isTokenOnQueue(5), false);
        assertEq(s_NFT.isTokenOnQueue(10), false);
        assertEq(s_NFT.isTokenOnQueue(15), false);

        assertEq(s_NFT.ownerOf(5), Alice);
        assertEq(s_NFT.ownerOf(10), Bob);
        assertEq(s_NFT.ownerOf(15), Bob);

        // 7. Bob re-sell his NFT-15
        skip(2 days);
        uint BobResellTime = block.timestamp;
        s_NFT.listNFT(Bob, 15, 10 ether);

        assertEq(s_NFT.isTokenOnQueue(5), false);
        assertEq(s_NFT.isTokenOnQueue(10), false);
        assertEq(s_NFT.isTokenOnQueue(15), true);

        // 8. Meow buys it
        skip(4 days);
        uint MeowBuyTime = block.timestamp;
        s_NFT.buyListingNFT(Meow, 15);

        assertEq(s_NFT.isTokenOnQueue(5), false);
        assertEq(s_NFT.isTokenOnQueue(10), false);
        assertEq(s_NFT.isTokenOnQueue(15), false);

        assertEq(s_NFT.ownerOf(5), Alice);
        assertEq(s_NFT.ownerOf(10), Bob);
        assertEq(s_NFT.ownerOf(15), Meow);

        vm.stopPrank();

        // 9. all of them do safeTransferFrom to Owner
        vm.prank(Alice);
        s_NFT.safeTransferFrom(Alice, Owner, 5);

        vm.prank(Bob);
        s_NFT.safeTransferFrom(Bob, Owner, 10);

        vm.prank(Meow);
        s_NFT.safeTransferFrom(Meow, Owner, 15);

        assertEq(s_NFT.ownerOf(5), Owner);
        assertEq(s_NFT.ownerOf(10), Owner);
        assertEq(s_NFT.ownerOf(15), Owner);

        // 10. Owner resell NFT-10
        skip(2 days);
        uint OwnerResellTime = block.timestamp;

        vm.prank(Owner);
        s_NFT.listNFT(Owner, 10, 20 ether);

        // 11. check trade history
        INFT.Trade memory tradeHistory0 = s_NFT.getPastTradeHistory(0);
        INFT.Trade memory tradeHistory1 = s_NFT.getPastTradeHistory(1);

        assert(tradeHistory0._ownerA == Alice);
        assert(tradeHistory0._ownerB == Bob);
        assert(tradeHistory0._tokenIdA == 10);
        assert(tradeHistory0._tokenIdB == 15);
        assert(tradeHistory0._approvedA == true);
        assert(tradeHistory0._approvedB == false);

        assert(tradeHistory1._ownerA == Bob);
        assert(tradeHistory1._ownerB == Alice);
        assert(tradeHistory1._tokenIdA == 5);
        assert(tradeHistory1._tokenIdB == 10);
        assert(tradeHistory1._approvedA == true);
        assert(tradeHistory1._approvedB == true);

        // 12. check reSell history

        INFT.reSell memory reSellHistory0 = s_NFT.getPastReSellHistory(0);
        assert(reSellHistory0.owner == Bob);
        assert(reSellHistory0.buyer == Meow);
        assert(reSellHistory0.sellingPrice == 10 ether);
        assert(reSellHistory0.tokenId == 15);
        assert(reSellHistory0.timeListed == BobResellTime);
        assert(reSellHistory0.timeSold == MeowBuyTime);

        INFT.reSell memory reSellHistory1 = s_NFT.getCurrentResell(10);
        assert(reSellHistory1.owner == Owner);
        assert(reSellHistory1.buyer == address(0));
        assert(reSellHistory1.sellingPrice == 20 ether);
        assert(reSellHistory1.tokenId == 10);
        assert(reSellHistory1.timeListed == OwnerResellTime);
        assert(reSellHistory1.timeSold == 0);

    }

}