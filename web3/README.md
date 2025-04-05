**Solidity smart contract + a clean hardhat setup using typescript and ignition for deployment.**

#### Make sure you're not missing the basics:
- node ≥ 18
- npm
- git
- Sepolia ETH (only if you're deploying to testnet)

#### Test Locally
1. `npm install`
2. `npx hardhat test`

Tests are in test/MediChain.test.ts and cover all the core flows:
- Inventory commitment
- Order placement
- Status updates
- Fail conditions

You’ll see green checkmarks if all is good.

#### the smart conrtract
contract is in contracts/MediChain.sol
If you're touching it, only rename the contract before deploying to Sepolia, otherwise the bytecode changes and it’ll deploy as a different contract.


#### Deployment (Ignition)
To deploy locally:

```
npx hardhat ignition deploy ./ignition/modules/MediChain.ts
```
To deploy to Sepolia (after setting up .env, see below):
```
npx hardhat ignition deploy ./ignition/modules/Medichain.ts --network sepolia
```

#### Testnet Setup (Sepolia)
Get a wallet (MetaMask or whatever)

Grab some Sepolia ETH from a faucet (e.g. https://sepoliafaucet.com/)

Create a .env file in the root:

```env
SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/<your-infura-id>
PRIVATE_KEY=your-wallet-private-key
```

**if anything breaks**
```
npx hardhat clean
npx hardhat compile
```