//MerkleTreeAirDrop
const {MerkleTree} = require('merkletreejs');
const keccak256 = require('keccak256');
const { ethers } = require('ethers');

// const { keccak256 } = require('ethers/lib/utils');

let users = [
  "0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf",
  "0x2B5AD5c4795c026514f8317c7a215E218DcCD6cF",
  "0x6813Eb9362372EEF6200f3b1dbC3f819671cBA69",
  "0x0376AAc07Ad725E01357B1725B5ceC61aE10473c",
  "0x1efF47bc3a10a45D4B230B5d10E37751FE6AA718"
  ];

//   const leafNodes = users.map( addr => keccak256(addr));
  const leafNodes = 
  users.map(addr => 
    keccak256(ethers.utils.defaultAbiCoder.encode(["address"], [addr])));
  const merkleTree = new MerkleTree(leafNodes, keccak256, { sortPairs: true});
  const rootHash = merkleTree.getHexRoot();
  const leaf = leafNodes[3];
  console.log();
  const hexProof = merkleTree.getHexProof(leaf);
  console.log("leafNodes:\n", leafNodes);
  console.log('Merkle Tree\n', merkleTree.toString());
  console.log('rootHash\n', rootHash.toString());
  console.log('hexProof\n', hexProof);
  