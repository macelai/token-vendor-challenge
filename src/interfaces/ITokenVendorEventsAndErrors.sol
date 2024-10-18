// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

/**
 * @notice TokenVendorEventsAndErrors contains errors and events
 *         related to TokenVendor interaction.
 */
interface ITokenVendorEventsAndErrors {
    /**
     * @dev Emit an event when tokens are purchased.
     */
    event TokensPurchased(address indexed buyer, uint256 amountOfETH, uint256 amountOfTokens);

    /**
     * @dev Emit an event when tokens are sold.
     */
    event TokensSold(address indexed seller, uint256 amountOfTokens, uint256 amountOfETH);

    /**
     * @dev Emit an event when ETH is withdrawn by the owner.
     */
    event EthWithdrawn(address indexed owner, uint256 amount);

    /**
     * @dev Revert with an error when an invalid token address is provided.
     */
    error InvalidTokenAddress();

    /**
     * @dev Revert with an error when insufficient ETH is sent.
     */
    error InsufficientEth();

    /**
     * @dev Revert with an error when there are insufficient tokens in the contract.
     */
    error InsufficientTokens();

    /**
     * @dev Revert with an error when there is insufficient ETH in the contract.
     */
    error InsufficientEthInContract();

    /**
     * @dev Revert with an error when there is no ETH to withdraw.
     */
    error NoEthToWithdraw();

    /**
     * @dev Revert with an error when a zero amount is provided.
     */
    error ZeroAmount();

    /**
     * @dev Revert with an error when an ETH transfer fails.
     */
    error EthTransferFailed();

    /**
     * @dev Revert with an error when a direct ETH transfer to the contract is attempted.
     */
    error DirectEthTransfer();

    /**
     * @dev Revert with an error when the sale has not started.
     */
    error SaleNotStarted();

    /**
     * @dev Revert with an error when the user is not whitelisted.
     */
    error NotWhitelisted();

    /**
     * @dev Revert with an error when invalid start times are provided.
     */
    error InvalidStartTimes();

    /**
     * @dev Revert with an error when an invalid initial supply is provided.
     */
    error InvalidInitialSupply();
}
