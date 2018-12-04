pragma solidity ^0.4.24;

contract Proposals {

    struct NormalProposal {
        address proposer;
        address ctrAddr;
        bytes args;
        uint invalidUntilBlock;
    }
    
    struct VetoProposal {
        address proposer;
        uint targetId;
    }
    
    NormalProposal[] public normalProposals;
    VetoProposal[] public vetoProposals;
    
    event NewNormalProposal(address indexed _proposer, uint indexed _id, address _ctrAddr, bytes _args);
    event NewVetoProposal(address indexed _proposer, uint indexed _targetId);
    
    function newNormalProposal(address _ctrAddr, bytes _args, uint _invalidUntilBlock) external returns (uint _id) {
        NormalProposal memory p = NormalProposal(msg.sender, _ctrAddr, _args, _invalidUntilBlock);
        _id = normalProposals.push(p) - 1;
        emit NewNormalProposal(msg.sender, _id, _ctrAddr, _args);
    }
    
    function newVetoProposal(uint _targetId) external returns (uint _id) {
        VetoProposal memory p = VetoProposal(msg.sender, _targetId);
        _id = vetoProposals.push(p) - 1;
        emit NewVetoProposal(msg.sender, _targetId);
    }
}
