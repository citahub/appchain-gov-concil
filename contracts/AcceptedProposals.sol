pragma solidity ^0.4.24;

contract AcceptedProposals {
    uint pendingTime = 3 days;

    enum Status {
        Vetoed,
        Accepted,
        Unknown
    }

    struct ProposalStatus {
        uint id;
        Status status;
        uint acceptedTime;
    }

    ProposalStatus[] public proposalStatuses;
    
    event NewProposal(uint indexed id);
    event NewVeto(uint indexed id);

    /**
     * @notice Import accpeted propoasl from Proposals
     */
    function newProposal(uint _id) external returns (uint _idInAccepted) {
        emit NewProposal(_id);
        return proposalStatuses.push(ProposalStatus(_id, Status.Accepted, block.timestamp)) - 1;
    }

    function veto(uint _id) external returns (bool success) {
        for (uint i = 0; i < proposalStatuses.length; i++) {
            ProposalStatus storage s = proposalStatuses[i];
            if (s.id == _id) {
                require(s.status == Status.Accepted, "Proposal has been vetoed");
                // removed for 
                // require(s.acceptedTime + pendingTime < block.timestamp, "Proposal has been resolved");
                s.status = Status.Vetoed;
                emit NewVeto(_id);
                return true;
            }
        }
        return false;
    }

    function proposalCount () public view returns (uint count) {
        count = proposalStatuses.length;
    }

    function getStatusById(uint _id) public view returns (Status status) {
        for (uint i = 0; i < proposalStatuses.length; i++) {
            ProposalStatus storage p = proposalStatuses[i];
            if (p.id == _id) {
                return p.status;
            }
        }
        return Status.Unknown;
    }
}
