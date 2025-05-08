// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title SoftlawCopyrightsLicense
 * @dev ERC1155 contract for representing copyright licenses
 * The SoftLawDAO is the owner of this contract and controls license minting
 */
contract SoftlawCopyrightsLicense is
    ERC1155,
    Ownable,
    ERC1155Burnable,
    ERC1155Supply
{
    // License metadata
    mapping(uint256 => string) public licenseMetadata;

    // License types and their meaning/description
    mapping(uint256 => string) public licenseTypes;

    // License creation events
    event LicenseTypeCreated(uint256 indexed licenseId, string description);
    event LicenseMetadataUpdated(uint256 indexed licenseId, string metadata);

    constructor(
        address _owner
    )
        ERC1155("")
        Ownable(_owner) // Initially owned by deployer (should be the DAO)
    {
        // Initialize with some standard license types
        _createLicenseType(1, "Full Copyright License");
        _createLicenseType(2, "Commercial Use License");
        _createLicenseType(3, "Educational Use License");
        _createLicenseType(4, "Non-Commercial License");
    }

    /**
     * @dev Create a new license type with description
     * @param licenseId The ID for the new license type
     * @param description Description of what this license permits
     */
    function createLicenseType(
        uint256 licenseId,
        string memory description
    ) public onlyOwner {
        _createLicenseType(licenseId, description);
    }

    /**
     * @dev Internal function to create license types
     */
    function _createLicenseType(
        uint256 licenseId,
        string memory description
    ) internal {
        licenseTypes[licenseId] = description;
        emit LicenseTypeCreated(licenseId, description);
    }

    /**
     * @dev Set metadata URI for all tokens
     */
    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    /**
     * @dev Set metadata for specific license type
     */
    function setLicenseMetadata(
        uint256 licenseId,
        string memory metadata
    ) public onlyOwner {
        licenseMetadata[licenseId] = metadata;
        emit LicenseMetadataUpdated(licenseId, metadata);
    }

    /**
     * @dev Mint new license tokens to an account
     * @param account The recipient address
     * @param id The license ID to mint
     * @param amount Number of licenses to mint
     * @param data Additional data (if needed)
     */
    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public onlyOwner {
        require(
            bytes(licenseTypes[id]).length > 0,
            "License type does not exist"
        );
        _mint(account, id, amount, data);
    }

    /**
     * @dev Mint multiple license types in a batch
     */
    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public onlyOwner {
        for (uint256 i = 0; i < ids.length; i++) {
            require(
                bytes(licenseTypes[ids[i]]).length > 0,
                "License type does not exist"
            );
        }
        _mintBatch(to, ids, amounts, data);
    }

    /**
     * @dev Returns the URI for a given license ID
     */
    function uri(uint256 id) public view override returns (string memory) {
        return
            bytes(licenseMetadata[id]).length > 0
                ? licenseMetadata[id]
                : super.uri(id);
    }

    /**
     * @dev Get description of a license type
     */
    function getLicenseDescription(
        uint256 licenseId
    ) public view returns (string memory) {
        return licenseTypes[licenseId];
    }

    // The following functions are overrides required by Solidity.
    function _update(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values
    ) internal override(ERC1155, ERC1155Supply) {
        super._update(from, to, ids, values);
    }
}
