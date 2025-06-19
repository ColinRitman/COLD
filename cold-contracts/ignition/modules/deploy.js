const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("EmbersTokenModule", (m) => {
  // Get the deployer account
  const initialOwner = m.getAccount(0);

  // Deploy the HeatToken contract
  const embersToken = m.contract("EmbersToken", [initialOwner]);

  return { embersToken };
}); 