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





### 7. 部署脚本

因为只有bsc test network有测试币，就只在这测了😭

在这里领水：https://www.bnbchain.org/en/testnet-faucet

脚本：

```
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../lib/forge-std/src/Script.sol";

import "../src/Market.sol";
import "../src/MyNFT.sol";
import "../lib/forge-std/src/Test.sol";

contract MarketScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("BSC_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // NFT nft = new NFT("NFT_tutorial", "TUT", "baseUri");
        // 0x5FbDB2315678afecb367f032d93F642f64180aa3
        MyNFT nft = new MyNFT();
        Market market = new Market(address(nft));
        console.log("nft:");
        console.log(address(nft));
        console.log("market:");
        console.log(address(market));
        
        vm.stopBroadcast();
    }
}
```

`.env`

<img src="/Users/mac/Documents/学习资料/登链社区区块链教程/OpenSpace线下学习/学习总结笔记/photo/image-20240828114359720.png" alt="image-20240828114359720" style="zoom:50%;" />

`foundry.toml`

```
[profile.default]
src = "src"
out = "out"
libs = ["lib"]
gas_reports = ["Market", "MarketReport"]

[rpc_endpoints]
#goerli = "${GOERLI_RPC_URL}"
bsctest = "${BSC_TEST_RPC_URL}"
[etherscan]
#goerli = { key = "${ETHERSCAN_API_KEY}" }
#bsctest = "${BSC_TEST_RPC_URL}"

# See more config options https://github.com/foundry-rs/foundry/blob/master/crates/config/README.md#all-options

```

部署：

`forge script ./script/MarketScript.s.sol --rpc-url $BSC_TEST_RPC_URL --broadcast --verify -vvvv`

部署成功：

```
Traces:
  [2341929] MarketScript::run()
    ├─ [0] VM::envUint("BSC_PRIVATE_KEY") [staticcall]
    │   └─ ← <env var value>
    ├─ [0] VM::startBroadcast(13041835056473959464645532088542975372699835762212378989501611808949970282388 [1.304e76])
    │   └─ ← ()
    ├─ [1021757] → new MyNFT@0xFdcD337D51fE3F63130Fd17294928FFBA7Ea3524
    │   └─ ← 5383 bytes of code
    ├─ [1246029] → new Market@0xD6A87015af0378a5FBD3319c7dC29A95A2c65AF0
    │   └─ ← 6109 bytes of code
    ├─ [0] console::log("nft:") [staticcall]
    │   └─ ← ()
    ├─ [0] console::log(MyNFT: [0xFdcD337D51fE3F63130Fd17294928FFBA7Ea3524]) [staticcall]
    │   └─ ← ()
    ├─ [0] console::log("market:") [staticcall]
    │   └─ ← ()
    ├─ [0] console::log(Market: [0xD6A87015af0378a5FBD3319c7dC29A95A2c65AF0]) [staticcall]
    │   └─ ← ()
    ├─ [0] VM::stopBroadcast()
    │   └─ ← ()
    └─ ← ()


Script ran successfully.

== Logs ==
  nft:
  0xFdcD337D51fE3F63130Fd17294928FFBA7Ea3524
  market:
  0xD6A87015af0378a5FBD3319c7dC29A95A2c65AF0
```

**交互：**

`cast send 0xFdcD337D51fE3F63130Fd17294928FFBA7Ea3524 --rpc-url https://data-seed-prebsc-1-s1.binance.org:8545 --private-key $BSC_PRIVATE_KEY "mint(address, string)(uint256)" 0xc061818057bA2454681507Ed5176144Aa4860De1 "test"`

```
blockHash               0xe3b6ba2d08ac7af81723e97acf72c7b25dbe9e05e06d541edae6036cb5437e87
blockNumber             43365131
contractAddress         
cumulativeGasUsed       21888
effectiveGasPrice       5000000000
from                    0xc061818057bA2454681507Ed5176144Aa4860De1
gasUsed                 21888
logs                    []
logsBloom               0x00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
root                    
status                  1
transactionHash         0x060cd311436e974f1c23d216dad1dbd71ec91e9aca4177bef3b3b8976776e854
transactionIndex        0
type                    0
to                      0xfdcd…3524
```

在这里查看交易历史：https://testnet.bscscan.com/

<img src="/Users/mac/Documents/学习资料/登链社区区块链教程/OpenSpace线下学习/学习总结笔记/photo/image-20240828114717863.png" alt="image-20240828114717863" style="zoom:50%;" />

