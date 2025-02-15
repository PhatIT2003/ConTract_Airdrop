const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");
const NFT= "0x5Fe33d765Eaf5710f1424FfC806D5849D2CD9Af1"; 

const TokenModule = buildModule("TokenModule", (m) => {
  const NFTAirdrop = m.contract("NFTAirdrop",[NFT]);

  return { NFTAirdrop  };
});

module.exports = TokenModule;

//  0xFc6b745C46cE47CA48054294681314268747bECe