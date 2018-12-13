const Concil = artifacts.require('Concil')
const ConcilMembers = artifacts.require('ConcilMembers')
const Proposals = artifacts.require('Proposals')
const AcceptedProposals = artifacts.require('AcceptedProposals')
const Referendum = artifacts.require('Referendum')

module.exports = deployer =>
  Promise.all([
    deployer.deploy(ConcilMembers),
    deployer.deploy(Proposals),
    deployer.deploy(AcceptedProposals),
    deployer.deploy(Referendum, '0x2c2b9c9a4a25e24b174f26114e8926a9f2128fe4', '0x2c2b9c9a4a25e24b174f26114e8926a9f2128fe4')
  ]).then(([concilMember, proposals, acceptedProposals, referendum]) => {
    console.log(referendum)

  }, )
// deployer.deploy(Concil, proposals.address, concilMember.address, referendum.address)
