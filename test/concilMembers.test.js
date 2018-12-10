const ConcilMembers = artifacts.require('ConcilMembers')
const {
  printLog
} = require('./utils')

const MemberType = {
  Candidate: 0,
  Senator: 1,
}

const RevertErr = 'Error: VM Exception while processing transaction: revert'

contract.skip('ConcilMember', accounts => {
  let concilMembers
  beforeEach(async () => {
    concilMembers = await ConcilMembers.deployed()
  })

  it('set amount of senator to be 1', async () => {
    let amount = await concilMembers.amountOfSenators()
    expect(+amount).to.be.equal(10)
    const result = await concilMembers.setSenatorAmount(1)
    amount = await concilMembers.amountOfSenators()
    expect(+amount).to.be.equal(1)
  })

  it('update term from 90 days to 0 secs', async () => {
    let term = await concilMembers.term()
    expect(+term).to.be.equal(90 * 24 * 3600)
    const result = await concilMembers.setTerm(0)
    term = await concilMembers.term()
    expect(+term).to.be.equal(0)
  })

  it('should has no members at begin', async () => {
    const memberCount = await concilMembers.getMemberCount()
    expect(+memberCount).to.be.equal(0)
  })

  it('should failed to be a member with deposito less than 1000', () => {
    const deposit = 999
    concilMembers
      .applyToBeAMember({
        from: accounts[0],
        value: deposit,
      })
      .catch(err => {
        expect(err.toString()).to.be.equal(RevertErr)
      })
  })

  it('should to be a member with deposit more than 1000', async () => {
    const deposit = 1001
    const result = await concilMembers.applyToBeAMember({
      from: accounts[0],
      value: deposit,
    })
    const count = await concilMembers.getMemberCount()
    const memberId = await concilMembers.getMemberId(accounts[0])
    expect(+memberId).to.be.equal(1)
    const member = await concilMembers.getMember(+memberId) // expect to be [addr, deposit, mType, electedTime, votes]
    expect(+count).to.be.equal(1)
    expect(member[0]).to.be.equal(accounts[0]) // addr
    expect(+member[1]).to.be.equal(deposit) // deposit
    expect(+member[2]).to.be.equal(MemberType.Candidate) // mType
    expect(+member[3]).to.be.equal(0) // electedTime
    expect(+member[4]).to.be.equal(0) // votes
  })

  it('should quit successfully', async () => {
    const result = await concilMembers.applyToQuit()
    const count = await concilMembers.getMemberCount()
    const member = await concilMembers.getMember(1)
    expect(+count).to.be.equal(1)
    expect(member[0]).to.be.equal(accounts[0])
    expect(+member[1]).to.be.equal(0)
  })

  it('should add deposit if already in member list', async () => {
    const deposit = 3333
    const result = await concilMembers.applyToBeAMember({
      from: accounts[0],
      value: deposit,
    })
    const memberId = await concilMembers.getMemberId(accounts[0])
    expect(+memberId).to.be.equal(1)
    let member = await concilMembers.getMember(+memberId)
    expect(member[0]).to.be.equal(accounts[0])
    expect(+member[1]).to.be.equal(deposit)
    // apply again
    await concilMembers.applyToBeAMember({
      from: accounts[0],
      value: deposit,
    })
    member = await concilMembers.getMember(+memberId)
    expect(+member[1]).to.be.equal(deposit * 2)
  })

  it('should add one more member', async () => {
    const deposit = 1001
    const result = await concilMembers.applyToBeAMember({
      from: accounts[1],
      value: deposit,
    })
    const count = await concilMembers.getMemberCount()
    const memberId = await concilMembers.getMemberId(accounts[1])
    const member = await concilMembers.getMember(+memberId)
    expect(+count).to.be.equal(2)
    expect(+memberId).to.be.equal(2)
    expect(member[0]).to.be.equal(accounts[1])
    expect(+member[1]).to.be.equal(deposit)
    expect(+member[2]).to.be.equal(MemberType.Candidate) // mType
    expect(+member[3]).to.be.equal(0) // electedTime
    expect(+member[4]).to.be.equal(0) // votes
  })

  it('accounts[2] votes for members[1]', async () => {
    const result = await concilMembers.voteForCandidate(1, {
      from: accounts[2],
    })
    const member1 = await concilMembers.getMember(1)
    expect(+member1[4]).to.be.equal(1)
    const voteOfAccount2 = await concilMembers.votesForMember(accounts[2])
    expect(+voteOfAccount2).to.be.equal(1)
  })

  it('accounts[2] votes for members[2]', async () => {
    let member1 = await concilMembers.getMember(1)
    expect(+member1[4]).to.be.equal(1)
    let member2 = await concilMembers.getMember(2)
    expect(+member2[4]).to.be.equal(0)
    let voteOfAccount2 = await concilMembers.votesForMember(accounts[2])
    expect(+voteOfAccount2).to.be.equal(1)

    const result = await concilMembers.voteForCandidate(2, {
      from: accounts[2],
    })
  })

  it('should return members[2] when getCandidateIdWithMostVotes', async () => {
    const id = await concilMembers.getCandidateIdWithMostVotes()
    expect(+id).to.be.equal(2)
  })

  it('members[2] becomes senator when addSenator', async () => {
    let member = await concilMembers.members(2)
    expect(+member[2]).to.be.equal(MemberType.Candidate)
    const result = await concilMembers.addSenator()
    member = await concilMembers.members(2)
    expect(+member[2]).to.be.equal(MemberType.Senator)
  })

  it('isSenator(accounts[1]) should be true, and isSenator(accounts[0]) should be false', async () => {
    const isSenator0 = await concilMembers.isSenator(accounts[0])
    const isSenator1 = await concilMembers.isSenator(accounts[1])
    expect(isSenator0).to.be.false
    expect(isSenator1).to.be.true
  })

  it('getSenatorCount should return 1', async () => {
    const count = await concilMembers.getSenatorCount()
    expect(+count).to.be.equal(1)
  })

  it('votes for members[1] and then update members[2], members[1] should be a senator', async () => {
    let member1 = await concilMembers.members(1)
    let member2 = await concilMembers.members(2)

    expect(+member1[2]).to.be.equal(MemberType.Candidate) // mType
    expect(+member1[4]).to.be.equal(0) // votes
    expect(+member2[2]).to.be.equal(MemberType.Senator) // mType
    expect(+member2[4]).to.be.equal(1) // votes

    const vote = await concilMembers.voteForCandidate(1, {
      from: accounts[2],
    })

    const updateSenator = await concilMembers.updateSenator(2)

    member1 = await concilMembers.members(1)
    member2 = await concilMembers.members(2)

    expect(+member1[2]).to.be.equal(MemberType.Senator)
    expect(+member1[4]).to.be.equal(1)
    expect(+member2[2]).to.be.equal(MemberType.Candidate)
    expect(+member2[4]).to.be.equal(0)
  })
})
