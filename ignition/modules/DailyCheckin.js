const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

const PiOne= "0xcEe5E1f4141edbd1dfA1d09d36292D1cB6F8d817";
const setPoint = "1000000000000000000";
const TokenModule = buildModule("TokenModule", (m) => {
  const DailyCheckIn = m.contract("DailyCheckIn", [PiOne, setPoint]);

  return { DailyCheckIn };
});

module.exports = TokenModule;

//  0x2eC01626bEA65942ed0377b628CdbC6be2b83FD9
