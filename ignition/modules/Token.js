const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

const TokenModule = buildModule("TokenModule", (m) => {
  const PiOne = m.contract("PiOne");

  return { PiOne };
});

module.exports = TokenModule;

// 0xcEe5E1f4141edbd1dfA1d09d36292D1cB6F8d817