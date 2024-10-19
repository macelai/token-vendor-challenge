// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import { Script } from "forge-std/Script.sol";
import { console2 } from "forge-std/console2.sol";
import { Merkle } from "murky-merkle/src/Merkle.sol";

contract GenerateMerkleProof is Script {
    function run() public {
        Merkle merkle = new Merkle();

        // TODO: load from file
        address[] memory addresses = new address[](2);
        addresses[0] = 0x97CcF8F927045E4C5f936832d14904A68e595380;
        addresses[1] = 0x6B2760f5C87add9d2f2AB99bb0F3afEF8ec27B42;

        bytes32[] memory data = new bytes32[](addresses.length);
        for (uint256 i = 0; i < addresses.length; i++) {
            data[i] = keccak256(abi.encodePacked(addresses[i]));
        }

        bytes32 merkleRoot = merkle.getRoot(data);
        console2.log("Merkle Root:");
        console2.logBytes32(merkleRoot);

        // TODO: write to file to be used on frontend
        for (uint256 i = 0; i < addresses.length; i++) {
            bytes32[] memory proof = merkle.getProof(data, i);
            console2.log("Proof for address", addresses[i]);
            for (uint256 j = 0; j < proof.length; j++) {
                console2.logBytes32(proof[j]);
            }
            console2.log(""); // Empty line for readability
        }
    }
}
