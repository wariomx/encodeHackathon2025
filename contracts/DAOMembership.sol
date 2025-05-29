// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

// todo => implement NFT ERC1155 as membership
import "@openzeppelin/contracts/access/Ownable.sol";

contract DaoMembership is Ownable {
    mapping(address => bool) public isMember;
    address[] private memberList;

    event MemberAdded(address indexed member);

    event MemberRemoved(address indexed member);

    constructor(
        address _initialMember,
        address _initialOwner
    ) Ownable(_initialOwner) {
        _addMember(_initialMember);
    }

    function _addMember(address _member) public onlyOwner {
        require(!isMember[_member], "Already a member");
        isMember[_member] = true;
        memberList.push(_member);
        emit MemberAdded(_member);
    }

    function _removeMember(address _member) public onlyOwner {
        require(isMember[_member], "Not a member");
        isMember[_member] = false;
        emit MemberRemoved(_member);
    }

    function getMemberCount() external view returns (uint256) {
        return memberList.length;
    }

    function changeOwnership(address _newOwner) public onlyOwner {
        transferOwnership(_newOwner);
    }
}
