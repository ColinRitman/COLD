pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/poseidon.circom";

// ProofOfDeposit circuit with nullifier:
//  - nullifier = Poseidon(depositSecret)
//  - depositHash = Poseidon(nullifier, recipientAddressHash)
// Public signals: [nullifier, depositHash, recipientAddressHash]

template ProofOfDeposit() {
    // --- Private inputs ---
    signal input depositSecret;             // user-chosen secret

    // --- Public inputs ---
    signal input recipientAddressHash;      // hash( recipient EVM address )

    // --- Public outputs (will be listed in the instantiation) ---
    signal nullifier;                       // unique identifier preventing double-spend
    signal depositHash;                     // commitment published on Fuego chain

    // Compute nullifier = Poseidon(depositSecret)
    component h1 = Poseidon(1);
    h1.inputs[0] <== depositSecret;
    nullifier <== h1.out;

    // Compute commitment = Poseidon(nullifier, recipientAddressHash)
    component h2 = Poseidon(2);
    h2.inputs[0] <== nullifier;
    h2.inputs[1] <== recipientAddressHash;
    depositHash <== h2.out;
}

// Expose the three public signals in the specified order
component main { public [nullifier, depositHash, recipientAddressHash] } = ProofOfDeposit(); 