pragma solidity ^0.4.24;
import "./AcceptedProposals.sol";

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

/**
 * @notice Referendum
 */

contract Referendum {
    
    using SafeMath for uint;
    
    /// @notice proposal comes from
    /// 1. concil submitted by senator
    /// 2. proposal queue submitted by normal account
    /// 3. parent proposal
    enum ProposalOrigin {
        Concil,
        ProposalQueue,
        Proposal
    }
    
    /// @notice types of vote in referendum
    /// pros to agree the proposal
    /// cons to disagree the proposal
    /// abs to quit voting for the proposal
    enum VoteType {
        Pros,
        Cons,
        Abs
    }

    // the way to handle abs vote
    // AsPros => Abs Vote as Pros Vote
    // AsCons => Abs Vote as Cons Vote
    // AsDis => Abs Vote distributed by propotion of Pros and Cons

    /// @notice the way threating abs votes
    /// 1. asPros to treat abs votes as pros
    /// 2. asCons to treat abs votes as cons
    /// 3. asDis to divide abs votes into two parts according to ratio of pros/cons
    enum AbsType {
        AsPros,
        AsCons,
        AsDis
    }
    
    /// @notice proposal structure, including
    struct Proposal {
        uint id; // proposal id in ProposalCtr
        ProposalOrigin origin; // proposal origin
        uint prosFromConcil; // percentage of pros in concil
        bool accepted; // status of proposal, accpeted or not
        address[] voters; // voter list
        mapping(address => VoteType) votes; // votes from normal account
    }
    
    // address[] public voters;
    Proposal[] public proposals; // proposal list
    
    address public concilAddr;
    address public proposalQueueAddr;
    // address public acceptedProposalsAddr;
    AcceptedProposals acceptedProposalsCtr;

    event NewProposal(uint indexed _id, ProposalOrigin indexed _origin, uint indexed _prosFromConcil);
    event NewVote(uint indexed _id, VoteType indexed _vType, address indexed voter);
    event CheckOnProposal(uint indexed id, bool indexed accepted);

    modifier proposalShouldNotExists(uint _id) {
        uint index = getProposalIndex(_id);
        require(index == proposals.length, "Proposal exists");
        _;
    }

    modifier proposalShouldExist(uint _id) {
        uint index = getProposalIndex(_id);
        require(index < proposals.length, "Proposal not exists");
        _;
    }
    
    constructor(address _concilAddr, address _proposalQueueAddr, address _acceptedProposalsAddr) public {
        concilAddr = _concilAddr;
        proposalQueueAddr = _proposalQueueAddr;
        acceptedProposalsCtr = AcceptedProposals(_acceptedProposalsAddr);
    }

    function setConcilAddr(address _concilAddr) public {
        concilAddr = _concilAddr;
    }

    function setProposalQueueAddr(address _proposalQueueAddr) public {
        proposalQueueAddr = _proposalQueueAddr;
    }

    
    /// @notice add new proposal
    /// @param _id id of proposal in Proposals
    /// @param _prosFromConcil props from concil, [0, 100]
    function newProposal(uint _id, uint _prosFromConcil) external proposalShouldNotExists(_id) {

        ProposalOrigin _origin = ProposalOrigin.Proposal;
        if (msg.sender == concilAddr) {
            _origin = ProposalOrigin.Concil;
        } else if (msg.sender == proposalQueueAddr) {
            _origin = ProposalOrigin.ProposalQueue;
        }

        Proposal memory p = Proposal(_id, _origin, _prosFromConcil, false, new address[](0));
        proposals.push(p);
        emit NewProposal(_id, _origin, _prosFromConcil);
    }

    /// @notice vote for proposal
    /// @param _id id for the proposal to vote
    /// @param _vType vote type, pros, cons or abs
    function voteForProposal(uint _id, VoteType _vType) external proposalShouldExist(_id) returns (bool success) {
        uint idx = getProposalIndex(_id);
        Proposal storage p = proposals[idx];

        for (uint vIdx = 0; vIdx < p.voters.length; vIdx++) {
            if (p.voters[vIdx] == msg.sender) {
                break;
            }
        }

        if (vIdx == p.voters.length) {
            p.voters.push(msg.sender);
        }

        p.votes[msg.sender] = _vType;
        emit NewVote(_id, _vType, msg.sender);
        return true;
    }

    /// @notice get votes of proposal by proposal id
    /// @param _id proposal id
    /// @return (uint pros, uint cons, uint abs)
    function getVotesOfProposalById(uint _id) 
    public 
    proposalShouldExist(_id) 
    view 
    returns (uint pros, uint cons, uint abs) 
    {
        uint idx = getProposalIndex(_id);
        Proposal storage p = proposals[idx];
        for (uint i = 0; i < p.voters.length; i++) {
            VoteType v = p.votes[p.voters[i]];
            if (v == VoteType.Pros) {
                pros = pros.add(1);
            } else if (v == VoteType.Cons) {
                cons = cons.add(1);
            } else {
                abs = abs.add(1);
            }
        }
    }

    /// @notice check proposal votes
    /// if proposal is from concil with 100 prosFromConcil
    ///    1. all abs are regarded as pros
    ///    2. > 50% pros makes the proposal passed
    ///
    /// if proposal is from concil with >50 prosFromConcil
    ///    1. divide abs into two parts according to pros/cons
    ///    2. > 50% pros makes the proposal passed
    /// 
    /// if proposal is from proposal queue
    ///    1. all abs are regarded as cons
    ///    2. > 50% pros makes the proposal passed
    ///
    /// if proposal is from parent proposal
    ///    1. inherits its parent proposal's standard
    function checkProposalById(uint _id) public returns (bool accepted) {
        // Proposal storage p = proposals[_id];
        uint idx = getProposalIndex(_id);
        Proposal storage p = proposals[idx];
        (uint pros, uint cons, uint abs) = getVotesOfProposalById(_id);
        uint base = 10000;
        pros = pros.mul(base);
        cons = cons.mul(base);
        abs = abs.mul(base);

        if(p.prosFromConcil == 100) {
            // 100% pros from concil
            pros = pros.add(abs);
        } else if (p.prosFromConcil > 50) {
            // > 50% from concil
            uint total = pros.add(cons);
            uint absToPros = abs.mul(pros).div(total);
            uint absToCons = abs.mul(cons).div(total);
            pros = pros.add(absToPros);
            cons = cons.add(absToCons);
        } else if (p.origin == ProposalOrigin.ProposalQueue) {
            cons = cons.add(abs);
        }
        //TODO: by parent proposal
        if (pros.mul(2) > p.voters.length.mul(base)) {
            // proposal passed
            p.accepted = true;
            acceptedProposalsCtr.newProposal(_id);
            emit CheckOnProposal(_id, true);
            return true;
        }
        emit CheckOnProposal(_id, false);
        return false;
    }

    function proposalCount() public view returns (uint count) {
        count = proposals.length;
    }

    function getProposalIndex(uint _id) public view returns (uint _index) {
        for (_index = 0; _index < proposals.length; _index++) {
            if (proposals[_index].id == _id) {
                return _index;
            }
        }
    }
}
