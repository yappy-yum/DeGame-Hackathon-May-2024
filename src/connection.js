const CONTRACT_ADDRESS = "0xC0768B537DB2401Cdbf1bCF5e7AB55c2019d41Fb";
const CONTRACT_ABI = [ [{"inputs":[{"internalType":"contract ISTKM","name":"_STKM","type":"address"},{"internalType":"contract INFT","name":"_NFT","type":"address"}],"stateMutability":"nonpayable","type":"constructor"},{"inputs":[],"name":"Game__MustMoreThanNFTPrice","type":"error"},{"inputs":[],"name":"Game__NFTPaymentFailed","type":"error"},{"inputs":[],"name":"Game__NoSTKMBought","type":"error"},{"inputs":[],"name":"Game__OnlyNeon","type":"error"},{"inputs":[],"name":"Game__TransactionFailed","type":"error"},{"stateMutability":"payable","type":"fallback"},{"inputs":[{"internalType":"uint256","name":"tradeId","type":"uint256"},{"internalType":"uint256","name":"yourToken","type":"uint256"}],"name":"AcceptTrade","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_tokenId","type":"uint256"}],"name":"BuyNFT","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_tokenId","type":"uint256"}],"name":"BuyResellNFT","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"CheckRewardsLatestUpdateTime","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"MintAccruedRewards","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_tokenId","type":"uint256"}],"name":"NFTOwnerOf","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"NFT_PRICE","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"_to","type":"address"},{"internalType":"uint256","name":"_amount","type":"uint256"}],"name":"OwnerGiveSTKM","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"tradeId","type":"uint256"},{"internalType":"uint256","name":"yourToken","type":"uint256"}],"name":"RejectTrade","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_tokenId","type":"uint256"},{"internalType":"uint256","name":"ResellPrice","type":"uint256"}],"name":"ResellNFT","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_tokenId","type":"uint256"}],"name":"RevokeResellNFT","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"STKMBalanceOf","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"STKMDecimals","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"_opponent","type":"address"},{"internalType":"uint256","name":"_yourTokenId","type":"uint256"},{"internalType":"uint256","name":"_opponentTokenId","type":"uint256"}],"name":"StartTrade","outputs":[{"internalType":"uint256","name":"tradeId","type":"uint256"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"buySTKM","outputs":[],"stateMutability":"payable","type":"function"},{"inputs":[],"name":"checkOwner","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"getBaseURI","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"_tokenId","type":"uint256"}],"name":"getCurrentResellNFT","outputs":[{"components":[{"internalType":"address","name":"owner","type":"address"},{"internalType":"address","name":"buyer","type":"address"},{"internalType":"uint256","name":"sellingPrice","type":"uint256"},{"internalType":"uint256","name":"tokenId","type":"uint256"},{"internalType":"uint256","name":"timeListed","type":"uint256"},{"internalType":"uint256","name":"timeSold","type":"uint256"}],"internalType":"struct INFT.reSell","name":"","type":"tuple"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"getNFTOriginalPrice","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"uint256","name":"_resellId","type":"uint256"}],"name":"getPastReSellHistory","outputs":[{"components":[{"internalType":"address","name":"owner","type":"address"},{"internalType":"address","name":"buyer","type":"address"},{"internalType":"uint256","name":"sellingPrice","type":"uint256"},{"internalType":"uint256","name":"tokenId","type":"uint256"},{"internalType":"uint256","name":"timeListed","type":"uint256"},{"internalType":"uint256","name":"timeSold","type":"uint256"}],"internalType":"struct INFT.reSell","name":"","type":"tuple"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"_tradeId","type":"uint256"}],"name":"getPastTradeHistory","outputs":[{"components":[{"internalType":"address","name":"_ownerA","type":"address"},{"internalType":"address","name":"_ownerB","type":"address"},{"internalType":"uint256","name":"_tokenIdA","type":"uint256"},{"internalType":"uint256","name":"_tokenIdB","type":"uint256"},{"internalType":"bool","name":"_approvedA","type":"bool"},{"internalType":"bool","name":"_approvedB","type":"bool"}],"internalType":"struct INFT.Trade","name":"","type":"tuple"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"_tokenId","type":"uint256"}],"name":"getTokenURI","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"_amount","type":"uint256"}],"name":"withdrawSTKM","outputs":[],"stateMutability":"nonpayable","type":"function"},{"stateMutability":"payable","type":"receive"}] ];

let web3;
let contract;
let userAddress;

