import hre from 'hardhat';
import "@nomicfoundation/hardhat-toolbox"; 

async function main() {
  const { ethers } = hre;

  const [deployer] = await ethers.getSigners();

  const contractAddress = '0xcf7ed3acca5a467e9e704c703e8d87f634fb0fc9'; 

  const lendingPool = await ethers.getContractAt(
    'LendingPool',
    contractAddress
  );

  // Contract's total balance
  const poolBalance = await lendingPool.getPoolBalance();
  console.log(`✅ Pool balance: ${ethers.formatEther(poolBalance)} ETH`);

  // User's personal deposit
  const depositInfo = await lendingPool.deposits(deployer.address);
  console.log(
    `👤 Your deposited amount: ${ethers.formatEther(depositInfo.amount)} ETH`
  );
  console.log(`📅 Deposited at (unix): ${depositInfo.depositedAt.toString()}`);
}

main().catch((error) => {
  console.error('❌ Script failed:', error);
  process.exit(1);
});
