# Token Vendor Machine Challenge

This project is designed to test your skills in smart contract development using Solidity.

## Project Overview

You are tasked with implementing a token vendor machine that allows users to buy and sell tokens. The project consists
of two main contracts:

1. `BlockfulToken.sol`: An ERC20 token contract
2. `TokenVendor.sol`: A vendor contract for buying and selling tokens

## Getting Started

To get started with this project, follow these steps:

1. Clone this repository.
2. Run `yarn install` to install dependencies.

## Usage

Here are some common commands you'll need:

### Build

```sh
yarn build
```

### Test

```sh
yarn test
```

### Coverage

```sh
yarn coverage
```

## Design Decisions and Implementation Details

### Merkle Tree Whitelist

I chose to implement a Merkle tree-based whitelist for the following reasons:

1. Gas Efficiency: Merkle trees are highly gas-efficient for large whitelists, as users only need to provide a small
   proof instead of storing the entire whitelist on-chain.
2. Scalability: Merkle trees can handle large whitelists without significant increase in gas costs or storage
   requirements.
3. Flexibility: The whitelist can be easily updated off-chain without modifying the contract, only the merkle root needs
   to be updated.

Other approaches considered:

- On-chain mapping of addresses
  - Which are simple but can be expensive for large whitelists.
- Signature-based whitelisting
  - Which move the whitelist off-chain but require careful key management.

### Dynamic Pricing Mechanism

I implemented a simple dynamic pricing mechanism where the token price increases as the supply decreases. This
encourages early participation and reflects the changing demand for tokens.

### Timed Sales

The contract implements two sale phases:

1. Whitelist Sale: Only whitelisted addresses can participate.
2. Public Sale: Open to all participants.

This allows for a fair distribution of tokens and prioritizes early supporters.

### Security Measures

- ReentrancyGuard: Prevents reentrancy attacks.
- Ownable: Restricts certain functions to the contract owner.
- Pausable: Allows pausing the contract in case of emergencies.
- SafeERC20: Ensures safe token transfers.

## Your Tasks

1. Review the implementation of `BlockfulToken` and `TokenVendor` contracts.
2. Complete the test file `test/TokenVendor.t.sol`:
   - Add more edge cases and potential failure scenarios.
   - Aim for at least 90% test coverage.
3. Update the deployment script if necessary.
4. Consider any potential improvements or considerations for a real-world deployment.

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

This project uses [Foundry](https://getfoundry.sh/). If you're new to Foundry, check out the
[Foundry Book](https://book.getfoundry.sh/) for detailed instructions and tutorials.

Good luck with the challenge! We're excited to see your implementation.
