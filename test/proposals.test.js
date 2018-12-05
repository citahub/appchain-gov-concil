const Proposals = artifacts.require('Proposals')

const {
  printLogs
} = require('./utils')

contract('Proposals', accounts => {
  let proposalsCtr

  beforeEach(async () => {
    proposalsCtr = await Proposals.deployed()
  })

  it('accounts[0] should propose a normal proposal', async () => {
    const proposer = accounts[0]
    const proposal = {
      ctrAddr: '0x3b284f5cb4136562c873035f6679aa6d87b480aa',
      args: '0xfffeeeffff',
      invalidUntilBlock: 10,
    }
    let count = await proposalsCtr.normalProposalsCount()
    expect(+count).to.be.equal(0)
    const result = await proposalsCtr.newNormalProposal(proposal.ctrAddr, proposal.args, proposal.invalidUntilBlock)
    count = await proposalsCtr.normalProposalsCount()
    const newNormalProposal = await proposalsCtr.normalProposals(0, {
      from: proposer,
    })
    expect(+count).to.be.equal(1)
    expect(newNormalProposal[0]).to.be.equal(proposer)
    expect(newNormalProposal[1]).to.be.equal(proposal.ctrAddr)
    expect(newNormalProposal[2]).to.be.equal(proposal.args)
    expect(+newNormalProposal[3]).to.be.equal(proposal.invalidUntilBlock)
  })

  it('accounts[1] should propose a veto proposal', async () => {
    const proposer = accounts[1]
    const proposal = {
      targetId: 0
    }

    let count = await proposalsCtr.vetoProposalsCount()
    expect(+count).to.be.equal(0)
    const result = await proposalsCtr.newVetoProposal(proposal.targetId, {
      from: proposer
    })
    count = await proposalsCtr.vetoProposalsCount()
    const newVetoProposal = await proposalsCtr.vetoProposals(0)
    expect(+count).to.be.equal(1)
    expect(newVetoProposal[0]).to.be.equal(proposer)
    expect(+newVetoProposal[1]).to.be.equal(proposal.targetId)
  })
})
