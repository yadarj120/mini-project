const { PocketProvider } = require("@ethersproject/providers");
const { ethers, getNamedAccounts } = require("hardhat");
const sdk = require("api")("@virustotal/v3.0#ijj11xglakx5yfm");
const { fs } = require("fs");
const { base64encode, base64decode } = require("nodejs-base64");
require("dotenv").config();

const VIRUSTOTAL_API_KEY = process.env.VIRUSTOTAL_API_KEY || "";

async function main() {
    const { peer2 } = await getNamedAccounts();
    const Main = await ethers.getContract("Main", peer2);
    console.log(`Got contract Main at ${Main.address}`);
    console.log("peer2 verifying file...");
    const version = await Main.checkVersion();
    // const PEER2_VERSION = fs.readFileSync("peer2/peer2version.txt").tostring();
    const PEER2_VERSION = ""

    if (PEER2_VERSION != version) {
        const ipfsAddress = await Main.getIpfsAddress();
        let str = base64encode(`${ipfsAddress}`);
        let id = str.substring(0, str.length - 1);
        console.log(id); // "aGV5ICB0aGVyZQ=="
        // sdk.urlInfo({
        //     id: `${id}`,
        //     "x-apikey":
        //         `${VIRUSTOTAL_API_KEY}`,
        // })
        //     .then(({ data }) => {
        //         console.log(data);
        //     })
        //     .catch((err) => {
        //         console.error(err);
        //         console.log("Unable to verify file!😞😞");
        //     });
        const transactionResponse = await Main.verify(true, peer2);
        await transactionResponse.wait();
        //update back the result of the call
        console.log("File verified Successfully!🎉🎉");
    } else {
        console.log("no file to verify!!");
    }
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
