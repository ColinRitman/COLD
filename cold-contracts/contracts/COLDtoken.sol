// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title COLDtoken (O)
 * @dev The governance token for the COLD protocol. It's an ERC20 token
 * with voting capabilities for DAO governance. Ownership is transferable
 * to the governor contract, and minting is restricted.
 */
contract COLDtoken is ERC20, ERC20Permit, ERC20Votes, Ownable {
    address public minter;

    event MinterChanged(address indexed newMinter);

    constructor() ERC20("COLD", "O") ERC20Permit("COLD") Ownable(msg.sender) {
        minter = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the minter.
     */
    modifier onlyMinter() {
        require(msg.sender == minter, "COLDtoken: caller is not the minter");
        _;
    }

    /**
     * @dev Allows the current owner (initially deployer, then DAO) to set a new minter.
     */
    function setMinter(address _minter) external onlyOwner {
        minter = _minter;
        emit MinterChanged(_minter);
    }

    /**
     * @dev Creates `amount` tokens and assigns them to `account`.
     * Can only be called by the minter.
     */
    function mint(address account, uint256 amount) external onlyMinter {
        _mint(account, amount);
    }

    // The following functions are overrides required by Solidity.
    function _update(address from, address to, uint256 value) internal override(ERC20, ERC20Votes) {
        super._update(from, to, value);
    }

    function nonces(address owner) public view override(ERC20Permit, Nonces) returns (uint256) {
        return super.nonces(owner);
    }
} 