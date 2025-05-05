// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

interface INFT {

    /*//////////////////////////////////////////////////////////////
                                 Struct
    //////////////////////////////////////////////////////////////*/    

    /// @notice user resell records
    struct reSell { 
        address owner; // re-seller
        address buyer; // buyer who buy the re-sell NFT
        uint256 sellingPrice;  // price of the re-sell NFT
        uint256 tokenId; // token id to re-sell
        uint timeListed; // the time the NFT listed (ready to sell)
        uint timeSold;  // the time the NFT sold
    }

    /// @notice user trade (NFT exchange) records
    struct Trade {
        address _ownerA; // owner of NFT A
        address _ownerB; // owner of NFT B
        uint256 _tokenIdA; // token id of NFT A
        uint256 _tokenIdB; // token id of NFT B
        bool _approvedA; // approved of NFT A
        bool _approvedB; // approved of NFT B (if true, trades has succeed)
    }           

    /*//////////////////////////////////////////////////////////////
                                transact
    //////////////////////////////////////////////////////////////*/    

    /**
     * @notice Mints `_tokenId` to address `_to`
     * @param _to The address to mint `_tokenId` to
     * @param _tokenId The NFT id to mint
     *
     */
    function mint(address _to, uint256 _tokenId) external;  

    /**
     * @notice user list their bought NFT to re-sell to make profits 
     * @dev 10% royalty handle by child contract
     *
     * @param _owner The address of the owner of the NFT
     * @param _tokenId The token id of the NFT
     * @param _price The price of the NFT
     *
     */
    function listNFT(address _owner, uint256 _tokenId, uint256 _price) external;    

    /**
     * @notice user remove re-sell
     * @param _owner The address of the owner of the NFT
     * @param _tokenId The token id of the NFT
     *
     */
    function unListNFT(address _owner, uint256 _tokenId) external;

    /**
     * @notice buy listing (re-sell) NFT
     * @param _buyer The address of the buyer
     * @param _tokenId The token id of the NFT to buy
     */
    function buyListingNFT(address _buyer, uint256 _tokenId) external;        

    /**
     * @notice start/request/create trade to exchange NFTs
     * @param _ownerA The address of the owner of the NFT A
     * @param _ownerB The address of the owner of the NFT B
     * @param _tokenIdA The token id of the NFT A
     * @param _tokenIdB The token id of the NFT B
     *
     */
    function createTrade(address _ownerA, address _ownerB, uint256 _tokenIdA, uint256 _tokenIdB) external returns(uint tradeId);

    /**
     * @notice accept and initialize the trades
     * @param _ownerB The address of the owner of the NFT B
     * @param _tokenIdB The token id of the NFT B
     * @param _tradeId The trade id
     *
     */
    function acceptTrade(address _ownerB, uint256 _tokenIdB, uint256 _tradeId) external;    

    /**
     * @notice reject the trades
     * @param _ownerB The address of the owner of the NFT B
     * @param _tokenIdB The token id of the NFT B
     * @param _tradeId The trade id
     *
     */
    function rejectTrade(address _ownerB, uint256 _tokenIdB, uint256 _tradeId) external;    

    /*//////////////////////////////////////////////////////////////
                                 getter
    //////////////////////////////////////////////////////////////*/        

    /**
     * @notice Returns the base URI (IPFS for metadata json folder)
     *
     */
    function baseURI() external view returns(string memory);

    /**
     * @notice Returns the token URI (IPFS for metadata json file)
     *
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);    

    /**
     * @notice Returns the current ongoing listing (re-sell) NFT
     * @param tokenId The token id of the NFT
     *
     */
    function getCurrentResell(uint256 tokenId) external view returns (reSell memory);

    /**
     * @notice Returns the past listing (re-sell) NFT - in history
     * @param resellId the resell transaction id
     *
     */
    function getPastReSellHistory(uint256 resellId) external view returns (reSell memory);

    /**
     * @notice Returns the trade history
     * @param tradeId The trade id
     *
     */
    function getPastTradeHistory(uint256 tradeId) external view returns (Trade memory);

    /**
     * @notice Returns if the token is on queue to wait for trade
     * @param tokenId The token id of the NFT
     *
     */
    function isTokenOnQueue(uint256 tokenId) external view returns (bool);    

    /**
     * @notice check the owner/holder of the NFT `tokenId`
     * @param tokenId The token id of the NFT
     *
     */
    function ownerOf(uint tokenId) external view returns (address);    
    
}