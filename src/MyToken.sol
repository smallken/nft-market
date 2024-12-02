// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/Address.sol";
// lib/openzeppelin-contracts/contracts/
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {Test, console2} from "forge-std/Test.sol";
import {MTokenInterface} from "./interfaces/MTokenInterface.sol";
// 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
// privateKey: 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
/**
 * Deployer: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
 * Deployed to: 0x5FbDB2315678afecb367f032d93F642f64180aa3
 * Transaction hash: 0x10252fcb517e3bfe387ea04d82acaf448bb8b74a6ac90ccbf9d7dfde530c5335
 */

interface TokenRecipient {
    function tokensReceived(address sender, uint256 amount) external returns (bool);
}

contract MyToken is ERC20Permit {
    using Address for address;

    address owner;

    constructor() ERC20("Dragon", "DRG") ERC20Permit("Dragon") {
        _mint(msg.sender, 100000000 * 10 ** 18);
        owner = msg.sender;
    }

    function transferWithCallback(address recipient, uint256 amount) external returns (bool) {
        _transfer(msg.sender, recipient, amount);
        if (recipient.code.length > 0) {
            bool rv = TokenRecipient(recipient).tokensReceived(msg.sender, amount);
            require(rv, "No tokensReceived");
        }
        return true;
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function getBlockNumber() virtual internal view returns (uint) {
        return block.number;
    }

    // function accrueInterest() virtual override public returns (uint) {
        //用的是简化版的计息，Compound的是比较复杂的
        // uint currentBlock = getBlockNumber();
        // if (accrualBlockNumber == currentBlock) {
        //     return NO_ERROR;
        // }
        // 获取当前借贷池剩余现金流
      //  uint cashPrior = getCashPrior();
        // 根据现金流、总借款totalBorrows，总储备金totalReserves， 从利率模型中获取区块利率
       // uint borrowRateOneBlock = getBorrowRate(cashPrior, totalBorrows, totalReserves);
        // 计算从上次计息到当前时刻的区间利率
      //  uint borrowRate = borrowRateOneBlock * (currentBlock - accrualBlockNumber);
        // 更新总借款
        //totalBorrows = totalBorrows*(1+borrowRate);
        // 更新总储备金
        //totalReserves = totalReserves + borrowRate*totalBorrows*reserveFactorMantissa;
        //borrowIndex = borrowIndex*(1+borrowRate);
       // accrualBlockNumber = currentBlock;
                /* We emit an AccrueInterest event */
        //emit AccrueInterest(cashPrior, borrowIndex, totalBorrows, totalReserves);

        // return NO_ERROR;
    //}
}
