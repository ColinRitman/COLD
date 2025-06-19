const hre = require("hardhat");
const { expect } = require("chai");
const snarkjs = require("snarkjs");
const fs = require("fs");
const { buildPoseidon } = require("circomlibjs");

async function main() {
    console.log("Starting full DAO-governed dual-reward deployment and test...");

    // ==========================================================================================
    // 1. SETUP & DEPLOYMENT
    // ==========================================================================================
    console.log("\n1. Deploying Contracts...");
    const [deployer, treasury, freshAccount] = await hre.ethers.getSigners();
    
    console.log("Deploying contracts with the account:", deployer.address);
    
    // Deploy Verifier
    const verifierFactory = await hre.ethers.getContractFactory("PlonkVerifier");
    const verifier = await verifierFactory.deploy();
    await verifier.waitForDeployment();
    console.log(`  - Verifier deployed to: ${verifier.target}`);

    // Deploy EmbersToken
    const embersToken = await hre.ethers.getContractFactory("EmbersToken");
    const heatToken = await embersToken.deploy(deployer.address);
    await heatToken.waitForDeployment();
    console.log("  - EmbersToken (HEAT) deployed to:", await heatToken.getAddress());

    // Deploy COLDtoken (O)
    const coldTokenFactory = await hre.ethers.getContractFactory("COLDtoken");
    const coldToken = await coldTokenFactory.deploy();
    await coldToken.waitForDeployment();
    console.log(`  - COLDtoken (O) deployed to: ${coldToken.target}`);

    // Deploy COLDprotocol
    const protocolFactory = await hre.ethers.getContractFactory("COLDprotocol");
    const protocol = await protocolFactory.deploy(
        heatToken.target,
        coldToken.target,
        treasury.address,
        verifier.target
    );
    await protocol.waitForDeployment();
    console.log(`  - COLDprotocol deployed to: ${protocol.target}`);
    
    // Deploy COLDgovna
    const governorFactory = await hre.ethers.getContractFactory("COLDgovna");
    const governor = await governorFactory.deploy(coldToken.target);
    await governor.waitForDeployment();
    console.log(`  - COLDgovna deployed to: ${governor.target}`);

    // ==========================================================================================
    // 2. LINKING & OWNERSHIP HANDOVER
    // ==========================================================================================
    console.log("\n2. Configuring roles and transferring ownership to DAO...");
    await heatToken.setMinter(protocol.target);
    await coldToken.setMinter(protocol.target);
    console.log(`  - COLDprotocol set as minter for both HEAT and O tokens.`);

    await protocol.transferOwnership(governor.target);
    await coldToken.transferOwnership(governor.target);
    console.log(`  - COLDprotocol and COLDtoken ownership transferred to COLDgovna.`);
    
    // ==========================================================================================
    // 3. DAO GOVERNANCE SIMULATION
    // ==========================================================================================
    console.log("\n3. Simulating DAO Proposal: Change Treasury Fee...");
    console.log("  - Generating a preliminary proof for deployer to gain voting power...");

    // Generate proof using deployer's address
    const proof = await generateProof(hre, deployer.address);

    console.log("  - Proof generated for deployer. (governance proposal call placeholder)");

    // ==========================================================================================
    // 4. ZK PROOF VERIFICATION AND REWARD DISTRIBUTION (FINAL TEST)
    // ==========================================================================================
    console.log("\n4. Simulating a fresh account claiming rewards with a ZK proof...");

    const poseidon = await buildPoseidon();
    const depositSecretBig = BigInt("0x" + hre.ethers.hexlify(hre.ethers.randomBytes(31)).slice(2));
    const depositSecret = depositSecretBig.toString();

    // New scheme
    const nullifierBig = poseidon([depositSecretBig]);
    const nullifier = poseidon.F.toString(nullifierBig);

    const recipientAddressHashHex = hre.ethers.keccak256(
        hre.ethers.AbiCoder.defaultAbiCoder().encode(["address"], [freshAccount.address])
    );
    const recipientAddressHashBig = BigInt(recipientAddressHashHex);
    const recipientAddressHash = recipientAddressHashBig.toString();

    const depositHashBig = poseidon([nullifierBig, recipientAddressHashBig]);
    const depositHash = poseidon.F.toString(depositHashBig);
    
    console.log("  - Generating proof...");
    const { proof: zkProof, publicSignals: zkPublicSignals } = await snarkjs.plonk.fullProve(
        { depositSecret, recipientAddressHash },
        "artifacts/circuits/ProofOfDeposit_js/ProofOfDeposit.wasm",
        "artifacts/circuits/ProofOfDeposit.zkey"
    );
    
    const proofCalldata = await snarkjs.plonk.exportSolidityCallData(zkProof, zkPublicSignals);
    const cIdx = proofCalldata.indexOf(',');
    const proofBytes = proofCalldata.slice(0, cIdx).trim();
    const publicSignalsBytes = JSON.parse(proofCalldata.slice(cIdx + 1).trim());
    console.log(`  - Proof generated. Public signals: [${zkPublicSignals[0]}, ${zkPublicSignals[1]}]`);

    const gasRelayer = deployer;
    console.log("  - Calling verifyAndDistribute via gas relayer...");
    await protocol.connect(gasRelayer).verifyAndDistribute(freshAccount.address, proofBytes, publicSignalsBytes);
    
    const heatReward = await protocol.heatRewardAmount();
    const oReward = await protocol.oRewardAmount();
    const userHeatBalance = await heatToken.balanceOf(freshAccount.address);
    const userOBalance = await coldToken.balanceOf(freshAccount.address);

    expect(userHeatBalance).to.equal(heatReward);
    expect(userOBalance).to.equal(oReward);
    console.log(`  - Verified fresh account balance. HEAT: ${hre.ethers.formatUnits(userHeatBalance, 18)}, O: ${hre.ethers.formatUnits(userOBalance, 18)}`);

    console.log("\n✅ Full system test complete!");
}

