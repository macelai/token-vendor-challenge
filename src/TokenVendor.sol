// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/// @title TokenVendor
/// @notice A contract for buying and selling tokens with whitelist and timed sales
/// @dev Implements ReentrancyGuard, Ownable, and Pausable for enhanced security
contract TokenVendor is ReentrancyGuard, Ownable, Pausable {
    using SafeERC20 for IERC20;

    IERC20 public immutable TOKEN;
    uint256 public immutable TOKENS_PER_ETH;
    uint256 public immutable WHITELIST_START_TIME;
    uint256 public immutable PUBLIC_START_TIME;
    bytes32 public immutable MERKLE_ROOT;

    event TokensPurchased(address indexed buyer, uint256 amountOfETH, uint256 amountOfTokens);
    event TokensSold(address indexed seller, uint256 amountOfTokens, uint256 amountOfETH);
    event EthWithdrawn(address indexed owner, uint256 amount);

    error InvalidTokenAddress();
    error InvalidTokenPrice();
    error InsufficientEth();
    error InsufficientTokens();
    error InsufficientEthInContract();
    error NoEthToWithdraw();
    error ZeroAmount();
    error EthTransferFailed();
    error DirectEthTransfer();
    error SaleNotStarted();
    error NotWhitelisted();
    error InvalidStartTimes();

    /// @notice Initializes the TokenVendor contract
    /// @param _token Address of the ERC20 token
    /// @param _tokensPerEth Exchange rate of tokens per ETH
    /// @param _whitelistStartTime Timestamp when the whitelist sale starts
    /// @param _publicStartTime Timestamp when the public sale starts
    /// @param _merkleRoot Merkle root of the whitelist
    constructor(
        address _token,
        uint256 _tokensPerEth,
        uint256 _whitelistStartTime,
        uint256 _publicStartTime,
        bytes32 _merkleRoot
    ) Ownable(msg.sender) {
        if (_token == address(0)) revert InvalidTokenAddress();
        if (_tokensPerEth == 0) revert InvalidTokenPrice();
        if (_whitelistStartTime >= _publicStartTime) revert InvalidStartTimes();
        TOKEN = IERC20(_token);
        TOKENS_PER_ETH = _tokensPerEth;
        WHITELIST_START_TIME = _whitelistStartTime;
        PUBLIC_START_TIME = _publicStartTime;
        MERKLE_ROOT = _merkleRoot;
    }

    /// @notice Allows users to buy tokens with ETH
    /// @param _proof Merkle proof for whitelist verification
    function buyTokens(bytes32[] calldata _proof) public payable nonReentrant whenNotPaused {
        if (msg.value == 0) revert InsufficientEth();

        if (block.timestamp < WHITELIST_START_TIME) {
            revert SaleNotStarted();
        } else if (block.timestamp < PUBLIC_START_TIME) {
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            if (!MerkleProof.verify(_proof, MERKLE_ROOT, leaf)) revert NotWhitelisted();
        }

        uint256 tokenAmount = msg.value * TOKENS_PER_ETH;
        if (TOKEN.balanceOf(address(this)) < tokenAmount) revert InsufficientTokens();

        TOKEN.safeTransfer(msg.sender, tokenAmount);
        emit TokensPurchased(msg.sender, msg.value, tokenAmount);
    }

    /// @notice Allows users to sell tokens for ETH
    /// @param _amount Amount of tokens to sell
    function sellTokens(uint256 _amount) public nonReentrant whenNotPaused {
        if (_amount == 0) revert ZeroAmount();
        uint256 ethAmount = _amount / TOKENS_PER_ETH;
        if (address(this).balance < ethAmount) revert InsufficientEthInContract();

        TOKEN.safeTransferFrom(msg.sender, address(this), _amount);
        (bool sent,) = payable(msg.sender).call{ value: ethAmount }("");
        if (!sent) revert EthTransferFailed();
        emit TokensSold(msg.sender, _amount, ethAmount);
    }

    /// @notice Allows the owner to withdraw ETH from the contract
    /// @dev Only callable by the contract owner
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        if (balance == 0) revert NoEthToWithdraw();

        (bool sent,) = payable(owner()).call{ value: balance }("");
        if (!sent) revert EthTransferFailed();
        emit EthWithdrawn(owner(), balance);
    }

    /// @notice Pauses the contract
    /// @dev Only callable by the contract owner
    function pause() public onlyOwner {
        _pause();
    }

    /// @notice Unpauses the contract
    /// @dev Only callable by the contract owner
    function unpause() public onlyOwner {
        _unpause();
    }

    /// @dev Prevents accidental ETH transfers to the contract
    fallback() external payable {
        revert DirectEthTransfer();
    }

    /// @dev Prevents accidental ETH transfers to the contract
    receive() external payable {
        revert DirectEthTransfer();
    }
}
