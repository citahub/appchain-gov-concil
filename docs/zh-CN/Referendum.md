# Referendum / 全民表决

## 基本类型

投票类型分为三种

```solidity
enum VoteType {
  Pros, // 赞成票
  Cons, // 反对票
  Abs // 弃权票
}
```

弃权票处理方式分为三种

```solidity
enum AbsType {
  AsPros, // 作为赞同票处理
  AsCons, // 作为反对票处理
  AsDis // 按照 Pros/Cons 比例分派给两边
}
```

提案来源分为三种

```solidity
enum ProposalOrigin {
  Concil, // 来自议会
  ProposalQueue, // 来自提案队列
  Proposal // 来自提案
}
```

提案内容保存在 `Proposals` 合约, 本合约仅保存相关信息

```solidity
struct Proposal {
  uint id, // 提案 id
  ProposalOrigin origin; // 提案来源
  uint prosFromConcil; // 来自议会的赞成率, 总额为100
  bool accepted; // 是否已被提交到待执行合约列表
  address[] voters; // 投票者账户
  mapping(address => VoteType) votes; // 投票情况
}
```

## 合约状态

提案状态保存在

```solidity
Proposal[] public proposals;
```

通过 `newProposal(uint _id, uint _prosFromConcil)` 提交新的提案.

通过 `voteForProposal(uint _id, VoteType _vType)` 对提案进行投票.

通过 `checkProposalById(uint _id)` 对提案做检票

- 如果提案来自议会且赞成率为 100, 则弃权票视为赞同票.
- 如果提案来自议会且赞成率大于 50, 弃权票按照 pros/cons 比例分派给赞成/否定票.
- 如果提案来自提案队列, 则弃权票视为反对票.

如果赞成票大于 50%, 则提案通过, 并发往待执行提案队列进入否决期.