#### 7.1 脚本部署问题：无合约代码

脚本部署后，没有合约部分，很奇怪。

换用单个的部署却可以：

`forge create --rpc-url $BSC_TEST_RPC_URL --private-key $BSC_PRIVATE_KEY ./src/MyNFT.sol:MyNFT`

结果：

`Deployer: 0xc061818057bA2454681507Ed5176144Aa4860De1
Deployed to: 0x66590317CbEF0a42728064878b3b2f907733aB63`

交互测试：

```
cast call 0x66590317CbEF0a42728064878b3b2f907733aB63 --rpc-url $BSC_TEST_RPC_URL "name()(string)"
"Dragon"
```

**部署Market**

#### 7.2 arguments were not provided: CONTRACT

```
forge create --rpc-url $BSC_TEST_RPC_URL --private-key $BSC_PRIVATE_KEY --constructor-args 0x66590317CbEF0a42728064878b3b2f907733aB63 \ ./src/Market.sol:Market 
error: the following required arguments were not provided:
  <CONTRACT>

Usage: forge create --rpc-url <URL> --private-key <RAW_PRIVATE_KEY> --constructor-args <ARGS>... <CONTRACT>
```

部署market的时候报上面错误，把--constructor-args放前面就行：

`forge create --rpc-url $BSC_TEST_RPC_URL --constructor-args 0x66590317CbEF0a42728064878b3b2f907733aB63 --p
rivate-key $BSC_PRIVATE_KEY ./src/Market.sol:Market `

结果：

```
Deployer: 0xc061818057bA2454681507Ed5176144Aa4860De1
Deployed to: 0x689Fb7972129Ef969e9578852c12159BE5d282e5
Transaction hash: 0x913d594a67d579ac434c1ed121e7c92652e01a8ce6b29461f92496b7b8dcef3f
```

#### 7.3 重新部署

因为没有打印时间，所以都重新部署了。

```
forge create --private-key $BSC_PRIVATE_KEY --rpc-url $BSC_URL ./src/MyNFT.sol:MyNFT
[⠒] Compiling...
[⠢] Compiling 3 files with 0.8.23
[⠰] Solc 0.8.23 finished in 10.88s

Deployer: 0xc061818057bA2454681507Ed5176144Aa4860De1
Deployed to: 0x4f7c69de399134C74190969a3Ebe2Dd347c28C6C
Transaction hash: 0xdd95cc2c555f890a2281bde47f38ea11d8ce44430a7068eb2f11e1a756788a72
```

测试没问题：

` cast call 0x4f7c69de399134C74190969a3Ebe2Dd347c28C6C --rpc-url $BSC_URL "name()(string)"
"Dragon"`

调用mint函数：

