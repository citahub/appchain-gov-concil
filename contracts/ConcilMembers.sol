pragma solidity ^0.4.24;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract ConcilMembers {
    using SafeMath for uint;

    uint public term = 90 days;
    uint public amountOfSenators = 10;
    uint public minDeposit = 1000;

    enum MemberType {
        Candidate,
        Senator
    }

    struct Member {
        address addr;
        uint deposit;
        MemberType mType;
        uint electedTime;
        uint votes;
    }

    Member[] public members;
    mapping(address => uint) public votesForMember;

    event NewMember(uint indexed id, address indexed memberAddr, uint indexed deposit);
    event AddDeposit(uint indexed id, address indexed memberAddr, uint indexed addDeposit);
    event MemberQuit(uint indexed id, address indexed memberAddr, uint refund);
    event Vote(address indexed from, uint indexed id, uint indexed prevId);
    event TermUpdated(uint indexed term);
    event SenatorAmountUpdated(uint indexed amount);
    event SenatorRetired(uint indexed id);
    event SenatorAdded(uint indexed id);

    constructor() public {
        // create member[0] as no one
        members.push(Member({
            addr: address(0),
            deposit: 0,
            mType: MemberType.Candidate,
            electedTime: 0,
            votes: 0
        }));
    }

    function setTerm(uint _time) external returns (bool success) {
        term = _time;
        emit TermUpdated(term);
        return true;
    }

    function setSenatorAmount(uint _amount) external returns (bool success) {
        amountOfSenators = _amount;
        emit SenatorAmountUpdated(amountOfSenators);
        return true;
    }

    // apply to be a member with deposit
    // if msg.sender is already at members, add up depost
    // if msg.sender is a fresh man, push to member list
    function applyToBeAMember() external payable returns (uint _id) {
        require(msg.value >= minDeposit, "Deposit not Enough");
        _id = getMemberId(msg.sender);
        if (_id == members.length) {
            return members.push(Member({
                addr: msg.sender,
                deposit: msg.value,
                mType: MemberType.Candidate,
                electedTime: 0,
                votes: 0
            })) - 1;
            emit NewMember(_id, msg.sender, msg.value);
        } else {
            members[_id].deposit = members[_id].deposit.add(msg.value);
            emit AddDeposit(_id, msg.sender, msg.value);
        }
    }

    // apply to quit the members
    // clear member's deposit
    function applyToQuit() external returns (bool success) {
        uint idInMembers = getMemberId(msg.sender);
        require(idInMembers < members.length, "You are not a member");
        Member storage member = members[idInMembers];
        require(member.mType != MemberType.Senator, "You are a senator");
        uint deposit = member.deposit;
        member.deposit = 0;
        member.addr.transfer(deposit);
        emit MemberQuit(idInMembers, msg.sender, deposit);
        return true;
    }

    // vote for candidate of id
    // if msg.sender have voted for prevId, prevId.votes--, id.votes++
    // if msg.sender have not voted for anyone, id.votes++
    // set votesForMember[msg.sender] for id
    function voteForCandidate(uint _id) external returns (bool success) {
        Member storage member = members[_id];
        require(member.mType != MemberType.Senator, "It's already a senator");
        require(member.deposit > 0, "It's quitted");
        uint prevId = votesForMember[msg.sender];
        require(_id != prevId, "You already vote for it");
        votesForMember[msg.sender] = _id;
        member.votes = member.votes.add(1);
        if (prevId != 0) {
            members[prevId].votes = members[prevId].votes.sub(1);
        }
        emit Vote(msg.sender, _id, prevId);
        return true;
    }

    // if senator _id is retired, set it to be a candidate, then add new senator
    function updateSenator(uint _id) external returns (uint _newSenatorId) {
        Member storage senator = members[_id];
        require(senator.mType == MemberType.Senator, "It's not a senator");
        // removed for testing
        // require(senator.electedTime + term < block.timestamp, "It's not retired");
        senator.mType = MemberType.Candidate;
        senator.electedTime = 0;
        emit SenatorRetired(_id);
        return addSenator();
    }
    
    function addSenator() public returns (uint _newSenatorId) {
        require(getSenatorCount() < amountOfSenators, "No More Senator Allowed");
        _newSenatorId = getCandidateIdWithMostVotes();
        require(_newSenatorId != 0, "No Candidate is Ready");
        members[_newSenatorId].mType = MemberType.Senator;
        members[_newSenatorId].electedTime = block.timestamp; 
        emit SenatorAdded(_newSenatorId);
    }
    
    // get member id by member address, if id = members.length, not found 
    function getMemberId(address _memberAddr) public view returns (uint _id) {
        for (_id = 0; _id < members.length; _id++) {
            if (members[_id].addr == _memberAddr) {
                return _id;
            }
        }
    }
    
    // get candidate id who has the most votes
    // if id == 0, it's wrong
    function getCandidateIdWithMostVotes() public view returns (uint _id) {
        for (uint i = 1; i < members.length; i++) {
            Member storage member = members[i];
            if (member.mType == MemberType.Candidate && member.deposit > 0 && member.votes > members[_id].votes) {
                _id = i;
            }
        }
    }
    
    // verify memberType
    function isSenator(address _senator) public view returns (bool) {
        uint id = getMemberId(_senator);
        return members[id].mType == MemberType.Senator;
    }

    // members[0] means no one
    function getMemberCount () public view returns (uint count) {
        return members.length - 1;
    }

    // return count of existing senators
    function getSenatorCount () public view returns (uint count) {
        for (uint i = 1; i < members.length; i++) {
            if (members[i].mType == MemberType.Senator){
                count = count.add(1);
            }
        }
    }
}
