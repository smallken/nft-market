# NFT Market

### 1. 新建空的foundry项目

`forge init nft-market`

### 2. 引入库；

`forge install OpenZeppelin/openzeppelin-contracts`

### 3. 编写合约；

### 4. 测试；

```
forge test --match-contract TestMarket --rpc-url http://127.0.0.1:8545 -vvv
[⠒] Compiling...
No files changed, compilation skipped

Running 4 tests for test/Market.t.sol:TestMarket
[PASS] testBuy() (gas: 131022)
Logs:
  set function market balance 2500000000000000
  nft owner before::: 0x0000000000000000000000000000000000000003
  nft owner after::: 0x0000000000000000000000000000000000000002
  address2 balance 900000000000000000
  address1 balance 2500000000000000
  address3 balance 1097500000000000000
  market balance 0

[PASS] testFetch() (gas: 6434252)
Logs:
  set function market balance 2500000000000000
  active items length: 21
  after buy items: 11
  itemsMyPurchased: 1
  id: 2
  contract: 0x522B3294E6d06aA25Ad0f1B8891242E335D3B459
  buyer: 0x157bFBEcd023fD6384daD2Bded5DAD7e27Bf92E4
  price: 100000000000000000
  price: 0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf
  tokenId: 1
  itemsMyCreated: 1
  market owner Balance: 0.25000000000000000000000000000000000 ether
  Balance: 0.9000 ether
  balance: 1097500000000000000
  balance: 1097500000000000000
  balance: 1097500000000000000
  balance: 1097500000000000000
  balance: 1097500000000000000
  balance: 1097500000000000000
  balance: 1097500000000000000
  balance: 1097500000000000000
  balance: 1097500000000000000
  balance: 997500000000000000

[PASS] testFuzzOnList(address,address,uint256,string,uint256) (runs: 256, μ: 283968, ~: 263829)
Logs:
  set function market balance 2500000000000000

[PASS] testOnList() (gas: 19115)
Logs:
  set function market balance 2500000000000000

Test result: ok. 4 passed; 0 failed; 0 skipped; finished in 2.22s
 
Ran 1 test suites: 4 tests passed, 0 failed, 0 skipped (4 total tests)
```

### 5. 静态分析；

```
slither ./src/Market.sol 
Compilation warnings/errors on ./src/Market.sol:
Warning: SPDX license identifier not provided in source file. Before publishing, consider adding a comment containing "SPDX-License-Identifier: <SPDX-License>" to each source file. Use "SPDX-License-Identifier: UNLICENSED" for non-open-source code. Please see https://spdx.org for more information.
--> src/Market.sol

Warning: Unused function parameter. Remove or comment out the variable name to silence this warning.
   --> src/Market.sol:132:38:
    |
132 |     function buyByEther(uint itemId, uint _price) public payable nonReentrant {
    |                                      ^^^^^^^^^^^

Market.buyByEther(uint256,uint256) (src/Market.sol#132-169) uses arbitrary from in transferFrom: IERC721(item.contractAddr).transferFrom(item.seller,msg.sender,item.tokenID) (src/Market.sol#143-147)
Reference: https://github.com/trailofbits/slither/wiki/Detector-Documentation#arbitrary-send-erc20

Reentrancy in Market.buyByEther(uint256,uint256) (src/Market.sol#132-169):
        External calls:
        - IERC721(item.contractAddr).transferFrom(item.seller,msg.sender,item.tokenID) (src/Market.sol#143-147)
        - (success) = marketowner.call{value: listingFee}() (src/Market.sol#150)
        - (sucessed) = item.seller.call{value: msg.value}() (src/Market.sol#155)
        External calls sending eth:
        - (success) = marketowner.call{value: listingFee}() (src/Market.sol#150)
        - (sucessed) = item.seller.call{value: msg.value}() (src/Market.sol#155)
        State variables written after the call(s):
        - item.buyer = address(msg.sender) (src/Market.sol#158)
        - item.state = State.Release (src/Market.sol#159)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#reentrancy-vulnerabilities
```

