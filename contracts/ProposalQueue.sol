pragma solidity ^0.4.24;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./Proposals.sol";
import "./Referendum.sol";

contract ProposalQueue {
    
    using SafeMath for uint;
    
    struct ProposalInfo {
        uint id;
        address[] depositors;
        uint[] deposits;
        bool submitted;
    }
    
    uint minDeposit = 1000;
    
    Proposals proposalCtr;
    Referendum referendumCtr;
    
    ProposalInfo[] public proposalInfos;
    
    constructor(address _proposalsAddr, address _referendumAddr) public {
        proposalCtr = Proposals(_proposalsAddr);
        referendumCtr = Referendum(_referendumAddr);
    }
    
    function newProposal(address _ctrAddr, bytes _args, uint _invalidUntilBlock) external payable returns (uint _id) {
        require(msg.value >= minDeposit, "Deposit not Enough");
        uint idInProposals = proposalCtr.newNormalProposal({
            _ctrAddr: _ctrAddr,
            _args: _args,
            _invalidUntilBlock: _invalidUntilBlock
        });

        ProposalInfo memory pInfo = ProposalInfo({
            id: idInProposals,
            depositors: new address[](0),
            deposits: new uint[](0),
            submitted: false
        });

        _id = proposalInfos.push(pInfo) - 1;
        proposalInfos[_id].depositors.push(msg.sender);
        proposalInfos[_id].deposits.push(msg.value);
    }
    
    function addDeposit(uint _id) public payable returns (bool success) {
        require(msg.value > 0, "Deposit Required");
        ProposalInfo storage pInfo = proposalInfos[_id];
        require(!pInfo.submitted, "Proposal has been submitted");
        uint depositorId = getDepositorId(_id, msg.sender);
        if (depositorId == pInfo.depositors.length) {
            pInfo.depositors.push(msg.sender);
            pInfo.deposits.push(msg.value);
        } else {
            pInfo.deposits[depositorId].add(msg.value);
        }
        return true;
    }
    
    function checkProposals() external returns (uint _idOfMostDeposit) {
        _idOfMostDeposit = proposalInfos.length;
        for (uint _id = 0; _id < proposalInfos.length; _id++) {
            if (!proposalInfos[_id].submitted && getTotalDepositOfProposal(_id) > getTotalDepositOfProposal(_idOfMostDeposit)) {
                _idOfMostDeposit = _id;
            }
        }
        require(_idOfMostDeposit != proposalInfos.length, "No proposal is ready");
        submitProposal(_idOfMostDeposit);
    }
    
    function submitProposal(uint _id) internal returns (uint _idInProposals) {
        ProposalInfo storage pInfo = proposalInfos[_id];
        require(!pInfo.submitted, "Proposal has been submitted");
        pInfo.submitted = true;
        for (uint i = 0; i < pInfo.deposits.length; i++) {
            uint value = pInfo.deposits[i];
            pInfo.deposits[i] = 0;
            pInfo.depositors[i].transfer(value);
        }

        uint pros = getTotalDepositOfProposal(_id);
        // submit to referendum
        referendumCtr.newProposalForVote(_id, Referendum.ProposalOrigin.Concil, pros);
    }
    
    function getDepositorId(uint _proposalId, address _depositor) public view returns (uint _id) {
        address[] memory depositors = proposalInfos[_proposalId].depositors;
        for (_id = 0; _id < depositors.length; _id++) {
            if (depositors[_id] == _depositor) {
                return _id;
            }
        }
    }
    
    function getTotalDepositOfProposal(uint _id) public view returns (uint _total) {
        uint[] storage deposits = proposalInfos[_id].deposits;
        for (uint i = 0; i < deposits.length; i++) {
            _total = _total.add(deposits[i]);
        }
    }

}
