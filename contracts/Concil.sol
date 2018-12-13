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
        NotYet,
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
    event NewVote(uint indexed id, VoteType indexed vType, address voter);
    event ProposalToReferendum(uint indexed id, uint indexed prosFromConcil);
    event ProposalNotAccepted(uint indexed id, uint indexed prosFromConcil);
    
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
    /// @notice vote for proposal
    /// @param _id the id of proposal
    /// @param _vType the vote type, Pros, Cons, or Abs
    function voteForProposal(uint _id, VoteType _vType) external returns (bool success) {

        ProposalInfo storage pInfo = proposalInfos[_id];

        // if lockedTime > 0 and lockedTime + lockTime < now, the proposal is still locked
        // require(pInfo.lockedTime == 0 || pInfo.lockedTime + lockTime < block.timestamp, "Proposal is locked");
        // if vote is type of veto and msg.sender is the last lock man, refuse
        require(!(_vType == VoteType.Cons && pInfo.lockedBy == msg.sender), "You cannot veto again");

        pInfo.votes[msg.sender] = _vType;
        if (_vType == VoteType.Cons) {
            pInfo.lockedTime = block.timestamp;
            pInfo.lockedBy = msg.sender;
        }
        emit NewVote(_id, _vType, msg.sender);
        return true;
    }

    // check proposal in concil, if passed, submit to referendum
    /// @notice check proposal
    function checkProposal(uint _id) external returns (bool accepted) {
        ProposalInfo storage pInfo = proposalInfos[_id];
        uint senatorCount = concilMembersCtr.getSenatorCount();
        (uint pros,,) = getVotesOfProposalById(_id);
        if (pros == senatorCount) {
            // accepted by 100%;
            emit ProposalToReferendum(_id, 100);
            if (pInfo.pType == ProposalType.Veto) {
                // cancel a proposal in accepted proposals
                acceptedProposalsCtr.veto(_id);
                return true;
            }
            // submit to referendum
            referendumCtr.newProposal(_id, 100);
            return true;
        }
        if (pros.mul(2) > senatorCount && pInfo.submitTime + proposalPendingTime < block.timestamp) {
            // accpted by 50% and > 30 days
            uint _pros = pros.mul(100).div(senatorCount);
            emit ProposalToReferendum(_id, _pros);
            return true;
        }
        emit ProposalNotAccepted(_id, pros);
    }
    
    // event Test(VoteType _vType);
    /// @notice get votes of proposal by id
    /// @param _id id of proposal
    function getVotesOfProposalById(uint _id) public view returns (uint pros, uint cons, uint abs) {
        ProposalInfo storage pInfo = proposalInfos[_id];
        // emit Test(pInfo.votes[0x627306090abaB3A6e1400e9345bC60c78a8BEf57]);
        for(uint i = 0; i < concilMembersCtr.getMemberCount()+1; i++) {
            (address addr, , ConcilMembers.MemberType mType, , ) = concilMembersCtr.members(i);
            // emit Test(pInfo.votes[addr]);
            if (mType != ConcilMembers.MemberType.Senator) continue;
            if (pInfo.votes[addr] == VoteType.Pros) {
                pros = pros.add(1);
            } else if (pInfo.votes[addr] == VoteType.Cons) {
                cons = cons.add(1);
            } else if (pInfo.votes[addr] == VoteType.Abs) {
                abs = abs.add(1);
            }
        }
    }
    
    function getVoteOfProposalByIdOfVoter(uint _id, address _proposer) public view returns (VoteType vType) {
        vType = proposalInfos[_id].votes[_proposer];
    }

    function getProposalCount() public view returns (uint count) {
        count = proposalInfos.length;
    }
}
