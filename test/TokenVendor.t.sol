// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import { Test } from "forge-std/Test.sol";
import { TokenVendor } from "../src/TokenVendor.sol";
import { BlockfulToken } from "../src/BlockfulToken.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";
import { Merkle } from "murky-merkle/src/Merkle.sol";
import { console2 } from "forge-std/console2.sol";

contract TokenVendorTest is Test {
    TokenVendor public vendor;
    BlockfulToken public token;
    address public owner;
    address public user1;
    address public user2;
    uint256 public constant INITIAL_SUPPLY = 1_000_000 * 10 ** 18;
    uint256 public constant TOKEN_PRICE = 100; // 1 ETH = 100 tokens
    uint256 public whitelistStartTime;
    uint256 public publicStartTime;
    bytes32 public merkleRoot;
    Merkle public merkle;

    function setUp() public {
        owner = makeAddr("owner");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        token = new BlockfulToken(INITIAL_SUPPLY);

        // Create a Merkle tree
        merkle = new Merkle();
        bytes32[] memory data = new bytes32[](2);
        data[0] = keccak256(abi.encodePacked(user1));
        data[1] = keccak256(abi.encodePacked(user2));
        merkleRoot = merkle.getRoot(data);

        whitelistStartTime = block.timestamp + 1000;
        publicStartTime = block.timestamp + 2000;

        vendor = new TokenVendor(
            address(token),
            TOKEN_PRICE,
            whitelistStartTime,
            publicStartTime,
            merkleRoot
        );
        token.transfer(address(vendor), INITIAL_SUPPLY);
        vendor.transferOwnership(owner);
    }

    // Deployment tests
    function testInvalidTokenAddress() public {
        vm.expectRevert(TokenVendor.InvalidTokenAddress.selector);
        new TokenVendor(
            address(0),
            TOKEN_PRICE,
            whitelistStartTime,
            publicStartTime,
            merkleRoot
        );
    }

    function testInvalidTokenPrice() public {
        vm.expectRevert(TokenVendor.InvalidTokenPrice.selector);
        new TokenVendor(
            address(token),
            0,
            whitelistStartTime,
            publicStartTime,
            merkleRoot
        );
    }

    function testInvalidStartTimes() public {
        vm.expectRevert(TokenVendor.InvalidStartTimes.selector);
        new TokenVendor(
            address(token),
            TOKEN_PRICE,
            publicStartTime,
            whitelistStartTime,
            merkleRoot
        );
    }

    // Buying tokens tests
    function testBuyTokens() public {
        uint256 ethAmount = 1 ether;
        uint256 expectedTokens = ethAmount * TOKEN_PRICE;

        vm.warp(publicStartTime + 1);
        vm.deal(user1, ethAmount);
        vm.prank(user1);
        vendor.buyTokens{ value: ethAmount }(new bytes32[](0));

        assertEq(token.balanceOf(user1), expectedTokens);
        assertEq(address(vendor).balance, ethAmount);
    }

    function testBuyTokensEvent() public {
        uint256 ethAmount = 1 ether;
        uint256 expectedTokens = ethAmount * TOKEN_PRICE;

        vm.warp(publicStartTime + 1);
        vm.deal(user1, ethAmount);
        vm.prank(user1);

        vm.expectEmit(true, false, false, true);
        emit TokenVendor.TokensPurchased(user1, ethAmount, expectedTokens);
        vendor.buyTokens{ value: ethAmount }(new bytes32[](0));
    }

    function testBuyTokensDuringWhitelist() public {
        uint256 ethAmount = 1 ether;
        uint256 expectedTokens = ethAmount * TOKEN_PRICE;

        bytes32[] memory data = new bytes32[](2);
        data[0] = keccak256(abi.encodePacked(user1));
        data[1] = keccak256(abi.encodePacked(user2));
        bytes32[] memory proof = merkle.getProof(data, 0);

        vm.warp(whitelistStartTime + 1);
        vm.deal(user1, ethAmount);
        vm.prank(user1);
        vendor.buyTokens{ value: ethAmount }(proof);

        assertEq(token.balanceOf(user1), expectedTokens);
        assertEq(address(vendor).balance, ethAmount);
    }

    function testBuyTokensBeforeWhitelist() public {
        uint256 ethAmount = 1 ether;

        bytes32[] memory data = new bytes32[](2);
        data[0] = keccak256(abi.encodePacked(user1));
        data[1] = keccak256(abi.encodePacked(user2));
        bytes32[] memory proof = merkle.getProof(data, 0);

        vm.warp(whitelistStartTime - 1);
        vm.deal(user1, ethAmount);
        vm.prank(user1);
        vm.expectRevert(TokenVendor.SaleNotStarted.selector);
        vendor.buyTokens{ value: ethAmount }(proof);
    }

    function testBuyTokensInsufficientEth() public {
        vm.warp(publicStartTime + 1);
        vm.expectRevert(TokenVendor.InsufficientEth.selector);
        vm.prank(user1);
        vendor.buyTokens{ value: 0 }(new bytes32[](0));
    }

    function testInsufficientTokensInContract() public {
        uint256 ethAmount = 1000 ether;

        // Transfer all tokens out of the vendor
        vm.prank(address(vendor));
        token.transfer(address(this), INITIAL_SUPPLY);

        vm.warp(publicStartTime + 1);
        vm.deal(user1, ethAmount);
        vm.prank(user1);
        vm.expectRevert(TokenVendor.InsufficientTokens.selector);
        vendor.buyTokens{ value: ethAmount }(new bytes32[](0));
    }

    // Selling tokens tests
    function testSellTokens() public {
        uint256 tokenAmount = 100 * 10 ** 18;
        uint256 expectedEth = tokenAmount / TOKEN_PRICE;

        // First, buy some tokens
        vm.warp(publicStartTime + 1);
        vm.deal(user1, 1 ether);
        vm.startPrank(user1);
        vendor.buyTokens{ value: 1 ether }(new bytes32[](0));

        // Approve vendor to spend tokens
        token.approve(address(vendor), tokenAmount);

        // Sell tokens
        uint256 initialBalance = user1.balance;
        vendor.sellTokens(tokenAmount);
        vm.stopPrank();

        assertEq(token.balanceOf(user1), 0);
        assertEq(user1.balance - initialBalance, expectedEth);
    }

    function testSellTokensEvent() public {
        uint256 tokenAmount = 100 * 10 ** 18;
        uint256 expectedEth = tokenAmount / TOKEN_PRICE;

        // First, buy some tokens
        vm.warp(publicStartTime + 1);
        vm.deal(user1, 1 ether);
        vm.startPrank(user1);
        vendor.buyTokens{ value: 1 ether }(new bytes32[](0));

        // Approve vendor to spend tokens
        token.approve(address(vendor), tokenAmount);

        // Sell tokens
        vm.expectEmit(true, false, false, true);
        emit TokenVendor.TokensSold(user1, tokenAmount, expectedEth);
        vendor.sellTokens(tokenAmount);
        vm.stopPrank();
    }

    function testSellTokensZeroAmount() public {
        vm.expectRevert(TokenVendor.ZeroAmount.selector);
        vm.prank(user1);
        vendor.sellTokens(0);
    }

    function testInsufficientEthInContractDuringSell() public {
        uint256 tokenAmount = 100 * 10 ** 18;

        vm.warp(publicStartTime + 1);
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        vendor.buyTokens{ value: 1 ether }(new bytes32[](0));

        vm.prank(owner);
        vendor.withdraw();

        vm.startPrank(user1);
        token.approve(address(vendor), tokenAmount);
        vm.expectRevert(TokenVendor.InsufficientEthInContract.selector);
        vendor.sellTokens(tokenAmount);
        vm.stopPrank();
    }

    // Withdraw tests
    function testWithdraw() public {
        uint256 ethAmount = 1 ether;

        // First, buy some tokens to add ETH to the vendor
        vm.warp(publicStartTime + 1);
        vm.deal(user1, ethAmount);
        vm.prank(user1);
        vendor.buyTokens{ value: ethAmount }(new bytes32[](0));

        // Withdraw ETH
        uint256 initialBalance = owner.balance;
        vm.prank(owner);
        vendor.withdraw();

        assertEq(owner.balance - initialBalance, ethAmount);
        assertEq(address(vendor).balance, 0);
    }

    function testWithdrawEvent() public {
        uint256 ethAmount = 1 ether;

        // First, buy some tokens to add ETH to the vendor
        vm.warp(publicStartTime + 1);
        vm.deal(user1, ethAmount);
        vm.prank(user1);
        vendor.buyTokens{ value: ethAmount }(new bytes32[](0));

        // Withdraw ETH
        vm.expectEmit(true, false, false, true);
        emit TokenVendor.EthWithdrawn(owner, ethAmount);
        vm.prank(owner);
        vendor.withdraw();
    }

    function testWithdrawNoEth() public {
        vm.expectRevert(TokenVendor.NoEthToWithdraw.selector);
        vm.prank(owner);
        vendor.withdraw();
    }

    // Pause and unpause tests
    function testPauseAndUnpause() public {
        vm.startPrank(owner);
        vendor.pause();
        assertTrue(vendor.paused());
        vendor.unpause();
        assertFalse(vendor.paused());
        vm.stopPrank();
    }

    function testBuyTokensWhenPaused() public {
        vm.prank(owner);
        vendor.pause();
        uint256 ethAmount = 1 ether;

        vm.warp(publicStartTime + 1);
        vm.deal(user1, ethAmount);
        vm.expectRevert(Pausable.EnforcedPause.selector);
        vm.prank(user1);
        vendor.buyTokens{ value: ethAmount }(new bytes32[](0));
    }

    function testSellTokensWhenPaused() public {
        vm.prank(owner);
        vendor.pause();

        vm.expectRevert(Pausable.EnforcedPause.selector);
        vm.prank(user1);
        vendor.sellTokens(100 * 10 ** 18);
    }

    function testOnlyOwnerCanPause() public {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user1));
        vm.prank(user1);
        vendor.pause();
    }

    function testOnlyOwnerCanUnpause() public {
        vm.prank(owner);
        vendor.pause();

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user1));
        vm.prank(user1);
        vendor.unpause();
    }

    // Miscellaneous tests
    function testDirectEthTransfer() public {
        vm.expectRevert(TokenVendor.DirectEthTransfer.selector);
        address(vendor).call{value: 1 ether}("");
    }

    function testEthTransferFailureDuringSell() public {
        uint256 tokenAmount = 100 * 10 ** 18;

        vm.warp(publicStartTime + 1);
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        vendor.buyTokens{ value: 1 ether }(new bytes32[](0));

        MaliciousContract malicious = new MaliciousContract();

        vm.prank(user1);
        token.transfer(address(malicious), tokenAmount);

        vm.startPrank(address(malicious));
        token.approve(address(vendor), tokenAmount);
        vm.expectRevert(TokenVendor.EthTransferFailed.selector);
        vendor.sellTokens(tokenAmount);
        vm.stopPrank();
    }

    function testEthTransferFailureDuringWithdraw() public {
        vm.warp(publicStartTime + 1);
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        vendor.buyTokens{ value: 1 ether }(new bytes32[](0));

        MaliciousContract malicious = new MaliciousContract();
        vm.prank(owner);
        vendor.transferOwnership(address(malicious));

        vm.prank(address(malicious));
        vm.expectRevert(TokenVendor.EthTransferFailed.selector);
        vendor.withdraw();
    }
}

// Helper contract that rejects ETH transfers
contract MaliciousContract {
    fallback() external payable {
        revert("ETH transfer rejected");
    }

    receive() external payable {
        revert("ETH transfer rejected");
    }
}
