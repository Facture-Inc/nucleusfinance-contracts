const { ethers } = require("hardhat");
const { expect } = require("chai");

const XTestTokenContractAdd = "0x36F1555619ba218FA899D0E77cF0b45Dd66f52B7";
const XChainTestContractAdd = "0x12Be4380590DD02ce113deB8c62bCBE8e13Ed042";
const YTestTokenContractAdd = "0xAc7d4B4EF29dB3dD31b8Cee15a02E01F9A6Eb6D4";
const YTestVaultContractAdd = "0x7100Dbaf269f4cD181a46428cE78C9957288ab75";
const YChainTestContractAdd = "0xFc342277Cf10a03dd01269Db85159212BF4CaBED";

module.exports = {
  XTestTokenContractAdd,
  XChainTestContractAdd,
  YTestTokenContractAdd,
  YTestVaultContractAdd,
  YChainTestContractAdd,
};

describe("X Deployment Contracts", function () {
  let deployer;

  before(async function () {
    const signers = await ethers.getSigners();
    deployer = signers[0].address;
  });

  describe("XTestToken Contract", function () {
    let XTestTokenContract;

    before(async function () {
      XTestTokenContract = await ethers.getContractAt(
        "XTestToken",
        XTestTokenContractAdd
      );
    });

    describe("token details", function () {
      it("should return correct decimals", async function () {
        let decimals = await XTestTokenContract.decimals();
        // console.log(decimals);
        expect(decimals).to.equal(0);
      });

      it("should return correct balance for deployer", async function () {
        let balance = await XTestTokenContract.balanceOf(deployer);
        // console.log(balance);
        expect(balance).to.equal(10000);
      });
    });
  });

  describe("XChainTest Contract", function () {
    let XChainTestContract;

    before(async function () {
      XChainTestContract = await ethers.getContractAt(
        "XChainTest",
        XChainTestContractAdd
      );
    });

    describe("contract details", function () {
      it("should return correct token address", async function () {
        let token = await XChainTestContract.asset();
        // console.log(token);
        expect(token).to.equal(XTestTokenContractAdd);
      });
    });
  });
});

describe("Y Deployment Contracts", function () {
  let deployer;

  before(async function () {
    const signers = await ethers.getSigners();
    deployer = signers[0].address;
  });

  describe("YTestToken Contract", function () {
    let YTestTokenContract;

    before(async function () {
      YTestTokenContract = await ethers.getContractAt(
        "YTestToken",
        YTestTokenContractAdd
      );
    });

    describe("token details", function () {
      it("should return correct decimals", async function () {
        let decimals = await YTestTokenContract.decimals();
        // console.log(decimals);
        expect(decimals).to.equal(0);
      });

      it("should return correct balance for deployer", async function () {
        let balance = await YTestTokenContract.balanceOf(deployer);
        // console.log(balance);
        expect(balance).to.equal(10000);
      });
    });
  });

  describe("YTestVault Contract", function () {
    let YTestVaultContract;

    before(async function () {
      YTestVaultContract = await ethers.getContractAt(
        "YTestVault",
        YTestVaultContractAdd
      );
    });

    describe("contract details", function () {
      it("should return correct token address", async function () {
        let token = await YTestVaultContract.asset();
        // console.log(token);
        expect(token).to.equal(YTestTokenContractAdd);
      });
    });
  });

  describe("YChainTest Contract", function () {
    let YChainTestContract;

    before(async function () {
      YChainTestContract = await ethers.getContractAt(
        "YChainTest",
        YChainTestContractAdd
      );
    });

    describe("contract details", function () {
      it("should return correct token address", async function () {
        let token = await YChainTestContract.testtoken();
        // console.log(token);
        expect(token).to.equal(YTestTokenContractAdd);
      });

      it("should return correct vault address", async function () {
        let vault = await YChainTestContract.testvault();
        // console.log(vault);
        expect(vault).to.equal(YTestVaultContractAdd);
      });
    });
  });
});
