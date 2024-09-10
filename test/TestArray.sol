pragma solidity ^0.8.0;

contract TestArray {
    uint[] public arr;

    constructor() {
        arr = [1, 2, 3, 4, 5];
    }

    function removeLastElement() public {
        arr.pop(); // 删除数组最后一个元素
    }

    function getArray() public view returns (uint[] memory) {
        return arr;
    }

    function getArrayLength() public view returns (uint) {
        return arr.length; // 返回数组的长度
    }
}
