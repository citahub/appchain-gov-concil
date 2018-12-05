const ConcilMembers = artifacts.require('ConcilMembers')
const Proposals = artifacts.require('Proposals')

module.exports = async deployer => {
  const [concilMembers, proposals] = await Promise.all([deployer.deploy(ConcilMembers), deployer.deploy(Proposals)])
}