```
 cast send 0x4f7c69de399134C74190969a3Ebe2Dd347c28C6C --rpc-url $BSC_URL --private-key $BSC_PRIVATE_KEY "mint(address, string)(uint256)" 0xc061818057bA2454681507Ed5176144Aa4860De1 "ipfs://QmWzNBw5YQCEQ8WovNDEGtkxwrAkHcqkzoSZTFw5XAo13T"

blockHash               0xfd73bde9c9a36399a984cc48638d8965c1fd9a84cd621b3aa70566b5eba75f51
blockNumber             43371324
contractAddress         
cumulativeGasUsed       727052
effectiveGasPrice       5000000000
from                    0xc061818057bA2454681507Ed5176144Aa4860De1
gasUsed                 161791
logs                    [{"address":"0x4f7c69de399134c74190969a3ebe2dd347c28c6c","topics":["0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef","0x0000000000000000000000000000000000000000000000000000000000000000","0x000000000000000000000000c061818057ba2454681507ed5176144aa4860de1","0x0000000000000000000000000000000000000000000000000000000000000000"],"data":"0x","blockHash":"0xfd73bde9c9a36399a984cc48638d8965c1fd9a84cd621b3aa70566b5eba75f51","blockNumber":"0x295cb3c","transactionHash":"0x9c48babf492712b6c2f257f3034e0c14d26475ea75877104796b756daca63b0c","transactionIndex":"0xb","logIndex":"0x8","removed":false},{"address":"0x4f7c69de399134c74190969a3ebe2dd347c28c6c","topics":["0xf8e1a15aba9398e019f0b49df1a4fde98ee17ae345cb5f6b5e2c27f5033e8ce7"],"data":"0x0000000000000000000000000000000000000000000000000000000000000000","blockHash":"0xfd73bde9c9a36399a984cc48638d8965c1fd9a84cd621b3aa70566b5eba75f51","blockNumber":"0x295cb3c","transactionHash":"0x9c48babf492712b6c2f257f3034e0c14d26475ea75877104796b756daca63b0c","transactionIndex":"0xb","logIndex":"0x9","removed":false},{"address":"0x4f7c69de399134c74190969a3ebe2dd347c28c6c","topics":["0x0f6798a560793a54c3bcfe86a93cde1e73087d944c0ea20544137d4121396885"],"data":"0x000000000000000000000000c061818057ba2454681507ed5176144aa4860de10000000000000000000000000000000000000000000000000000000000000000","blockHash":"0xfd73bde9c9a36399a984cc48638d8965c1fd9a84cd621b3aa70566b5eba75f51","blockNumber":"0x295cb3c","transactionHash":"0x9c48babf492712b6c2f257f3034e0c14d26475ea75877104796b756daca63b0c","transactionIndex":"0xb","logIndex":"0xa","removed":false}]
logsBloom               0x00000000000000000000000000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000020000000000008000000000400000000000000000000000000000000000400020000000000000000000800000000000000400000000010000000000000000000000000000000000000000000000000000000000000000000000000000080000000000000000000000000002000000000000000000000000000008004000002000000000000000000000000000000100010000000000000000020000000000000000000200000000000000000000000000000000000000000000000
root                    
status                  1
transactionHash         0x9c48babf492712b6c2f257f3034e0c14d26475ea75877104796b756daca63b0c
transactionIndex        11
type                    0
to                      0x4f7c…8c6c
```

打印的事件：

```
Address
0x4f7c69de399134c74190969a3ebe2dd347c28c6c   
Name
Mint (index_topic_1 address user, uint256 value)View Source

Topics
0 0x0f6798a560793a54c3bcfe86a93cde1e73087d944c0ea20544137d4121396885
Data
value :
1098300681440072161752531734442467661700009430497
// 把上面的value换成Hex的：
0x000000000000000000000000c061818057ba2454681507ed5176144aa4860de10000000000000000000000000000000000000000000000000000000000000000
```

Decode 事件：

```
 cast abi-decode "abi()(address, uint256)" 0x000000000000000000000000c061818057ba2454681507ed5176144aa4860de10000000000000000000000000000000000000000000000000000000000000000
 结果：
0xc061818057bA2454681507Ed5176144Aa4860De1
0
```

### 8. 调用函数

调用onList函数

```
 cast send 0x689Fb7972129Ef969e9578852c12159BE5d282e5 --rpc-url $BSC_URL --private-key $BSC_PRIVATE_KEY "onList(address, uint, uint)(uint)" 0x66590317CbEF0a42728064878b3b2f907733aB63 0 80000000
Error: 
(code: 3, message: execution reverted: Fee must be equal to listing fee, data: Some(String("0x08c379a000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000020466565206d75737420626520657175616c20746f206c697374696e6720666565")))
```

报错了，转点ether过去：

```
cast send 0x689Fb7972129Ef969e9578852c12159BE5d282e5 --value 0.0025ether  --rpc-url $BSC_URL --private-key
 $BSC_PRIVATE_KEY "onList(address, uint, uint)(uint)" 0x66590317CbEF0a42728064878b3b2f907733aB63 0 80000000
Error: 
(code: 3, message: execution reverted: NFT must be approved to market, data: Some(String("0x08c379a00000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000001e4e4654206d75737420626520617070726f76656420746f206d61726b65740000")))
```

噢，没有approve:

