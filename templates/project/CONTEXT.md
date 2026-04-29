# {Context Name}

{1-2 句描述这个上下文是什么}

## Language

**Order**:
客户提交的购买请求，包含商品列表和配送地址。
_Avoid_: Purchase, transaction

**Invoice**:
发货后发给客户的付款请求。
_Avoid_: Bill, payment request

## Relationships

- 一个 **Order** 产生一个或多个 **Invoice**
- 一个 **Invoice** 属于一个 **Customer**

## Example Dialogue

> **Dev:** "当 **Customer** 下了一个 **Order**，我们立即创建 **Invoice** 吗？"
> **Domain expert:** "不——**Invoice** 只在 **Fulfillment** 确认后才生成。"

## Flagged Ambiguities

- "account" 曾同时指 **Customer** 和 **User** — 已解决：这是两个独立概念
