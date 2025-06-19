require("@nomicfoundation/hardhat-toolbox");
require("hardhat-circom");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.20",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    localhost: {
      url: "http://127.0.0.1:8545",
    },
  },
  circom: {
    input: "circuits/ProofOfDeposit.circom",
    output: "artifacts/circuits",
    ptau: "https://storage.googleapis.com/zkevm/ptau/powersOfTau28_hez_final_14.ptau",
    circuits: [
      {
        name: "ProofOfDeposit",
        protocol: "plonk",
      },
    ],
  },
};
