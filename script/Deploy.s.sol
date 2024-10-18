// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import { BlockfulToken } from "../src/BlockfulToken.sol";
import { TokenVendor } from "../src/TokenVendor.sol";
import { BaseScript } from "./Base.s.sol";
import { Merkle } from "murky-merkle/src/Merkle.sol";

/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting
contract Deploy is BaseScript {
    function run() public broadcast returns (BlockfulToken token, TokenVendor vendor) {
        uint256 INITIAL_SUPPLY = 1_000_000 * 10 ** 18;
        uint256 WHITELIST_START_TIME = block.timestamp + 1 days;
        uint256 PUBLIC_START_TIME = WHITELIST_START_TIME + 1 days;

        token = new BlockfulToken(INITIAL_SUPPLY);

        // Create a Merkle tree
        Merkle merkle = new Merkle();
        bytes32[] memory data = new bytes32[](2);
        data[0] = keccak256(abi.encodePacked(address(0x1234))); // Replace with actual addresses
        data[1] = keccak256(abi.encodePacked(address(0x5678))); // Replace with actual addresses
        bytes32 merkleRoot = merkle.getRoot(data);

        vendor = new TokenVendor(address(token), INITIAL_SUPPLY, WHITELIST_START_TIME, PUBLIC_START_TIME, merkleRoot);

        token.transfer(address(vendor), INITIAL_SUPPLY);
    }
}
