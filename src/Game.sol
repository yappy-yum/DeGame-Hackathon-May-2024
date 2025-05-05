// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {SafeModifier} from "./SafeModifier/SafeModifier.sol";

import {ISTKM} from "./Interface/ISTKM.sol";
import {INFT} from "./Interface/INFT.sol";

contract Game is SafeModifier(msg.sender) {

    error Game__TransactionFailed();
    error Game__NFTPaymentFailed();
    error Game__MustMoreThanNFTPrice();

    ISTKM private immutable I_STKM;  
    INFT private immutable I_NFT;
    uint constant public NFT_PRICE = 1 ether;

    constructor(ISTKM _STKM, INFT _NFT) { I_STKM = _STKM; I_NFT = _NFT; }

    /*//////////////////////////////////////////////////////////////
                                 ERC20
    //////////////////////////////////////////////////////////////*/

    function buySTKM() external payable onlyEOA(msg.sender) noReentrant {
        I_STKM.buySTKM(msg.sender, msg.value);
    }   

    function OwnerGiveSTKM(address _to, uint256 _amount) external onlyOwner(msg.sender) {
        I_STKM.giveSTKM(_to, _amount);
    }

    function withdrawSTKM(uint256 _amount) external onlyEOA(msg.sender) noReentrant {
        I_STKM.withdrawSTKM(msg.sender, _amount);

        (bool ok, ) = msg.sender.call{value: _amount}("");
        if (!ok) revert Game__TransactionFailed();
    }

    function MintAccruedRewards() external onlyEOA(msg.sender) noReentrant {
        I_STKM.updateInterest(msg.sender);
    }

    function STKMBalanceOf() external view returns (uint256) {
        return I_STKM.balanceOf(msg.sender);
    }

    function CheckRewardsLatestUpdateTime() external view returns (uint256) {
        return I_STKM.checkInterestLastUpdate(msg.sender);
    }

    /*//////////////////////////////////////////////////////////////
                                 ERC721
    //////////////////////////////////////////////////////////////*/

    function BuyNFT(uint256 _tokenId) external onlyEOA(msg.sender) noReentrant {
        I_NFT.mint(msg.sender, _tokenId);
        I_STKM.withdrawSTKM(msg.sender, NFT_PRICE);
    }

    function ResellNFT(uint256 _tokenId, uint ResellPrice) external onlyEOA(msg.sender) noReentrant {
        if (ResellPrice <= NFT_PRICE) revert Game__MustMoreThanNFTPrice();
        I_NFT.listNFT(msg.sender, _tokenId, ResellPrice);
    }

    function RevokeResellNFT(uint256 _tokenId) external onlyEOA(msg.sender) noReentrant {
        I_NFT.unListNFT(msg.sender, _tokenId);
    }

    function BuyResellNFT(uint256 _tokenId) external onlyEOA(msg.sender) noReentrant {
        INFT.reSell memory resell = I_NFT.getCurrentResell(_tokenId);

        address NFTOwner = resell.owner;
        uint sellingPrice = resell.sellingPrice;
        uint sellerProfit = (sellingPrice * 90) / 100;

        I_NFT.buyListingNFT(msg.sender, _tokenId);
        I_STKM.giveSTKM(NFTOwner, sellerProfit);
        I_STKM.withdrawSTKM(msg.sender, sellingPrice);
    }

    function StartTrade(address _opponent, uint256 _yourTokenId, uint256 _opponentTokenId) external onlyEOA(msg.sender) noReentrant returns(uint tradeId) {
        return I_NFT.createTrade(msg.sender, _opponent, _yourTokenId, _opponentTokenId);
    }

    function AcceptTrade(uint tradeId, uint yourToken) external onlyEOA(msg.sender) noReentrant {
        I_NFT.acceptTrade(msg.sender, yourToken, tradeId);
    }

    function RejectTrade(uint tradeId, uint yourToken) external onlyEOA(msg.sender) noReentrant {
        I_NFT.rejectTrade(msg.sender, yourToken, tradeId);
    }

    function NFTOwnerOf(uint256 _tokenId) external view returns (address) {
        return I_NFT.ownerOf(_tokenId);
    }

    function getCurrentResellNFT(uint256 _tokenId) external view returns (INFT.reSell memory) {
        return I_NFT.getCurrentResell(_tokenId);
    }

    function getPastReSellHistory(uint256 _resellId) external view returns (INFT.reSell memory) {
        return I_NFT.getPastReSellHistory(_resellId);
    }

    function getPastTradeHistory(uint256 _tradeId) external view returns (INFT.Trade memory) {
        return I_NFT.getPastTradeHistory(_tradeId);
    }

    /*//////////////////////////////////////////////////////////////
                             Free Funds :D
    //////////////////////////////////////////////////////////////*/    

    receive() external payable onlyEOA(msg.sender) noReentrant {}
    fallback() external payable onlyEOA(msg.sender) noReentrant {}

}