const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

const TokenModule = buildModule("TokenModule", (m) => {
  const MyNFT = m.contract("MyNFT");

  return { MyNFT };
});

module.exports = TokenModule;

// 0xdb27Ff7bd307DBDe72a060d0b27666c4821B3984