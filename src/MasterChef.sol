// SPDX-License-Identifier: MIT

pragma solidity  ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
interface IToken is IERC20 {
    function mint(address _to, uint256 _amount) external;
}
import {Test, console2} from "forge-std/Test.sol";


contract MasterChef is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    // Info of each user.
    struct UserInfo {
        address userAddr;
        uint256 amount;     
        uint256 rewardDebt; 
        uint64 lastUpdate; 
    }
   
    // NFT plateform TOKEN!
    IToken public myToken;
    // Block number when bonus SUSHI period ends.
    // uint256 public bonusEndBlock;
    // SUSHI tokens created per block.
    uint256 public tokenPerBlock;
    // Bonus muliplier for early sushi makers.
    uint256 public constant BONUS_MULTIPLIER = 10;
    // 积分,1个ETH有多少积分
    uint256 public accEthPerShare;
    // 上次更新积分的时间
    uint256 public lastRewardBlock;
    // Info of each user that stakes LP tokens.
    mapping(address => UserInfo) public userInfo;    
    // The block number when SUSHI mining starts.
    uint256 public startBlock;
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 amount
    );


    constructor(
        IToken _myToken,
        uint256 _tokenPerBlock,
        uint256 _startBlock
    ) Ownable(msg.sender) {
        myToken = _myToken;
        tokenPerBlock = _tokenPerBlock;
        startBlock = _startBlock;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to)
        public
        pure
        returns (uint256)
    {
        return _to - _from;
    }

    function updateAccEthPerShare() public {
        if (block.number <= lastRewardBlock) {
            return;
        }
        // 返回当前合约的ETH数量
        uint256 ethBalance = address(this).balance;
        if (ethBalance == 0) {
            lastRewardBlock = block.number;
            return;
        }
        // 获取乘数
        uint256 multiplier = getMultiplier(lastRewardBlock, block.number);
        uint256 tokenReward =
            multiplier * tokenPerBlock  ;
            // multiplier.mul(tokenPerBlock);
        console2.log("tokenReward: %s", tokenReward / 1e18);
        myToken.mint(address(this), tokenReward);
        uint256 newReward = (tokenReward * 1e12);
        require(newReward / 1e12 == tokenReward, "Overflow in reward calculation");
        require(ethBalance != 0, "Division by zero");
        // 本来tokenReward是1e18,1e18除以1e18,可能会丧失精度
        accEthPerShare = accEthPerShare + (newReward / ethBalance);
        console2.log("ethBalance:", ethBalance / 1e18);
        console2.log("accEthPerSharea: %s", accEthPerShare / 1e12);
        console2.log("lastRewardBlock: %s", lastRewardBlock / 1e12);
        lastRewardBlock = block.number;
    }

    // Deposit LP tokens to MasterChef for SUSHI allocation.
    function deposit(uint256 _amount) public payable{
        // 结构体就可以这样操作，如果映射有，就获取地址对应的映射；没有就创建这样的映射，并创建结构体，赋默认的值。
        UserInfo storage user = userInfo[msg.sender];
        console2.log("user:", user.userAddr);
        console2.log("user amount:", user.amount / 1e18);
        require(msg.value > 0, "deposit: no eth");
        if ( user.userAddr == address(0)) {
            user.userAddr = msg.sender;
        }
        updateAccEthPerShare();
        if (user.amount > 0) {
            uint256 pending =
                user.amount * accEthPerShare /1e12 -
                    user.rewardDebt ;
        console2.log("pending: %s pen", pending / 1e18);
            // 如果之前存入过，先把利息转给用户。
            myToken.transfer(msg.sender, pending);
        }
        user.amount = user.amount + _amount;
        user.rewardDebt = user.amount * accEthPerShare / 1e12 ;
        console2.log("user.rewardDebt: %s", user.rewardDebt / 1e18);
        console2.log("after deposit user amount:", user.amount / 1e18);
        console2.log("adfer deposit user addr:", user.userAddr);
        emit Deposit(msg.sender, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _amount) external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        require(user.userAddr == msg.sender, "withdraw: not owner");
        updateAccEthPerShare();
        uint256 pending =
            user.amount * accEthPerShare /1e12  -
                user.rewardDebt
            ;
        safeSushiTransfer(msg.sender, pending);
        user.amount = user.amount - _amount;
        // 哦，这里原来是把剩下的算积分；也就是用户不一定把全部取出
        user.rewardDebt = user.amount * accEthPerShare / 1e12 ;
        (bool success,) = msg.sender.call{value: _amount}("");
        require(success, "ETH transfer failed");
        emit Withdraw(msg.sender, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw() public nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        require(msg.sender == user.userAddr, "emergencyWithdraw: only owner can withdraw");
        (bool success, ) = msg.sender.call{value: user.amount}("");
        require(success, "ETH transfer failed");
        emit EmergencyWithdraw(msg.sender, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }

    // Safe sushi transfer function, just in case if rounding error causes pool to not have enough SUSHIs.
    function safeSushiTransfer(address _to, uint256 _amount) internal {
        uint256 sushiBal = myToken.balanceOf(address(this));
        if (_amount > sushiBal) {
            myToken.transfer(_to, sushiBal);
        } else {
            myToken.transfer(_to, _amount);
        }
    }

    receive() external payable {}

}
