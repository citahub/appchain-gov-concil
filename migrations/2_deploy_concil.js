const Concil = artifacts.require('Concil')
const ConcilMembers = artifacts.require('ConcilMembers')
const Proposals = artifacts.require('Proposals')
const AcceptedProposals = artifacts.require('AcceptedProposals')
const Referendum = artifacts.require('Referendum')

const contracts = {}

module.exports = deployer => {
  deployer
    .deploy(ConcilMembers)
    .then(ins => {
      contracts.concilMembers = ins
      return deployer.deploy(Proposals)
    })
    .then(ins => {
      contracts.proposals = ins
      return deployer.deploy(AcceptedProposals)
    })
    .then(ins => {
      contracts.acceptedProposals = ins
      return deployer.deploy(
        Referendum,
        '0x2c2b9c9a4a25e24b174f26114e8926a9f2128fe4',
        '0x2c2b9c9a4a25e24b174f26114e8926a9f2128fe4',
      )
    })
    .then(ins => {
      contracts.referendum = ins
      return deployer.deploy(
        Concil,
        contracts.proposals.address,
        contracts.concilMembers.address,
        contracts.referendum.address,
        contracts.acceptedProposals.address,
      )
    })
}
