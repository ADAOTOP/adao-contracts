// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers } from "hardhat";

const officialAccount = "0x622cB4f5Ab9fA81eEC83251D23Cc0AF5f2ee029F";

async function main() {
  const theSigner = await ethers.getSigner(officialAccount);

  // We get the contract to deploy
  const c = await ethers.getContractFactory("EvmDappsStaking", theSigner);
  const ci = await c.deploy("ADAO insterest-bearing ASTR", "ibASTR");

  await ci.deployed();

  console.log("contract deployed to:", ci.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
