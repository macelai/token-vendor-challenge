// SPDX-License-Identifier: UNLICENSED

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

pragma solidity >=0.8.25;

contract BlockfulToken is ERC20 {

    constructor(uint256 initialSupply, address tokenVendor) ERC20("BlockfulToken", "BFT") {
        _mint(tokenVendor, initialSupply);
    }
}
