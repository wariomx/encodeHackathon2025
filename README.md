# 🧠 Softlaw

<div align="center">
  <img src="./assets/logo.png" alt="Softlaw Logo" width="250px">
  
  **A Decentralized Autonomous Legal Organization Protocol**
  
  [![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
  [![Built with Solidity](https://img.shields.io/badge/Built%20with-Solidity-7e4798.svg)](https://soliditylang.org/)
</div>

## 📜 Overview

Softlaw is a decentralized legal automation protocol that bridges traditional legal frameworks with blockchain technology. Initially developed during a hackathon, this project is now evolving as part of a Web3 Foundation grant. The protocol enables the creation, management, and enforcement of digital legal licenses through smart contracts with DAO-based governance.

## 🔑 Key Features

- **Digital Legal Licensing**: Create and manage legal licenses on-chain
- **DAO Governance**: Decentralized decision-making for protocol updates and license management
- **Modular Treasury**: Flexible financial operations for the protocol ecosystem
- **ERC-20 Utility Token**: Native token for governance and protocol functionality

## 📦 Smart Contract Architecture

The protocol consists of the following core smart contracts:

| Contract               | Description                                                                                                    |
| ---------------------- | -------------------------------------------------------------------------------------------------------------- |
| **Governor.sol**       | Core DAO contract that manages proposals, calls, and memberships. Integrates with LicenseManager and Treasury. |
| **LicenseManager.sol** | Handles creation, validation, and revocation of legal licenses across the protocol.                            |
| **License.sol**        | Defines structure, permissions, and lifecycle for individual legal licenses.                                   |
| **Treasury.sol**       | Manages the DAO's financial operations, token allocations, and transfers.                                      |
| **Token.sol**          | ERC-20 compliant token providing governance rights and protocol utility.                                       |

## ⚙️ Development Guide

### Prerequisites

- Node.js (v16+)
- pnpm

### Local Setup

```bash
# Clone the repository
git clone https://github.com/your-username/softlaw.git
cd softlaw

# Install dependencies
pnpm install
```

### Development Workflow

1. Edit smart contracts in the root directory
2. Compile smart contracts:
   ```bash
   pnpm build
   ```
3. Deploy contracts:
   ```bash
   pnpm deploy-contracts
   ```
4. Export contract data:
   ```bash
   pnpm export
   ```

### Environment Variables

Create a `.env` file with the following variables:

```
ACCOUNT_SEED=your_seed_phrase_here
RPC_URL=https://westend-asset-hub-eth-rpc.polkadot.io
```

- `ACCOUNT_SEED`: Seed phrase for the account that will sign the deployment
- `RPC_URL`: RPC endpoint
  - For Westend Asset Hub: `https://westend-asset-hub-eth-rpc.polkadot.io`
  - For local development: `http://localhost:8545`

## 🔗 Related Projects

This repository is part of a Web3 Foundation grant that is currently in progress. The DAO components developed during the hackathon will be integrated into the broader grant project.

For more information about the W3F grant project, visit: [https://github.com/soft-law/W3F_Grant](https://github.com/soft-law/W3F_Grant)

## 👤 Team

**Wario**  
LegalTech Wizard

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

<div align="center">
  <sub>Built with ❤️ for the decentralized legal future</sub>
</div>
