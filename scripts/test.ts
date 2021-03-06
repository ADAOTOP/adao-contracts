
// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers } from "hardhat";

const officialAccount = "0x622cB4f5Ab9fA81eEC83251D23Cc0AF5f2ee029F";

const shibuyaContract = "0x50CE77Ed745374980aE8366424e79D08bD1BB37B";
const astarContract = "0x3BFcAE71e7d5ebC1e18313CeCEbCaD8239aA386c";

async function main() {
  const theSigner = await ethers.getSigner(officialAccount);

    const c = await ethers.getContractAt("AdaoDappsStaking", astarContract, theSigner);
    // try{
        // const r = await c.depositFor(officialAccount, {value: "502000000000000000000"});
        // const r2 = await c.balanceOf(officialAccount);
        // const r3 = await c.withdraw("1000000000000000000");
        // console.log(`r: ${JSON.stringify(r)}`);
        // console.log(`r2: ${JSON.stringify(r2)}`);
        // console.log(`r3: ${JSON.stringify(r3)}`);
    // }catch (e){
    //     console.log(`e: ${JSON.stringify(e)}`)
    // }
    
    // const e = await c.getUserWithdrawRecords(officialAccount, 0, 20);
    const e = await c.getWithdrawRecords(0, 20);
    // const e = await c.records("0");
    console.log(`e: ${JSON.stringify(e)}`);
    const e1 = await c.getBalance();
    const e2 = await c.getStaked();
    const e3 = await c.ratio();
    const e4 = await c.toWithdrawed();
    const e5 = await c.totalSupply();
    const e6 = await c.recordsIndex();
    const e7 = await c.getRecordsLength();
    console.log(`e1: ${JSON.stringify(e1.toString())}`);
    console.log(`e2: ${JSON.stringify(e2.toString())}`);
    console.log(`e3: ${JSON.stringify(e3.toString())}`);
    console.log(`e4: ${JSON.stringify(e4.toString())}`);
    console.log(`e5: ${JSON.stringify(e5.toString())}`);
    console.log(`e6: ${JSON.stringify(e6.toString())}`);
    console.log(`e6: ${JSON.stringify(e7.toString())}`);

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
