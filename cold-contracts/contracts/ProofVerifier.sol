// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {EmbersToken} from "./EmbersToken.sol";

/**
 * @title ProofVerifier
 * @dev This contract is responsible for verifying zk-proofs for XFG deposits
 * and minting EmbersToken rewards upon successful verification.
 * It enforces a one-time mint per recipient address to encourage privacy
 * through the use of fresh, unused accounts for minting.
 */
contract ProofVerifier {
    EmbersToken public embersToken;
    mapping(address => bool) public hasMinted;

    event Minted(address indexed recipient, uint256 amount);

    /**
     * @dev Sets the address of the EmbersToken contract.
     */
    constructor(address _embersTokenAddress) {
        embersToken = EmbersToken(_embersTokenAddress);
    }

    /**
     * @dev Verifies a deposit proof and mints tokens to a fresh recipient address.
     *
     * @param _recipient The address to receive the minted tokens. Must not have minted before.
     * @param _amount The amount of tokens to mint.
     * @param _proof A placeholder for the actual proof data.
     */
    function verifyAndMint(
        address _recipient,
        uint256 _amount,
        bytes calldata _proof
    ) external {
        // 1. Check if the recipient account has already minted.
        require(!hasMinted[_recipient], "ProofVerifier: Recipient has already minted.");

        // 2. Placeholder for actual zk-proof verification logic.
        bool isProofValid = _verifyProof(_proof);
        require(isProofValid, "ProofVerifier: Invalid proof.");

        // 3. Mark the recipient as having minted.
        hasMinted[_recipient] = true;

        // 4. Mint tokens to the recipient address.
        embersToken.mint(_recipient, _amount);

        emit Minted(_recipient, _amount);
    }

    /**
     * @dev Internal function to contain the zk-proof verification logic.
     * THIS IS A PLACEHOLDER.
     */
    function _verifyProof(bytes calldata _proof) internal pure returns (bool) {
        // In a real implementation, you would replace this with a call
        // to a verifier library for your specific zk-proof.
        return _proof.length > 0;
    }
} 