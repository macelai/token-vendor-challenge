# Token Vendor Machine Challenge

This project is designed to test your skills in smart contract development using Solidity.

## Project Overview

You are tasked with implementing a token vendor machine that allows users to buy and sell tokens. The project consists of two main contracts:

1. `BlockfulToken.sol`: An ERC20 token contract
2. `TokenVendor.sol`: A vendor contract for buying and selling tokens

## Getting Started

To get started with this project, follow these steps:

1. Clone this repository.
2. Run `npm install` to install Node.js dependencies

## Your Tasks

1. Implement the `BlockfulToken` contract:
   - It should be an ERC20 token with a name, symbol, and 18 decimals.
   - Initial supply should be 1,000,000 tokens.

2. Implement the `TokenVendor` contract with the following functionality:
   - Allow users to buy tokens with ETH (1 ETH = 100 tokens)
   - Allow users to sell tokens back to the contract
   - Allow the owner to withdraw ETH from the contract
   - Implement proper access control (only owner can withdraw)
   - Emit events for token purchases, sales, and ETH withdrawals

3. Complete the test file `test/TokenVendor.t.sol`:
   - We've provided some basic "happy path" tests
   - Implement additional tests for edge cases and potential failure scenarios
   - Aim for at least 90% test coverage

4. Update this README with:
   - Any additional setup or testing instructions
   - An explanation of your design decisions
   - Any potential improvements or considerations for a real-world deployment

## Bonus Tasks

If you complete the main tasks and want to demonstrate more advanced skills:

1. Implement a simple dynamic pricing mechanism (e.g., price increases as supply decreases)
2. Add a feature to pause/unpause the contract (owner only)
3. Implement a whitelist system for early access to token sales

## Usage

Here are some common commands you'll need:

### Build

```sh
npm run build
```

### Test

```sh
npm run  test
```

### Coverage

```sh
npm run test:coverage
```

## Evaluation Criteria

Your submission will be evaluated based on:

- Correctness of the implementation
- Code quality and organization
- Test coverage and quality
- Security considerations
- Testnet deployment
- Documentation and comments
- (For bonus tasks) Creativity and effectiveness of additional features

## Submission

Please submit your completed project as a Git repository. Make sure to include:

- All source code files
- Complete test suite
- Updated README with your notes and explanations

## Note

This project uses [Foundry](https://getfoundry.sh/). If you're new to Foundry, check out the [Foundry Book](https://book.getfoundry.sh/) for detailed instructions and tutorials.

Good luck with the challenge! We're excited to see your implementation.
