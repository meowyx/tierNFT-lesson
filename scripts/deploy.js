const hre = require("hardhat");

const CONTRACT_NAME = "TierNFT"

const COLLECTION_NAME = "TierNFT"
const COLLECTION_SYMBOL = "Tier"

async function main() {

  const contractFactory = await hre.ethers.getContractFactory(CONTRACT_NAME);
  const contract = await contractFactory.deploy(COLLECTION_NAME, COLLECTION_SYMBOL);

  await contract.deployed();

  console.log(`Contract deployed to ${contract.address}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});