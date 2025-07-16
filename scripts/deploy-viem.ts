// scripts/deploy-viem.ts
import { task } from 'hardhat/config';
import artifact from '../artifacts/contracts/Lock.sol/Lock.json';
import type { Address } from 'viem';

task('deploy', 'Deploy Lock with Viem').setAction(async (_args, hre) => {
  // 1️⃣ Await the PublicClient promise
  const publicClient = await hre.viem.getPublicClient();

  // 2️⃣ Bypass strict typing on request (eth_accounts isn't in Viem's built-in JSON-RPC types)
  const accounts = (await (publicClient.request as any)({
    method: 'eth_accounts',
    params: [],
  })) as Address[];
  const deployer = accounts[0];

  // 3️⃣ Now get the WalletClient for that deployer
  const walletClient = await hre.viem.getWalletClient(deployer);

  // 4️⃣ Deploy—ABI, bytecode (cast to `0x${string}`), and args (even if empty) all required
  const deployedAddress = await walletClient.deployContract({
    abi: artifact.abi,
    bytecode: artifact.bytecode as `0x${string}`,
    args: [123],
  });

  console.log('🔒 Lock deployed to:', deployedAddress);
});
