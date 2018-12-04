const ConcilMembers = artifacts.require('ConcilMembers')

module.exports = deployer => {
  deployer.deploy(ConcilMembers)
}
