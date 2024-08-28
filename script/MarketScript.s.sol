// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../lib/forge-std/src/Script.sol";

import "../src/Market.sol";
import "../src/MyNFT.sol";
import "../lib/forge-std/src/Test.sol";

contract MarketScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("BSC_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // NFT nft = new NFT("NFT_tutorial", "TUT", "baseUri");
        // 0x5FbDB2315678afecb367f032d93F642f64180aa3
        MyNFT nft = new MyNFT();
        Market market = new Market(address(nft));
        console.log("nft:");
        console.log(address(nft));
        console.log("market:");
        console.log(address(market));
        
        vm.stopBroadcast();
    }
}