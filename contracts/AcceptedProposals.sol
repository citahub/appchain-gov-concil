pragma solidity ^0.4.24;

contract AcceptedProposals {
    uint pendingTime = 3 days;

    enum Status {
        Accepted,
        Vetoed
    }
    struct ProposalStatus {
        uint id;
        Status status;
        uint acceptedTime;
    }


    ProposalStatus[] public proposalStatuses;


    /**
     * @notice Import accpeted propoasl from Proposals
     */
    function newAcceptedProposal(uint _id) external returns (uint _idInAccepted) {
        return proposalStatuses.push(ProposalStatus(_id, Status.Accepted, block.timestamp)) - 1;
    }

    function vetoProposal(uint _id) external view returns (bool success) {
        for (uint i = 0; i < proposalStatuses.length; i++) {
            ProposalStatus memory s = proposalStatuses[i];
            if (s.id == _id) {
                require(s.status == Status.Accepted, "Proposal has been vetoed");
                require(s.acceptedTime + pendingTime < block.timestamp, "Proposal has been resolved");
                s.status = Status.Vetoed;
                return true;
            }
        }
        return false;
    }
}
