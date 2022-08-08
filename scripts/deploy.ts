import { ethers } from "hardhat";

async function main() {
  const contract = await ethers.getContractFactory("Marketplace");
  const deployingContract = await contract.deploy();
  await deployingContract.deployed();

  console.log("deploy completed! contract address:", deployingContract.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
