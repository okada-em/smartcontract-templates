import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
require("@nomiclabs/hardhat-etherscan");
import dotenv from "dotenv";
dotenv.config();

const config: HardhatUserConfig = {
  solidity: "0.8.9",
  networks: {
    rinkeby: {
      url: 'https://rinkeby.infura.io/v3/' + process.env.INFURA_KEY,
      accounts: [`${process.env.PRIVATE_KEY}`],
    }
  },
  etherscan: {
    apiKey: 'BFGWJBMNX77RTKQQ78J7VIVXBP3NXGGEH8'
  }
};

export default config;
