// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title EmbersToken (HEAT)
 * @dev A simple ERC20 token used as a reward. Minting is restricted.
 */
contract EmbersToken is ERC20, Ownable {
    address public minter;

    event MinterChanged(address indexed newMinter);

    constructor(address initialOwner) ERC20("Fuego Embers", "HEAT") Ownable(initialOwner) {
        minter = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the minter.
     */
    modifier onlyMinter() {
        require(msg.sender == minter, "EmbersToken: caller is not the minter");
        _;
    }

    /**
     * @dev Allows the current owner (initially deployer, then DAO) to set a new minter.
     * This will be the COLDprotocol contract.
     */
    function setMinter(address _minter) external {
        // For simplicity, we allow this to be called by anyone for now,
        // but in a real scenario, this would be owned and called by the DAO.
        // The deploy script will call this once.
        require(minter == msg.sender, "EmbersToken: only current minter can set new minter");
        minter = _minter;
        emit MinterChanged(_minter);
    }

    /**
     * @dev Creates `amount` tokens and assigns them to `account`, overriding the internal ERC20 mint.
     * Can only be called by the minter.
     */
    function mint(address account, uint256 amount) external onlyMinter {
        _mint(account, amount);
    }
} 