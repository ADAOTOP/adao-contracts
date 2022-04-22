// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers, upgrades } from "hardhat";

const officialAccount = "0x622cB4f5Ab9fA81eEC83251D23Cc0AF5f2ee029F";
const proxyAdmin = "0xFD9ad4f0493965CFEc4710b6acb2463afDefC5c4";
const implementation = "0x712665E76f8bC41c57b6b7C85aCE7bf3E70de6c9";

async function main() {
  const theSigner = await ethers.getSigner(officialAccount);

  //========ungraedable========
  // const cPA = await ethers.getContractFactory("ProxyAdmin", theSigner);
  // const cPAi = await cPA.deploy();
  // console.log(`ProxyAdmin deployed to: ${cPAi.address}`)

  // const c = await ethers.getContractFactory("AdaoDappsStaking", theSigner);
  // const ci = await c.deploy();
  // console.log(`AdaoDappsStaking deployed to: ${ci.address}`)


  const c = await ethers.getContractFactory("AdaoDappsStaking", theSigner);
  const callData = c.interface.encodeFunctionData("initialize", ["ADAO insterest-bearing ASTR", "ibASTR"])
  console.log(`calldata: ${callData}`);

  const cTU = await ethers.getContractFactory("TransparentUpgradeableProxy", theSigner);
  const cTUi = await cTU.deploy(implementation, proxyAdmin, callData);
  console.log(`TransparentUpgradeableProxy(AdaoDappsStaking) deployed to: ${cTUi.address}`)


  //========non ungraedable========
  // // We get the contract to deploy
  // const cf = await ethers.getContractFactory("AdaoDappsStaking", theSigner);
  // const ci = await upgrades.deployProxy(cf, ["ADAO insterest-bearing ASTR", "ibASTR"])
  // await ci.deployed();

  // console.log("contract deployed to:", ci.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
