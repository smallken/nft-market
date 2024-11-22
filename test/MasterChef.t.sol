// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console2} from "forge-std/Test.sol";
import {MasterChef} from "../src/MasterChef.sol";
import {MyToken} from "../src/MyToken.sol";
import {IToken} from "../src/MasterChef.sol";
contract MasterChefTest is Test {
    MasterChef public masterChef;
    MyToken public token;
    uint256 startBlock = block.number;

    function setUp() public {
        // Method 1: Use the current block number
        
        // Or method 2: Use a fixed value
        // uint256 startBlock = 100;
        vm.startPrank(address(1));
        token = new MyToken();
        console2.log("token.balance:", token.balanceOf(address(1)));
        masterChef = new MasterChef(
            IToken(address(token)),
            1000 * 1e18,  // tokenPerBlock: 1 token per block
            startBlock
        );
        vm.stopPrank();
        
        // If you need to test the state before it starts
        // vm.roll(startBlock - 1);
        
        // If you need to test the state after it starts
        // vm.roll(startBlock + 1);
    }
    
    function testDeposit() public {
        vm.startPrank(address(1));
        vm.deal(address(1), 3 ether);
        token.approve(address(masterChef), 100000 * 1e18);
        token.approve(address(1), 100000 * 1e18);
        
        // Format values to ETH units
        console2.log("Initial token balance: %s token", token.balanceOf(address(1)) / 1e18);
        console2.log("Allowance: %s token", token.allowance(address(1), address(masterChef)) / 1e18);
        
        token.transferFrom(address(1), address(masterChef), 100000 * 1e18);
        console2.log("MasterChef ETH balance: %s ETH", address(masterChef).balance / 1e18);
        
        masterChef.deposit{value: 1 ether}(1 ether);
        console2.log("After deposit MasterChef balance: %s ETH", address(masterChef).balance / 1e18);
        console2.log("MasterChef token balance: %s", token.balanceOf(address(masterChef)) / 1e18);
        console2.log("After deposit address1 token balance: %s", token.balanceOf(address(1)) / 1e18);
        // Use scientific notation for large numbers
        console2.log("Accumulated ETH per share: %e", masterChef.accEthPerShare());
        
        token.approve(address(1), 100000 * 1e18);
        vm.stopPrank();

        vm.roll(startBlock + 3);
        vm.deal(address(2), 1 ether);
        vm.startPrank(address(2));
        masterChef.deposit{value: 0.5 ether}(0.5 ether);
        
        console2.log("Current MasterChef balance: %s ETH", address(masterChef).balance / 1e18);
        console2.log("AccEthPerShare after 3 blocks: %e", masterChef.accEthPerShare());
        console2.log("After address2 deposit address1 token balance: %s", token.balanceOf(address(1)) / 1e18);
        console2.log("After address2 deposit MasterChef token balance: %s", token.balanceOf(address(2)) / 1e18);
        vm.stopPrank();
    }

    function testDepoisteAndWithdraw() public {
        address[] memory users = new address[](10);
        uint256 blockJump = block.number;
        
        // 修改用户地址生成方式，避开预编译合约地址
        for(uint8 i = 0; i < 10; i++) {
            // 使用 makeAddr 生成地址
            users[i] = makeAddr(string.concat("user", vm.toString(i)));
            vm.deal(users[i], 100 ether);
            
            vm.startPrank(users[i]);
            token.approve(address(masterChef), type(uint256).max);
            vm.stopPrank();
        }

        for(uint8 i = 0; i < 10; i++) {
            vm.roll(blockJump);
            vm.startPrank(users[i]);
            console2.log("blockJump: %s", blockJump);
            // 存款随机1-3eth
            uint256 amount = (uint256(keccak256(abi.encode(i, "amount"))) % 2 + 1) * 1 ether;
            console2.log("User %s deposit: %s ETH", i, amount / 1e18);
            masterChef.deposit{value: amount}(amount);
            vm.stopPrank();
            blockJump++;
            console2.log("User %s token balance: %s", i, token.balanceOf(address(users[i])) / 1e18);
            console2.log("accEthPerShare: %s", masterChef.accEthPerShare() / 1e12);

        }
        for(uint8 i = 0; i < 10; i++) {
            vm.roll(blockJump);
            vm.startPrank(users[i]);
            console2.log("blockJump: %s", blockJump);
            masterChef.withdraw(0.5 ether);
            console2.log("User %s withdraw:0.5 ETH", i);
            vm.stopPrank();
            blockJump++;
            console2.log("contract balance:", address(masterChef).balance / 1e18);
            console2.log("User %s token balance: %s", i, token.balanceOf(address(users[i])) / 1e18);
            console2.log("accEthPerShare: %s", masterChef.accEthPerShare() / 1e12);
        }

    }

    function testBeforeStartBlock() public {
        vm.roll(startBlock - 1);
        // Test behavior before mining starts
    }

    function testAtStartBlock() public {
        vm.roll(startBlock);
        // Test behavior at the beginning of mining
    }

    function testAfterStartBlock() public {
        vm.roll(startBlock + 100);
        // Test behavior after mining for a while
    }

    function formatEth(uint256 amount) internal pure returns (string memory) {
        return string(abi.encodePacked(vm.toString(amount / 1e18), ".", vm.toString((amount % 1e18) / 1e16), " ETH"));
    }

    // Use in tests

    function testFuzz_MultipleUsersOperations(
        uint8 userCount,
        uint16 operationCount,
        uint16 maxBlockJump
    ) public {
        // Bound the input values to reasonable ranges
        // userCount = uint8(bound(userCount, 1, 10));  // 1-10 users
        // operationCount = uint8(bound(operationCount, 1, 20));  // 1-20 operations per user
        // maxBlockJump = uint16(bound(maxBlockJump, 1, 100));  // 1-100 blocks jump each time
        userCount = 100;  // 1-10 users
        operationCount = 1000;  // 1-20 operations per user
        maxBlockJump = 200; 
        // Create an array to track user addresses and their balances
        address[] memory users = new address[](userCount);
        uint256[] memory deposits = new uint256[](userCount);
        
        // 初始化用户状态
        for(uint8 i = 0; i < userCount; i++) {
            // 从地址 0x1000 开始
            users[i] = address(uint160(0x1000 + i));
            vm.deal(users[i], 100 ether);
            
            vm.startPrank(users[i]);
            token.approve(address(masterChef), type(uint256).max);
            vm.stopPrank();
        }

        // Perform random operations
        for(uint256 i = 0; i < operationCount; i++) {
            // Randomly select a user
            uint256 userIndex = uint256(keccak256(abi.encode(i, "user"))) % userCount;
            address user = users[userIndex];
            
            // Random amount between 0.1 and 5 ETH
            uint256 amount = (uint256(keccak256(abi.encode(i, "amount"))) % 49 + 1) * 0.1 ether;
            
            // Random block jump
            uint256 blockJump = uint256(keccak256(abi.encode(i, "block"))) % maxBlockJump + 1;
            vm.roll(block.number + blockJump);

            // 50% chance to deposit, 50% chance to withdraw
            bool isDeposit = uint256(keccak256(abi.encode(i, "operation"))) % 2 == 0;

            vm.startPrank(user);
            
            if(isDeposit) {
                // Deposit
                try masterChef.deposit{value: amount}(amount) {
                    deposits[userIndex] += amount;
                    console2.log(
                        "User %s deposited: %s ETH, Block: %s",
                        userIndex,
                        amount / 1e18,
                        block.number
                    );
                } catch {
                    console2.log("Deposit failed for user", userIndex);
                }
            } else {
                // Only try to withdraw if user has deposits
                if(deposits[userIndex] > 0) {
                    uint256 withdrawAmount = amount > deposits[userIndex] ? deposits[userIndex] : amount;
                    try masterChef.withdraw(withdrawAmount) {
                        deposits[userIndex] -= withdrawAmount;
                        console2.log(
                            "User %s withdrew: %s ETH, Block: %s",
                            userIndex,
                            withdrawAmount / 1e18,
                            block.number
                        );
                    } catch {
                        console2.log("Withdraw failed for user", userIndex);
                    }
                }
            }
            
            vm.stopPrank();

            // Verify contract state after each operation
            verifyContractState(users, deposits);
        }
    }

    // Helper function to verify contract state
    function verifyContractState(address[] memory users, uint256[] memory deposits) internal {
        uint256 totalDeposits;
        for(uint256 i = 0; i < users.length; i++) {
            // 解构返回值
            (address userAddr, uint256 amount, uint256 rewardDebt,) = masterChef.userInfo(users[i]);
            // 验证用户存款匹配
            assertEq(amount, deposits[i], "User deposit mismatch");
            totalDeposits += deposits[i];
        }
        
        // 验证总存款匹配合约余额
        assertEq(address(masterChef).balance, totalDeposits, "Contract balance mismatch");
        
        // 验证 accEthPerShare 计算
        masterChef.updateAccEthPerShare();
    }

    // Additional helper test to check specific scenarios
    function testFuzz_SpecificScenario(
        uint256 depositAmount,
        uint8 blockJump
    ) public {
        depositAmount = bound(depositAmount, 0.1 ether, 10 ether);
        blockJump = uint8(bound(blockJump, 1, 50));

        address user1 = address(1);
        address user2 = address(2);
        
        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);

        // User 1 deposits
        vm.startPrank(user1);
        masterChef.deposit{value: depositAmount}(depositAmount);
        vm.stopPrank();

        // Move blocks forward
        vm.roll(block.number + blockJump);

        // User 2 deposits
        vm.startPrank(user2);
        masterChef.deposit{value: depositAmount}(depositAmount);
        vm.stopPrank();

        // 验证奖励计算
        (,, uint256 user1RewardDebt,) = masterChef.userInfo(user1);
        (,, uint256 user2RewardDebt,) = masterChef.userInfo(user2);
        
        console2.log("User1 reward debt: %s", user1RewardDebt);
        console2.log("User2 reward debt: %s", user2RewardDebt);
        console2.log("AccEthPerShare: %s", masterChef.accEthPerShare());
    }
} 