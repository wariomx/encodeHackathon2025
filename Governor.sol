// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./Token.sol";
import "./Treasury.sol";
import "./LicenseManager.sol";

/**
 * @title SoftLawGovernance
 * @dev Core governance contract that handles proposals and voting
 */
contract SoftLawGovernance {
    // DAO VARIABLES
    uint256 public votingQuorum;
    uint256 public lockingPeriod;

    enum VoteType {
        Nay,
        Aye,
        Abstain
    }
    enum ProposalType {
        Treasury,
        Admin,
        License
    }

    // Basic proposal info - common to all proposal types
    struct ProposalCore {
        string name;
        string description;
        address proponent;
        address beneficiary;
        uint256 createdAt;
        bool executed;
        ProposalType proposalType;
    }

    // Voting data separated to avoid stack too deep errors
    struct ProposalVotes {
        uint256 ayeVotes;
        uint256 nayVotes;
        uint256 abstainVotes;
        mapping(address => bool) hasVoted;
    }

    // Admin-specific data
    struct AdminData {
        bytes callData;
    }

    // Treasuary-specific data
    struct TreasuryData {
        bytes callData;
    }

    // Mapping for proposal types
    mapping(uint256 => ProposalCore) private _proposalCore;
    mapping(uint256 => ProposalVotes) private _proposalVotes;
    mapping(uint256 => AdminData) private _adminData;
    mapping(uint256 => TreasuryData) private _treasuryData;

    uint256 public proposalCount;

    mapping(address => bool) public isMember;
    address[] public memberList;

    SoftLawToken public governanceToken;
    SoftLawTreasury public treasury;
    SoftLawLicenseManager public licenseManager;

    // Events
    event ProposalCreated(
        uint256 indexed id,
        address indexed proposer,
        ProposalType proposalType
    );
    event VoteCast(uint256 indexed id, address indexed voter, VoteType vote);
    event ProposalExecuted(uint256 indexed id);
    event MemberAdded(address indexed member);
    event MemberRemoved(address indexed member);

    modifier onlyMember() {
        require(isMember[msg.sender], "Not a Softlaw DAO member");
        _;
    }

    modifier onlySelf() {
        require(msg.sender == address(this), "Only DAO can call");
        _;
    }

    constructor(
        string memory tokenName,
        string memory tokenSymbol,
        uint256 tokenSupply
    ) {
        votingQuorum = 1;
        lockingPeriod = 60;

        governanceToken = new SoftLawToken(
            tokenName,
            tokenSymbol,
            tokenSupply,
            address(this)
        );
        governanceToken.transfer(
            address(this),
            governanceToken.balanceOf(msg.sender)
        );

        treasury = new SoftLawTreasury(address(governanceToken));
        licenseManager = new SoftLawLicenseManager(address(this));

        _addMember(msg.sender);
    }

    function _addMember(address _member) internal {
        require(!isMember[_member], "Already a member");
        isMember[_member] = true;
        memberList.push(_member);
        emit MemberAdded(_member);
    }

    function _removeMember(address _member) internal {
        require(isMember[_member], "Not a member");
        isMember[_member] = false;
        emit MemberRemoved(_member);
    }

    // Creates a core proposal record with common data
    function _createProposalCore(
        string memory _name,
        string memory _description,
        address _beneficiary,
        ProposalType _type
    ) internal returns (uint256) {
        uint256 id = proposalCount++;

        ProposalCore storage pc = _proposalCore[id];
        pc.name = _name;
        pc.description = _description;
        pc.proponent = msg.sender;
        pc.beneficiary = _beneficiary;
        pc.createdAt = block.timestamp;
        pc.executed = false;
        pc.proposalType = _type;

        return id;
    }

    function createTreasuryProposal(
        string memory _name,
        string memory _description,
        address _beneficiary,
        uint256 _requestedTokens,
        bytes memory _callData
    ) public onlyMember returns (uint256) {
        uint256 id = _createProposalCore(
            _name,
            _description,
            _beneficiary,
            ProposalType.Treasury
        );

        TreasuryData storage td = _treasuryData[id];
        td.callData = _callData;
        // Call treasury to register this proposal
        treasury.registerTreasuryProposal(id, _requestedTokens);

        emit ProposalCreated(id, msg.sender, ProposalType.Treasury);
        return id;
    }

    function createAdminProposal(
        string memory _name,
        string memory _description,
        address _beneficiary,
        bytes memory _callData
    ) public onlyMember returns (uint256) {
        uint256 id = _createProposalCore(
            _name,
            _description,
            _beneficiary,
            ProposalType.Admin
        );

        AdminData storage ad = _adminData[id];
        ad.callData = _callData;

        emit ProposalCreated(id, msg.sender, ProposalType.Admin);
        return id;
    }

    function createLicenseProposal(
        string memory _name,
        string memory _description,
        address _beneficiary,
        uint256 _licenseId,
        uint256 _licenseAmount
    ) public onlyMember returns (uint256) {
        uint256 id = _createProposalCore(
            _name,
            _description,
            _beneficiary,
            ProposalType.License
        );

        // Call license manager to register this proposal
        licenseManager.registerLicenseProposal(id, _licenseId, _licenseAmount);

        emit ProposalCreated(id, msg.sender, ProposalType.License);
        return id;
    }

    function vote(uint256 _id, VoteType _voteType) public onlyMember {
        require(_id < proposalCount, "Invalid proposal ID");
        require(!_proposalCore[_id].executed, "Already executed");

        ProposalVotes storage votes = _proposalVotes[_id];
        require(!votes.hasVoted[msg.sender], "Already voted");

        votes.hasVoted[msg.sender] = true;

        if (_voteType == VoteType.Aye) votes.ayeVotes++;
        else if (_voteType == VoteType.Nay) votes.nayVotes++;
        else votes.abstainVotes++;

        emit VoteCast(_id, msg.sender, _voteType);
    }

    function hasProposalPassed(uint256 _id) public view returns (bool) {
        require(_id < proposalCount, "Invalid proposal ID");

        ProposalVotes storage votes = _proposalVotes[_id];
        uint256 totalVotes = votes.ayeVotes +
            votes.nayVotes +
            votes.abstainVotes;
        return totalVotes >= votingQuorum && votes.ayeVotes > votes.nayVotes;
    }

    function executeProposal(uint256 _id) public onlyMember {
        require(_id < proposalCount, "Invalid proposal ID");

        ProposalCore storage pc = _proposalCore[_id];
        require(!pc.executed, "Already executed");
        require(hasProposalPassed(_id), "Not enough support");
        require(
            block.timestamp >= pc.createdAt + lockingPeriod,
            "Locking period active"
        );

        pc.executed = true;

        if (pc.proposalType == ProposalType.Treasury) {
            treasury.executeTreasuryProposal(_id, pc.beneficiary);
        } else if (pc.proposalType == ProposalType.Admin) {
            AdminData storage ad = _adminData[_id];
            if (ad.callData.length > 0) {
                (bool success, ) = address(this).call(ad.callData);
                require(success, "Admin execution failed");
            }
        } else if (pc.proposalType == ProposalType.License) {
            licenseManager.executeLicenseProposal(_id, pc.beneficiary);
        }

        emit ProposalExecuted(_id);
    }

    // ====== Call Data Helpers ======

    function createAddMemberCallData(
        address _member
    ) public pure returns (bytes memory) {
        return abi.encodeWithSignature("addMemberExternal(address)", _member);
    }

    function createRemoveMemberCallData(
        address _member
    ) public pure returns (bytes memory) {
        return
            abi.encodeWithSignature("removeMemberExternal(address)", _member);
    }

    function createChangeQuorumCallData(
        uint256 _newQuorum
    ) public pure returns (bytes memory) {
        return
            abi.encodeWithSignature("changeVotingQuorum(uint256)", _newQuorum);
    }

    function createChangeLockingPeriodCallData(
        uint256 _newPeriod
    ) public pure returns (bytes memory) {
        return
            abi.encodeWithSignature("changeLockingPeriod(uint256)", _newPeriod);
    }

    function createSetLicenseURICallData(
        string memory _newURI
    ) public pure returns (bytes memory) {
        return abi.encodeWithSignature("setLicenseURI(string)", _newURI);
    }

    function mintSoftLawTokens(
        uint256 _amount
    ) public pure returns (bytes memory) {
        return abi.encodeWithSignature("mintTokens(uint256)", _amount);
    }

    // ====== Admin-callable Functions ======
    function addMemberExternal(address _newMember) public onlySelf {
        _addMember(_newMember);
    }

    function removeMemberExternal(address _member) public onlySelf {
        _removeMember(_member);
    }

    function changeVotingQuorum(uint256 _newQuorum) public onlySelf {
        votingQuorum = _newQuorum;
    }

    function changeLockingPeriod(uint256 _newPeriod) public onlySelf {
        lockingPeriod = _newPeriod;
    }

    function setLicenseURI(string memory _newURI) public onlySelf {
        licenseManager.setURI(_newURI);
    }

    function mintTokens(uint256 _amount) public onlySelf {
        governanceToken.mint(address(treasury), _amount);
    }

    // ====== View Access ======
    // Breaking up the view functions to avoid stack too deep errors

    function getProposalCore(
        uint256 _id
    )
        public
        view
        returns (
            string memory name,
            string memory description,
            address proponent,
            address beneficiary,
            uint256 createdAt,
            bool executed,
            ProposalType proposalType
        )
    {
        require(_id < proposalCount, "Invalid proposal ID");
        ProposalCore storage pc = _proposalCore[_id];

        return (
            pc.name,
            pc.description,
            pc.proponent,
            pc.beneficiary,
            pc.createdAt,
            pc.executed,
            pc.proposalType
        );
    }

    function getProposalVotes(
        uint256 _id
    )
        public
        view
        returns (uint256 ayeVotes, uint256 nayVotes, uint256 abstainVotes)
    {
        require(_id < proposalCount, "Invalid proposal ID");
        ProposalVotes storage votes = _proposalVotes[_id];

        return (votes.ayeVotes, votes.nayVotes, votes.abstainVotes);
    }

    function hasVoted(uint256 _id, address _voter) public view returns (bool) {
        require(_id < proposalCount, "Invalid proposal ID");
        return _proposalVotes[_id].hasVoted[_voter];
    }

    function totalProposals() public view returns (uint256) {
        return proposalCount;
    }

    function getMemberCount() public view returns (uint256) {
        return memberList.length;
    }
}
