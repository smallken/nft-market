pragma solidity ^0.8.13;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Nonces.sol";
// @openzeppelin/contracts/=lib/openzeppelin-contracts/contracts/
// 创建新的NFT
contract MyNFT is ERC721URIStorage, Nonces{
    // using Counters for Counters.Counter;
    // Counters.Counter private _tokenIds; 
    constructor() ERC721("Dragon", "DRG") {}
   uint private tokenId;

    function mint(address student, string memory tokenURI) public returns (uint256) {
        // _tokenIds.increment();
        uint256 newItemId = tokenId++;
        // uint256 newItemId = nonces(address(this));
        _mint(student, newItemId);
        _setTokenURI(newItemId, tokenURI);
        return newItemId;
    }
    
}