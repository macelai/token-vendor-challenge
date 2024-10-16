// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { BlockfulToken } from "../src/BlockfulToken.sol";
import { TokenVendor } from "../src/TokenVendor.sol";

import { BaseScript } from "./Base.s.sol";

/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting
contract Deploy is BaseScript {
    function run() public broadcast returns (BlockfulToken token, TokenVendor vendor) {
        token = new BlockfulToken(100 ether, address(vendor));
        vendor = new TokenVendor(address(token), 0.001 ether);
    }
}
