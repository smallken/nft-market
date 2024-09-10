pragma solidity ^0.8.13;

import {Test, console} from "../lib/openzeppelin-contracts/lib/forge-std/src/Test.sol";
import { Market } from "../src/Market.sol";
import { MyNFT } from "../src/MyNFT.sol";
import {MyToken} from "../src/MyToken.sol";
import { AirdopMerkleNFTMarket } from "../src/AirdopMerkleNFTMarket.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {SigUtils} from "../src/libraries/SigUtils.sol";

// import { MyToken } from "../MyToken.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";


contract TestMarket is Test{
    // 初始化
    MyNFT myNFT;
    Market market;
    MyToken token;
    AirdopMerkleNFTMarket airdrop;
    SigUtils sigUtils;

    // MyToken token;
    uint itemId ;
    uint256 public listingFee = 0.0025 ether;
    address nftOwner = address(1);
    AirdopMerkleNFTMarket.NftRecord[] public nfts;
    uint256 internal ownerPrivateKey;
    uint256 internal spenderPrivateKey;
    address internal owner;
    address internal spender;
   
    function setUp() public {
        // vm.startPrank(address(1));
        ownerPrivateKey = 0xA11CE;
        spenderPrivateKey = 0xB0B;
        owner = vm.addr(ownerPrivateKey);
        spender = vm.addr(spenderPrivateKey);
        vm.deal(owner, 5 ether);
        vm.startPrank(owner);
        myNFT = new MyNFT();
        token = new MyToken();
        token.transfer(spender, 10000000);
        sigUtils = new SigUtils(token.DOMAIN_SEPARATOR());
        //nftRecord[] memory _nfts
        // myNFT.mint();

        uint id1 = myNFT.mint(owner, "ipfs://QmWzNBw5YQCEQ8WovNDEGtkxwrAkHcqkzoSZTFw5XAo13T");
        uint id2 = myNFT.mint(owner, "ipfs://QmWzNBw5YQCEQ8WovNDEGtkxwrAkHcqkzoSZTFw5XAo13T");
        uint id3 = myNFT.mint(owner, "ipfs://QmWzNBw5YQCEQ8WovNDEGtkxwrAkHcqkzoSZTFw5XAo13T");
        /**
         * struct nftRecord {
        address nftTokenAddress;
        uint tokenId;
        address owner;
        bool ifTaked;
         */
        // uint[] memory arrs=new uint[](3);
        AirdopMerkleNFTMarket.NftRecord memory nft1 = AirdopMerkleNFTMarket.NftRecord({
             nftTokenAddress:address(myNFT),
             tokenId: id1,
             owner: owner,
             ifTaked: false
        });
        nfts.push(nft1);
        AirdopMerkleNFTMarket.NftRecord memory nft2 = AirdopMerkleNFTMarket.NftRecord({
             nftTokenAddress:address(myNFT),
             tokenId: id2,
             owner: owner,
             ifTaked: false
        });
        nfts.push(nft2);
        AirdopMerkleNFTMarket.NftRecord memory nft3 = AirdopMerkleNFTMarket.NftRecord({
             nftTokenAddress:address(myNFT),
             tokenId: id3,
             owner: owner,
             ifTaked: false
        });
        nfts.push(nft3);
        // nfts[0] = nft1;
        
        airdrop = new AirdopMerkleNFTMarket(address(token), address(myNFT),nfts);
        market = new Market(address(myNFT),address(token), address(airdrop));
        myNFT.setApprovalForAll(address(airdrop), true);
        // token = new MyToken();
        vm.stopPrank();
        // vm.startPrank(address(3));
        // uint id = myNFT.mint(address(3), "ipfs://QmWzNBw5YQCEQ8WovNDEGtkxwrAkHcqkzoSZTFw5XAo13T");
        // myNFT.approve(address(market), id);
        // vm.deal(address(3),1 ether);
        // itemId = market.onList{value: 0.0025 ether}(address(myNFT), itemId, 0.1 ether);
        // console.log("set function market balance",address(market).balance);
        // vm.stopPrank();
    }

    function testBuyNFTWithAirdrop() public{
        vm.startPrank(spender);
        console.log("token balance address1:", token.balanceOf(spender));
        // 这个Permit的测试
        SigUtils.Permit memory permit = SigUtils.Permit({
            owner: spender,
            spender: address(airdrop),
            value: 100,
            nonce: 0,
            deadline: block.timestamp + 1 days
        });
        bytes32 digest = sigUtils.getTypedDataHash(permit);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(spenderPrivateKey, digest);
        // token.permit(permit.owner, permit.spender, permit.value, permit.deadline, v, r, s);
        airdrop.permitPrePay(spender, address(airdrop), block.timestamp + 1 days, v, r, s);
        assertEq(token.allowance(spender, address(airdrop)),100);
        // vm.stopPrank();
        // vm.startPrank(address(1));
        airdrop.claimNFT(spender);

        vm.stopPrank();
    }

/**
 * function buyNFTWithAirdrop(address owner, address spender, uint256 deadline,
    uint8 v,bytes32 r,bytes32 s) public {
        bytes[] memory call;
        call[0] = abi.encodeWithSelector(AirdopMerkleNFTMarket(airdrop).permitPrePay.selector, 
        owner, spender, deadline, v, r, s);
        call[1] = abi.encodeWithSelector(AirdopMerkleNFTMarket(airdrop).claimNFT.selector, msg.sender);
        AirdopMerkleNFTMarket(airdrop).multicall(call);
    }
 */
    function testBuywithMulticall() public {
         vm.startPrank(spender);
        // console.log("token balance address1:", token.balanceOf(spender));
        // 这个Permit的测试
        SigUtils.Permit memory permit = SigUtils.Permit({
            owner: spender,
            spender: address(airdrop),
            value: 100,
            nonce: 0,
            deadline: block.timestamp + 1 days
        });
        bytes32 digest = sigUtils.getTypedDataHash(permit);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(spenderPrivateKey, digest);
        market.buyNFTWithAirdrop(spender, address(airdrop), block.timestamp + 1 days, v, r, s);
        vm.stopPrank();
    }
    
    function testOnList() public {
        // 测试onlist函数，参数有contractAddr,tokenID,price，前两个怎么造呢？
        // 随便搞一个试试行不行
        
        vm.startPrank(address(2));
        vm.deal(address(2), 2 ether);
        vm.expectRevert("must be the owner");
        // 测试下架
        market.unList(itemId);
        vm.stopPrank();
    }

    function testBuy() public {
        vm.startPrank(address(2));
        vm.deal(address(2), 1 ether);
        address owner = myNFT.ownerOf(market.getItemTokenId(itemId));
        console.log("nft owner before:::",owner);
        market.buyByEther{value: 0.1 ether}(itemId, 0.1 ether);
        owner = myNFT.ownerOf(market.getItemTokenId(itemId));
        console.log("nft owner after:::",owner);
        // uint tokenID = market.marketItems[itemId].tokenID;
        //   item =  market.getItem(itemId);
        assertEq(myNFT.ownerOf(market.getItemTokenId(itemId)), address(2));
        console.log("address2 balance",address(2).balance);
        console.log("address1 balance",address(1).balance);
        console.log("address3 balance",address(3).balance);
        console.log("market balance",address(market).balance);
        vm.stopPrank();
    }

    // 剩下要测试的就是增加测试次数，然后看返回的各个数据是否有问题
    // function tes
    function testFuzzOnList(address user, address buyer,
    uint256 balanceOfUser, string memory uri, 
    uint price
        ) public {
        // assume的作用是，如果出现了address(0),则会跳过
        vm.assume(user != address(0));
        vm.assume(price > 0);  // Price must be greater than 0
        vm.deal(user,10 ether);
        vm.startPrank(user);
        uint256 tokenId = myNFT.mint(user, uri);
        myNFT.approve(address(market), tokenId);
        vm.stopPrank();
        // vm.assume(price > 0);
        // vm.assume(price < type(uint).max);
        
        vm.startPrank(user);
        uint id = market.onList{value: listingFee}(address(myNFT), tokenId, price);
        console.log("market.marketItems(1):::");
        // console.log(market.marketItems(1));
        // Market.MarketItem memory item = market.marketItems(1);
        (uint _id, address contractAddr, uint _tokenID, uint _price, 
        address _seller, address payable buyer, Market.State state) 
        = market.marketItems(id);
        vm.stopPrank();
        console.log("_tokenID:", _tokenID);
        console.log("tokenID:", tokenId);
        assertEq(_tokenID, tokenId);
        
        // assertEq(_price, price);
        assertEq(_seller, user);
        // 购买
        vm.assume(buyer != user);
        vm.startPrank(buyer);
        
        vm.stopPrank();
    }
    // 再增加测试次数，看看gas消耗。

    function testFetch() public {
        
        // 运行1000次，把onlist，还有buy的，都循环几次，然后再把数据fetch出来。
        // uint count = 0 ;
        // 创建1000个账号，并且mint，上架
        for (uint count = 0; count < 20; count++) {
            address user = vm.addr(count+1);
            // console.log("user address:", user);
            vm.deal(user, 1 ether);
            vm.startPrank(user);
           uint256 tokenId =  myNFT.mint(user,  "ipfs://QmWzNBw5YQCEQ8WovNDEGtkxwrAkHcqkzoSZTFw5XAo13T");
            myNFT.approve(address(market), tokenId);
            // console.log("approve:::", IERC721(myNFT).getApproved(tokenId));
           uint id = market.onList{value: listingFee}(address(myNFT), tokenId, 0.1 ether);
        //    console.log("id:", market.getItemTokenId(id));
           Market.MarketItem memory item = market.getItem(id);
        //    console.log("approve:::", IERC721(item.contractAddr).getApproved(tokenId));
           vm.stopPrank();
        }
        // 随机购买
        // 查看marketItems
        // for (uint i = 0; i < 20; i++) {
        //     Market.MarketItem memory item = market.getItem(i+1);
            
        //     console.log("item id===", item.id);
        //     console.log("item tokenId===", item.tokenID);
        //     console.log("item seller===", item.seller);
        // }
        Market.MarketItem[] memory items =  market.fetchActiveItems(Market.ItemStatus.ActiveItems);
        console.log("active items length:",items.length);
        // 购买
        uint countBuy;
        uint buyItemId = 1;
        for (countBuy = 20; countBuy < 30; countBuy++) {
            address buyer = vm.addr(countBuy);
            vm.deal(buyer, 1 ether);
            vm.startPrank(buyer);
            Market.MarketItem memory item = market.getItem(buyItemId);
            market.buyByEther{value: item.price}(buyItemId, item.price);
            buyItemId++;
            vm.stopPrank();
        }
        //重新获取active
        items = market.fetchActiveItems(Market.ItemStatus.ActiveItems);
        console.log("after buy items:", items.length);
        // MyPurchasedItems
        address buyerAddr = vm.addr(21);
        vm.prank(buyerAddr);
        Market.MarketItem[] memory itemsMyPurchased = 
        market.fetchPurchasedItems(Market.ItemStatus.MyPurchasedItems);
        console.log("itemsMyPurchased:", itemsMyPurchased.length);
        Market.MarketItem memory purchasedItem = itemsMyPurchased[0];
        console.log("id:", purchasedItem.id);
        console.log("contract:", purchasedItem.contractAddr);
        console.log("buyer:", purchasedItem.buyer);
        console.log("price:", purchasedItem.price);
        console.log("price:", purchasedItem.seller);
        // console.log("state:", purchasedItem.state);
        console.log("tokenId:", purchasedItem.tokenID);
        // mycreated
        address mycreatedAddr = vm.addr(3);
        vm.prank(mycreatedAddr);
        Market.MarketItem[] memory itemsMyCreated = 
        market.fetchCreatedItems(Market.ItemStatus.MyCreatedItems);
        console.log("itemsMyCreated:", itemsMyCreated.length);
        address owner = market.marketowner();
        // market.marketowner.balance; 用这种写法会报错，直接调状态变量，可以用.状态变量（）这种格式。
        // console.log("market owner balance:", owner.balance);
        // 计算 ether 单位的小数值
        uint integerPart = owner.balance / 1 ether;
        uint fractionalPart = (owner.balance % 1 ether) * 1e18;  // 计算小数部分

        console.log("market owner Balance: %s.%s ether", integerPart, fractionalPart);
        // console.log("buyer balance:::",buyerAddr.balance);
        getEth(buyerAddr.balance);
        for (uint i = 1; i <= 10; i++) {
            // getEth(vm.addr(i).balance);
            console.log("balance:",vm.addr(i).balance);
        }
        // console.log("seller 3 balance:::",vm.addr(3).balance);
    }

    function getEth(uint weiBalance) internal view  {
        uint integerPart = weiBalance/ 1 ether;
        uint fractionalPart = (weiBalance % 1 ether) / 1e14 ;  // 计算小数部分
        // 这个打印有问题，前面小数后面前面有0不会加，gpt说"Balance: %s.%04d ether"%这种可以，但结果不行
        console.log("Balance: %s.%s ether", integerPart, fractionalPart);
        // return (integerPart, fractionalPart);
    }
}