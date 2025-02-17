const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");
const NFT= "0xdb27Ff7bd307DBDe72a060d0b27666c4821B3984"; 

const TokenModule = buildModule("TokenModule", (m) => {
  const NFTAirdrop = m.contract("NFTAirdrop",[NFT]);

  return { NFTAirdrop  };
});

module.exports = TokenModule;

//  0xFc6b745C46cE47CA48054294681314268747bECe