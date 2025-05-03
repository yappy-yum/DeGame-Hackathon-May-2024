// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

/*
                ________
               |       |
               |  O O  |
               |   ^   |    <-- Cute yet Esthetic Stickman NFT
               |  \_/  |
               |_______|
              /|       |\
             / |_______| \
            /     | |     \
                 /   \
                /     \
               O       O

   ███████╗████████╗██╗ ██████╗██╗   ██╗███╗   ███╗ █████╗ ███╗   ██╗
   ██╔════╝╚══██╔══╝██║██╔════╝██║  ██║ ████╗ ████║██╔══██╗████╗  ██║
   ███████╗   ██║   ██║██║     ██████║  ██╔████╔██║███████║██╔██╗ ██║
   ╚════██║   ██║   ██║██║     ██╔══██║ ██║╚██╔╝██║██╔══██║██║╚██╗██║
   ███████║   ██║   ██║╚██████╗██║   ██║██║ ╚═╝ ██║██║  ██║██║ ╚████║
   ╚══════╝   ╚═╝   ╚═╝ ╚═════╝╚═╝   ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝

        Unique On-Chain Avatars • Collect • Trade • Flex
*/

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {INFT} from "src/Interface/INFT.sol";

contract NFT is INFT, ERC721("STICKMAN", "STKM"), Ownable(msg.sender) {
    using Strings for uint256;

    error NFT__NFTOwned();
    error NFT__NFTNotOwnedOrNotExist();
    error NFT__AlreadyListed();
    error NFT__ListingNotFound();
    error NFT__NoSellingForFree();
    error NFT__NoZeroAddress();
    error NFT__NFTANotOwnerA();
    error NFT__NFTBNotOwnerB();
    error NFT__TradeNotApproved();
    error NFT__TradeNotFound();
    error NFT__SameOwner();
    error NFT__NFTNotFound();
    error NFT__ZeroAddress();

    string private s_baseMetaURI;

    /*//////////////////////////////////////////////////////////////
                              constructor
    //////////////////////////////////////////////////////////////*/    

    constructor(string memory _baseMetaURI) { 
        s_baseMetaURI = _baseMetaURI;
    }

    /*//////////////////////////////////////////////////////////////
                                mint NFT
    //////////////////////////////////////////////////////////////*/    

    /**
     * @notice Mints `_tokenId` to address `_to`
     * @param _to The address to mint `_tokenId` to
     * @param _tokenId The NFT id to mint
     *
     */
    function mint(address _to, uint256 _tokenId) external onlyOwner {
        if (_tokenId == 0 || _tokenId > 23) revert NFT__NFTNotFound();
        if (_to == address(0)) revert NFT__ZeroAddress();
        if (_ownerOf(_tokenId) != address(0)) revert NFT__NFTOwned();

        _update(_to, _tokenId, address(0));
    }

    /*//////////////////////////////////////////////////////////////
                            NFT market place
    //////////////////////////////////////////////////////////////*/

    uint private resellID = 0;
    
    // struct reSell { 
    //     address owner; // re-seller
    //     address buyer; // buyer who buy the re-sell NFT
    //     uint256 sellingPrice;  // price of the re-sell NFT
    //     uint256 tokenId; // token id to re-sell
    //     uint timeListed; // the time the NFT listed (ready to sell)
    //     uint timeSold;  // the time the NFT sold
    // }
    mapping(uint256 resellId => reSell reSellInfo) private s_pastReSellHistory;
    mapping(uint256 tokenId => reSell reSellInfo) private s_currentResellTokens;

    /**
     * @notice user list their bought NFT to re-sell to make profits 
     * @dev 10% royalty handle by child contract
     *
     * @param _owner The address of the owner of the NFT
     * @param _tokenId The token id of the NFT
     * @param _price The price of the NFT
     *
     */
    function listNFT(
        address _owner, 
        uint256 _tokenId, 
        uint256 _price
    ) external onlyOwner {
        // reSell storage info = s_currentResellTokens[_tokenId];

        // if (_price == 0) revert NFT__NoSellingForFree();
        // if (_owner == address(0)) revert NFT__ZeroAddress();
        // if (_ownerOf(_tokenId) != _owner) revert NFT__NFTNotOwnedOrNotExist();
        // if (info.owner != address(0)) revert NFT__AlreadyListed();

        // info.owner = _owner;
        // info.sellingPrice = _price;
        // info.tokenId = _tokenId;
        // info.timeListed = block.timestamp;

        // s_currentResellTokens[_tokenId] = info;

        if (_price == 0) revert NFT__NoSellingForFree();
        if (_owner == address(0)) revert NFT__ZeroAddress();
        if (_ownerOf(_tokenId) != _owner) revert NFT__NFTNotOwnedOrNotExist();
        if (s_currentResellTokens[_tokenId].owner != address(0)) revert NFT__AlreadyListed();

        assembly {
            mstore(0x00, _tokenId)
            mstore(0x20, s_currentResellTokens.slot)
            let base := keccak256(0x00, 0x40) 

            sstore(base, _owner)              
            sstore(add(base, 2), _price)      
            sstore(add(base, 3), _tokenId)    
            sstore(add(base, 4), timestamp()) 
        }
    }  

    /**
     * @notice user remove re-sell
     * @param _owner The address of the owner of the NFT
     * @param _tokenId The token id of the NFT
     *
     */
    function unListNFT(address _owner, uint256 _tokenId) external onlyOwner {
        reSell storage info = s_currentResellTokens[_tokenId];
        if (info.owner != _owner || info.tokenId != _tokenId) revert NFT__ListingNotFound();

        // delete s_currentResellTokens[_tokenId];
        assembly {
            mstore(0x00, _tokenId)
            mstore(0x20, s_currentResellTokens.slot)
            let base := keccak256(0x00, 0x40)

            sstore(base, 0)           
            sstore(add(base, 1), 0)   
            sstore(add(base, 2), 0)   
            sstore(add(base, 3), 0)   
            sstore(add(base, 4), 0)   
            sstore(add(base, 5), 0)   
        }
    }

    /**
     * @notice buy listing (re-sell) NFT
     * @param _buyer The address of the buyer
     * @param _tokenId The token id of the NFT to buy
     */
    function buyListingNFT(address _buyer, uint256 _tokenId) external onlyOwner {
        reSell storage info = s_currentResellTokens[_tokenId];
        
        if (info.tokenId != _tokenId) revert NFT__ListingNotFound();
        _transfer(info.owner, _buyer, _tokenId);

        // s_pastReSellHistory[resellID] = reSell({
        //     owner: info.owner,
        //     buyer: _buyer,
        //     sellingPrice: info.sellingPrice,
        //     tokenId: _tokenId,
        //     timeListed: info.timeListed,
        //     timeSold: block.timestamp
        // });
        assembly {
            mstore(0x00, _tokenId)
            mstore(0x20, s_currentResellTokens.slot)
            let srcSlot := keccak256(0x00, 0x40)

            let Owner := sload(srcSlot)
            let SellingPrice := sload(add(srcSlot, 2))
            let TimeListed := sload(add(srcSlot, 4))

            let id := sload(resellID.slot)
            mstore(0x00, id)
            mstore(0x20, s_pastReSellHistory.slot)
            let dstSlot := keccak256(0x00, 0x40)

            sstore(dstSlot, Owner)
            sstore(add(dstSlot, 1), _buyer)
            sstore(add(dstSlot, 2), SellingPrice)
            sstore(add(dstSlot, 3), _tokenId)
            sstore(add(dstSlot, 4), TimeListed)
            sstore(add(dstSlot, 5), timestamp())

            sstore(resellID.slot, add(sload(resellID.slot), 1))
        }

        // delete s_currentResellTokens[_tokenId];
        assembly {
            mstore(0x00, _tokenId)
            mstore(0x20, s_currentResellTokens.slot)
            let base := keccak256(0x00, 0x40)

            sstore(base, 0)           
            sstore(add(base, 1), 0)   
            sstore(add(base, 2), 0)   
            sstore(add(base, 3), 0)   
            sstore(add(base, 4), 0)   
            sstore(add(base, 5), 0)   
        }


        // assembly {
        //     sstore(
        //         resellID.slot,
        //         add(
        //             sload(resellID.slot),
        //             1
        //         )
        //     )
        // }
    }

    /*//////////////////////////////////////////////////////////////
                                 trades
    //////////////////////////////////////////////////////////////*/

    uint256 private tradeID = 0;
    
    // struct Trade {
    //     address _ownerA; // owner of NFT A
    //     address _ownerB; // owner of NFT B
    //     uint256 _tokenIdA; // token id of NFT A
    //     uint256 _tokenIdB; // token id of NFT B
    //     bool _approvedA; // approved of NFT A
    //     bool _approvedB; // approved of NFT B (if true, trades has succeed)
    // }    
    mapping(uint256 tradeId => Trade trade) private s_trades;

    /**
     * @notice start/request/create trade to exchange NFTs
     * @param _ownerA The address of the owner of the NFT A
     * @param _ownerB The address of the owner of the NFT B
     * @param _tokenIdA The token id of the NFT A
     * @param _tokenIdB The token id of the NFT B
     *
     */
    function createTrade(
        address _ownerA,
        address _ownerB,
        uint256 _tokenIdA,
        uint256 _tokenIdB
    ) external override onlyOwner returns(uint tradeId) {
        
        if (_ownerA == address(0) || _ownerB == address(0)) revert NFT__NoZeroAddress();
        if (_ownerA == _ownerB) revert NFT__SameOwner();
        if (_ownerOf(_tokenIdA) != _ownerA) revert NFT__NFTANotOwnerA();
        if (_ownerOf(_tokenIdB) != _ownerB) revert NFT__NFTBNotOwnerB();

        // uint256 TradeId = tradeID;

        // s_trades[TradeId] = Trade({
        //     _ownerA: _ownerA,
        //     _ownerB: _ownerB,
        //     _tokenIdA: _tokenIdA,
        //     _tokenIdB: _tokenIdB,
        //     _approvedA: true,
        //     _approvedB: false
        // });

        // assembly {
        //     sstore(
        //         tradeID.slot,
        //         add(
        //             sload(tradeID.slot),
        //             1
        //         )
        //     )
        // }

        // return TradeId;

        assembly {
            tradeId := sload(tradeID.slot)

            mstore(0x00, tradeId)
            mstore(0x20, s_trades.slot)
            let tradeSlot := keccak256(0x00, 0x40)

            sstore(tradeSlot, _ownerA)
            sstore(add(tradeSlot, 1), _ownerB) 
            sstore(add(tradeSlot, 2), _tokenIdA)
            sstore(add(tradeSlot, 3), _tokenIdB)
            sstore(add(tradeSlot, 4), 1)        
            sstore(add(tradeSlot, 5), 0)        

            sstore(tradeID.slot, add(sload(tradeID.slot), 1))
        }
    }

    /**
     * @notice accept and initialize the trades
     * @param _ownerB The address of the owner of the NFT B
     * @param _tokenIdB The token id of the NFT B
     * @param _tradeId The trade id
     *
     */
    function acceptTrade(
        address _ownerB,
        uint256 _tokenIdB,
        uint256 _tradeId
    ) external onlyOwner {
        Trade storage trade = s_trades[_tradeId];
        if (trade._ownerB != _ownerB || trade._tokenIdB != _tokenIdB) revert NFT__TradeNotFound();

        _safeTransfer(trade._ownerA, trade._ownerB, trade._tokenIdA);
        _safeTransfer(trade._ownerB, trade._ownerA, trade._tokenIdB);

        trade._approvedB = true;
    }

    /*//////////////////////////////////////////////////////////////
                                 getter
    //////////////////////////////////////////////////////////////*/    

    /**
     * @notice Returns the base URI (IPFS for metadata json folder)
     *
     */
    function baseURI() external view returns(string memory) {
        return s_baseMetaURI;
    }  

    /**
     * @notice Returns the token URI (IPFS for metadata json file)
     *
     */
    function tokenURI(uint256 tokenId) public view override(INFT, ERC721) returns (string memory) {
        if (tokenId == 0 || tokenId > 23) return "";
        return string(abi.encodePacked(s_baseMetaURI, "/", tokenId.toString(), ".json"));
    }

    /**
     * @notice Returns the current ongoing listing (re-sell) NFT
     * @param tokenId The token id of the NFT
     *
     */
    function getCurrentResell(uint256 tokenId) external view returns (reSell memory) {
        return s_currentResellTokens[tokenId];
    }

    /**
     * @notice Returns the past listing (re-sell) NFT - in history
     * @param resellId the resell transaction id
     *
     */
    function getPastReSellHistory(uint256 resellId) external view returns (reSell memory) {
        return s_pastReSellHistory[resellId];
    }

    /**
     * @notice Returns the trade history
     * @param tradeId The trade id
     *
     */
    function getPastTradeHistory(uint256 tradeId) external view returns (Trade memory) {
        return s_trades[tradeId];
    }

}