// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {
  const XTestToken = await hre.ethers.getContractFactory("XTestToken");
  const XChainTest = await hre.ethers.getContractFactory("XChainTest");

  const XTestTokenContract = await XTestToken.deploy();
  await XTestTokenContract.deployed();
  const XTestTokenContractAdd = XTestTokenContract.address;
  console.log(`XTestToken deployed to ${XTestTokenContractAdd}`);

  const XChainTestContract = await XChainTest.deploy(
    XTestTokenContractAdd,
    "xUSDC",
    "xUSDC",
    "0x93f54d755a063ce7bb9e6ac47eccc8e33411d706"
  );
  await XChainTestContract.deployed();
  const XChainTestContractAdd = XChainTestContract.address;
  console.log(`XChainTest deployed to ${XChainTestContractAdd}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
