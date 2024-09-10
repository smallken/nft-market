// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {TestArray} from "./TestArray.sol";

contract TestArrayTest is Test {

    TestArray array;

    function setUp() public{
        array = new TestArray();
    }

    function testRemoveAndGet() public {
        uint[] memory arr = array.getArray();
        console.log("arr length:", arr.length);
        array.removeLastElement();
        uint[] memory arr2 = array.getArray();
        console.log("arr2 length:", arr2.length);
    }


}