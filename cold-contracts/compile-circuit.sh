#!/bin/bash
set -e

mkdir -p artifacts/circuits

# 1. Compile the circuit
circom circuits/ProofOfDeposit.circom --r1cs --wasm -o artifacts/circuits

# 2. Generate the .zkey file
npx snarkjs plonk setup \
  artifacts/circuits/ProofOfDeposit.r1cs \
  ptau/powersOfTau28_hez_final_14.ptau \
  artifacts/circuits/ProofOfDeposit.zkey

# 3. Export the Verifier contract
npx snarkjs zkey export solidityverifier \
  artifacts/circuits/ProofOfDeposit.zkey \
  contracts/Verifier.sol

echo "✅ Circuit compilation and verifier generation complete!" 