const { ethers } = require("hardhat");
const { expect } = require("chai");
const {
  XTestTokenContractAdd,
  XChainTestContractAdd,
  YTestTokenContractAdd,
  YTestVaultContractAdd,
  YChainTestContractAdd,
} = require("./DeploymentTest.js");
const readline = require("readline");
const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout,
});

describe("Initial Setup", function () {
  describe("Initial X Contracts", function () {
    let deployer;
    let user;

    before(async function () {
      const signers = await ethers.getSigners();
      deployer = signers[0].address;
      user = signers[1].address;
    });

    describe("XTestToken Contract", function () {
      let XTestTokenContract;

      before(async function () {
        XTestTokenContract = await ethers.getContractAt(
          "XTestToken",
          XTestTokenContractAdd
        );
      });

      describe("X Token Increase Allowance", function () {
        it("give allowance to XChainTest", async function () {
          await XTestTokenContract.connect(
            await ethers.getSigner(user)
          ).increaseAllowance(XChainTestContractAdd, 10000);
          await XTestTokenContract.connect(
            await ethers.getSigner(deployer)
          ).increaseAllowance(XChainTestContractAdd, 10000);
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

      describe("trust Y address", function () {
        it("should add YChainTest as a trusted address", async function () {
          await XChainTestContract.trustAddress(YChainTestContractAdd);
        });
      });
    });
  });
  /*//////////////////////////////////////////////////////////////
                              Y Contracts
    //////////////////////////////////////////////////////////////*/
  describe("Initial Y Contracts", function () {
    let deployer;
    let user;

    before(async function () {
      const signers = await ethers.getSigners();
      deployer = signers[0].address;
      user = signers[1].address;
    });

    describe("YTestToken Contract", function () {
      let YTestTokenContract;

      before(async function () {
        YTestTokenContract = await ethers.getContractAt(
          "YTestToken",
          YTestTokenContractAdd
        );
      });

      describe("YTestToken Increase Allowance", function () {
        it("give allowance to YTestVault", async function () {
          await YTestTokenContract.increaseAllowance(
            YTestVaultContractAdd,
            10000
          );
        });
      });

      describe("YTestToken transfer", function () {
        it("transfers 5000 tokens to YChainTest", async function () {
          // const address = await new Promise((resolve) => {
          //   rl.question("Enter the address to send the tokens to: ", (answer) => {
          //     resolve(answer);
          //   });
          // });
          await YTestTokenContract.transfer(YChainTestContractAdd, 5000);
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
    });

    describe("YChainTest Contract", function () {
      let YChainTestContract;

      before(async function () {
        YChainTestContract = await ethers.getContractAt(
          "YChainTest",
          YChainTestContractAdd
        );
      });

      describe("YChainTest increase allowance", function () {
        it("should increase token allowance for YTestVault", async function () {
          await YChainTestContract.myincreaseAllowance(
            YTestVaultContractAdd,
            10000
          );
          expect(await YChainTestContract.mycheckAllowance()).to.equal(10000);
        });
      });

      describe("trust X address", function () {
        it("should add XChainTest as a trusted address", async function () {
          await YChainTestContract.trustAddress(XChainTestContractAdd);
        });
      });
    });
  });
});
/*//////////////////////////////////////////////////////////////
                          Dev Setup Tests
//////////////////////////////////////////////////////////////*/
describe("Dev Setup", function () {
  describe("Dev X Contracts", function () {
    let deployer;
    let user;

    before(async function () {
      const signers = await ethers.getSigners();
      deployer = signers[0].address;
      user = signers[1].address;
    });

    describe("XTestToken Contract", function () {
      let XTestTokenContract;

      before(async function () {
        XTestTokenContract = await ethers.getContractAt(
          "XTestToken",
          XTestTokenContractAdd
        );
      });

      describe("XTestToken transfer to user", function () {
        it("should transfer tokens", async function () {
          const amount = await new Promise((resolve) => {
            rl.question("Enter the amount: ", (amount) => {
              resolve(amount);
            });
          });
          await XTestTokenContract.transfer(user, amount);
        });
      });

      describe("XTestToken transfer to XTestChain", function () {
        it("should transfer tokens", async function () {
          const amount = await new Promise((resolve) => {
            rl.question("Enter the amount: ", (amount) => {
              resolve(amount);
            });
          });
          await XTestTokenContract.transfer(XChainTestContractAdd, amount);
        });
      });

      describe("XTestToken balance of", function () {
        it("should return balance of all", async function () {
          // const address = await new Promise((resolve) => {
          //   rl.question("Enter the address to check balance of: ", (answer) => {
          //     resolve(answer);
          //   });
          // });
          // console.log(await YTestTokenContract.balanceOf(address));
          console.log(
            "Balance of Deployer: ",
            await XTestTokenContract.balanceOf(deployer)
          );
          console.log(
            "Balance of User: ",
            await XTestTokenContract.balanceOf(user)
          );
          console.log(
            "Balance of XChainTest: ",
            await XTestTokenContract.balanceOf(XChainTestContractAdd)
          );
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

      describe("XChainTest balance of", function () {
        it("should return balance of all", async function () {
          // const address = await new Promise((resolve) => {
          //   rl.question("Enter the address to check balance of: ", (answer) => {
          //     resolve(answer);
          //   });
          // });
          // console.log(await YTestTokenContract.balanceOf(address));
          console.log(
            "Balance of Deployer: ",
            await XChainTestContract.balanceOf(deployer)
          );
          console.log(
            "Balance of User: ",
            await XChainTestContract.balanceOf(user)
          );
        });
      });

      describe("XChainTest Deposit as deployer", function () {
        it("should deposit as deployer", async function () {
          const amount = await new Promise((resolve) => {
            rl.question("Enter the amount: ", (amount) => {
              resolve(amount);
            });
          });
          await XChainTestContract.deposit(amount);
        });
      });

      describe("XChainTest Deposit as user", function () {
        it("should deposit as user", async function () {
          const amount = await new Promise((resolve) => {
            rl.question("Enter the amount: ", (amount) => {
              resolve(amount);
            });
          });
          await XChainTestContract.connect(
            await ethers.getSigner(user)
          ).deposit(amount);
        });
      });

      describe("XChainTest data", function () {
        it("deposit and withdrawal amount", async function () {
          console.log(
            "Amount to deposit: ",
            await XChainTestContract.data("0")
          );
          console.log(
            "Amount to withdraw:",
            await XChainTestContract.data("1")
          );
        });
      });

      describe("XChainTest invest", function () {
        it("should invest", async function () {
          let fee = await XChainTestContract.estimateFee("10112", false, "0x");
          let actFee = parseFloat(fee[0]) * 1.02;
          actFee = actFee.toFixed(0);
          console.log(actFee);

          await XChainTestContract.send({
            value: actFee,
          });
        });
      });

      describe("XChainTest TotalVaultAssets", function () {
        it("should return value of TotalVaultAssets", async function () {
          console.log(await XChainTestContract.totalAssets());
        });
      });

      describe("XChainTest Withdraw as deployer", function () {
        it("should send a req to wtihdraw", async function () {
          const amount = await new Promise((resolve) => {
            rl.question("Enter the amount of shares: ", (amount) => {
              resolve(amount);
            });
          });
          await XChainTestContract.requestWithdrawal(amount);
        });
      });

      describe("XChainTest Withdraw as user", function () {
        it("should send a req to wtihdraw", async function () {
          const amount = await new Promise((resolve) => {
            rl.question("Enter the amount of shares: ", (amount) => {
              resolve(amount);
            });
          });
          await XChainTestContract.connect(
            await ethers.getSigner(user)
          ).requestWithdrawal(amount);
        });
      });

      describe("XChainTest redeem tokens as deployer", function () {
        it("should withdraw tokens from XChainTest to the deployer", async function () {
          const amount = await new Promise((resolve) => {
            rl.question("Enter the amount: ", (amount) => {
              resolve(amount);
            });
          });
          await XChainTestContract.redeem(amount);
        });
      });

      describe("XChainTest redeem tokens as user", function () {
        it("should withdraw tokens from XChainTest to the user", async function () {
          const amount = await new Promise((resolve) => {
            rl.question("Enter the amount: ", (amount) => {
              resolve(amount);
            });
          });
          await XChainTestContract.connect(await ethers.getSigner(user)).redeem(
            amount
          );
        });
      });
    });
  });
  /*//////////////////////////////////////////////////////////////
                              Y Contracts
    //////////////////////////////////////////////////////////////*/
  describe("Dev Y Contracts", function () {
    let deployer;
    let user;

    before(async function () {
      const signers = await ethers.getSigners();
      deployer = signers[0].address;
      user = signers[1].address;
    });

    describe("YTestToken Contract", function () {
      let YTestTokenContract;

      before(async function () {
        YTestTokenContract = await ethers.getContractAt(
          "YTestToken",
          YTestTokenContractAdd
        );
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

      describe("YTestVault add rewards", function () {
        it("should increase total vault amount", async function () {
          const amount = await new Promise((resolve) => {
            rl.question("Enter the amount of rewards to add: ", (amount) => {
              resolve(amount);
            });
          });
          await YTestVaultContract.addrewards(amount);
        });
      });

      describe("YTestVault PreviewRedeem", function () {
        it("should return value of Shares", async function () {
          const amount = await new Promise((resolve) => {
            rl.question(
              "Enter the amount to preview redeem for: ",
              (amount) => {
                resolve(amount);
              }
            );
          });
          console.log(await YTestVaultContract.previewRedeem(amount));
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

      describe("YChainTest TotalVaultAssets", function () {
        it("should return value of TotalVaultAssets", async function () {
          console.log(await YChainTestContract.mypreviewRedeem());
        });
      });

      describe("YChainTest send totalVaultAssets", function () {
        it("should send value of totalVaultAssets", async function () {
          let fee = await YChainTestContract.estimateFee("10106", false, "0x");
          let actFee = parseFloat(fee[0]) * 1.02;
          actFee = actFee.toFixed(0);
          console.log(actFee);

          await YChainTestContract.send({
            value: actFee,
          });
        });
      });

      describe("YChainTest withdrawfromVault", function () {
        it("should withdraw from YTestVault", async function () {
          await YChainTestContract.withdrawfromVault();
        });
      });
    });
  });
});
