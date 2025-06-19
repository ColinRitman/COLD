// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./EmbersToken.sol";
import "./COLDtoken.sol";

/**
 * @title IVerifier
 * @dev Interface for the Plonk verifier contract.
 */
interface IVerifier {
    function verifyProof(bytes calldata proof, uint256[] calldata pubSignals) external view returns (bool);
}

/**
 * @title COLDprotocol
 * @dev The core logic contract for the COLD privacy-preserving reward protocol.
 */
contract COLDprotocol is Ownable(msg.sender) {
    uint256 public constant heatRewardAmount = 100 * 10**18; // 100 'HEAT' tokens
    uint256 public constant oRewardAmount = 1 * 10**18; // 1 'O' token

    EmbersToken public immutable heatToken;
    COLDtoken public immutable oToken;
    IVerifier public immutable verifier;

    address public treasuryAddress;
    uint256 public treasuryFeeBps; // Fee in basis points. 800 = 8%

    mapping(address => bool) public hasClaimed;
    mapping(uint256 => bool) public nullifierSpent;

    event RewardClaimed(address indexed recipient, uint256 heatAmount, uint256 oAmount);
    event NullifierUsed(uint256 indexed nullifier);
    event TreasuryFeeUpdated(uint256 newFeeBps);
    event TreasuryAddressUpdated(address indexed newTreasury);

    /**
     * @dev Sets up the core protocol contract.
     * @param _heatTokenAddress The address of the HEAT token contract.
     * @param _oTokenAddress The address of the O token contract.
     * @param _treasuryAddress The initial address for the treasury.
     * @param _verifierAddress The address of the proof verifier contract.
     */
    constructor(
        address _heatTokenAddress,
        address _oTokenAddress,
        address _treasuryAddress,
        address _verifierAddress
    ) {
        heatToken = EmbersToken(_heatTokenAddress);
        oToken = COLDtoken(_oTokenAddress);
        treasuryAddress = _treasuryAddress;
        treasuryFeeBps = 800; // Default 8%
        verifier = IVerifier(_verifierAddress);
    }

    /**
     * @dev Verifies a proof, mints new tokens to the protocol, and distributes them.
     */
    function verifyAndDistribute(
        address _recipient,
        bytes calldata _proof,
        uint256[] calldata _pubSignals
    ) external {
        /*
            Public signals layout (see circuit):
            0 -> nullifier        (Poseidon(secret))
            1 -> depositHash      (commitment stored on Fuego, not used on-chain yet)
            2 -> recipientAddrHash = keccak256(abi.encode(addr))
        */

        uint256 nullifier = _pubSignals[0];

        require(!nullifierSpent[nullifier], "COLDprotocol: Nullifier already used.");

        // Ensure the proof is bound to the passed recipient address.
        require(
            _pubSignals[2] == uint256(keccak256(abi.encodePacked(_recipient))),
            "COLDprotocol: Public signal does not match recipient."
        );

        bool isProofValid = verifier.verifyProof(_proof, _pubSignals);
        require(isProofValid, "COLDprotocol: Invalid proof.");

        // --- HEAT Distribution ---
        uint256 totalHeatToMint = (heatRewardAmount * 10000) / (10000 - treasuryFeeBps);
        heatToken.mint(address(this), totalHeatToMint);
        heatToken.transfer(treasuryAddress, totalHeatToMint - heatRewardAmount);
        heatToken.transfer(_recipient, heatRewardAmount);

        // --- O Distribution ---
        uint256 totalOToMint = (oRewardAmount * 10000) / (10000 - treasuryFeeBps);
        oToken.mint(address(this), totalOToMint);
        oToken.transfer(treasuryAddress, totalOToMint - oRewardAmount);
        oToken.transfer(_recipient, oRewardAmount);
        
        hasClaimed[_recipient] = true;
        nullifierSpent[nullifier] = true;
        emit RewardClaimed(_recipient, heatRewardAmount, oRewardAmount);
        emit NullifierUsed(nullifier);
    }

    /**
     * @dev Updates the treasury fee. Only callable by the owner (future DAO).
     */
    function setTreasuryFee(uint256 _newFeeBps) external onlyOwner {
        require(_newFeeBps <= 1000, "COLDprotocol: Fee cannot exceed 10%."); // Sanity check
        treasuryFeeBps = _newFeeBps;
        emit TreasuryFeeUpdated(_newFeeBps);
    }

    /**
     * @dev Updates the treasury address. Only callable by the owner (future DAO).
     */
    function setTreasuryAddress(address _newTreasury) external onlyOwner {
        treasuryAddress = _newTreasury;
        emit TreasuryAddressUpdated(_newTreasury);
    }

    // This function is now deprecated and will be removed.
    /*
    function _verifyProof(bytes calldata _proof) internal pure returns (bool) {
        return _proof.length > 0;
    }
    */
} 