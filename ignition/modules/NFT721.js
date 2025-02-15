const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

const TokenModule = buildModule("TokenModule", (m) => {
  const MyNFT = m.contract("MyNFT");

  return { MyNFT };
});

module.exports = TokenModule;

// 0x5Fe33d765Eaf5710f1424FfC806D5849D2CD9Af1