// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import { Test } from "forge-std/Test.sol";

import { TokenVendor } from "../src/TokenVendor.sol";
import { BlockfulToken } from "../src/BlockfulToken.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";

contract TokenVendorTest is Test {
    TokenVendor public vendor;
    BlockfulToken public token;
    address public owner;
    address public user1;
    uint256 public constant INITIAL_SUPPLY = 1_000_000 * 10 ** 18;
    uint256 public constant TOKEN_PRICE = 100; // 1 ETH = 100 tokens

    function setUp() public {
        owner = makeAddr("owner");
        user1 = makeAddr("user1");
        token = new BlockfulToken(INITIAL_SUPPLY);
        vendor = new TokenVendor(address(token), TOKEN_PRICE);
        token.transfer(address(vendor), INITIAL_SUPPLY);
        vendor.transferOwnership(owner);
    }

    function testBuyTokens() public {
        uint256 ethAmount = 1 ether;
        uint256 expectedTokens = ethAmount * TOKEN_PRICE;

        // Add ETH to the user
        vm.deal(user1, ethAmount);
        // Impersonate the user
        vm.prank(user1);
        vendor.buyTokens{ value: ethAmount }();

        assertEq(token.balanceOf(user1), expectedTokens);
        assertEq(address(vendor).balance, ethAmount);
    }

    function testSellTokens() public {
        uint256 tokenAmount = 100 * 10 ** 18;
        uint256 expectedEth = tokenAmount / TOKEN_PRICE;

        // First, buy some tokens
        vm.deal(user1, 1 ether);
        vm.startPrank(user1);
        vendor.buyTokens{ value: 1 ether }();

        // Approve vendor to spend tokens
        token.approve(address(vendor), tokenAmount);

        // Sell tokens
        uint256 initialBalance = user1.balance;
        vendor.sellTokens(tokenAmount);
        vm.stopPrank();

        assertEq(token.balanceOf(user1), 0);
        assertEq(user1.balance - initialBalance, expectedEth);
    }

    function testWithdraw() public {
        uint256 ethAmount = 1 ether;

        // First, buy some tokens to add ETH to the vendor
        vm.deal(user1, ethAmount);
        vm.prank(user1);
        vendor.buyTokens{ value: ethAmount }();

        // Withdraw ETH
        uint256 initialBalance = owner.balance;
        vm.prank(owner);
        vendor.withdraw();

        assertEq(owner.balance - initialBalance, ethAmount);
        assertEq(address(vendor).balance, 0);
    }

    function testBuyTokensEvent() public {
        uint256 ethAmount = 1 ether;
        uint256 expectedTokens = ethAmount * TOKEN_PRICE;

        vm.deal(user1, ethAmount);
        vm.prank(user1);

        vm.expectEmit(true, false, false, true);
        emit TokenVendor.TokensPurchased(user1, ethAmount, expectedTokens);
        vendor.buyTokens{ value: ethAmount }();
    }

    function testSellTokensEvent() public {
        uint256 tokenAmount = 100 * 10 ** 18;
        uint256 expectedEth = tokenAmount / TOKEN_PRICE;

        // First, buy some tokens
        vm.deal(user1, 1 ether);
        vm.startPrank(user1);
        vendor.buyTokens{ value: 1 ether }();

        // Approve vendor to spend tokens
        token.approve(address(vendor), tokenAmount);

        // Sell tokens
        vm.expectEmit(true, false, false, true);
        emit TokenVendor.TokensSold(user1, tokenAmount, expectedEth);
        vendor.sellTokens(tokenAmount);
        vm.stopPrank();
    }

    function testWithdrawEvent() public {
        uint256 ethAmount = 1 ether;

        // First, buy some tokens to add ETH to the vendor
        vm.deal(user1, ethAmount);
        vm.prank(user1);
        vendor.buyTokens{ value: ethAmount }();

        // Withdraw ETH
        vm.expectEmit(true, false, false, true);
        emit TokenVendor.EthWithdrawn(owner, ethAmount);
        vm.prank(owner);
        vendor.withdraw();
    }

    function testPause() public {
        vm.prank(owner);
        vendor.pause();
        assertTrue(vendor.paused());
    }

    function testUnpause() public {
        vm.startPrank(owner);
        vendor.pause();
        vendor.unpause();
        vm.stopPrank();
        assertFalse(vendor.paused());
    }

    function testBuyTokensWhenPaused() public {
        vm.prank(owner);
        vendor.pause();
        uint256 ethAmount = 1 ether;

        vm.deal(user1, ethAmount);
        vm.expectRevert(Pausable.EnforcedPause.selector);
        vm.prank(user1);
        vendor.buyTokens{ value: 1 ether }();
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

    function testBuyTokensInsufficientEth() public {
        vm.expectRevert(TokenVendor.InsufficientEth.selector);
        vm.prank(user1);
        vendor.buyTokens{ value: 0 }();
    }

    function testSellTokensZeroAmount() public {
        vm.expectRevert(TokenVendor.ZeroAmount.selector);
        vm.prank(user1);
        vendor.sellTokens(0);
    }

    function testWithdrawNoEth() public {
        vm.expectRevert(TokenVendor.NoEthToWithdraw.selector);
        vm.prank(owner);
        vendor.withdraw();
    }

    function testDirectEthTransfer() public {
        vm.expectRevert(TokenVendor.DirectEthTransfer.selector);
        address(vendor).call{ value: 1 ether }("");
    }
}
