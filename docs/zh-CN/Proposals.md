# Proposal / 提案

## 基本类型

### 普通提案

```solidity
struct NormalProposal {
  address proposer; // 提案发起者
  address ctrAddr; // 提案对应合约地址
  bytes args; // 提案对应参数
  uint invalidUntilBlock; // 提案生效时间, 超过 invalidUntilBlock 的块高度时提案可被执行
}
```

### 否决提案

```solidity
struct VetoProposal {
  address proposer; // 提案发起者
  uint targetId; // 需要否决的提案 id
}
```

## 合约状态

普通提案和否决提案分别保存在

```solidity
NormalProposal[] public normalProposals;
VetoProposal[] public vetoProposals`
```

通过 `newNormalProposal(address _ctrAddr, bytes _args, uint _invalidUntilBlock)` 方法提交普通提案

通过 `newVetoProposal(uint _targetId)` 提交否决提案
