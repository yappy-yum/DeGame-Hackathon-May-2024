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
    error NFT__ListingNotFound();
    error NFT__NoSellingForFree();
    error NFT__NoZeroAddress();
    error NFT__TradeNotFound();
    error NFT__SameOwner();
    error NFT__NFTNotFound();
    error NFT__ZeroAddress();
    error NFT__NFTNotOnQueue();
    error NFT__SomethingWentWrong();
    error NFT__NotAvailable();
    error NFT__OnlyAllowedNFTOwnerTransfer();

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
        if (_price == 0) revert NFT__NoSellingForFree();
        if (_owner == address(0)) revert NFT__ZeroAddress();

        (bool ok) = _isValidate(_owner, _tokenId);
        if (!ok) revert NFT__SomethingWentWrong();

        assembly {
            mstore(0x00, _tokenId)
            mstore(0x20, s_currentResellTokens.slot)
            let base := keccak256(0x00, 0x40) 

            sstore(base, _owner)              
            sstore(add(base, 2), _price)      
            sstore(add(base, 3), _tokenId)    
            sstore(add(base, 4), timestamp()) 
        }
        _setTokenOnQueue(_tokenId, 1);
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
        _setTokenOnQueue(_tokenId, 0);
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
        _setTokenOnQueue(_tokenId, 0);
    }

    /*//////////////////////////////////////////////////////////////
                                 trades
    //////////////////////////////////////////////////////////////*/

    uint256 private tradeID = 0;
    mapping(uint256 tradeId => Trade trade) private s_trades;
    mapping(uint256 tokenId => bool onqueue) private s_onqueue;

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

        bool ok = _isValidate(_ownerA, _tokenIdA) && _isValidate(_ownerB, _tokenIdB);
        if (!ok) revert NFT__SomethingWentWrong();

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

        _setTokenOnQueue(_tokenIdA, 1);
        _setTokenOnQueue(_tokenIdB, 1);

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

        if (!s_onqueue[_tokenIdB]) revert NFT__NFTNotOnQueue();
        if (trade._ownerB != _ownerB || trade._tokenIdB != _tokenIdB) revert NFT__TradeNotFound();

        trade._approvedB = true;

        _safeTransfer(trade._ownerA, trade._ownerB, trade._tokenIdA);
        _safeTransfer(trade._ownerB, trade._ownerA, trade._tokenIdB);

        _setTokenOnQueue(trade._tokenIdA, 0);
        _setTokenOnQueue(_tokenIdB, 0);      
    }

    /**
     * @notice reject the trades
     * @param _ownerB The address of the owner of the NFT B
     * @param _tokenIdB The token id of the NFT B
     * @param _tradeId The trade id
     *
     */
    function rejectTrade(
        address _ownerB,
        uint256 _tokenIdB,
        uint256 _tradeId
    ) external onlyOwner {
        Trade storage trade = s_trades[_tradeId];

        if (!s_onqueue[_tokenIdB]) revert NFT__NFTNotOnQueue();
        if (trade._ownerB != _ownerB || trade._tokenIdB != _tokenIdB) revert NFT__TradeNotFound();

        _setTokenOnQueue(trade._tokenIdA, 0);
        _setTokenOnQueue(_tokenIdB, 0);        
    }

    /*//////////////////////////////////////////////////////////////
                                transact
    //////////////////////////////////////////////////////////////*/

    function approve(address to, uint256 tokenId) public override {
        revert("this function has deprecated");
    }    

    function transferFrom(address from, address to, uint tokenId) public override {
        if (s_onqueue[tokenId]) revert NFT__NotAvailable();
        if (from != msg.sender) revert NFT__OnlyAllowedNFTOwnerTransfer();

        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint tokenId, bytes memory data) public override {
        if (s_onqueue[tokenId]) revert NFT__NotAvailable();
        if (from != msg.sender) revert NFT__OnlyAllowedNFTOwnerTransfer();
        
        super.safeTransferFrom(from, to, tokenId, data);
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

    /**
     * @notice Returns if the token is on queue to wait for trade
     * @param tokenId The token id of the NFT
     *
     */
    function isTokenOnQueue(uint256 tokenId) external view returns (bool) {
        return s_onqueue[tokenId];
    }

    /**
     * @notice check the owner/holder of the NFT `tokenId`
     * @param tokenId The token id of the NFT
     *
     */
    function ownerOf(uint tokenId) public view override(INFT, ERC721) returns (address) {
        return _ownerOf(tokenId);
    }

    /*//////////////////////////////////////////////////////////////
                               validation
    //////////////////////////////////////////////////////////////*/

    function _isValidate(address _owner, uint256 _tokenId) private view returns (bool) {
        return 
            _ownerOf(_tokenId) == _owner && 
            !s_onqueue[_tokenId];
    }

    function _setTokenOnQueue(uint256 _tokenId, uint8 _value) private {
        assembly {
            mstore(0x00, _tokenId)
            mstore(0x20, s_onqueue.slot)
            let queueSlot := keccak256(0x00, 0x40)
            sstore(queueSlot, _value)
        }
    }

}