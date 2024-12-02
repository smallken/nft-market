// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TestMyNFT {
    address public owner;
    string public tokenURI;

    constructor(address _owner, string memory _tokenURI) {
        owner = _owner;
        tokenURI = _tokenURI;
    }
}