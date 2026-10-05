---
source: baton-runner work unit, phase 2 of 8, checkpoint (docs/specs/02-truthful-order-confirm.md)
scope: br-2026-10-04-p0-queue
parent_session: 2026-10-04T114637-phase1-review-iter2.md
status: IN PROGRESS: store half green (Scenario.placeOrder); ticket UI half not started; nothing committed (the manager owns git)
---

# Phase 2 checkpoint: Scenario.placeOrder is the order write path (store tests green)

Branch `feat/br-2026-10-04-p0-queue/phase-2`, uncommitted.

## Done (store half)
- `app/lib/scenario/scenario.dart`: `OrderKind` (moved from order_ticket.dart), `notEnoughFunds`, `OrderIntent` (late-final cents: `notionalCents = (units*price*100).round()`, `marginCents = (notionalCents/leverage).round()`, `feeCents = notionalCents*feeBps ~/ 10000`, `totalCents`), `OrderReceipt`, sealed `OrderResult` = `OrderFilled(receipt) | OrderResting(order) | OrderFailed(reason)`. Store fields `receipts` (seed `[]`), `stalePrices` (seed `TradeMock.stalePrices` = {'AVAX'}). Methods `placeOrder`, `problem`, `refreshPrice`, `maxMarginCents`. Duplicate guard derives from state (receipt id / open-order id == actionId); failures are not remembered so Retry can reuse the actionId.
- `PortfolioPosition` gained `id`, `notionalCents`, `marginCents`, optional `clashId` (seeds: p-eth 400000/80000, p-sol 50000/5000, p-0xreal 6750/6750).
- `TradeMock.takerFeeBps = 5`, `makerFeeBps = 2`, `stalePrices = {'AVAX'}`. `formatCents(int)` in `live_feed.dart` (integer-exact).

## RED evidence (store tests, before the store existed)
`flutter test test/scenario_test.dart` → compile failure: `Error: Type 'OrderIntent' not found.`, `Error: Member not found: 'Scenario.placeOrder'.`, `Error: Member not found: 'receipts'.`, `Error: 'OrderFilled' isn't a type.` GREEN after: 11/11 pass.

## Next
Widget tests in new `app/test/order_ticket_test.dart` (double tap, cancel, stale+Retry, both tickets, trader-index toast), RED, then the review/receipt stage in both tickets, `OrderTicket.available` removal, View in Wallet.