```
cast send 0x66590317CbEF0a42728064878b3b2f907733aB63 --rpc-url $BSC_URL --private-key $BSC_PRIVATE_KEY "approve(address, uint256)" 0x689Fb7972129Ef969e9578852c12159BE5d282e5 0

blockHash               0x0ac3ac625ddde601d1d76c86aef6060b0d18ca846a19121e407a31c74fde9f09
blockNumber             43376731
contractAddress         
cumulativeGasUsed       2229760
effectiveGasPrice       5000000000
from                    0xc061818057bA2454681507Ed5176144Aa4860De1
gasUsed                 48612
logs                    [{"address":"0x66590317cbef0a42728064878b3b2f907733ab63","topics":["0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925","0x000000000000000000000000c061818057ba2454681507ed5176144aa4860de1","0x000000000000000000000000689fb7972129ef969e9578852c12159be5d282e5","0x0000000000000000000000000000000000000000000000000000000000000000"],"data":"0x","blockHash":"0x0ac3ac625ddde601d1d76c86aef6060b0d18ca846a19121e407a31c74fde9f09","blockNumber":"0x295e05b","transactionHash":"0x96a52f52d37211f6187ec95e5524f4998113740704ca9501d10c2204756f8d78","transactionIndex":"0x39","logIndex":"0x38","removed":false}]
logsBloom               0x00000000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000000000000000400020000000000000000000800000000100000000000010000000000000000000000000000000000000000000000000000000000000000000000000000020000000000000010000000000000000100000000000000000000000000000004000000000000000000000000000000000000000010000000000000000020000010000000000000000000000000000000000000000010000000000000000000
root                    
status                  1
transactionHash         0x96a52f52d37211f6187ec95e5524f4998113740704ca9501d10c2204756f8d78
transactionIndex        57
type                    0
to                      0x6659…ab63
```

再尝试：

```
cast send 0x689Fb7972129Ef969e9578852c12159BE5d282e5 --value 0.0025ether  --rpc-url $BSC_URL --private-key $BSC_PRIVATE_KEY "onList(address, uint, uint)(uint)" 0x66590317CbEF0a42728064878b3b2f907733aB63 0 80000000

blockHash               0xdab0f573813320402a634e3f81ee53499d98ff3568665890eb87d7a049caec99
blockNumber             43376737
contractAddress         
cumulativeGasUsed       2139631
effectiveGasPrice       5000000000
from                    0xc061818057bA2454681507Ed5176144Aa4860De1
gasUsed                 153372
logs                    [{"address":"0x689fb7972129ef969e9578852c12159be5d282e5","topics":["0x268d319293e48221f9eee519b52c3c8874cb052769bc49802c8e15597bd2ca35","0x0000000000000000000000000000000000000000000000000000000000000001","0x00000000000000000000000066590317cbef0a42728064878b3b2f907733ab63","0x0000000000000000000000000000000000000000000000000000000000000000"],"data":"0x0000000000000000000000000000000000000000000000000000000004c4b400000000000000000000000000c061818057ba2454681507ed5176144aa4860de100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000","blockHash":"0xdab0f573813320402a634e3f81ee53499d98ff3568665890eb87d7a049caec99","blockNumber":"0x295e061","transactionHash":"0x401b8054fab6fa5c2385ca1d95ac02e84c890ef011dc07ba2a3149bd78d7d747","transactionIndex":"0x41","logIndex":"0x3f","removed":false}]
logsBloom               0x00000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000000000000000000000000000040000000010000000000000000000000000000000000000040000000000000000000000000000020000000000000000000800000000000000000000000800000000000000000004000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000800000002000000000000000000000060000000000000000000000000000000000000000000000000000000010000000000
root                    
status                  1
transactionHash         0x401b8054fab6fa5c2385ca1d95ac02e84c890ef011dc07ba2a3149bd78d7d747
transactionIndex        65
type                    0
to                      0x689f…82e5
```





### 9. 新增签名授权转账，白名单（默克尔树），multicall

