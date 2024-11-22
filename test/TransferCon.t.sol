pragma solidity ^0.8.13;

import {Test, console} from "../lib/openzeppelin-contracts/lib/forge-std/src/Test.sol";
import { TransferCon } from "../src/TransferCon.sol";

// import { MyToken } from "../MyToken.sol";

contract TestMarket is Test{
    TransferCon transferCon;

    function setUp() public{
        transferCon = new TransferCon();
    }

        // fallback() external payable {}

    function testAdd() public {
        console.log("address1 balance:", address(1).balance);
        vm.deal(address(1), 10 ether);
        vm.deal(address(transferCon), 10 ether);
        vm.deal(address(this), 50 ether);
        console.log("contract balance:", address(transferCon).balance);
        //这种写法，是从测试合约转过去
        // payable(address(1)).transfer(1 ether);
        // 这里从transCon转到去调用者
        vm.expectRevert(); // 预测会失败，不输入就不会规定特定的类型
        transferCon.testSend(address(1), 1 ether);
        console.log("after transfer contract balance:", address(transferCon).balance);
        console.log("after transfer address1 balance:", address(1).balance);
        // assertFalse(data);
    
        // 测试合约接收
        // vm.startPrank(address(1));
        // // transferCon.deposite{value: 1 ether}(address(1));
        // (bool ifSucced, ) = address(transferCon).call{value: 1 ether}("");
        // assertEq(ifSucced, true);
        // vm.stopPrank();
        // 测试合约向合约转
        (bool ifSuccesed, ) = address(transferCon).call{value: 1 ether}("");
        assertEq(ifSuccesed, true);
    }


}