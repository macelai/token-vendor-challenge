// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

contract TokenVendor {
    event TokensPurchased(address buyer, uint256 amountOfETH, uint256 amountOfTokens);
    event TokensSold(address seller, uint256 amountOfTokens, uint256 amountOfETH);
    event EthWithdrawn(address owner, uint256 amount);

    constructor(address _token, uint256 _tokenPrice) { }

    function buyTokens() public payable {
        // Implement buying logic
    }

    function sellTokens(uint256 _amount) public {
        // Implement selling logic
    }

    function withdraw() public {
        // Implement withdrawal logic
    }

    // Add any additional functions here
}
