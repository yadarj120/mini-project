const { network } = require("hardhat");
const { developmentChains } = require("../helper-hardhat-config");
const { verify } = require("../utils/verify");
require("dotenv").config();

module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, log } = deployments;
    const { deployer } = await getNamedAccounts();
    const [, addr1, addr2] = await ethers.getSigners();

    log("----------------------------------------------------");
    log("Deploying Main and waiting for confirmations...");
    const Main = await deploy("Main", {
        from: deployer,
        args: [[addr1.address, addr2.address]],
        log: true,
        // we need to wait if on a live network so we can verify properly
        waitConfirmations: network.config.blockConfirmations || 1,
    });
    log(`Main deployed at ${Main.address}`);

    if (
        !developmentChains.includes(network.name) &&
        process.env.ETHERSCAN_API_KEY
    ) {
        await verify(Main.address, [[addr1.address, addr2.address]]);
    }
};

module.exports.tags = ["all", "Main"];
