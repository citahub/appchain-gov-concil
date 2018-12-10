pragma solidity ^0.4.24;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";
import "../node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./Proposals.sol";
import "./ConcilMembers.sol";
import "./Referendum.sol";
import "./AcceptedProposals.sol";

contract Concil is Ownable {
    
    using SafeMath for uint;

    /// @notice lockTime, if a proposal is denied, it's locked 3 days
    uint public lockTime =  3 days;
    /// @notice 
    uint public proposalPendingTime = 30 days;

    Proposals proposalCtr;
    ConcilMembers concilMembersCtr;
    Referendum referendumCtr;
    AcceptedProposals acceptedProposalsCtr;
    
    /// @notice vote type
    /// pros to agree the proposal
    /// cons to disagree the proposal
    /// abs to show no idea about the proposal
    enum VoteType { 
        Pros, 
        Cons, 
        Abs
    }
    
    /// @notice proposal type
    /// normal proposal
    /// veto proposal to veto a cancel an pending proposal in referendum
    enum ProposalType{ 
        Normal, 
        Veto 
    }
    
    struct ProposalInfo { 
        uint id; // proposal id in proposal contract
        ProposalType pType;  // proposal type, normal or veto
        uint submitTime; // when submitted
        uint lockedTime; // when locked
        address lockedBy; // who locked
        mapping(address => VoteType) votes; // votes
    }

    ProposalInfo[] public proposalInfos;
    
    mapping(address => uint) votesForCandidates;
    event NewProposal(uint indexed id, address indexed proposer, ProposalType pType);
    
    constructor(
        address _proposalsAddr,
        address _concilMembersAddr,
        address _referendumAddr,
        address _acceptedProposalsAddr
    ) public {
        proposalCtr = Proposals(_proposalsAddr);
        concilMembersCtr = ConcilMembers(_concilMembersAddr);
        referendumCtr = Referendum(_referendumAddr);
        acceptedProposalsCtr = AcceptedProposals(_acceptedProposalsAddr);
    }
    
    /// @notice propose normal one
    /// @param _ctrAddr target contract address
    /// @param _args target function and parameters
    /// @param _invalidUntilBlock proposal is invalid until the block number reaches
    function newNormalProposal(
        address _ctrAddr,
        bytes _args,
        uint _invalidUntilBlock)
    external returns (uint _id) {
        uint idInProposals = proposalCtr.newNormalProposal(_ctrAddr, _args, _invalidUntilBlock);
        ProposalInfo memory pInfo = ProposalInfo({
            id: idInProposals,
            pType: ProposalType.Normal,
            submitTime: block.timestamp,
            lockedTime: 0,
            lockedBy: address(0)
        });
        _id = proposalInfos.push(pInfo) - 1;
        emit NewProposal(_id, msg.sender, ProposalType.Normal);
    }

    /// @notice propose a veto one
    // / @param _targetId, the proposal id to veto
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
        emit NewProposal(_id, msg.sender, ProposalType.Veto);
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
        uint pros = getProsOfProposalById(_id).mul(100).div(senatorCount);
        if (pros == senatorCount) {
            // accepted by 100%;
            if (pInfo.pType == ProposalType.Veto) {
                // cancel a proposal in referendum
                return true;
            }
            // submit to referendum
            referendumCtr.newProposal(_id, 100);
            return true;
        }
        if (pros.mul(2) > senatorCount && pInfo.submitTime + proposalPendingTime < block.timestamp) {
            // accpted by 50% and > 30 days
            return true;
        }
    }
    
    // get pros of proposal in concil
    function getProsOfProposalById(uint _id) public view returns (uint _pros) {
        ProposalInfo storage pInfo = proposalInfos[_id];
        for (uint i = 0; i < concilMembersCtr.getMemberCount(); i++) {
            (address addr, ,ConcilMembers.MemberType mType, , ) = concilMembersCtr.getMember(i);
            if (mType == ConcilMembers.MemberType.Senator && pInfo.votes[addr] == VoteType.Pros) {
                _pros.add(1);
            }
        }
    }
    function getProposalCount() public view returns (uint count) {
        count = proposalInfos.length;
    }
}
