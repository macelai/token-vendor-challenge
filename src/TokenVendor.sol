// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import { ITokenVendorEventsAndErrors } from "./interfaces/ITokenVendorEventsAndErrors.sol";

/// @title TokenVendor with Dynamic Pricing
/// @notice A contract for buying and selling tokens with whitelist, timed sales, and dynamic pricing
/// @dev Implements ReentrancyGuard, Ownable, and Pausable for enhanced security
contract TokenVendor is ReentrancyGuard, Ownable, Pausable, ITokenVendorEventsAndErrors {
    using SafeERC20 for IERC20;

    IERC20 public immutable TOKEN;
    uint256 public immutable INITIAL_SUPPLY;
    uint256 public immutable WHITELIST_START_TIME;
    uint256 public immutable PUBLIC_START_TIME;
    bytes32 public immutable MERKLE_ROOT;

    uint256 public constant INITIAL_PRICE = 1e15; // 0.001 ETH initial price
    uint256 public constant PRICE_INCREMENT = 1e14; // 0.0001 ETH price increment per token sold

    /// @notice Initializes the TokenVendor contract
    /// @param _token Address of the ERC20 token
    /// @param _initialSupply Initial supply of tokens to be sold
    /// @param _whitelistStartTime Timestamp when the whitelist sale starts
    /// @param _publicStartTime Timestamp when the public sale starts
    /// @param _merkleRoot Merkle root of the whitelist
    constructor(
        address _token,
        uint256 _initialSupply,
        uint256 _whitelistStartTime,
        uint256 _publicStartTime,
        bytes32 _merkleRoot
    )
        Ownable(msg.sender)
    {
        if (_token == address(0)) revert InvalidTokenAddress();
        if (_initialSupply == 0) revert InvalidInitialSupply();
        if (_whitelistStartTime >= _publicStartTime) revert InvalidStartTimes();
        TOKEN = IERC20(_token);
        INITIAL_SUPPLY = _initialSupply;
        WHITELIST_START_TIME = _whitelistStartTime;
        PUBLIC_START_TIME = _publicStartTime;
        MERKLE_ROOT = _merkleRoot;
    }

    /// @notice Gets the current price of tokens
    /// @return The current price of tokens
    function getCurrentPrice() public view returns (uint256) {
        uint256 soldTokens = INITIAL_SUPPLY - TOKEN.balanceOf(address(this));
        return INITIAL_PRICE + (PRICE_INCREMENT * soldTokens / 1e18);
    }

    /// @notice Calculates the token amount for a given ETH amount (for buying)
    /// @param _ethAmount The ETH amount
    /// @return The token amount
    function calculateTokenAmountForBuying(uint256 _ethAmount) public view returns (uint256) {
        uint256 remainingSupply = TOKEN.balanceOf(address(this));
        uint256 soldTokens = INITIAL_SUPPLY - remainingSupply;

        // Solve quadratic equation: 0 = a*n^2 + b*n + c
        // Where n is the number of tokens to buy
        uint256 a = PRICE_INCREMENT;
        uint256 b = 2 * (INITIAL_PRICE + PRICE_INCREMENT * soldTokens / 1e18) - PRICE_INCREMENT;
        int256 c = -2 * int256(_ethAmount);

        // Calculate discriminant
        uint256 discriminant = b * b + 4 * a * uint256(-c);
        uint256 sqrtDiscriminant = sqrt(discriminant);

        // Calculate n using quadratic formula, rounding down and scaling up to ETH decimals
        uint256 n = (sqrtDiscriminant - b) / (2 * a) * 1e18;
        // Ensure we don't exceed remaining supply
        return n > remainingSupply ? remainingSupply : n;
    }

    /// @notice Calculates the ETH amount received for selling a given token amount
    /// @param _tokenAmount The amount of tokens to sell
    /// @return The ETH amount to be received
    function calculateEthAmountForSelling(uint256 _tokenAmount) public view returns (uint256) {
        uint256 currentSupply = TOKEN.balanceOf(address(this));
        uint256 soldTokens = INITIAL_SUPPLY - currentSupply;

        // Ensure we don't exceed current supply
        uint256 tokensToSell = _tokenAmount > currentSupply ? currentSupply : _tokenAmount;

        // Calculate the first term of the arithmetic progression (current price)
        uint256 a1 = INITIAL_PRICE + (PRICE_INCREMENT * (soldTokens - 1e18) / 1e18);

        // Calculate the last term of the arithmetic progression (price decrements)
        uint256 an = a1 - (PRICE_INCREMENT * (tokensToSell - 1e18) / 1e18);

        // Use the arithmetic progression sum formula: S = n * (a1 + an) / 2
        uint256 ethAmount = (tokensToSell / 2) * (a1 + an);

        // Scale down to ETH decimals
        uint256 scaledEthAmount = ethAmount / 1e18;

        return scaledEthAmount;
    }

    /// @notice Allows users to buy tokens with ETH
    /// @param _proof Merkle proof for whitelist verification
    function buyTokens(bytes32[] calldata _proof) public payable nonReentrant whenNotPaused {
        if (msg.value == 0) revert InsufficientEth();
        _checkSaleStatus(_proof);

        uint256 tokenAmount = calculateTokenAmountForBuying(msg.value);
        if (tokenAmount == 0) revert InsufficientTokens();
        if (TOKEN.balanceOf(address(this)) < tokenAmount) revert InsufficientTokens();

        TOKEN.safeTransfer(msg.sender, tokenAmount);

        uint256 ethCost = calculateEthAmountForSelling(tokenAmount);
        uint256 excessEth = msg.value - ethCost;
        if (excessEth > 0) {
            _safeTransferETH(msg.sender, excessEth);
        }

        emit TokensPurchased(msg.sender, ethCost, tokenAmount);
    }

    /// @notice Allows users to sell tokens for ETH
    /// @param _amount Amount of tokens to sell
    function sellTokens(uint256 _amount) public nonReentrant whenNotPaused {
        if (_amount == 0) revert ZeroAmount();
        uint256 ethAmount = calculateEthAmountForSelling(_amount);
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
        _safeTransferETH(owner(), balance);
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

    /// @dev Checks the current sale status and user's eligibility
    /// @param _proof Merkle proof for whitelist verification
    function _checkSaleStatus(bytes32[] calldata _proof) internal view {
        if (block.timestamp < WHITELIST_START_TIME) {
            revert SaleNotStarted();
        } else if (block.timestamp < PUBLIC_START_TIME) {
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            if (!MerkleProof.verify(_proof, MERKLE_ROOT, leaf)) revert NotWhitelisted();
        }
    }

    /// @dev Safely transfers ETH to the specified address
    /// @param to The address to transfer ETH to
    /// @param amount The amount of ETH to transfer
    function _safeTransferETH(address to, uint256 amount) internal {
        (bool sent,) = payable(to).call{ value: amount }("");
        if (!sent) revert EthTransferFailed();
    }

    /// @dev Prevents accidental ETH transfers to the contract
    fallback() external payable {
        revert DirectEthTransfer();
    }

    /// @dev Prevents accidental ETH transfers to the contract
    receive() external payable {
        revert DirectEthTransfer();
    }

    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}
