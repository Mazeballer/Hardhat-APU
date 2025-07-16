# DeFi Lending DApp Quick Start

## 1. Clone the Repository

```bash
git clone https://github.com/Mazeballer/Hardhat-APU.git
cd Hardhat-APU/contracts
```

## 2. Install Dependencies

```bash
pnpm install 
```

## 3. Start the Local Blockchain

```bash
npx hardhat node
```

* This launches a local node at **[http://127.0.0.1:8545](http://127.0.0.1:8545)** with 20 test accounts (10000 ETH each).

## 4. Deploy Contracts Locally

```bash
# In a new terminal, still inside 'contracts' folder
npx hardhat compile
npx hardhat run scripts/deploy.ts --network localhost
```

## 5. Connect MetaMask to Hardhat Local

1. Open MetaMask and go to **Settings → Networks → Add a network**.
2. Enter:

   * **Network Name:** Hardhat Local
   * **RPC URL:** [http://127.0.0.1:8545](http://127.0.0.1:8545)
   * **Chain ID:** 31337
   * **Currency:** ETH
3. Save and switch to this network.

## 6. Import Test Accounts

1. From the terminal running `npx hardhat node`, copy the **private key** of any test account.
2. In MetaMask, click **Import Account** and paste the private key.
3. You’ll see the account with 10000 ETH available locally.

---

You’re now ready to interact with your deployed contracts via MetaMask and your frontend/backend code!
