const { network } = require("hardhat");
const { developmentChains } = require("../helper-hardhat-config");
const { verify } = require("../utils/verify");


module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();

  args = [];

  const mock = await deploy("MockToken", {
    from: deployer,
    args: args,
    log: true,
    waitConfirmations: network.config.waitConfirmations || 1,
  });

  args1 = [mock.address, 5];

  const nftcontract = await deploy("PabloNFT", {
    from: deployer,
    args: args1,
    log: true,
    waitConfirmations: network.config.waitConfirmations || 1,
  });

  //   if (
  //     !developmentChains.includes(network.name) &&
  //     process.env.ETHERSCAN_API_KEY
  //   ) {
  //     log("Verifying...");
  //     await verify(.address, args);
  //   }
  //   log("----------------------------");
};

module.exports.tags = ["all"];
