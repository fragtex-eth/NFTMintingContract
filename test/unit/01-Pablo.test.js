const { expect } = require("chai");
const { network, deployments, ethers} = require("hardhat");
const { developmentChains } = require("../../helper-hardhat-config");
const { tokenConfig } = require("../../hardhat-token-config");

const tokenName = tokenConfig.name;
const symbol = tokenConfig.symbol;
const fee = tokenConfig.fee;
const MaxNfts = tokenConfig.initialSupply;

let credit = async function (to, amount) {
  return await ercContract.transfer(to.address, amount);
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
          it("should have the fee " + fee, async function () {
            expect(await tokenContract.fee()).to.equal(5);
          });
        });
        describe("Whitelist()", function () {
          it("Non owner should not be able to call the function", async function () {
            await expect(
              tokenContractAlice.addToWhitelist([alice.address])
            ).to.be.revertedWith("Ownable: caller is not the owner");
            await expect(
              tokenContractAlice.removeFromWhitelist([alice.address])
            ).to.be.revertedWith("Ownable: caller is not the owner");
          });
          it("Owner should able to call the function", async function () {
            await expect(tokenContract.addToWhitelist([alice.address])).to.not
              .be.reverted;
            await expect(tokenContract.removeFromWhitelist([alice.address])).to
              .not.be.reverted;
          });
          it("Owner can add remove whitelist multiple addresses and addresses are whitlisted after calling", async function () {
            expect(
              await tokenContract.addToWhitelist([
                alice.address,
                bob.address,
                charles.address,
              ])
            ).to.not.be.reverted;
            expect(await tokenContract.whitelist(alice.address)).to.equal(true);
            expect(await tokenContract.whitelist(accounts[5].address)).to.equal(
              false
            );
            expect(await tokenContract.whitelist(bob.address)).to.equal(true);
            expect(await tokenContract.whitelist(charles.address)).to.equal(
              true
            );
            expect(await tokenContract.whitelist(alice.address)).to.equal(true);
            expect(
              await tokenContract.removeFromWhitelist([
                alice.address,
                charles.address,
              ])
            ).to.not.be.reverted;
            expect(await tokenContract.whitelist(accounts[5].address)).to.equal(
              false
            );
            expect(await tokenContract.whitelist(bob.address)).to.equal(true);
            expect(await tokenContract.whitelist(charles.address)).to.equal(
              false
            );
            expect(await tokenContract.whitelist(alice.address)).to.equal(
              false
            );
          });
        });
        describe("Mint()", function () {
          beforeEach(async () => {
            await tokenContract.addToWhitelist([
              alice.address,
              charles.address,
            ]);
            //Set Allowances
            ercContract = await ethers.getContract("MockToken");
            ercContractAlice = ercContract.connect(alice);
            await ercContractAlice.approve(
              tokenContract.address,
              10000000000
            );
            await ercContract.transfer(alice.address, 100000);
          });
          it("should return when address is not whitelisted ", async function () {
            await expect(tokenContractBob.mint()).to.be.revertedWith(
              "Address not in whitelist"
            );
          });
          it("should return when allowance is not set ", async function () {
            await expect(tokenContractCharles.mint()).to.be.revertedWith(
              "ERC20: insufficient allowance"
            );
          });
          it("should work when allowance is set ", async function () {
            await expect(tokenContractAlice.mint()).to.not.be.reverted;
          });
          it("should return when try to mint twice ", async function () {
            await expect(tokenContractAlice.mint()).to.not.be.reverted;
            await expect(tokenContractAlice.mint()).to.be.revertedWith(
              "Already minted"
            );
          });
          it("should revert after 25 nfts are minted", async function () {
            for(var i = 0; i< MaxNfts; i++){
              //Set Up
              let newWallet = ethers.Wallet.createRandom();
              newWallet = newWallet.connect(ethers.provider);
              await deployer.sendTransaction({
                to: newWallet.address,
                value: ethers.utils.parseEther("1"),
              });
  
              await ercContract.transfer(newWallet.address, fee);
              ercContractNew = ercContract.connect(newWallet);
              tokenContractNew = tokenContract.connect(newWallet);
              await ercContractNew.approve(tokenContract.address, fee);
              await ercContract.transfer(ercContractNew.address, 100000);
              await tokenContract.addToWhitelist([newWallet.address]);

              await expect(tokenContractNew.mint()).to.not.be.reverted;

            }
            let newWallet = ethers.Wallet.createRandom();
            newWallet = newWallet.connect(ethers.provider);
            await deployer.sendTransaction({
              to: newWallet.address,
              value: ethers.utils.parseEther("1"),
            });

            await ercContract.transfer(newWallet.address, fee);
            ercContractNew = ercContract.connect(newWallet);
            tokenContractNew = tokenContract.connect(newWallet);
            await ercContractNew.approve(tokenContract.address, fee);
            await ercContract.transfer(ercContractNew.address, 100000);
            await tokenContract.addToWhitelist([newWallet.address]);

            await expect(tokenContractNew.mint()).to.be.revertedWith(
              "All NFTs already minted"
            );
          });
        });
        describe("Withdraw()", function () {
          beforeEach(async () => {
            await tokenContract.addToWhitelist([alice.address, charles.address]);
            //Set Allowances
            ercContract = await ethers.getContract("MockToken");
            ercContractAlice = ercContract.connect(alice);
            await ercContractAlice.approve(tokenContract.address, 10000000000);
            await ercContract.transfer(alice.address, 100000);
            await tokenContractAlice.mint();
          });
          it("non owner should not be able to withdraw", async function () {
            await expect(tokenContractAlice.withdraw()).to.be.revertedWith(
              "Ownable: caller is not the owner"
            );
          });
          it("owner should have the right amount after withdrawal", async function () {
            let balance1 = await ercContract.balanceOf(deployer.address);
            await tokenContract.withdraw();
            let balance2 = await ercContract.balanceOf(deployer.address);
            expect(balance2.sub(balance1)).is.equal(fee);
          });
        });
      });
    });
module.exports.tags = ["all", "token"];
