pragma solidity ^0.8.13;

import {Test, console} from "../lib/openzeppelin-contracts/lib/forge-std/src/Test.sol";
import {TokenFactory} from "../src/TokenFactory.sol";
import {MyToken} from "../src/MyToken.sol";

contract TestMarketFactory is Test{
    TokenFactory tokenFactory;
    function setUp() public{
        vm.startPrank(address(1));
        MyToken token = new MyToken();
        tokenFactory = new TokenFactory(address(token));

        vm.stopPrank();
    }

    function test_createToken() public{
        vm.startPrank(address(2));
        address token = tokenFactory.createToken();
        console.log("token:",token);
        vm.stopPrank();
        vm.startPrank(address(3));
        address token2 = tokenFactory.createToken();
        console.log("token2:",token2);
        vm.stopPrank();
    }
}