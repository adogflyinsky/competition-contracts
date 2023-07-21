import "@nomicfoundation/hardhat-toolbox";
import * as dotenv from "dotenv";
dotenv.config({ path: __dirname + "/.env" });
/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.16",
  paths: {
    sources: './src/v0.3'
  },
  networks: {
    bsctest: {
      url: "https://data-seed-prebsc-2-s2.binance.org:8545",
      accounts: [process.env.PRIVATE_KEY]
    },
    baobab: {
      url: 'https://api.baobab.klaytn.net:8651',
      accounts: [process.env.PRIVATE_KEY]
    }
  }
};

