require("@nomiclabs/hardhat-etherscan")
require("@openzeppelin/hardhat-upgrades")
const dotenv = require("dotenv");

dotenv.config();

task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

module.exports = {
  solidity: "0.8.13",
  networks: {
    goerli: {
      url: process.env.GOERLI,
      accounts: [process.env.PRIVATE_KEY]
      /*,
      gasLimit: 999999,
      gasPrice: 50*10**9 //50 gwei*/
    },
    mainnet: {
      url: process.env.MAINNET,
      accounts: [process.env.PRIVATE_KEY]
    }
  },
  etherscan: {
    apiKey: process.env.API_KEY
  }
};