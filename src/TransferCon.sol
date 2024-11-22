pragma solidity ^0.8.13;

import {Test, console} from "../lib/openzeppelin-contracts/lib/forge-std/src/Test.sol";
                                    // lib/chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol


contract TransferCon {
    
    receive() external payable {}
    fallback() external payable {}

    function testTransfer(address receiver, uint value) public payable{
        // 这样写会导致gas不足，只能用call方法
        payable(receiver).transfer(value);
    }

    function testSend(address receiver, uint value) public{
        // 这样写也报EvmError: PrecompileOOG
        bool ifSucces = payable(receiver).send(value);
        require(ifSucces, "send failed");
    }


    // function deposite(address depositer) public payable{
    //     // address payable thisContract = payable(this);
    //     //  thisContract.transfer(msg.value);
    //     // 自己向自己转也不行
    //     (bool ifSuccess, ) = address(this).call{value: msg.value}("");
    //     require(ifSuccess, "transfer failed");
    // }


}