const AcceptedProposals = artifacts.require('AcceptedProposals')
const {
  printLogs
} = require('./utils')

const Status = {
  Vetoed: 0,
  Accepted: 1
}

contract('AcceptedProposals', async (accounts) => {
  let ap // acceptedProposals
  const proposalId = 1;
  beforeEach(async () => {
    ap = await AcceptedProposals.deployed()
  })

  it('new accepted proposal', async () => {
    let count = await ap.proposalCount()
    expect(+count).to.be.equal(0)
    const result = await ap.newProposal(proposalId);
    count = await ap.proposalCount()
    const proposal = await ap.proposalStatuses(0)
    expect(+count).to.be.equal(1)
    expect(+proposal[0]).to.be.equal(proposalId)
    expect(+proposal[1]).to.be.equal(Status.Accepted)
  })

  it(`get proposal stauts of id ${proposalId}`, async () => {
    const status = await ap.getStatusById(proposalId)
    expect(+status).to.be.equal(Status.Accepted)
  })

  it(`veto an accepted proposal of id ${proposalId}`, async () => {
    let status = await ap.getStatusById(proposalId)
    expect(+status).to.be.equal(Status.Accepted)
    const result = await ap.veto(proposalId)
    status = await ap.getStatusById(proposalId)
    expect(+status).to.be.equal(Status.Vetoed)
  })
})