/**
 * @description connect wallet
 * @returns connected user address
 */
async function initWeb3() {
  if (window.ethereum) {
    web3 = new Web3(window.ethereum);
    await window.ethereum.enable();
    const accounts = await web3.eth.getAccounts();
    userAddress = accounts[0];
    contract = new web3.eth.Contract(CONTRACT_ABI, CONTRACT_ADDRESS);
    return userAddress;
  } else {
    throw new Error("MetaMask not found");
  }
}

/**
 * @description user buy STKM using their NEON token, and the purchase is in equivalent values
 * @param {Number} amountInEther amount of NEON token to purchase STKM
 * 
 */
async function buySTKM(amountInEther) {
  const valueWei = web3.utils.toWei(amountInEther.toString(), 'ether');

  const gasPrice = await web3.eth.getGasPrice();
  const gasLimit = await contract.methods.buySTKM().estimateGas({
    from: userAddress,
    value: valueWei,
  });

  console.log('Gas price:', web3.utils.fromWei(gasPrice, 'gwei'), 'gwei');
  console.log('Gas limit:', gasLimit);

  return await contract.methods.buySTKM().send({
    from: userAddress,
    value: valueWei,
    gas: gasLimit,
    gasPrice,
  });
}

/**
 * @description user withdraw their existing STKM in exchange to NEON
 * @param {Number} amountInEther amount of STKM token to be withdrawn
 * 
 */
async function withdrawSTKM(amountInEther) {
  const amountWei = web3.utils.toWei(amountInEther.toString(), 'ether');
  const gasPrice = await web3.eth.getGasPrice();
  const gas = await contract.methods.withdrawSTKM(amountWei).estimateGas({ from: userAddress });

  return await contract.methods.withdrawSTKM(amountWei).send({
    from: userAddress,
    gas,
    gasPrice,
  });
}

/**
 * @description this is used to mint daily rewards 
 * 
 */
async function mintRewards() {
  const gasPrice = await web3.eth.getGasPrice();
  const gas = await contract.methods.MintAccruedRewards().estimateGas({ from: userAddress });

  return await contract.methods.MintAccruedRewards().send({
    from: userAddress,
    gas,
    gasPrice,
  });
}

/**
 * @description checks user STKM balance, including the accrued rewards, but the accrueds rewards are not minted
 * 
 * (buySTKM, transfers and withdrawal process will also carry out the accrued mint, therefore ``mintRewards`` is very optional)
 * 
 * @returns user STKM balance (18 decimals is included)
 * 
 */
async function getSTKMBalance() {
  const result = await contract.methods.STKMBalanceOf().call({ from: userAddress });
  return web3.utils.fromWei(result, 'ether');
}

/**
 * @description return the lastest time the daily rewards were minted
 * @returns blockchain timestamp (unix time)
 * 
 */
async function getLastRewardUpdateTime() {
  const timestamp = await contract.methods.CheckRewardsLatestUpdateTime().call({ from: userAddress });
  return parseInt(timestamp); 
}

/**
 * @description user buy NFT, if user balance is below 500 STKM, the transaction will revert
 * @param {Number} tokenId to buy 
 * 
 */
async function buyNFT(tokenId) {
  const gasPrice = await web3.eth.getGasPrice();
  const gas = await contract.methods.BuyNFT(tokenId).estimateGas({ from: userAddress });

  return await contract.methods.BuyNFT(tokenId).send({
    from: userAddress,
    gas,
    gasPrice,
  });
}

/**
 * @description user resell their NFT
 * @param {Number} tokenId to resell
 * @param {Number} resellPrice resell price
 * 
 */
async function resellNFT(tokenId, resellPrice) {
  const gasPrice = await web3.eth.getGasPrice();
  const gas = await contract.methods.ResellNFT(tokenId, resellPrice).estimateGas({ from: userAddress });

  return await contract.methods.ResellNFT(tokenId, resellPrice).send({
    from: userAddress,
    gas,
    gasPrice,
  });
}

/**
 * @description user who initialized the resell revoke (close) the resell
 * @param {Number} tokenId to be revoked
 * 
 */
async function revokeResellNFT(tokenId) {
  const gasPrice = await web3.eth.getGasPrice();
  const gas = await contract.methods.RevokeResellNFT(tokenId).estimateGas({ from: userAddress });

  return await contract.methods.RevokeResellNFT(tokenId).send({
    from: userAddress,
    gas,
    gasPrice,
  });
}

