const Concil = artifacts.require('Concil')
const Proposals = artifacts.require('Proposals')
const ConcilMembers = artifacts.require('ConcilMembers')
const {
  printLogs
} = require('./utils')

const ZeroAddr = '0x0000000000000000000000000000000000000000'

const Events = {
  ProposalNotAccepted: 'ProposalNotAccepted',
  ProposalToReferendum: 'ProposalToReferendum',
}

const VoteType = {
  NotYet: 0,
  Pros: 1,
  Cons: 2,
  Abs: 3,
}

const ProposalType = {
  Normal: 0,
  Veto: 1,
}

contract('Concil', accounts => {
  let concil
  let proposals
  let concilMembers

  beforeEach(async () => {
    concil = await Concil.deployed()
    proposals = await Proposals.deployed()
    concilMembers = await ConcilMembers.deployed()
  })

  // add one senator
  it('accounts[0] should be a senator in concil members', async () => {
    const deposit = 1001
    await concilMembers.applyToBeAMember({
      from: accounts[0],
      value: deposit,
    })
    await concilMembers.voteForCandidate(1, {
      from: accounts[2],
    })
    await concilMembers.addSenator()
    member = await concilMembers.members(1)
    expect(+member[2]).to.be.equal(1)
  })

  it('has no proposals', async () => {
    let count = await concil.getProposalCount()
    expect(+count).to.be.equal(0)
  })

  it('propose a new normal proposal', async () => {
    const proposal = {
      ctrAddr: accounts[0],
      args: '0xffeeff',
      invalidUntilBlock: 10,
    }

    const result = await concil.newNormalProposal(proposal.ctrAddr, proposal.args, proposal.invalidUntilBlock)

    count = await concil.getProposalCount()

    expect(+count).to.be.equal(1)

    const newProposal = await concil.proposalInfos(0)

    expect(+newProposal[0]).to.be.equal(0)
    expect(+newProposal[1]).to.be.equal(ProposalType.Normal)
    expect(+newProposal[3]).to.be.equal(0) // lockedtime
    expect(newProposal[4]).to.be.equal(ZeroAddr)

    const pInProposals = await proposals.normalProposals(0)

    expect(pInProposals[0]).to.be.equal(concil.address)
    expect(pInProposals[1]).to.be.equal(proposal.ctrAddr)
    expect(pInProposals[2]).to.be.equal(proposal.args)
    expect(+pInProposals[3]).to.be.equal(proposal.invalidUntilBlock)
  })

  it('propose a veto proposal', async () => {
    const vetoProposal = {
      targetId: 1,
    }
    const result = await concil.newVetoProposal(vetoProposal.targetId)
    const newVetoProposal = await concil.proposalInfos(1)
    expect(+newVetoProposal[0]).to.be.equal(0)
    expect(+newVetoProposal[1]).to.be.equal(ProposalType.Veto)
    expect(+newVetoProposal[3]).to.be.equal(0)
    expect(newVetoProposal[4]).to.be.equal(ZeroAddr)
    const pInProposals = await proposals.vetoProposals(0)
    expect(pInProposals[0]).to.be.equal(concil.address)
    expect(+pInProposals[1]).to.be.equal(vetoProposal.targetId)
  })

  it('vote for proposal with id = 0, vType = Pros', async () => {
    const proposal = {
      id: 0,
      vType: VoteType.Pros,
    }
    let votes = await concil.getVotesOfProposalById(proposal.id)
    let pros = votes[0]
    expect(+pros).to.be.equal(0)
    const result = await concil.voteForProposal(proposal.id, proposal.vType)
    const voteOfAccounts0 = await concil.getVoteOfProposalByIdOfVoter(proposal.id, accounts[0])
    expect(+voteOfAccounts0).to.be.equal(proposal.vType)
    votes = await concil.getVotesOfProposalById(proposal.id)
    expect(+votes[0]).to.be.equal(1) // pros
    expect(+votes[1]).to.be.equal(0) // cons
    expect(+votes[2]).to.be.equal(0) // abs
    const p = await concil.proposalInfos(proposal.id)
    expect(+p[3]).to.be.equal(0) // lockedtime
  })

  it('vote for proposal with id = 0, vType = Cons', async () => {
    const proposal = {
      id: 0,
      vType: VoteType.Cons,
    }

    let votes = await concil.getVotesOfProposalById(proposal.id)
    let cons = votes[1]
    expect(+cons).to.be.equal(0)
    const result = await concil.voteForProposal(proposal.id, proposal.vType)
    const voteOfAccounts0 = await concil.getVoteOfProposalByIdOfVoter(proposal.id, accounts[0])
    expect(+voteOfAccounts0).to.be.equal(proposal.vType)
    votes = await concil.getVotesOfProposalById(proposal.id)
    expect(+votes[0]).to.be.equal(0) // pros
    expect(+votes[1]).to.be.equal(1) // cons
    expect(+votes[2]).to.be.equal(0) // abs
    const p = await concil.proposalInfos(proposal.id)
    expect(+p[3]).to.not.be.equal(0) // lockedtime
  })

  it('check proposal with id = 0, it should have votes of [0, 1, 0], not accepted', async () => {
    const proposal = {
      id: 0,
      pros: 0,
    }
    const senatorCount = await concilMembers.getSenatorCount()
    expect(+senatorCount).to.be.equal(1)
    const votes = await concil.getVotesOfProposalById(proposal.id)
    let result = await concil.checkProposal(proposal.id)
    expect(result.logs[0].event).to.be.equal(Events.ProposalNotAccepted)
    expect({
      id: +result.logs[0].args.id,
      pros: +result.logs[0].args.prosFromConcil,
    }).to.be.deep.equal(proposal)
  })

  it('check proposal with id = 0, it will have votes of [1, 0, 0], not accepted', async () => {
    const proposal = {
      id: 0,
      vType: VoteType.Pros,
      pros: 100,
    }
    const senatorCount = await concilMembers.getSenatorCount()
    expect(+senatorCount).to.be.equal(1)
    await concil.voteForProposal(proposal.id, proposal.vType)
    const votes = await concil.getVotesOfProposalById(proposal.id)
    console.log(votes)
    let result = await concil.checkProposal(proposal.id)
    expect(result.logs[0].event).to.be.equal(Events.ProposalToReferendum)
    expect({
      id: +result.logs[0].args.id,
      pros: +result.logs[0].args.prosFromConcil,
    }).to.be.deep.equal({
      id: proposal.id,
      pros: proposal.pros
    })
  })
})
