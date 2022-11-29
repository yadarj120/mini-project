const { ethers, getNamedAccounts } = require("hardhat");

async function main() {
    const { deployer } = await getNamedAccounts();
    const Main = await ethers.getContract("Main", deployer);
    console.log(`Got contract Main at ${Main.address}`);
    console.log("Uploading file...");
    // const COINMARKETCAP_API_KEY = process.env.COINMARKETCAP_API_KEY || "";
    const transactionResponse = await Main.fileUploading();
    await transactionResponse.wait();
    console.log("File uploaded Successfully!");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
