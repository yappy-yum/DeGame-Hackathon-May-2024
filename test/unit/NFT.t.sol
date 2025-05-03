// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {NFT} from "src/factory/NFT.sol";
import {Test} from "forge-std/Test.sol";
import {NFT_S} from "script/NFT.s.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract NFT_T is Test {
    using Strings for uint256;

    NFT s_NFT;
    string baseURI = "ipfs://bafybeie5ztgmhxv2gyx3nwzdj3c36vbyqfuxsw4vahnke4j2aik27dd7s4";

    address Owner = makeAddr("Owner");
    address Alice = makeAddr("Alice");
    address Bob = makeAddr("Bob");

    function setUp() public {
        NFT_S nft_s = new NFT_S();
        s_NFT = nft_s.run();
    }

    /*//////////////////////////////////////////////////////////////
                             Token Setting
    //////////////////////////////////////////////////////////////*/

    function test_setting_token() public view {
        assertEq(s_NFT.name(), "STICKMAN");
        assertEq(s_NFT.symbol(), "STKM");
    }

    function test_setting_baseURI() public view {
        assertEq(s_NFT.baseURI(), baseURI);

        for (uint i = 0; i < 10000; i++) {
            if (i == 0 || i > 23) {
                assertEq(s_NFT.tokenURI(i), "");
            } else {
                assertEq(
                    s_NFT.tokenURI(i), 
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

    function test_contract_owner() public view {
        assertEq(s_NFT.owner(), Owner);
    }

    /*//////////////////////////////////////////////////////////////
                                  mint
    //////////////////////////////////////////////////////////////*/

    function test_onlyOwner_can_mint() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector, 
                Bob
            )
        );

        vm.prank(Bob);
        s_NFT.mint(Alice, 20);
    }  

    function test_no_zero_address_mint() public {
        vm.expectRevert(NFT.NFT__ZeroAddress.selector);

        vm.prank(Owner);
        s_NFT.mint(address(0), 20);
    }

    function test_Invalid_NFTId() public {
        vm.startPrank(Owner);

        for (uint NFTId = 0; NFTId < 50000; NFTId++) {
            // revert if NFT id not found 
            if (NFTId == 0 || NFTId > 23) {
                vm.expectRevert(NFT.NFT__NFTNotFound.selector);
                s_NFT.mint(Alice, NFTId);
            } 
            // else mint
            else {
                s_NFT.mint(Alice, NFTId);
            }
        }

        vm.stopPrank();
    }

    function test_can_mint_NFT() public {
        vm.startPrank(Owner);

        // mint NFT
        s_NFT.mint(Alice, 5);
        s_NFT.mint(Alice, 10);
        s_NFT.mint(Bob, 15);

        // checks minted NFT
        assertEq(s_NFT.ownerOf(5), Alice);
        assertEq(s_NFT.ownerOf(10), Alice);
        assertEq(s_NFT.ownerOf(15), Bob);

        vm.stopPrank();

        assertNotEq(s_NFT.ownerOf(5), Bob);
        assertNotEq(s_NFT.ownerOf(10), Bob);
        assertNotEq(s_NFT.ownerOf(15), Alice);
    }

    function test_cannot_mint_owned_NFT() public {
        vm.startPrank(Owner);

        // mint NFT
        s_NFT.mint(Alice, 5);
        s_NFT.mint(Alice, 10);
        s_NFT.mint(Bob, 15);

        // checks minted NFT
        assertEq(s_NFT.ownerOf(5), Alice);
        assertEq(s_NFT.ownerOf(10), Alice);
        assertEq(s_NFT.ownerOf(15), Bob);

        // mint again minted NFT
        vm.expectRevert(NFT.NFT__NFTOwned.selector);
        s_NFT.mint(Alice, 5);

        vm.expectRevert(NFT.NFT__NFTOwned.selector);
        s_NFT.mint(Owner, 10);

        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                                listNFT
    //////////////////////////////////////////////////////////////*/

    function test_onlyOwner_can_listNFT() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector, 
                Bob
            )
        );
        
        vm.prank(Bob);
        s_NFT.listNFT(Bob, 5, 10 ether);
    }

    function test_cannot_set_zero_price_to_resell() public {
        vm.startPrank(Owner);

        // Alice buys NFT
        s_NFT.mint(Alice, 5);
        assertEq(s_NFT.ownerOf(5), Alice);

        // list NFT
        vm.expectRevert(NFT.NFT__NoSellingForFree.selector);
        s_NFT.listNFT(Alice, 5, 0);

        vm.stopPrank();
    }    

    function test_can_only_sell_owned_NFT() public {
        vm.startPrank(Owner);

        // Bob sells NFT that not belongs to him
        vm.expectRevert(NFT.NFT__NFTNotOwnedOrNotExist.selector);
        s_NFT.listNFT(Bob, 5, 10 ether);

        vm.stopPrank();
    }

    function test_cannot_zeroAddress() public {
        vm.startPrank(Owner);

        vm.expectRevert(NFT.NFT__ZeroAddress.selector);
        s_NFT.listNFT(address(0), 5, 10 ether);

        vm.stopPrank();
    }

    function test_cannot_resell_again_when_reselling() public {
        vm.startPrank(Owner);

        // Alice buys NFT
        s_NFT.mint(Alice, 5);
        assertEq(s_NFT.ownerOf(5), Alice);

        // Alice list NFT
        s_NFT.listNFT(Alice, 5, 10 ether);

        // Alice list NFT again
        vm.expectRevert(NFT.NFT__AlreadyListed.selector);
        s_NFT.listNFT(Alice, 5, 10 ether);

        vm.stopPrank();
    }

    function test_resell() public {
        vm.startPrank(Owner);

        // Bob and Alice buys NFT
        s_NFT.mint(Bob, 5);
        s_NFT.mint(Alice, 10);

        assertEq(s_NFT.ownerOf(5), Bob);
        assertEq(s_NFT.ownerOf(10), Alice);

        skip(3 days);
        uint BobListingTimeStamp = block.timestamp;
        s_NFT.listNFT(Bob, 5, 10 ether);

        skip(2 days);
        uint AliceListingTimeStamp = block.timestamp;
        s_NFT.listNFT(Alice, 10, 20 ether);

        // checls resell informations:
        NFT.reSell memory BobResellStruct = s_NFT.getCurrentResell(5);
        assertEq(BobResellStruct.owner, Bob);
        assertEq(BobResellStruct.buyer, address(0));
        assertEq(BobResellStruct.sellingPrice, 10 ether);
        assertEq(BobResellStruct.tokenId, 5);
        assertEq(BobResellStruct.timeListed, BobListingTimeStamp);
        assertEq(BobResellStruct.timeSold, 0);

        NFT.reSell memory AliceResellStruct = s_NFT.getCurrentResell(10);
        assertEq(AliceResellStruct.owner, Alice);
        assertEq(AliceResellStruct.buyer, address(0));
        assertEq(AliceResellStruct.sellingPrice, 20 ether);
        assertEq(AliceResellStruct.tokenId, 10);
        assertEq(AliceResellStruct.timeListed, AliceListingTimeStamp);
        assertEq(AliceResellStruct.timeSold, 0);



        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                               unListNFT
    //////////////////////////////////////////////////////////////*/

    function test_cannot_resell_something_out_of_thin_air() public {
        vm.expectRevert(NFT.NFT__ListingNotFound.selector);

        vm.prank(Owner);
        s_NFT.unListNFT(Alice, 5);
    } 

    /// @notice potential bug 
    /// @notice hypothethically impossible due to the owner being child contract
    function test_potential_bug_for_allZero() public {
        vm.prank(Owner);
        s_NFT.unListNFT(address(0), 0);
    }

    function test_unList_incorrect_info() public {
        vm.startPrank(Owner);

        s_NFT.mint(Alice, 5);
        s_NFT.listNFT(Alice, 5, 10 ether);

        vm.expectRevert(NFT.NFT__ListingNotFound.selector);
        s_NFT.unListNFT(Bob, 5);

        vm.expectRevert(NFT.NFT__ListingNotFound.selector);
        s_NFT.unListNFT(Alice, 20);

        vm.stopPrank();
    }

    function test_can_unList() public {
        vm.startPrank(Owner);

        s_NFT.mint(Alice, 5);
        s_NFT.listNFT(Alice, 5, 10 ether);

        // check listing
        NFT.reSell memory AliceResellStruct = s_NFT.getCurrentResell(5);
        assertEq(AliceResellStruct.owner, Alice);
        assertEq(AliceResellStruct.buyer, address(0));
        assertEq(AliceResellStruct.sellingPrice, 10 ether);
        assertEq(AliceResellStruct.tokenId, 5);
        assertEq(AliceResellStruct.timeListed, block.timestamp);
        assertEq(AliceResellStruct.timeSold, 0);

        s_NFT.unListNFT(Alice, 5);

        // check listing again
        AliceResellStruct = s_NFT.getCurrentResell(5);
        assertEq(AliceResellStruct.owner, address(0));
        assertEq(AliceResellStruct.buyer, address(0));
        assertEq(AliceResellStruct.sellingPrice, 0 ether);
        assertEq(AliceResellStruct.tokenId, 0);
        assertEq(AliceResellStruct.timeListed, 0);
        assertEq(AliceResellStruct.timeSold, 0);

        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                             buyListingNFT
    //////////////////////////////////////////////////////////////*/

    function test_buying_unlisted_NFT() public {
        vm.startPrank(Owner);

        vm.expectRevert(NFT.NFT__ListingNotFound.selector);
        s_NFT.buyListingNFT(Bob, 5);

        vm.stopPrank();
    }

    function test_buyListingNFT() public {
        vm.startPrank(Owner);

        // Alice and Bob buys NFT
        s_NFT.mint(Alice, 5);
        s_NFT.mint(Bob, 3);

        // Alice resell NFT
        s_NFT.listNFT(Alice, 5, 10 ether);

        uint firstTimestamp = block.timestamp;

        // check current listing for NFT-5
        NFT.reSell memory AliceResellStruct = s_NFT.getCurrentResell(5);
        assertEq(AliceResellStruct.owner, Alice);
        assertEq(AliceResellStruct.buyer, address(0));
        assertEq(AliceResellStruct.sellingPrice, 10 ether);
        assertEq(AliceResellStruct.tokenId, 5);
        assertEq(AliceResellStruct.timeListed, firstTimestamp);
        assertEq(AliceResellStruct.timeSold, 0);

        skip(2 days);

        uint secondTimestamp = block.timestamp;

        // Bob buys Alice NFT-5
        s_NFT.buyListingNFT(Bob, 5);

        // check listing again for NFT-5
        AliceResellStruct = s_NFT.getCurrentResell(5);
        assertEq(AliceResellStruct.owner, address(0));
        assertEq(AliceResellStruct.buyer, address(0));
        assertEq(AliceResellStruct.sellingPrice, 0 ether);
        assertEq(AliceResellStruct.tokenId, 0);
        assertEq(AliceResellStruct.timeListed, 0);
        assertEq(AliceResellStruct.timeSold, 0);

        assertEq(s_NFT.ownerOf(5), Bob);
        
        AliceResellStruct = s_NFT.getPastReSellHistory(0);
        assertEq(AliceResellStruct.owner, Alice);
        assertEq(AliceResellStruct.buyer, Bob);
        assertEq(AliceResellStruct.sellingPrice, 10 ether);
        assertEq(AliceResellStruct.tokenId, 5);
        assertEq(AliceResellStruct.timeListed, firstTimestamp);
        assertEq(AliceResellStruct.timeSold, secondTimestamp);

        // Bob list NFT-3
        s_NFT.listNFT(Bob, 3, 50 ether);

        // check listing again for NFT-3
        NFT.reSell memory BobResellStruct = s_NFT.getCurrentResell(3);
        assertEq(BobResellStruct.owner, Bob);
        assertEq(BobResellStruct.buyer, address(0));
        assertEq(BobResellStruct.sellingPrice, 50 ether);
        assertEq(BobResellStruct.tokenId, 3);
        assertEq(BobResellStruct.timeListed, secondTimestamp);
        assertEq(BobResellStruct.timeSold, 0);

        skip(2 days);

        // Owner buy the Bob listing
        s_NFT.buyListingNFT(Owner, 3);

        // check listing again for NFT-3
        BobResellStruct = s_NFT.getCurrentResell(3);
        assertEq(BobResellStruct.owner, address(0));
        assertEq(BobResellStruct.buyer, address(0));
        assertEq(BobResellStruct.sellingPrice, 0 ether);
        assertEq(BobResellStruct.tokenId, 0);
        assertEq(BobResellStruct.timeListed, 0);
        assertEq(BobResellStruct.timeSold, 0);

        assertEq(s_NFT.ownerOf(3), Owner);

        BobResellStruct = s_NFT.getPastReSellHistory(1);
        assertEq(BobResellStruct.owner, Bob);
        assertEq(BobResellStruct.buyer, Owner);
        assertEq(BobResellStruct.sellingPrice, 50 ether);
        assertEq(BobResellStruct.tokenId, 3);
        assertEq(BobResellStruct.timeListed, secondTimestamp);
        assertEq(BobResellStruct.timeSold, block.timestamp);

        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                              createTrade
    //////////////////////////////////////////////////////////////*/    

    function test_onlyOwner_can_createTrade() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector, 
                Alice
            )
        );
        
        vm.prank(Alice);
        s_NFT.createTrade(Alice, Bob, 5, 10 ether);
    }

    function test_no_zeroAddress_on_trades() public {
        vm.expectRevert(NFT.NFT__NoZeroAddress.selector);
        vm.prank(Owner);
        s_NFT.createTrade(Alice, address(0), 5, 10 ether);

        vm.expectRevert(NFT.NFT__NoZeroAddress.selector);
        vm.prank(Owner);
        s_NFT.createTrade(address(0), Bob, 5, 10 ether);

        vm.expectRevert(NFT.NFT__NoZeroAddress.selector);
        vm.prank(Owner);
        s_NFT.createTrade(address(0), address(0), 5, 10 ether);
    }

    function test_cannot_have_both_sameAddress() public {
        vm.expectRevert(NFT.NFT__SameOwner.selector);

        vm.prank(Owner);
        s_NFT.createTrade(Bob, Bob, 5, 10 ether);
    }

    function test_both_party_must_be_ownerOf_NFT() public {
        vm.startPrank(Owner);

        vm.expectRevert(NFT.NFT__NFTANotOwnerA.selector);
        s_NFT.createTrade(Bob, Alice, 5, 10 ether);

        s_NFT.mint(Alice, 5);
        vm.expectRevert(NFT.NFT__NFTBNotOwnerB.selector);
        s_NFT.createTrade(Alice, Bob, 5, 10 ether);

        vm.stopPrank();
    }

    function test_can_start_trade() public {
        vm.startPrank(Owner);

        s_NFT.mint(Alice, 5);
        s_NFT.mint(Bob, 10);

        assertEq(s_NFT.createTrade(Alice, Bob, 5, 10), 0);

        // checks trade
        NFT.Trade memory trade = s_NFT.getPastTradeHistory(0);
        assertEq(trade._ownerA, Alice);
        assertEq(trade._ownerB, Bob);
        assertEq(trade._tokenIdA, 5);
        assertEq(trade._tokenIdB, 10);
        assertEq(trade._approvedA, true);
        assertEq(trade._approvedB, false);

        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                              acceptTrade
    //////////////////////////////////////////////////////////////*/

    function test_onlyOwner_can_acceptTrade() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector, 
                Bob
            )
        );

        vm.prank(Bob);
        s_NFT.acceptTrade(Bob, 20, 2);
    }   

    function test_notradesFound() public {
        vm.expectRevert(NFT.NFT__TradeNotFound.selector);
        vm.prank(Owner);
        s_NFT.acceptTrade(Bob, 20, 2);
    } 

    function test_can_acceptTrade() public {
        vm.startPrank(Owner);

        // 1. mint NFT
        s_NFT.mint(Alice, 5);
        s_NFT.mint(Bob, 10);

        assertEq(s_NFT.ownerOf(5), Alice);
        assertEq(s_NFT.ownerOf(10), Bob);

        // 2. create trade
        assertEq(s_NFT.createTrade(Alice, Bob, 5, 10), 0);

        // 3. checks trade
        NFT.Trade memory trade = s_NFT.getPastTradeHistory(0);
        assertEq(trade._ownerA, Alice, "1");
        assertEq(trade._ownerB, Bob, "2");
        assertEq(trade._tokenIdA, 5);
        assertEq(trade._tokenIdB, 10);
        assertEq(trade._approvedA, true);
        assertEq(trade._approvedB, false); 

        // 4. Bob accept trades
        s_NFT.acceptTrade(Bob, 10, 0);

        // 5. checks trade
        trade = s_NFT.getPastTradeHistory(0);
        assertEq(trade._ownerA, Alice, "3");
        assertEq(trade._ownerB, Bob, "4");
        assertEq(trade._tokenIdA, 5);
        assertEq(trade._tokenIdB, 10);
        assertEq(trade._approvedA, true);
        assertEq(trade._approvedB, true);

        vm.stopPrank();
    }

}