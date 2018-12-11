const ProposalQueue = artifacts.require('ProposalQueue')
const Proposals = artifacts.require('Proposals')
const { printLogs } = require('./utils')

contract('ProposalQueue', accounts => {
  let queue
  let proposals
  beforeEach(async () => {
    queue = await ProposalQueue.deployed()
    proposals = await Proposals.deployed()
  })

  it('propose a new proposal', async () => {
    const proposal = {
      ctrAddr: accounts[9],
      args: '0xffeeff',
      invalidUntilBlock: 0,
      deposit: 1001,
    }
    let count = await queue.getProposalCount()
    expect(+count).to.be.equal(0)
    const result = await queue.newProposal(proposal.ctrAddr, proposal.args, proposal.invalidUntilBlock, {
      from: accounts[0],
      value: proposal.deposit,
    })
    count = await queue.getProposalCount()
    expect(+count).to.be.equal(1)
    const newProposal = await queue.proposalInfos(0)
    const id = +newProposal[0]
    const pInProposals = await proposals.normalProposals(id)
    expect({
      proposer: pInProposals[0],
      ctrAddr: pInProposals[1],
      args: pInProposals[2],
      invalidUntilBlock: +pInProposals[3],
    }).to.be.deep.equal({
      ctrAddr: accounts[9],
      args: '0xffeeff',
      invalidUntilBlock: 0,
      proposer: queue.address,
    })
    const deposit = await queue.getDepositOfProposal(0, accounts[0])
    expect(+deposit).to.be.equal(proposal.deposit)
    const totalDeposit = await queue.getTotalDepositOfProposalById(id)
    expect(+totalDeposit).to.be.equal(proposal.deposit)
  })

  it('add deposit', async () => {
    const deposits = {
      id: 0,
      prevDeposit: 1001,
      addDeposit: 2000,
    }
    const prevDeposit = await queue.getTotalDepositOfProposalById(deposits.id)
    expect(+prevDeposit).to.be.equal(deposits.prevDeposit)
    const result = await queue.addDeposit(deposits.id, {
      from: accounts[1],
      value: deposits.addDeposit,
    })
    const currentDeposit = await queue.getTotalDepositOfProposalById(deposits.id)
    const deposit1 = await queue.getDepositOfProposal(deposits.id, accounts[0])
    const deposit2 = await queue.getDepositOfProposal(deposits.id, accounts[1])
    expect(+deposit1).to.be.equal(deposits.prevDeposit)
    expect(+deposit2).to.be.equal(deposits.addDeposit)
    expect(+currentDeposit - +prevDeposit).to.be.equal(deposits.addDeposit)
  })

  it('check proposal', async () => {
    const result = await queue.checkProposals()
  })

  it('get depositor id', async () => {
    const info = {
      proposalId: 0,
      depositorAddr: accounts[0],
      depositorId: 0,
    }
    const id = await queue.getDepositorId(info.proposalId, info.depositorAddr)
    expect(+id).to.be.equal(info.depositorId)
  })
})