其中的风险包括：

1. uses arbitrary from in transferFrom；

   随意调用，攻击合约可能用其它nft进行转账，所以要设置条件为Owner才允许转；

   修复：

   ```
         // 要求只有owner才能转移
         require(IERC721(item.contractAddr).ownerOf(item.tokenID) == item.seller, "Seller is not the owner");
   // 转账
           IERC721(item.contractAddr).safeTransferFrom(
               item.seller,
               msg.sender,
               item.tokenID
           );
   ```

   

2. 重入风险：

   ```
   Reentrancy in Market.buyByEther(uint256,uint256) (src/Market.sol#132-170):
           External calls:
           - IERC721(item.contractAddr).safeTransferFrom(item.seller,msg.sender,item.tokenID) (src/Market.sol#144-148)
           - (success) = marketowner.call{value: listingFee}() (src/Market.sol#151)
           - (sucessed) = item.seller.call{value: msg.value}() (src/Market.sol#156)
           External calls sending eth:
           - (success) = marketowner.call{value: listingFee}() (src/Market.sol#151)
           - (sucessed) = item.seller.call{value: msg.value}() (src/Market.sol#156)
           State variables written after the call(s):
           - item.buyer = address(msg.sender) (src/Market.sol#159)
           - item.state = State.Release (src/Market.sol#160)
   
   
   ```

   上面的静态分析，函数已经加了nonReentrant,但还报这种重入的风险，是因为有几次的外部调用；另外先转账，这样攻击合约就有可能利用这个旧的状态，把状态调整上来，所以更改如下：

   ```solidity
   function buyByEther(uint itemId, uint _price) public payable nonReentrant {
           MarketItem storage item = marketItems[itemId];
   
           require( msg.value == item.price, "money not enough");
           require(item.state == State.Created, "item must be on market");
           require(
               IERC721(item.contractAddr).getApproved(item.tokenID) ==
                   address(this),
               "NFT must be approved to market"
           );
           require(IERC721(item.contractAddr).ownerOf(item.tokenID) == item.seller, "Seller is not the owner");
           // 转账
           IERC721(item.contractAddr).safeTransferFrom(
               item.seller,
               msg.sender,
               item.tokenID
           );
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
               State.Release
           );
       }
   ```

   最后剩下这个风险：

   ```
   Market.buyByEther(uint256,uint256) (src/Market.sol#132-171) sends eth to arbitrary user
           Dangerous calls:
           - (success) = marketowner.call{value: listingFee}() (src/Market.sol#154)
   Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#functions-that-send-ether-to-arbitrary-destinations
   
   ```

   这个没办法， 用不了transfer，gas会超，开始状态使用了immutable，应该会增加安全性。

### 6. gas分析

| src/Market.sol:Market contract |                 |        |        |        |         |
| ------------------------------ | --------------- | ------ | ------ | ------ | ------- |
| Deployment Cost                | Deployment Size |        |        |        |         |
| 1246029                        | 6109            |        |        |        |         |
| Function Name                  | min             | avg    | median | max    | # calls |
| buyByEther                     | 66726           | 78845  | 77550  | 102626 | 11      |
| fetchActiveItems               | 107297          | 138233 | 138233 | 169169 | 2       |
| fetchCreatedItems              | 62261           | 62261  | 62261  | 62261  | 1       |
| fetchPurchasedItems            | 61440           | 61440  | 61440  | 61440  | 1       |
| getItem                        | 1856            | 1856   | 1856   | 1856   | 30      |
| getItemTokenId                 | 522             | 1188   | 522    | 2522   | 3       |
| marketItems                    | 1365            | 1365   | 1365   | 1365   | 1       |
| marketowner                    | 261             | 261    | 261    | 261    | 1       |
| onList                         | 121148          | 122524 | 121948 | 130748 | 25      |
| unList                         | 7670            | 7670   | 7670   | 7670   | 1       |

