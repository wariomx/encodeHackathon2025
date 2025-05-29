// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title DAOTreasury
 * @dev Treasury contract focused on balance management and token distribution
 * @notice Only the owner (core DAO contract) can execute payments
 */
contract DAOTreasury is ERC20, Ownable, ReentrancyGuard {
    // ERC20 token configuration
    string private constant TOKEN_NAME = "SoftLaw Token";
    string private constant TOKEN_SYMBOL = "SLaw";
    uint256 private constant INITIAL_SUPPLY = 10000000000000000;

    // Spending tier limits (in tokens)
    uint256 public spenderLimit = 10000;

    address public contractOwner;

    // Events
    event TokensDistributed(address indexed beneficiary, uint256 amount);
    event TokensMinted(uint256 amount);

    // Custom errors
    error InsufficientTreasuryBalance();

    constructor(
        address _owner
    ) ERC20(TOKEN_NAME, TOKEN_SYMBOL) Ownable(_owner) {
        _mint(address(this), INITIAL_SUPPLY * 10 ** decimals());
    }

    /**
     * @dev Mint additional tokens to the treasury (only owner)
     * @param amount Amount of tokens to mint
     */
    function printBrrrr(uint256 amount) public onlyOwner nonReentrant {
        _mint(msg.sender, amount);
        emit TokensMinted(amount);
    }

    function spend(
        uint256 amount,
        address beneficiary
    ) public onlyOwner nonReentrant {
        require(beneficiary != address(0), "Invalid beneficiary");
        require(amount > 0, "Amount must be greater than zero");
        require(
            amount < spenderLimit,
            "Amount must be less than the spending limit"
        );

        // Check treasury balance
        if (balanceOf(address(this)) < amount) {
            revert InsufficientTreasuryBalance();
        }

        _transfer(address(this), beneficiary, amount);
        emit TokensDistributed(beneficiary, amount);
    }

    /**
     * @dev Check if treasury has sufficient balance for a payment
     * @param amount Amount to check
     * @return hasBalance True if sufficient balance exists
     */
    function hasSufficientBalance(
        uint256 amount
    ) external view returns (bool hasBalance) {
        return balanceOf(address(this)) >= amount;
    }

    // View functions
    /**
     * @dev Get the current token balance of the treasury
     * @return balance The token balance of the treasury
     */
    function getTreasuryBalance() external view returns (uint256 balance) {
        return balanceOf(msg.sender);
    }

    /**
     * @dev Get the current token balance of any account
     * @param account Account address to check
     * @return balance The token balance
     */
    function getAccountBalance(
        address account
    ) external view returns (uint256 balance) {
        return balanceOf(account);
    }

    // override functions
    function transferOwnership(
        address _newOwner
    ) public virtual override onlyOwner {
        super.transferOwnership(_newOwner);
        contractOwner = _newOwner;
    }
}
