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
   event Mint (
    address to,
    uint256 tokenId
   );

    function mint(address receiver, string memory tokenURI) public returns (uint256) {
        // _tokenIds.increment();
        uint256 newItemId = tokenId++;
        // uint256 newItemId = nonces(address(this));
        _mint(receiver, newItemId);
        _setTokenURI(newItemId, tokenURI);
        emit Mint(receiver, newItemId);
        return newItemId;
    }
    //nft:
//   0x66590317CbEF0a42728064878b3b2f907733aB63
//   market:
//   0x689Fb7972129Ef969e9578852c12159BE5d282e5
}