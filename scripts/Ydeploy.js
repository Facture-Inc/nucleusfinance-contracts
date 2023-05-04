// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {
  const YTestToken = await hre.ethers.getContractFactory("YTestToken");
  const YChainTest = await hre.ethers.getContractFactory("YChainTest");
  const YTestVault = await hre.ethers.getContractFactory("YTestVault");

  const YTestTokenContract = await YTestToken.deploy();
  await YTestTokenContract.deployed();
  const YTestTokenContractAdd = YTestTokenContract.address;
  console.log(`YTestToken deployed to ${YTestTokenContractAdd}`);

  const YTestVaultContract = await YTestVault.deploy(
    YTestTokenContractAdd,
    "yUSDC",
    "yUSDC"
  );
  await YTestVaultContract.deployed();
  const YTestVaultContractAdd = YTestVaultContract.address;
  console.log(`YTestVault deployed to ${YTestVaultContractAdd}`);

  const YChainTestContract = await YChainTest.deploy(
    YTestTokenContractAdd,
    YTestVaultContractAdd,
    "0x7dcAD72640F835B0FA36EFD3D6d3ec902C7E5acf"
  );
  await YChainTestContract.deployed();
  const YChainTestContractAdd = YChainTestContract.address;
  console.log(`YChainTest deployed to ${YChainTestContractAdd}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
