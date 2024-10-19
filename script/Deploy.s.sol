// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import { BlockfulToken } from "../src/BlockfulToken.sol";
import { TokenVendor } from "../src/TokenVendor.sol";
import { BaseScript } from "./Base.s.sol";
import { Merkle } from "murky-merkle/src/Merkle.sol";

contract Deploy is BaseScript {
    function run() public broadcast returns (BlockfulToken token, TokenVendor vendor) {
        uint256 INITIAL_SUPPLY = 1_000_000 * 10 ** 18;
        uint256 WHITELIST_START_TIME = block.timestamp;
        uint256 PUBLIC_START_TIME = WHITELIST_START_TIME + 1 hours;

        token = new BlockfulToken(INITIAL_SUPPLY);

        // Create a Merkle tree
        Merkle merkle = new Merkle();
        bytes32[] memory data = new bytes32[](2);
        data[0] = keccak256(abi.encodePacked(address(0x97CcF8F927045E4C5f936832d14904A68e595380)));
        data[1] = keccak256(abi.encodePacked(address(0x6B2760f5C87add9d2f2AB99bb0F3afEF8ec27B42)));
        bytes32 merkleRoot = merkle.getRoot(data);

        vendor = new TokenVendor(address(token), INITIAL_SUPPLY, WHITELIST_START_TIME, PUBLIC_START_TIME, merkleRoot);

        token.transfer(address(vendor), INITIAL_SUPPLY);
    }
}
