// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  
  // 1. Deploy EmbersToken
  const embersToken = await hre.ethers.deployContract("EmbersToken", [deployer.address]);
  await embersToken.waitForDeployment();
  console.log(`EmbersToken deployed to ${embersToken.target}`);

  // 2. Deploy ProofVerifier, linking it to EmbersToken
  const proofVerifier = await hre.ethers.deployContract("ProofVerifier", [embersToken.target]);
  await proofVerifier.waitForDeployment();
  console.log(`ProofVerifier deployed to ${proofVerifier.target}`);

  // 3. Set the ProofVerifier as the only minter on EmbersToken
  await embersToken.setMinter(proofVerifier.target);
  console.log(`ProofVerifier set as minter for EmbersToken`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
}); 