1. 测试；

   `forge test --match-test testBuyNFTWithAirdrop -vvvv`

   ```
   Running 1 test for test/Market.t.sol:TestMarket
   [PASS] testBuyNFTWithAirdrop() (gas: 274896)
   Logs:
     copyNFT, times: 0
     copyNFT, times: 1
     copyNFT, times: 2
     token balance address1: 10000000
   
   Traces:
     [274896] TestMarket::testBuyNFTWithAirdrop()
       ├─ [0] VM::startPrank(0x0376AAc07Ad725E01357B1725B5ceC61aE10473c)
       │   └─ ← ()
       ├─ [2563] MyToken::balanceOf(0x0376AAc07Ad725E01357B1725B5ceC61aE10473c) [staticcall]
       │   └─ ← 10000000 [1e7]
       ├─ [0] console::log("token balance address1:", 10000000 [1e7]) [staticcall]
       │   └─ ← ()
       ├─ [3307] SigUtils::getTypedDataHash(Permit({ owner: 0x0376AAc07Ad725E01357B1725B5ceC61aE10473c, spender: 0x4e2958b9682A516020581D381a776ee0232Ffe8a, value: 100, nonce: 0, deadline: 86401 [8.64e4] })) [staticcall]
       │   └─ ← 0xccb9062d7bbc4a9c7f0dff151ad901c4c9b43765f319836f86e33b39d17baccf
       ├─ [0] VM::sign(2827, 0xccb9062d7bbc4a9c7f0dff151ad901c4c9b43765f319836f86e33b39d17baccf) [staticcall]
       │   └─ ← 28, 0x11c3f24f4106729c5e348eae9a18714d2f713f2b339a86d01862e0b21c7f6762, 0x75a4c769525feb56a1ad4b1795bcfc21c491d6fcf49bb7ae7db1d36e6adb6984
       ├─ [54654] AirdopMerkleNFTMarket::permitPrePay(0x0376AAc07Ad725E01357B1725B5ceC61aE10473c, AirdopMerkleNFTMarket: [0x4e2958b9682A516020581D381a776ee0232Ffe8a], 86401 [8.64e4], 28, 0x11c3f24f4106729c5e348eae9a18714d2f713f2b339a86d01862e0b21c7f6762, 0x75a4c769525feb56a1ad4b1795bcfc21c491d6fcf49bb7ae7db1d36e6adb6984)
       │   ├─ [51484] MyToken::permit(0x0376AAc07Ad725E01357B1725B5ceC61aE10473c, AirdopMerkleNFTMarket: [0x4e2958b9682A516020581D381a776ee0232Ffe8a], 100, 86401 [8.64e4], 28, 0x11c3f24f4106729c5e348eae9a18714d2f713f2b339a86d01862e0b21c7f6762, 0x75a4c769525feb56a1ad4b1795bcfc21c491d6fcf49bb7ae7db1d36e6adb6984)
       │   │   ├─ [3000] PRECOMPILES::ecrecover(0xccb9062d7bbc4a9c7f0dff151ad901c4c9b43765f319836f86e33b39d17baccf, 28, 8035525962846974955719379202791074398317335858750846892766247569290671646562, 53211742489858300667034990264133638789998699522138864784591914614506544392580) [staticcall]
       │   │   │   └─ ← 0x0000000000000000000000000376aac07ad725e01357b1725b5cec61ae10473c
       │   │   ├─ emit Approval(owner: 0x0376AAc07Ad725E01357B1725B5ceC61aE10473c, spender: AirdopMerkleNFTMarket: [0x4e2958b9682A516020581D381a776ee0232Ffe8a], value: 100)
       │   │   └─ ← ()
       │   └─ ← ()
       ├─ [814] MyToken::allowance(0x0376AAc07Ad725E01357B1725B5ceC61aE10473c, AirdopMerkleNFTMarket: [0x4e2958b9682A516020581D381a776ee0232Ffe8a]) [staticcall]
       │   └─ ← 100
       ├─ [218333] AirdopMerkleNFTMarket::claimNFT(0x0376AAc07Ad725E01357B1725B5ceC61aE10473c, [0xcfc42f28608f55d154a718c604f767a905e8abe69db3c43ac9148b62bc354f5d, 0x528ec4302eea6221220ebeae9f37ef81215fb615a508d4e7e665a7746edd06a1, 0x61078cfb32f020ffc6202a24b0ebe2f4e461ff6e162d22f5f0bc738951a72818])
       │   ├─ [26234] MerkleTreeAirDrop::whitelistMint([0xcfc42f28608f55d154a718c604f767a905e8abe69db3c43ac9148b62bc354f5d, 0x528ec4302eea6221220ebeae9f37ef81215fb615a508d4e7e665a7746edd06a1, 0x61078cfb32f020ffc6202a24b0ebe2f4e461ff6e162d22f5f0bc738951a72818], 0x0376AAc07Ad725E01357B1725B5ceC61aE10473c)
       │   │   └─ ← ()
       │   ├─ [28840] MyToken::transferFrom(0x0376AAc07Ad725E01357B1725B5ceC61aE10473c, MyNFT: [0xCF75462c9e7fFf4eEB0c50185087a0fb9A056d2b], 100)
       │   │   ├─ emit Transfer(from: 0x0376AAc07Ad725E01357B1725B5ceC61aE10473c, to: MyNFT: [0xCF75462c9e7fFf4eEB0c50185087a0fb9A056d2b], value: 100)
       │   │   └─ ← true
       │   ├─ [40251] MyNFT::transferFrom(0xe05fcC23807536bEe418f142D19fa0d21BB0cfF7, 0x0376AAc07Ad725E01357B1725B5ceC61aE10473c, 2)
       │   │   ├─ emit Transfer(from: 0xe05fcC23807536bEe418f142D19fa0d21BB0cfF7, to: 0x0376AAc07Ad725E01357B1725B5ceC61aE10473c, tokenId: 2)
       │   │   └─ ← ()
       │   ├─ emit NFTClaimed(nftRecordNum: 0, tokenId: 2, taker: 0x0376AAc07Ad725E01357B1725B5ceC61aE10473c)
       │   └─ ← ()
       ├─ [0] VM::stopPrank()
       │   └─ ← ()
       └─ ← ()
   
   Test result: ok. 1 passed; 0 failed; 0 skipped; finished in 29.83ms
   ```

