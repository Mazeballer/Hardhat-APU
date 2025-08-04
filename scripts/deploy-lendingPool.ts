// scripts/deploy-lendingPool.ts
import { task } from 'hardhat/config';
import type { HardhatRuntimeEnvironment } from 'hardhat/types';
import type { Address } from 'viem';

task('deploy-lendingPool', 'Deploy LendingPool contract').setAction(
  async (_args, hre: HardhatRuntimeEnvironment & any) => {
    const artifact = require('../artifacts/contracts/LendingPool.sol/LendingBorrowingPool.json');

    const publicClient = await hre.viem.getPublicClient();
    const accounts = (await publicClient.request({
      method: 'eth_accounts',
      params: [],
    })) as Address[];
    const deployer = accounts[0];
    const walletClient = await hre.viem.getWalletClient(deployer);

    // Step 1: Get transaction hash from deployment
    const txHash = await walletClient.deployContract({
      abi: artifact.abi,
      bytecode: artifact.bytecode as `0x${string}`,
      args: [],
    });

    // Step 2: Wait for the transaction to complete and fetch receipt
    const receipt = await publicClient.waitForTransactionReceipt({
      hash: txHash,
    });

    // Step 3: Get contract address from receipt
    const contractAddress = receipt.contractAddress;

    console.log('🏦 LendingPool deployed at:', contractAddress);
  }
);
