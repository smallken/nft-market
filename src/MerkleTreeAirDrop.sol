pragma solidity ^0.8.20;

import "lib/openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";
import {Test, console} from "../lib/openzeppelin-contracts/lib/forge-std/src/Test.sol";

contract MerkleTreeAirDrop{
    bytes32 public merkleRoot = 0x5cf78b654ee64fe8452e7a430f0a4ddf0561867c2753ece939c82c1ed763ed1f;
                                // b990956beffcbf13ed9fcc2dbdaff0d94e4cb35076aea8531877a25079e4b551
                                
                                
    mapping(address => bool) public whitelistClaimed;

    function whitelistMint(bytes32[] calldata _merkleProof, address listPerson) public {
        require(!whitelistClaimed[listPerson], "Address has already claimed.");
        bytes32 leaf = keccak256(abi.encode(listPerson));
        // bytes32 leaf = keccak256(msg.sender);
        // console.log("msg.sender:", msg.sender);
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf),"Invilid proof.");
        whitelistClaimed[listPerson] = true;
    }


}