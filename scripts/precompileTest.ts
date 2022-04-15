// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers } from "hardhat";

const officialAccount = "0x622cB4f5Ab9fA81eEC83251D23Cc0AF5f2ee029F";

const astarCommuContracct = "0x101B453a02f961b4E3f0526eCd4c533c3A80d795";



async function main() {
  const theSigner = await ethers.getSigner(officialAccount);

    // const c = await ethers.getContractAt("SR25519","0x0000000000000000000000000000000000005002");
    // const r = await c.verify("0xcae65573cd7522dbed18547b872d66f663b1765b3ee1544d84a5b34c38038f6e", 
    // "0xf4101bf19623d82998e4e55324127f056b8af7b81da17716ce630534d857583259efb40626529e4b09afbe6a0edf1549de0c36a59b6bbcac2dd2ed07bae47586",
    // "0x6f");
    // console.log(`r: ${r}`);

    const c = await ethers.getContractAt("DappsStaking","0x0000000000000000000000000000000000005001", theSigner);
    // const r = await c.bond_and_stake(astarCommuContracct, "1000000000000000000");
    // const r = await c.claim_staker(astarCommuContracct);
    // const r = await c.unbond_and_unstake(astarCommuContracct, "200000000000000000000");
    // const r = await c.withdraw_unbonded();
    // const r = await c.read_contract_stake(astarCommuContracct);
    // console.log(`r: ${JSON.stringify(r)}`);

    const r1 = await c.read_staked_amount(officialAccount);
    console.log(`r1: ${JSON.stringify(r1)}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