async function generateProof(hre, recipientAddress) {
    const poseidon = await buildPoseidon();
    const depositSecretBig = BigInt("0x" + hre.ethers.hexlify(hre.ethers.randomBytes(31)).slice(2));
    const depositSecret = depositSecretBig.toString();

    // New scheme
    const nullifierBig = poseidon([depositSecretBig]);
    const nullifier = poseidon.F.toString(nullifierBig);

    const recipientAddressHashHex = hre.ethers.keccak256(
        hre.ethers.AbiCoder.defaultAbiCoder().encode(["address"], [recipientAddress])
    );
    const recipientAddressHashBig = BigInt(recipientAddressHashHex);
    const recipientAddressHash = recipientAddressHashBig.toString();

    const depositHashBig = poseidon([nullifierBig, recipientAddressHashBig]);
    const depositHash = poseidon.F.toString(depositHashBig);

    // Check if circuit artifacts exist
    const wasmPath = "artifacts/circuits/ProofOfDeposit_js/ProofOfDeposit.wasm";
    const zkeyPath = "artifacts/circuits/ProofOfDeposit.zkey";
    
    if (!fs.existsSync(wasmPath) || !fs.existsSync(zkeyPath)) {
        throw new Error("Circuit artifacts not found. Please compile the circuits first.");
    }

    const { proof, publicSignals } = await snarkjs.plonk.fullProve(
        { depositSecret, recipientAddressHash },
        wasmPath,
        zkeyPath
    );

    const calldata = await snarkjs.plonk.exportSolidityCallData(proof, publicSignals);
    const commaIdx = calldata.indexOf(',');
    const proofHex = calldata.slice(0, commaIdx).trim();
    const pubJson = calldata.slice(commaIdx + 1).trim();
    const pubSignalsArr = JSON.parse(pubJson);
    return { proofHex, pubSignalsArr };
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
}); 