# Concil / 议会

议会分为两部分

- 议员管理
- 提交提案

分别由 `ConcilMembers` 合约和 `Concil` 合约管理

## ConcilMembers

本合约用于议员管理

### 基本类型

成员类型分为两类

```solidity
enum MemberType {
  Candidate, // 候选人
  Senator // 议员
}
```

成员结构为

```solidity
struct Member {
  address addr; // 地址
  uint deposit; // 参选押金
  MemberType mType; // 成员类型
  electedTime; // 当选时间
  uint votes; // 当前票数
}
```

投票情况通过 mapping 保存

```solidity
mapping(address => uint) public votesForMember;
```

### 合约状态

通过数组 members 保存所有候选人及议员, 以数组下标作为成员 id.

```solidity
Member[] public members;
```

合约初始化时, 添加 no-one 成员

```solidity
constructor () public {
  members.push({
    addr: address(0),
    deposit: 0,
    mType: MemberType.Candidate,
    electedTime: 0,
    votes: 0
  });
}
```

议员任期默认为 90 天, 可以通过 `function setTerm(uint _time)` 方法修改任期.

议员上限默认为 10, 可以通过 `function setSenatorAmount(uint _amount)` 设置.

通过 `applyForMember()` 质押小额代币申请成为议员候选人, 若已是候选人, 则该方法增加押金.

通过 `applyToQuit()` 方法退出竞选并取回押金.

通过 `voteForCandidate(uint _id)` 向候选人发起投票.

通过 `updateSenator(uint _id)` 检查议员的任期是否结束, 如果任期结束, 则设置身份为候选人.

通过 `addSenator()` 方法从候选人中选择票数最多的成员成为新的议员.

## Concil

### 基本类型

投票类型分为

```solidity
enum VoteType {
  NotYet, // 尚未投票
  Pros, // 赞成票
  Cons, // 反对票
  Abs, // 弃权票
}
```

提案类型分为

```solidity
enum ProposalType {
  Normal, // 普通提案
  Veto // 否决提案
}
```

提案内容保存在 `Proposals` 合约中, 本合约仅保存合约附加信息

```solidity
ProposalInfo[] public proposalInfos;

struct ProposalInfo {
  uint id; // 提案 id
  ProposalType pType; // 提案类型
  uint submitTime; // 提交时间
  uint lockedTime; // 锁定时间
  address lockedBy; // 锁定者
  mapping(address => VoteType) votes; // 投票记录
}
```

### 合约状态

通过 `newNormalProposal(address _ctrAddr, bytes _args, uint _invalidUntilBlock)` 提交普通提案.

通过 `newVetoProposal(uint _targetId)` 提交否决提案.

通过 `voteForProposal(uint _id, VoteType _vType)` 对 \_id 提案发起投票, 如果投票类型为 `VoteType.Cons`, 则锁定提案.

通过 `checkProposal(uint _id)` 检查提案投票情况.

1. 如果是 100% 赞同, 且提案类型为普通提案, 则将提案提交给全民表决合约.
2. 如果是 100% 赞同, 且提案类型为否决提案, 则将提案提交给待执行提案合约, 由待执行提案合约执行相关操作.
3. 如果是 > 50% 赞同, 提案存在时间超过设定期限且提案曾被锁定, 则提交给全民表决合约.
