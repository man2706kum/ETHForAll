require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config()
/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.17",
  networks: {
    "mantle-testnet": {
      url: "https://rpc-mumbai.maticvigil.com/",
      accounts: [process.env.PRIV_KEY] // Uses the private key from the .env file
    }
  }
};
