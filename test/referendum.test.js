const Referendum = artifacts.require('Referendum')
const { printLogs } = require('./utils')

const ProposalOrigin = {
  Concil: 0,
  ProposalQueue: 1,
  Proposal: 2,
}

const VoteType = {
  Pros: 0,
  Cons: 1,
  Abs: 2,
}

contract.skip('Referendum', accounts => {
  let referendum
  beforeEach(async () => {
    referendum = await Referendum.deployed()
  })

  const concilAddr = accounts[1]
  const proposalQueueAddr = accounts[2]

  it('has not proposals', async () => {
    const count = await referendum.proposalCount()
    expect(+count).to.be.equal(0)
  })

  it('new proposal for vote from parent proposal', async () => {
    const proposal = {
      id: 1,
      prosFromConcil: 0,
    }
    const result = await referendum.newProposal(proposal.id, proposal.prosFromConcil)
    const proposalFromConcil = await referendum.proposals(0)
    expect(+proposalFromConcil[0]).to.be.equal(proposal.id)
    expect(+proposalFromConcil[1]).to.be.equal(ProposalOrigin.Proposal)
    expect(+proposalFromConcil[2]).to.be.equal(proposal.prosFromConcil)
  })

  it(`set concilAddr to ${concilAddr}, proposalQueueAddr to ${proposalQueueAddr}`, async () => {
    const setConcilResult = await referendum.setConcilAddr(concilAddr)
    const setProposalQueueResult = await referendum.setProposalQueueAddr(proposalQueueAddr)
    const concilAddrOfReferendum = await referendum.concilAddr()
    const proposalQueueAddrOfReferendum = await referendum.proposalQueueAddr()
    expect(concilAddrOfReferendum).to.be.equal(concilAddr)
    expect(proposalQueueAddrOfReferendum).to.be.equal(proposalQueueAddr)
  })

  it('new proposal from concil with 100 pros', async () => {
    const proposal = {
      id: 2,
      prosFromConcil: 100,
    }
    const result = await referendum.newProposal(proposal.id, proposal.prosFromConcil, {
      from: concilAddr,
    })
    const proposalFromConcil = await referendum.proposals(1)
    expect(+proposalFromConcil[0]).to.be.equal(proposal.id)
    expect(+proposalFromConcil[1]).to.be.equal(ProposalOrigin.Concil)
    expect(+proposalFromConcil[2]).to.be.equal(proposal.prosFromConcil)
  })

  it('new proposal from concil with 80 pros', async () => {
    const proposal = {
      id: 3,
      prosFromConcil: 80,
    }
    const result = await referendum.newProposal(proposal.id, proposal.prosFromConcil, {
      from: concilAddr,
    })
    const proposalFromConcil = await referendum.proposals(2)
    expect(+proposalFromConcil[0]).to.be.equal(proposal.id)
    expect(+proposalFromConcil[1]).to.be.equal(ProposalOrigin.Concil)
    expect(+proposalFromConcil[2]).to.be.equal(proposal.prosFromConcil)
  })

  it('new proposal from proposal queue', async () => {
    const proposal = {
      id: 4,
      prosFromConcil: 0,
    }

    const result = await referendum.newProposal(proposal.id, proposal.prosFromConcil, {
      from: proposalQueueAddr,
    })
    const proposalFromQueue = await referendum.proposals(3)
    expect(+proposalFromQueue[0]).to.be.equal(proposal.id)
    expect(+proposalFromQueue[1]).to.be.equal(ProposalOrigin.ProposalQueue)
    expect(+proposalFromQueue[2]).to.be.equal(proposal.prosFromConcil)
  })

  it('vote for proposal with id = 2, vType = Pros from accounts[0]', async () => {
    const vote = {
      id: 2,
      vType: VoteType.Pros,
      voter: accounts[0],
    }
    let votes = await referendum.getVotesOfProposalById(vote.id)
    expect(votes.toString()).to.be.equal('0,0,0')
    const result = await referendum.voteForProposal(vote.id, vote.vType, {
      from: vote.voter,
    })
    votes = await referendum.getVotesOfProposalById(vote.id)
    expect(votes.toString()).to.be.equal('1,0,0')
  })

  it('vote for proposal with id = 2, vType = Cons from accounts[1]', async () => {
    const vote = {
      id: 2,
      vType: VoteType.Cons,
      voter: accounts[1],
    }
    let votes = await referendum.getVotesOfProposalById(vote.id)
    expect(votes.toString()).to.be.equal('1,0,0')
    const result = await referendum.voteForProposal(vote.id, vote.vType, {
      from: vote.voter,
    })
    votes = await referendum.getVotesOfProposalById(vote.id)
    expect(votes.toString()).to.be.equal('1,1,0')
  })

  it('vote for proposal with id = 2, vType = Abs from accounts[2]', async () => {
    const vote = {
      id: 2,
      vType: VoteType.Abs,
      voter: accounts[2],
    }
    let votes = await referendum.getVotesOfProposalById(vote.id)
    expect(votes.toString()).to.be.equal('1,1,0')
    const result = await referendum.voteForProposal(vote.id, vote.vType, {
      from: vote.voter,
    })
    votes = await referendum.getVotesOfProposalById(vote.id)
    expect(votes.toString()).to.be.equal('1,1,1')
  })

  it('check proposal with id = 2, now it has votes [1, 1, 1] and from concil with 100 pros, accepted', async () => {
    const proposal = {
      id: 2,
      accepted: true,
    }
    const result = await referendum.checkProposalById(proposal.id)
    expect(result.logs[0].args.accepted).to.be.equal(proposal.accepted)
  })

  it('check proposal with id = 2, it will have votes [1, 2, 1] and from concil with 100 pros, not accepted', async () => {
    const proposal = {
      id: 2,
      accepted: false,
    }
    const voteResult = await referendum.voteForProposal(proposal.id, VoteType.Cons)
    const checkResult = await referendum.checkProposalById(proposal.id)
    expect(checkResult.logs[0].args.accepted).to.be.equal(proposal.accepted)
  })

  it('check proposal with id = 3, it will have votes [1, 0, 0] and from concil with 80 pros, accepted', async () => {
    const proposal = {
      id: 3,
      accepted: true,
    }
    const voteResult = await referendum.voteForProposal(proposal.id, VoteType.Pros)
    const checkResult = await referendum.checkProposalById(proposal.id)
    expect(checkResult.logs[0].args.accepted).to.be.equal(proposal.accepted)
  })

  it('check proposal with id = 3, it will have votes [1, 1, 2] and from concil with 80 pros, false', async () => {
    const proposal = {
      id: 3,
      accepted: false,
    }
    await referendum.voteForProposal(proposal.id, VoteType.Cons, {
      from: accounts[2],
    })
    await referendum.voteForProposal(proposal.id, VoteType.Abs, {
      from: accounts[3],
    })
    let votes = await referendum.getVotesOfProposalById(proposal.id)
    const checkResult = await referendum.checkProposalById(proposal.id)
    expect(checkResult.logs[0].args.accepted).to.be.equal(proposal.accepted)
  })

  it('check proposal with id = 3, it will have votes [2, 1, 2], and from concil with 80 pros, true', async () => {
    const proposal = {
      id: 3,
      accepted: true,
    }
    const voteResult = await referendum.voteForProposal(proposal.id, VoteType.Pros, {
      from: accounts[4],
    })
    const checkResult = await referendum.checkProposalById(proposal.id)
    const votes = await referendum.getVotesOfProposalById(proposal.id)
    expect(checkResult.logs[0].args.accepted).to.be.equal(proposal.accepted)
  })
})
