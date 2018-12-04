pragma solidity ^0.4.24;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

/**
 * @notice Referendum
 */

contract Referendum {
    
    using SafeMath for uint;
    
    enum ProposalOrigin {
        Concil,
        ProposalQueue,
        Proposal
    }
    
    enum VoteType {
        Pros,
        Cons,
        Abs
    }

    // the way to handle abs vote
    // AsPros => Abs Vote as Pros Vote
    // AsCons => Abs Vote as Cons Vote
    // AsDis => Abs Vote distributed by propotion of Pros and Cons

    enum AbsType {
        AsPros,
        AsCons,
        AsDis
    }
    
    struct Proposal {
        uint id;
        ProposalOrigin origin;
        uint prosFromConcil;
        bool accepted;
        mapping(address => VoteType) votes;
    }
    
    address[] public voters;
    Proposal[] public proposals;
    
    address public concilAddr;
    address public proposalQueueAddr;
    
    constructor(address _concilAddr, address _proposalQueueAddr) public {
        concilAddr = _concilAddr;
        proposalQueueAddr = _proposalQueueAddr;
    }
    
    function newProposalForVote(uint _id, ProposalOrigin _origin, uint _prosFromConcil) external {
        Proposal memory p = Proposal(_id, _origin, _prosFromConcil, false);
        proposals.push(p);
    }

    function checkProposal(uint _id) public view returns (uint _pros, uint _cons) {
        Proposal storage p = proposals[_id];
        if(p.prosFromConcil == 100) {
            // 100% pros from concil
            (_pros, _cons) = getVotesOfProposal(_id, AbsType.AsPros);
        } else if (p.prosFromConcil > 50) {
            // > 50% from concil
            (_pros, _cons) = getVotesOfProposal(_id, AbsType.AsDis);
        } else if (p.origin == ProposalOrigin.ProposalQueue) {
            (_pros, _cons) = getVotesOfProposal(_id, AbsType.AsCons);
        }
        //TODO: by parent proposal
        if (_pros.mul(2) > _cons) {
            // accepted
        }
    }
    
    function _voteFor(uint _id, VoteType vType) internal returns (bool _success) {
        Proposal storage p = proposals[_id];
        _addVoter(msg.sender);
        p.votes[msg.sender] = vType;
        return true;
    }
    
    function _addVoter(address _voter) internal {
        for (uint i = 0; i < voters.length; i++){
            if (_voter == voters[i]) {
                return;
            }
        }
        voters.push(_voter);
    }
    
    function getVotesOfProposal(uint _id, AbsType aType) public view returns (uint _pros, uint _cons) {
        Proposal storage p = proposals[_id];
        for (uint i = 0; i < voters.length; i++) {
            if (p.votes[voters[i]] == VoteType.Pros) {
                _pros.add(voters[i].balance);
            } else if (p.votes[voters[i]] == VoteType.Cons) {
                _cons.add(voters[i].balance);
            } else if (p.votes[voters[i]] == VoteType.Abs) {
                if (aType == AbsType.AsPros) {
                    _pros.add(voters[i].balance);
                } else if (aType == AbsType.AsCons) {
                    _cons.add(voters[i].balance);
                }
            }
        }
    }
}
