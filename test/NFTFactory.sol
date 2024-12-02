// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {TestMyNFT} from "./TestMyNFT.sol";
contract NFTFactory {
    event NFTCreated(address nftAddress);

    function createNFT(uint _salt, string memory tokenURI) external returns (address){
        // 使用create2创建MyNFT合约
        TestMyNFT nft = new TestMyNFT{salt: keccak256(abi.encode(_salt))}(msg.sender, tokenURI);
        emit NFTCreated(address(nft));
        return address(nft);
    }

    function getAddress(uint _salt, string memory tokenURI) external view returns (address) {
        bytes memory bytecode = abi.encodePacked(
            type(TestMyNFT).creationCode,
            abi.encode(msg.sender, tokenURI)
        );
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                keccak256(abi.encode(_salt)),
                keccak256(bytecode)
            )
        );
        return address(uint160(uint(hash)));
    }
}