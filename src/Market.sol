pragma solidity ^0.8.13;

import "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "./libraries/Counters.sol";
import {EIP712} from "lib/openzeppelin-contracts/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
// import {Nonces} from "lib/openzeppelin-contracts/contracts/utils/Nonces.sol";
import {ReentrancyGuard} from "lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import { AirdopMerkleNFTMarket } from "src/AirdopMerkleNFTMarket.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
interface IMyERC721 {
    function safeTransferFrom(address, address, uint256) external;
    function ownerOf(uint) external returns (address);
    function approve(address, uint256) external;
    function mint(address, string memory) external returns (uint256);
}
contract Market is ReentrancyGuard{
    // NFT结构体:  上架的结构体，但一个NFT上架承接的参数，合约地址，tokenID，价格等
    // market合约要有的功能：买卖NFT，铸造NFT（提供铸造接口），展示用户所有的NFT，展示所有用户上架的NFT（后面两个应该是页面做的了）
    using Counters for Counters.Counter;
    Counters.Counter private _itemCounter; //start from 1
    Counters.Counter private _itemSoldCounter;
    address public myNFT;
    address public token;
    address public airdrop;
    address payable public immutable marketowner;
    enum State {
        Created,
        Release,
        Inactive
    }
    struct MarketItem {
        uint id;
        address contractAddr;
        uint tokenID;
        uint price;
        address seller;
        address payable buyer;
        State state;
        uint amount;
    }
    // items映射
    // 应该是前端从这里扫出来，然后再放到页面上去
    mapping(uint256 => MarketItem) public marketItems;
    uint256 public listingFee = 0.0025 ether;
    event MarketItemCreated(
        uint indexed id,
        address indexed contractAddr,
        uint indexed tokenID,
        uint price,
        address seller,
        address buyer,
        State state,
        uint amount
    );
    
    event MarketItemSold(
        uint indexed id,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address buyer,
        uint256 price,
        State state,
        uint amount
    );
    bytes32 private constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint tokenId,uint256 nonce,uint256 deadline)");

    error ERC2612ExpiredSignature(uint256 deadline);

    error ERC2612InvalidSigner(address signer, address owner);

    constructor(address _myNFT, address _token, address _airdrop) {
        myNFT = _myNFT;
        marketowner = payable(msg.sender);
        token = _token;
        airdrop = _airdrop;
    }
    // 1. 上架， 上架后要加入事件。
       function onList(
       address _contractAddr,
       uint _tokenID,
       uint _price,
       uint _amount // 新增参数
   ) public payable nonReentrant returns (uint) {
       require(msg.value == listingFee, "Fee must be equal to listing fee");
       require(_price > 0, "Price must be at least 1 wei ");
       require(_amount > 0, "Amount must be at least 1");
       getApprove(_contractAddr, _tokenID);
       _itemCounter.increment();
       uint256 id = _itemCounter.current();
       marketItems[id] = MarketItem(
           id,
           _contractAddr,
           _tokenID,
           _price,
           msg.sender,
           payable(address(0)),
           State.Created,
           _amount // 设置代币数量
       );
       emit MarketItemCreated(
           id,
           _contractAddr,
           _tokenID,
           _price,
           msg.sender,
           address(0),
           State.Created,
           _amount
       );
       return id;
   }
    // 2. 下架，
    function unList(uint itemId) public nonReentrant{
        MarketItem storage item = marketItems[itemId];
        require(item.buyer == msg.sender, "must be the owner");
        require(item.state == State.Created, "item must be on market");
        require(itemId <= _itemCounter.current(), "id must <= item count");
        getApprove(item.contractAddr, item.tokenID);
        // 修改
        item.state == State.Inactive;
        emit MarketItemSold(
            itemId,
            item.contractAddr,
            item.tokenID,
            item.seller,
            payable(address(0)),
            0,
            State.Inactive,
            item.amount
        );
    }
    // 3. 购买
    function buyByEther(uint itemId, uint _price) public payable nonReentrant {
        MarketItem storage item = marketItems[itemId];

        require( msg.value == item.price, "money not enough");
        require(item.state == State.Created, "item must be on market");
         if (IERC165(item.contractAddr).supportsInterface(type(IERC721).interfaceId)) {
           require(
               IERC721(item.contractAddr).getApproved(item.tokenID) == address(this),
               "NFT must be approved to market"
           );
           require(IERC721(item.contractAddr).ownerOf(item.tokenID) == item.seller, "Seller is not the owner");
           IERC721(item.contractAddr).safeTransferFrom(
               item.seller,
               msg.sender,
               item.tokenID
           );
       } else if (IERC165(item.contractAddr).supportsInterface(type(IERC1155).interfaceId)) {
           require(
               IERC1155(item.contractAddr).isApprovedForAll(item.seller, address(this)),
               "NFT must be approved to market"
           );
           require(IERC1155(item.contractAddr).balanceOf(item.seller, item.tokenID) >= item.amount, "Seller does not have enough tokens");
        // 判断是否为Owner
        //    require(IERC1155(item.contractAddr).ownerOf(item.tokenID, item.amount) == item.seller, "Seller is not the owner");
           IERC1155(item.contractAddr).safeTransferFrom(
               item.seller,
               msg.sender,
               item.tokenID,
               item.amount,
               ""
           );
       } else {
           revert("Unsupported token type");
       }
        // 把buyer改为购买者
        item.buyer = payable(msg.sender);
        item.state = State.Release;
        // 合约转手续费给owner，爽歪歪
        // payable(marketowner).transfer(listingFee);
        (bool success, ) = marketowner.call{value: listingFee}("");
        require(success, "transfer fee failed");
        // 这里是合约转给seller，因为在函数触发的时候，就把eth从buyer转到合约了，上面转给Owner的手续费也是其中的
        // 噢，上面的不用判断，实际上扣除了手续费，把剩下的转给seller
        // payable(item.seller).transfer(msg.value);
        (bool sucessed, ) = item.seller.call{value: msg.value}("");
        require(sucessed, "transfer value failed");
        
        emit MarketItemSold(
            itemId,
            item.contractAddr,
            item.tokenID,
            item.seller,
            item.buyer,
            msg.value,
            State.Release,
            item.amount
        );
    }

    // 4. 铸造
    function mint(
        address to,
        string memory tokenURI
    ) public returns (uint256, address) {
        //    function mint(address student, string memory tokenURI) public returns (uint256)
        uint256 tokenId = IMyERC721(myNFT).mint(to, tokenURI);
        return (tokenId, myNFT);
    }

    function getItemTokenId(uint256 _id) public view returns (uint256) {
        return marketItems[_id].tokenID;
    }
    function getItem(uint256 _id) public view returns ( MarketItem memory) {
        return marketItems[_id];
    }

    // 返回3种状态的item: MyCreatedItems,MyPurchasedItems, ActiveItems
    enum ItemStatus {
        MyCreatedItems,
        MyPurchasedItems,
        ActiveItems
    }
    // 不搞那么复杂，先这样吧
    // 这里的逻辑是，active，返回所有active的，
    function fetchActiveItems(
        ItemStatus _itemStatus
    ) public view returns (MarketItem[] memory) {
        return fetchItems(_itemStatus);
    }

    function fetchItems(ItemStatus _itemStatus) public view returns (MarketItem[] memory) {
        uint total = _itemCounter.current();
        // console.log("in fetchItems, total:", total);
        uint count = 0;
        for (uint i = 1; i <= total; i++) {
            // 判断，如果符合就+1，并加入数组
            if (isCondition(_itemStatus, marketItems[i])) {
                count++;
            }
        }
        // console.log("count:", count);
        // 这样子新建固定长度的数组，不固定长度的数组只能是storage
        uint index = 0;
        MarketItem[] memory items = new MarketItem[](count);
        // 卧槽，这里看了好久，原来id是从1开始的
        for (uint i = 1; i <= total; i++) {
            if (isCondition(_itemStatus, marketItems[i])) {
                // 直接push会报错
                // activeItems.push(marketItems[i]);
                items[index] = marketItems[i];
                index++;
            }
        }
        return items;
    }

    function isCondition(
        ItemStatus _itemStatus,
        MarketItem memory item
    ) internal view returns (bool) {
    // 如果是Active,那么直接判断state是Created, 并且buyer是0，还有apprvoer是此合约
    // 如果是MyCreated, 那么就是sate不是inactived,seller == msg.sender,
    // 如果是购买过的，buyer==msg.sender(但只要放上架了，就会失效，这个逻辑是有点问题的，以后再改。)
        if(_itemStatus == ItemStatus.ActiveItems){
            return (item.buyer == address(0) 
            && item.state == State.Created
            && (IERC721(item.contractAddr).getApproved(item.tokenID) ==
                address(this))
             ) ? true : false;
            //  IERC721(item.contractAddr).getApproved(item.tokenID) == address(this)
        }else if(_itemStatus == ItemStatus.MyCreatedItems) {
            return (item.state != State.Inactive 
            && item.seller == msg.sender) ? true : false;
        }else if(_itemStatus == ItemStatus.MyPurchasedItems) {
            return (item.buyer == msg.sender) ? true : false;
        }else {
            return false;
        }
    }

    function fetchCreatedItems(
        ItemStatus _itemStatus
    ) public view returns (MarketItem[] memory) {
        return fetchItems(_itemStatus);
    }

    function fetchPurchasedItems(
        ItemStatus _itemStatus
    ) public view returns (MarketItem[] memory) {
        return fetchItems(_itemStatus);
    }

    // 新增multicall,问题是如果新增的话， 是不是直接在market合约增加？这样合约要升级的。
    function buyNFTWithAirdrop(address nftTaker, address spender, bytes32[] calldata _merkleProof,
    uint256 deadline,uint8 v,bytes32 r,bytes32 s) public {
        bytes[] memory call = new bytes[](2);
        call[0] = abi.encodeWithSelector(AirdopMerkleNFTMarket(airdrop).permitPrePay.selector, 
        nftTaker, spender, deadline, v, r, s);
        call[1] = abi.encodeWithSelector(AirdopMerkleNFTMarket(airdrop).claimNFT.selector,
         nftTaker,_merkleProof);
        AirdopMerkleNFTMarket(airdrop).multicall(call);
    }

    function getApprove(address _contractAddr, uint _tokenID) view internal {
        if (IERC165(_contractAddr).supportsInterface(type(IERC721).interfaceId)) {
             require(IERC721(_contractAddr).getApproved(_tokenID) == address(this), "NFT must be approved to market");
        } else if (IERC165(_contractAddr).supportsInterface(type(IERC1155).interfaceId)) {
             require(IERC1155(_contractAddr).isApprovedForAll(msg.sender, address(this)), "NFT must be approved to market");
        } else {
           revert("Unsupported token type");
       }
    }
}
