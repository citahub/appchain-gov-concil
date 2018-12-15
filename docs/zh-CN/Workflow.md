# 工作流程

# 来自议会的普通提案

`Concil` 合约通过 `newNormalProposal` 提交提案, 通过 `voteForProposal` 对提案进行投票, 通过 `checkProposal` 对提案进行检票.

- 如果 100% 赞同, 则发往 `Referendum` 合约.
- 如果 > 50% 赞同且提案查过设定时间并且曾被锁定, 则发往 `Referendum` 合约.

`Referendum` 合约通过 `newProposal` 方法提交新合约, 通过 `voteForProposal` 对提案进行投票, 通过 `checkProposalById` 对提案进行检票.

- 如果提案来自议会且赞成率为 100, 则弃权票视为赞同票.
- 如果提案来自议会且赞成率大于 50, 弃权票按照 pros/cons 比例分派给赞成/否定票.

如果赞成票大于 50%, 则提案通过, 并发往待执行提案队列进入否决期.

`AcceptedProposals` 通过 `newProposal` 保存被通过的合约.

# 来自议会的否决提案

`Concil` 通过 `newVetoProposal` 提交否决提案, 通过 `voteForProposal` 对提案进行投票, 通过 `checkProposal` 对提案进行检票.

- 如果是 100 % 赞同, 则通过 `AcceptedProposals` 的 `veto` 方法将待执行的合约否决.

# 来自提案队列的普通提案

`ProposalQueue` 合约通过 `newProposal` 方法提交新提案, 通过 `addDeposit` 方法对提案添加押金表示支持, 通过 `checkProposals` 方法检查累计押金最高的提案并发往 `Referendum` 合约.

`Referendum` 合约通过 `newProposal` 方法提交新合约, 通过 `voteForProposal` 对提案进行投票, 通过 `checkProposalById` 对提案进行检票.

- 如果提案来自提案队列, 则弃权票视为反对票.

如果赞成票大于 50%, 则提案通过, 并发往待执行提案队列进入否决期.