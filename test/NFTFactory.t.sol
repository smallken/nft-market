pragma solidity ^0.8.13;

import {Test, console} from "../lib/openzeppelin-contracts/lib/forge-std/src/Test.sol";
import {NFTFactory} from "./NFTFactory.sol";

contract TestNFTFactory is Test{
    NFTFactory nftFactory;

    function setUp() public{
        nftFactory = new NFTFactory();
    }

    function test_createNFT() public{
        address nftAddress = nftFactory.createNFT(168168, "https://www.baidu.com");
        address nftAddress2 = nftFactory.getAddress(168168, "https://www.baidu.com");
        assertEq(nftAddress, nftAddress2);
    }
}
