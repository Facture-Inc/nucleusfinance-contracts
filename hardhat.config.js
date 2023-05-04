require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();
require("@openzeppelin/hardhat-upgrades");
require("@nomiclabs/hardhat-ethers");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.19",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
        details: {
          yul: false,
        },
      },
    },
  },

  networks: {
    localhost: {
      url: "http://127.0.0.1:8545/",
    },
  },

  paths: {
    sources: "./contracts/PF_USDC_Polygon-Fantom",
  },
};