2. 测试multicall;

   `forge test --match-test testBuywithMulticall -vvvv`

   ```
   PASS] testBuywithMulticall() (gas: 283294)
   Logs:
     copyNFT, times: 0
     copyNFT, times: 1
     copyNFT, times: 2
   
   Traces:
     [283294] TestMarket::testBuywithMulticall()
       ├─ [0] VM::startPrank(0x0376AAc07Ad725E01357B1725B5ceC61aE10473c)
       │   └─ ← ()
       ├─ [3307] SigUtils::getTypedDataHash(Permit({ owner: 0x0376AAc07Ad725E01357B1725B5ceC61aE10473c, spender: 0x4e2958b9682A516020581D381a776ee0232Ffe8a, value: 100, nonce: 0, deadline: 86401 [8.64e4] })) [staticcall]
       │   └─ ← 0xccb9062d7bbc4a9c7f0dff151ad901c4c9b43765f319836f86e33b39d17baccf
       ├─ [0] VM::sign(2827, 0xccb9062d7bbc4a9c7f0dff151ad901c4c9b43765f319836f86e33b39d17baccf) [staticcall]
       │   └─ ← 28, 0x11c3f24f4106729c5e348eae9a18714d2f713f2b339a86d01862e0b21c7f6762, 0x75a4c769525feb56a1ad4b1795bcfc21c491d6fcf49bb7ae7db1d36e6adb6984
       ├─ [292221] Market::buyNFTWithAirdrop(0x0376AAc07Ad725E01357B1725B5ceC61aE10473c, AirdopMerkleNFTMarket: [0x4e2958b9682A516020581D381a776ee0232Ffe8a], [0xcfc42f28608f55d154a718c604f767a905e8abe69db3c43ac9148b62bc354f5d, 0x528ec4302eea6221220ebeae9f37ef81215fb615a508d4e7e665a7746edd06a1, 0x61078cfb32f020ffc6202a24b0ebe2f4e461ff6e162d22f5f0bc738951a72818], 86401 [8.64e4], 28, 0x11c3f24f4106729c5e348eae9a18714d2f713f2b339a86d01862e0b21c7f6762, 0x75a4c769525feb56a1ad4b1795bcfc21c491d6fcf49bb7ae7db1d36e6adb6984)
       │   ├─ [282397] AirdopMerkleNFTMarket::multicall([0xd66bb9e80000000000000000000000000376aac07ad725e01357b1725b5cec61ae10473c0000000000000000000000004e2958b9682a516020581d381a776ee0232ffe8a0000000000000000000000000000000000000000000000000000000000015181000000000000000000000000000000000000000000000000000000000000001c11c3f24f4106729c5e348eae9a18714d2f713f2b339a86d01862e0b21c7f676275a4c769525feb56a1ad4b1795bcfc21c491d6fcf49bb7ae7db1d36e6adb6984, 0xb67f313e0000000000000000000000000376aac07ad725e01357b1725b5cec61ae10473c00000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000003cfc42f28608f55d154a718c604f767a905e8abe69db3c43ac9148b62bc354f5d528ec4302eea6221220ebeae9f37ef81215fb615a508d4e7e665a7746edd06a161078cfb32f020ffc6202a24b0ebe2f4e461ff6e162d22f5f0bc738951a72818])
       │   │   ├─ [57154] AirdopMerkleNFTMarket::permitPrePay(0x0376AAc07Ad725E01357B1725B5ceC61aE10473c, AirdopMerkleNFTMarket: [0x4e2958b9682A516020581D381a776ee0232Ffe8a], 86401 [8.64e4], 28, 0x11c3f24f4106729c5e348eae9a18714d2f713f2b339a86d01862e0b21c7f6762, 0x75a4c769525feb56a1ad4b1795bcfc21c491d6fcf49bb7ae7db1d36e6adb6984) [delegatecall]
       │   │   │   ├─ [51484] MyToken::permit(0x0376AAc07Ad725E01357B1725B5ceC61aE10473c, AirdopMerkleNFTMarket: [0x4e2958b9682A516020581D381a776ee0232Ffe8a], 100, 86401 [8.64e4], 28, 0x11c3f24f4106729c5e348eae9a18714d2f713f2b339a86d01862e0b21c7f6762, 0x75a4c769525feb56a1ad4b1795bcfc21c491d6fcf49bb7ae7db1d36e6adb6984)
       │   │   │   │   ├─ [3000] PRECOMPILES::ecrecover(0xccb9062d7bbc4a9c7f0dff151ad901c4c9b43765f319836f86e33b39d17baccf, 28, 8035525962846974955719379202791074398317335858750846892766247569290671646562, 53211742489858300667034990264133638789998699522138864784591914614506544392580) [staticcall]
       │   │   │   │   │   └─ ← 0x0000000000000000000000000376aac07ad725e01357b1725b5cec61ae10473c
       │   │   │   │   ├─ emit Approval(owner: 0x0376AAc07Ad725E01357B1725B5ceC61aE10473c, spender: AirdopMerkleNFTMarket: [0x4e2958b9682A516020581D381a776ee0232Ffe8a], value: 100)
       │   │   │   │   └─ ← ()
       │   │   │   └─ ← ()
       │   │   ├─ [220333] AirdopMerkleNFTMarket::claimNFT(0x0376AAc07Ad725E01357B1725B5ceC61aE10473c, [0xcfc42f28608f55d154a718c604f767a905e8abe69db3c43ac9148b62bc354f5d, 0x528ec4302eea6221220ebeae9f37ef81215fb615a508d4e7e665a7746edd06a1, 0x61078cfb32f020ffc6202a24b0ebe2f4e461ff6e162d22f5f0bc738951a72818]) [delegatecall]
       │   │   │   ├─ [26234] MerkleTreeAirDrop::whitelistMint([0xcfc42f28608f55d154a718c604f767a905e8abe69db3c43ac9148b62bc354f5d, 0x528ec4302eea6221220ebeae9f37ef81215fb615a508d4e7e665a7746edd06a1, 0x61078cfb32f020ffc6202a24b0ebe2f4e461ff6e162d22f5f0bc738951a72818], 0x0376AAc07Ad725E01357B1725B5ceC61aE10473c)
       │   │   │   │   └─ ← ()
       │   │   │   ├─ [30840] MyToken::transferFrom(0x0376AAc07Ad725E01357B1725B5ceC61aE10473c, MyNFT: [0xCF75462c9e7fFf4eEB0c50185087a0fb9A056d2b], 100)
       │   │   │   │   ├─ emit Transfer(from: 0x0376AAc07Ad725E01357B1725B5ceC61aE10473c, to: MyNFT: [0xCF75462c9e7fFf4eEB0c50185087a0fb9A056d2b], value: 100)
       │   │   │   │   └─ ← true
       │   │   │   ├─ [40251] MyNFT::transferFrom(0xe05fcC23807536bEe418f142D19fa0d21BB0cfF7, 0x0376AAc07Ad725E01357B1725B5ceC61aE10473c, 2)
       │   │   │   │   ├─ emit Transfer(from: 0xe05fcC23807536bEe418f142D19fa0d21BB0cfF7, to: 0x0376AAc07Ad725E01357B1725B5ceC61aE10473c, tokenId: 2)
       │   │   │   │   └─ ← ()
       │   │   │   ├─ emit NFTClaimed(nftRecordNum: 0, tokenId: 2, taker: 0x0376AAc07Ad725E01357B1725B5ceC61aE10473c)
       │   │   │   └─ ← ()
       │   │   └─ ← [0x, 0x]
       │   └─ ← ()
       ├─ [0] VM::stopPrank()
       │   └─ ← ()
       └─ ← ()
   
   Test result: ok. 1 passed; 0 failed; 0 skipped; finished in 50.42ms
   ```

   

