// imports
const { ethers, run, network } = require("hardhat");
require("dotenv").config();

// const addresses = [
//   "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
//   "0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
//   "0x90F79bf6EB2c4f870365E785982E1f101E93b906",
//   "0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65",
//   "0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc",
// ];

// async main
async function main() {
  const MainFactory = await ethers.getContractFactory("Main");
  console.log("Deploying contract...");
  const Main = await MainFactory.deploy();
  await Main.deployed();
  console.log(`Deployed contract to: ${Main.address}`);

  // what happens when we deploy to our hardhat network?
  if (network.config.chainId === 5 && process.env.ETHERSCAN_API_KEY) {
    console.log("Waiting for block confirmations...");
    await Main.deployTransaction.wait(6);
    await verify(Main.address, []);
  }
  // const currentValue = await Main.retrieve()
  // console.log(`Current Value is: ${currentValue}`)

  // // Update the current value
  // const transactionResponse = await Main.store(7)
  // await transactionResponse.wait(1)
  // const updatedValue = await Main.retrieve()
  // console.log(`Updated Value is: ${updatedValue}`)
}

// async function verify(contractAddress, args) {
const verify = async (contractAddress, args) => {
  console.log("Verifying contract...");
  try {
    await run("verify:verify", {
      address: contractAddress,
      constructorArguments: args,
    });
  } catch (e) {
    if (e.message.toLowerCase().includes("already verified")) {
      console.log("Already Verified!");
    } else {
      console.log(e);
    }
  }
};

// main
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
