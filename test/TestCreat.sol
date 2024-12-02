pragma solidity ^0.8.13;

import {MyNFT} from "../src/MyNFT.sol";
contract TestCreat{

    function testCreat() public{
        MyNFT nft = new MyNFT();
        nft.mint(msg.sender, "https://www.baidu.com");
    }

    function createBysalt(uint _salt) public{
        MyNFT nft = new MyNFT{salt: keccak256(abi.encode(_salt))}();
        nft.mint(msg.sender, "https://www.baidu.com");
    }

}
