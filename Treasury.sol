// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./Token.sol";

/**
 * @title SoftLawTreasury
 * @dev Treasury management for the SoftLaw DAO
 */
contract SoftLawTreasury {
    // Treasury-specific data
    struct TreasuryData {
        uint256 requestedTokens;
        bool exists;
    }

    // Mapping for treasury proposal data
    mapping(uint256 => TreasuryData) private _treasuryData;

    // Token instance
    SoftLawToken public governanceToken;

    // The governance contract that controls this treasury
    address public governanceContract;

    event TreasuryProposalRegistered(
        uint256 indexed id,
        uint256 requestedTokens
    );
    event TreasuryProposalExecuted(
        uint256 indexed id,
        address beneficiary,
        uint256 amount
    );

    modifier onlyGovernance() {
        require(msg.sender == governanceContract, "Only governance can call");
        _;
    }

    constructor(address _tokenAddress) {
        governanceContract = msg.sender;
        governanceToken = SoftLawToken(_tokenAddress);
    }

    /**
     * @dev Register a new treasury proposal
     * @param _id The proposal ID
     * @param _requestedTokens The amount of tokens requested
     */
    function registerTreasuryProposal(
        uint256 _id,
        uint256 _requestedTokens
    ) external onlyGovernance {
        require(_requestedTokens > 0, "Requested tokens must be > 0");

        TreasuryData storage td = _treasuryData[_id];
        td.requestedTokens = _requestedTokens;
        td.exists = true;

        emit TreasuryProposalRegistered(_id, _requestedTokens);
    }

    /**
     * @dev Execute a treasury proposal by transferring tokens
     * @param _id The proposal ID to execute
     * @param _beneficiary The address to send tokens to
     */
    function executeTreasuryProposal(
        uint256 _id,
        address _beneficiary
    ) external onlyGovernance {
        TreasuryData storage td = _treasuryData[_id];
        require(td.exists, "Treasury proposal doesn't exist");

        uint256 tokenBalance = governanceToken.balanceOf(address(this));
        require(
            tokenBalance >= td.requestedTokens,
            "Not enough tokens in treasury"
        );

        governanceToken.transfer(_beneficiary, td.requestedTokens);

        emit TreasuryProposalExecuted(_id, _beneficiary, td.requestedTokens);
    }

    /**
     * @dev Get treasury proposal data
     * @param _id The proposal ID
     * @return requestedTokens The amount of tokens requested
     */
    function getTreasuryData(
        uint256 _id
    ) external view returns (uint256 requestedTokens) {
        require(_treasuryData[_id].exists, "Treasury proposal doesn't exist");
        return _treasuryData[_id].requestedTokens;
    }

    /**
     * @dev Check if a treasury proposal exists
     * @param _id The proposal ID
     * @return Whether the proposal exists
     */
    function treasuryProposalExists(uint256 _id) external view returns (bool) {
        return _treasuryData[_id].exists;
    }

    /**
     * @dev Get the current token balance of the treasury
     * @return The token balance
     */
    function getTokenBalance() external view returns (uint256) {
        return governanceToken.balanceOf(address(this));
    }
}