/**
 * @description user B buy the resell NFT
 * @param {Number} tokenId to buy
 * 
 */
async function buyResellNFT(tokenId) {
  const gasPrice = await web3.eth.getGasPrice();
  const gas = await contract.methods.BuyResellNFT(tokenId).estimateGas({ from: userAddress });

  return await contract.methods.BuyResellNFT(tokenId).send({
    from: userAddress,
    gas,
    gasPrice,
  });
}

/**
 * @description User A start trade with User B
 * @param {String} opponentAddress user B address
 * @param {Number} yourTokenId user A NFT id
 * @param {Number} opponentTokenId user B nft id
 * @returns trade id, needed for user B to accept/reject
 * 
 */
async function startTrade(opponentAddress, yourTokenId, opponentTokenId) {
  const gasPrice = await web3.eth.getGasPrice();
  const gas = await contract.methods.StartTrade(opponentAddress, yourTokenId, opponentTokenId).estimateGas({
    from: userAddress
  });

  return await contract.methods.StartTrade(opponentAddress, yourTokenId, opponentTokenId).send({
    from: userAddress,
    gas,
    gasPrice,
  });
}

/**
 * @description User B accept the trade
 * @param {Number} tradeId generated by ``startTrade``
 * @param {Number} yourToken user B NFT id
 * 
 */
async function acceptTrade(tradeId, yourToken) {
  const gasPrice = await web3.eth.getGasPrice();
  const gas = await contract.methods.AcceptTrade(tradeId, yourToken).estimateGas({ from: userAddress });

  return await contract.methods.AcceptTrade(tradeId, yourToken).send({
    from: userAddress,
    gas,
    gasPrice,
  });
}

/**
 * @description User B reject the trade
 * @param {*} tradeId generated by ``startTrade``
 * @param {*} yourToken user B NFT id
 * 
 */
async function rejectTrade(tradeId, yourToken) {
  const gasPrice = await web3.eth.getGasPrice();
  const gas = await contract.methods.RejectTrade(tradeId, yourToken).estimateGas({ from: userAddress });

  return await contract.methods.RejectTrade(tradeId, yourToken).send({
    from: userAddress,
    gas,
    gasPrice,
  });
}

/**
 * @description check the current owner of the NFT
 * @param {Number} tokenId 
 * @returns current owner of this NFT 
 * 
 */
async function getNFTOwner(tokenId) {
  const owner = await contract.methods.NFTOwnerOf(tokenId).call();
  console.log('NFT Owner:', owner);
  return owner;
}

/**
 * @description check the current resell NFT
 * @param {Number} tokenId 
 * @returns the information of the current resell NFT (has yet to be sold/revoked)
 * 
 */
async function getCurrentResellNFT(tokenId) {
  const resellInfo = await contract.methods.getCurrentResellNFT(tokenId).call();
  console.log('Current Resell NFT:', resellInfo);
  return resellInfo;
}

/**
 * @description check the past resell history information
 * @param {Number} resellId 
 * @returns the information of the past resell NFT (in history - sold) 
 * 
 */
async function getPastReSellHistory(resellId) {
  const resellHistory = await contract.methods.getPastReSellHistory(resellId).call();
  console.log('Past Resell History:', resellHistory);
  return resellHistory;
}

/**
 * @description check the past trade history
 * @param {Number} tradeId 
 * @returns the information of the past trade history 
 * 
 */
async function getPastTradeHistory(tradeId) {
  const tradeHistory = await contract.methods.getPastTradeHistory(tradeId).call();
  console.log('Past Trade History:', tradeHistory);
  return tradeHistory;
}

/**
 * @description get the base URI
 * @returns the base URI (metadata folder)
 * 
 */
async function getBaseURI() {
  const baseURI = await contract.methods.getBaseURI().call();
  console.log('Base URI:', baseURI);
  return baseURI;
}

/**
 * @description get the token URI
 * @param {Number} tokenId NFT id
 * @returns tokenURI (metadata for specific NFT)
 */
async function getTokenURI(tokenId) {
  const tokenURI = await contract.methods.getTokenURI(tokenId).call();
  console.log('Token URI:', tokenURI);
  return tokenURI;
}

/**
 * @description get the NFT original price (selling price, not resell price)
 * @returns the NFT price
 * 
 */
async function getNFTOriginalPrice() {
  const price = await contract.methods.getNFTOriginalPrice().call();
  console.log('NFT Original Price:', price);
  return price;
}