# Proposal

## Proposal Types

### Common Proposal

- 欲调用的功能（合约地址）
- 调用参数
- 生效最小块高度（0 代表通过后立即生效）

### Veto Proposal

- 该提案用来否决已进入全民表决但尚未表决通过的提案

## Proposer

Not limited, anyone can submit an proposal

## New Proposal

- Submitted via concil

- Submitted via proposal queue

- Submitted in other proposal

Proposal Queue / 提案队列

发起提案

任何人都可以向提案队列发起提案，但发起提案时必须附带规定的最小押金。

支持提案

任何人都可以向提案队列中的提案进行“支持”，支持的方式为增加提案押金。

提案确认

每隔一段固定时间（一个月），提案队列中获得累计押金最多的提案得到确认，得到确认的提案被发往 Referendum 进行全民表决。同时，该提案已经获得的押金被自动撤回给抵押人。
