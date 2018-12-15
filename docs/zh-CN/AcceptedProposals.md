# AcceptedProposal / 待执行提案

用于记录被通过的提案, 刚通过的提案进入否决期, 议会可以在否决期内提出否决提案来阻止被通过的提案的执行.

## 基本类型

合约状态分为

```solidity
enum Status {
  Vetoed, // 被否决
  Accepted, // 被接受
  Unknown // 未知状态
}
```

本合约不保存提案内容, 仅保存提案相关信息.

```solidity
struct ProposalStatus {
  uint id; // 提案 id
  Status status; // 提案状态
  uint acceptedTime; // 提案被通过时间
}
```

## 合约状态

被通过的提案保存在

```solidity
ProposalStatus[] public proposalStatuses;
```

通过 `newProposal(uint _id)` 方法提交被通过的提案.

通过 `veto(uint _id)` 方法否决处于否决期的提案.
