const { expect } = require("chai");
const { network, deployments, ethers} = require("hardhat");
const { developmentChains } = require("../../helper-hardhat-config");
const { tokenConfig } = require("../../hardhat-token-config");

const tokenName = tokenConfig.name;
const symbol = tokenConfig.symbol;
const fee = tokenConfig.fee;
const MaxNfts = tokenConfig.initialSupply;

let credit = async function (to, amount) {
  return await tokenContract.transfer(to.address, amount);
};

!developmentChains.includes(network.name)
  ? describe.skip
  : describe("Token Unit Tests", function () {
      beforeEach(async () => {
        accounts = await ethers.getSigners();
        deployer = accounts[0];
        alice = accounts[1];
        bob = accounts[2];
        charles = accounts[3];
        await deployments.fixture(["all"]);

        tokenContract = await ethers.getContract("PabloNFT");
        tokenContract = tokenContract.connect(deployer);
        tokenContractAlice = tokenContract.connect(alice);
        tokenContractBob = tokenContract.connect(bob);
        tokenContractCharles = tokenContract.connect(charles);
      });
      describe("Pablo IERC-20", function () {
        describe("Initialization()", function () {
          it("should have the name " + tokenName, async function () {
            expect(await tokenContract.name()).to.equal(tokenName);
          });
          it("should have the symbol " + symbol, async function () {
            expect(await tokenContract.symbol()).to.equal(symbol);
          });
        });
      });
    });
module.exports.tags = ["all", "token"];
