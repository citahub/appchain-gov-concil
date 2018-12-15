# ProposalQueue / 提案队列

## 基本类型

提案具体内容保存在 `Proposals` 合约, 本合约仅保存相关信息

```solidity
struct ProposalInfo {
  uint id; // 提案 id
  address[] depositors; // 提交押金的账户
  uint[] deposits; // 提交押金列表
  bool submitted; // 是否提交到全民表决
}
```

## 合约状态

通过 `newProposal(address _ctrAddr, bytes _args, uint _invalidUntilBlock)` 提交新的提案, 并将附加的 token 作为提案押金.

通过 `addDeposit(uint _id)` 方法向对应提案添加押金.

通过 `checkProposals()` 方法检查当前提案列表, 将累计押金最多的提案发往全民表决, 并退还押金.
