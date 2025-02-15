require("@nomicfoundation/hardhat-toolbox");
require('dotenv').config();


// const PRIVATE_KEY = process.env.PRIVATE_KEY || "";
// console.log("PRIVATE_KEY:", PRIVATE_KEY);
module.exports = {
  paths: {
    sources: "./contracts", // Thư mục chứa các tệp hợp đồng
    tests: "./test", // Thư mục chứa các tệp kiểm thử
    cache: "./cache", // Thư mục chứa cache biên dịch
    artifacts: "./artifacts" // Thư mục chứa các tệp ABI và bytecode đã biên dịch
  },
  solidity: {
    compilers: [
      {
        version: "0.8.1", 
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
      {
        version: "0.8.24", 
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    ],
  },
  
  networks: {
    Etherscan: {
      url: "https://sepolia.infura.io/v3/082f3c154c4d4ccdbd305e854d654836", // URL của nút RPC mạng Sepolia
      accounts: [process.env.PRIVATE_KEY], // Khóa riêng của tài khoản để ký giao dịch
      chainId: 11155111, // Chain ID của mạng Sepolia
    },
    Bscscan: {
      url: "https://bsc-testnet-dataseed.bnbchain.org",
      accounts: [process.env.PRIVATE_KEY]
    } 
  },
  etherscan: {
    apiKey: {
      sepolia: process.env.API_KEY_ETH, 
      bscTestnet: process.env.API_KEY_BSC
    }
  },
  sourcify: {
   enabled: true
  }
};