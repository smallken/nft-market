// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TToken is ERC20 {
    constructor() ERC20("Token", "TKN") {
        _mint(msg.sender, 100000000 * 10 ** 18);
    }


}