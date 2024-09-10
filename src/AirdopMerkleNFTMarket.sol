pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Multicall.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "src/MyNFT.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {Test, console} from "../lib/openzeppelin-contracts/lib/forge-std/src/Test.sol";

contract AirdopMerkleNFTMarket is Multicall{
    address token;
    address nftAddress;

    struct NftRecord {
        address nftTokenAddress;
        uint tokenId;
        address owner;
        // 是否领取
        bool ifTaked;
    }
    NftRecord[] nftsNotaked;
    NftRecord[] nftstaked;
    constructor (address _token, address _nftAddress, NftRecord[] memory _nfts) {
        token = _token;
        nftAddress = _nftAddress;
        // nftsNotoaked = _nfts;
        copyNft(_nfts);
    }

    event NFTClaimed(
        // 数组
        uint nftRecordNum,
        uint tokenId,
        address taker
    );
    function copyNft(NftRecord[] memory _nfts) internal {
        for(uint i = 0; i < _nfts.length; i++) {
            console.log("copyNFT, times:", i);
            // nftsNotaked[i] = _nfts[i]; 这样会报访问索引超出数组长度
            nftsNotaked.push(_nfts[i]);
        }
    }
    // 完成预授权
    function permitPrePay(address owner, address spender,         
    uint256 deadline,uint8 v,bytes32 r,bytes32 s) public{
        // 授权给此合约100token购买nft
        IERC20Permit(token).permit(owner, spender, 100, deadline, v, r, s);
    }

    function claimNFT(address nftTaker) public {
        // 校验白名单略
        // 直接使⽤ permitPrePay 的授权，转⼊ 100 token， 并转出 NFT .
        require(IERC20(token).transferFrom(nftTaker, nftAddress, 100), "transf failed");
        // 这个思路是，把nft放到一个数组里面，如果
        require(nftsNotaked.length>0, "NFT is taked!");
        NftRecord memory nft = nftsNotaked[nftsNotaked.length-1];
        // IERC721(nftAddress).approve(address(this), nft.tokenId);
        // 这里有点问题，谁来调这个函数？用户来调，是要转nft到用户的，之前是在其他人手上的nft，怎么授权转？
        // 还是提前授权了？但nft好像没有Permit的。。
        // setApprovalForAll，可以用这个，把Mint的nft给一个人，然后把approve权限给合约
        IERC721(nftAddress).transferFrom(nft.owner, nftTaker, nft.tokenId);
        nftsNotaked.pop();
        nft.ifTaked = true;
        nft.owner = nftTaker;
        nftstaked.push(nft);
        emit NFTClaimed(nftstaked.length -1 , nft.tokenId, nftTaker);

    }
    
}