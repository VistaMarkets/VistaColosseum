# 02 — Truthful order confirm, cancel, failure, receipt

**PRD:** VC-ORD-001/002/003, VC-MKT-003, VC-DEM-004. **Gap:** `order_ticket.dart:196-235` and `feed_order_ticket.dart:135-170` toast "Market … filled (simulated)" and mutate nothing for market orders; money is `double` (`available = 1000`).

## Behavior

- Both tickets route through one `Scenario.placeOrder(OrderIntent)` → `OrderResult {filled | resting | failed(reason)}`. Intent carries a client-generated `actionId`; a second call with the same `actionId` is a no-op returning the first result (duplicate guard). Disable the confirm button while a submission is in flight.
- Market order: validate size > 0, margin ≤ cash, price context fresh (see failure). On success: debit cash, add exactly one position (reuse `PortfolioPosition`), append a `Receipt`, return `filled`. Toast and bottom sheet say what happened and offer "View in Wallet".
- Limit/stop: unchanged path, but through the store.
- Cancel/back/dismiss: no store call. Opening the ticket: no store call.
- One scripted failure: a fixture asset (pick one from `trade_mock.dart`) whose price context is flagged `stale`; confirm returns `failed('Price expired')` with a Retry that refreshes the context and then succeeds. Insufficient funds stays as the second failure (already validated; make the message consistent).
- Money: cash, margin, fee, notional computed in int cents or `Decimal`-like fixed strings; display formatting via one helper. `double` allowed only for chart geometry.
- Review and receipt show: instrument, direction, size, reference price, paper funds required, "Simulated — no real order".

## Acceptance

- [ ] Confirm → Wallet shows one new position, cash reduced by margin + fee; totals on review, receipt and Wallet agree to the cent.
- [ ] Cancel → nothing changes (test asserts store equality).
- [ ] Double-tap confirm → one position (test with same actionId).
- [ ] Stale-price failure → no position; Retry succeeds once.
- [ ] Widget tests cover both tickets; existing overflow tests still pass.

## Out of scope
Trader-index tickets (VC-MKT-005), advanced order types, Arena participation (unit 04 wires it).
