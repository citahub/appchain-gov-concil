const ConcilMembers = artifacts.require('ConcilMembers')
const Proposals = artifacts.require('Proposals')
const AcceptedProposals = artifacts.require('AcceptedProposals')

module.exports = async deployer => {
  const [
    concilMembers,
    proposals,
    acceptedProposals
  ] = await Promise.all([
    deployer.deploy(ConcilMembers),
    deployer.deploy(Proposals),
    deployer.deploy(AcceptedProposals)
  ])
}
