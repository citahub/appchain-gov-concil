pragma solidity ^0.4.24;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";
import "../node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./Proposals.sol";
import "./ConcilMembers.sol";
import "./Referendum.sol";
import "./AcceptedProposals.sol";

contract Concil is Ownable {
    
    using SafeMath for uint;

    uint public lockTime =  3 days;
    uint public proposalPendingTime = 30 days;

    Proposals proposalCtr;
    ConcilMembers concilMembersCtr;
    Referendum referendumCtr;
    AcceptedProposals acceptedProposalsCtr;

    enum VoteType { Pros, Cons, Abs }
    
    enum ProposalType{ Normal, Veto }
    
    struct Candidate { address addr; uint deposit; uint votes; }
    
    struct Senator { address addr; uint electedTime; }
    
    struct ProposalInfo { uint id; ProposalType pType; uint submitTime; uint lockedTime; address lockedBy; mapping(address => VoteType) votes; }

    ProposalInfo[] public proposalInfos;
    
    mapping(address => uint) votesForCandidates;
    
    constructor(address _proposalsAddr, address _concilMembersAddr, address _referendumAddr, address _acceptedProposalsAddr) public {
        proposalCtr = Proposals(_proposalsAddr);
        concilMembersCtr = ConcilMembers(_concilMembersAddr);
        referendumCtr = Referendum(_referendumAddr);
        acceptedProposalsCtr = AcceptedProposals(_acceptedProposalsAddr);
    }
    
    // propose normal proposal to concil
    function newNormalProposal(address _ctrAddr, bytes _args, uint _invalidUntilBlock) external returns (uint _id) {
        uint IdInProposals = proposalCtr.newNormalProposal(_ctrAddr, _args, _invalidUntilBlock);
        ProposalInfo memory pInfo = ProposalInfo({
            id: IdInProposals,
            pType: ProposalType.Normal,
            submitTime: block.timestamp,
            lockedTime: 0,
            lockedBy: address(0)
        });
        _id = proposalInfos.push(pInfo) - 1;
    }

    // propose veto proposal to concil
    function newVetoProposal(uint _targetId) external returns (uint _id) {
        uint idInProposals = proposalCtr.newVetoProposal(_targetId);

        ProposalInfo memory pInfo = ProposalInfo({
            id: idInProposals,
            pType: ProposalType.Veto,
            submitTime: block.timestamp,
            lockedTime: 0,
            lockedBy: address(0)
        });

        _id = proposalInfos.push(pInfo) - 1;
    }


    // vote for proposal in concil
    function voteForProposal(uint _id, VoteType vType) external returns (bool success) {
        ProposalInfo storage pInfo = proposalInfos[_id];
        require(pInfo.lockedTime == 0 || pInfo.lockedTime + lockTime < block.timestamp, "Proposal is locked");
        require(!(vType == VoteType.Cons && pInfo.lockedBy == msg.sender), "You cannot veto again");
        pInfo.votes[msg.sender] = vType;
        if (vType == VoteType.Cons) {
            pInfo.lockedTime = block.timestamp;
            pInfo.lockedBy = msg.sender;
        }
        return true;
    }

    // check proposal in concil, if passed, submit to referendum
    function checkProposal(uint _id) external returns (bool accepted) {
        ProposalInfo storage pInfo = proposalInfos[_id];
        uint senatorCount = concilMembersCtr.getSenatorCount();
        uint pros = getProsOfPropsal(_id).mul(100).div(senatorCount);
        if (pros == senatorCount) {
            // accepted by 100%;
            if (pInfo.pType == ProposalType.Veto) {
                // cancel a proposal in referendum
                return true;
            }
            // submit to referendum
            referendumCtr.newProposalForVote(_id, Referendum.ProposalOrigin.Concil, 100);
            return true;
        }
        if (pros.mul(2) > senatorCount && pInfo.submitTime + proposalPendingTime < block.timestamp) {
            // accpted by 50% and > 30 days
            return true;
        }
    }
    
    // get pros of proposal in concil
    function getProsOfPropsal(uint _id) public view returns (uint _pros) {
        ProposalInfo storage pInfo = proposalInfos[_id];
        for (uint i = 0; i < concilMembersCtr.getMemberCount(); i++) {
            (address addr, ,ConcilMembers.MemberType mType, , ) = concilMembersCtr.getMember(i);
            if (mType == ConcilMembers.MemberType.Senator && pInfo.votes[addr] == VoteType.Pros) {
                _pros.add(1);
            }
        }
    }
}
