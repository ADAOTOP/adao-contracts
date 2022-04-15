
// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers } from "hardhat";

const officialAccount = "0x622cB4f5Ab9fA81eEC83251D23Cc0AF5f2ee029F";

const shibuyaContract = "0xAAf103f445aFFB3246c3c8Fe2370F861C9dcb3E2";

async function main() {
  const theSigner = await ethers.getSigner(officialAccount);

    const c = await ethers.getContractAt("EvmDappsStaking", shibuyaContract, theSigner);
    // try{
        // const r = await c.depositFor(officialAccount, {value: "0"});
        // const r2 = await c.balanceOf(officialAccount);
        // const r3 = await c.withdraw("1000000000000000000");
        // console.log(`r: ${JSON.stringify(r)}`);
        // console.log(`r2: ${JSON.stringify(r2)}`);
        // console.log(`r3: ${JSON.stringify(r3)}`);
    // }catch (e){
    //     console.log(`e: ${JSON.stringify(e)}`)
    // }
    
    const e = await c.getWithdrawRecords(0, 5);
    console.log(`e: ${JSON.stringify(e)}`);
    // const e1 = await c.getBalance();
    // const e2 = await c.getStaked();
    // const e3 = await c.ratio();
    // console.log(`e1: ${JSON.stringify(e1)}`);
    // console.log(`e2: ${JSON.stringify(e2)}`);
    // console.log(`e3: ${JSON.stringify(e3)}`);

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
