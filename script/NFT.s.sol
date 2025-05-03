// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {NFT} from "src/factory/NFT.sol";
import {Script} from "forge-std/Script.sol";

contract NFT_S is Script {

    address Owner = makeAddr("Owner");
    string baseURI = "ipfs://bafybeie5ztgmhxv2gyx3nwzdj3c36vbyqfuxsw4vahnke4j2aik27dd7s4";

    function run() public returns(NFT) {

        vm.broadcast(Owner);
        NFT nft = new NFT(baseURI);

        return nft;

    }

}