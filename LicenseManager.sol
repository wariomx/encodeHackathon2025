// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./License.sol";

/**
 * @title SoftLawLicenseManager
 * @dev Manages license operations for the SoftLaw DAO
 */
contract SoftLawLicenseManager {
    // License-specific data
    struct LicenseData {
        uint256 licenseId;
        uint256 licenseAmount;
        bool exists;
    }

    // Mapping for license proposal data
    mapping(uint256 => LicenseData) private _licenseData;

    // License contract instance
    SoftlawCopyrightsLicense public licenseContract;
    bool public licenseContractInitialized = false;

    // The governance contract that controls this license manager
    address public governanceContract;

    event LicenseContractInitialized(address indexed licenseContractAddress);
    event LicenseProposalRegistered(
        uint256 indexed id,
        uint256 licenseId,
        uint256 licenseAmount
    );
    event LicenseProposalExecuted(
        uint256 indexed id,
        address beneficiary,
        uint256 licenseId,
        uint256 amount
    );
    event LicenseURIUpdated(string newURI);

    modifier onlyGovernance() {
        require(msg.sender == governanceContract, "Only governance can call");
        _;
    }

    constructor(address _owner) {
        governanceContract = _owner;
        // Initialize license contract immediately
        licenseContract = new SoftlawCopyrightsLicense(_owner);
        licenseContractInitialized = true;

        emit LicenseContractInitialized(address(licenseContract));
    }

    /**
     * @dev Register a new license proposal
     * @param _id The proposal ID
     * @param _licenseId The license ID to mint
     * @param _licenseAmount The amount of licenses to mint
     */
    function registerLicenseProposal(
        uint256 _id,
        uint256 _licenseId,
        uint256 _licenseAmount
    ) external onlyGovernance {
        require(_licenseAmount > 0, "License amount must be > 0");

        LicenseData storage ld = _licenseData[_id];
        ld.licenseId = _licenseId;
        ld.licenseAmount = _licenseAmount;
        ld.exists = true;

        emit LicenseProposalRegistered(_id, _licenseId, _licenseAmount);
    }

    /**
     * @dev Execute a license proposal by minting tokens
     * @param _id The proposal ID to execute
     * @param _beneficiary The address to send licenses to
     */
    function executeLicenseProposal(
        uint256 _id,
        address _beneficiary
    ) external onlyGovernance {
        require(licenseContractInitialized, "License contract not initialized");

        LicenseData storage ld = _licenseData[_id];
        require(ld.exists, "License proposal doesn't exist");

        licenseContract.mint(
            _beneficiary,
            ld.licenseId,
            ld.licenseAmount,
            "" // No additional data
        );

        emit LicenseProposalExecuted(
            _id,
            _beneficiary,
            ld.licenseId,
            ld.licenseAmount
        );
    }

    /**
     * @dev Set the URI for the license contract
     * @param _newURI The new URI to set
     */
    function setURI(string memory _newURI) external onlyGovernance {
        require(licenseContractInitialized, "License contract not initialized");

        licenseContract.setURI(_newURI);

        emit LicenseURIUpdated(_newURI);
    }

    /**
     * @dev Get license proposal data
     * @param _id The proposal ID
     * @return licenseId The license ID
     * @return licenseAmount The amount of licenses
     */
    function getLicenseData(
        uint256 _id
    ) external view returns (uint256 licenseId, uint256 licenseAmount) {
        require(_licenseData[_id].exists, "License proposal doesn't exist");

        LicenseData storage ld = _licenseData[_id];
        return (ld.licenseId, ld.licenseAmount);
    }

    /**
     * @dev Check if a license proposal exists
     * @param _id The proposal ID
     * @return Whether the proposal exists
     */
    function licenseProposalExists(uint256 _id) external view returns (bool) {
        return _licenseData[_id].exists;
    }

    /**
     * @dev Get the license contract address
     * @return The license contract address
     */
    function getLicenseContractAddress() external view returns (address) {
        require(licenseContractInitialized, "License contract not initialized");
        return address(licenseContract);
    }
}
