# 02: Truthful order confirm, cancel, failure, receipt

## Rules for this unit

Common rules for every unit: original lightweight code (CONTEXT.md), no new pub dependencies, money as `int` minor units or fixed-decimal strings (never new `double` money), every success message describes something that actually happened, keep the existing "— not in the demo yet" toast for anything you don't build. Run `scripts/gate.sh <log-dir>` before returning; it must print `GATE: PASS`. Every acceptance criterion names its test as `app/test/<file>.dart: <test name>` or is marked `manual, waived`; add the tests the spec names.

**PRD:** VC-ORD-001/002/003, VC-MKT-003, VC-DEM-004. **Gap:** `order_ticket.dart:196-235` and `feed_order_ticket.dart:135-170` toast "Market … filled (simulated)" and mutate nothing for market orders; money is `double` (`available = 1000`).

## Behavior

- Both tickets route through one `Scenario.placeOrder(OrderIntent)` → `OrderResult {filled | resting | failed(reason)}`. Intent carries an `actionId` minted once when the ticket opens (in the ticket state, never inside the confirm handler) and reused on every confirm tap of that ticket; a second call with the same `actionId` is a no-op returning the first result (duplicate guard). Disable the confirm button while a submission is in flight.
- Market order: validate size > 0, margin ≤ cash, price context fresh (see failure). On success: debit cash, add exactly one position (extend `PortfolioPosition` with `id`, `notionalCents`, `marginCents` and an optional `clashId`; existing display strings stay), append a `Receipt` carrying the same cent fields and `clashId`, return `filled`. `OrderIntent` carries an optional `clashId` so unit 04 adds behavior only. Toast and bottom sheet say what happened and offer "View in Wallet".
- Limit/stop: unchanged path, but through the store.
- Cancel/back/dismiss: no store call. Opening the ticket: no store call.
- The trader-market entry (`trader_market_screen.dart:79`, symbol is a handle, not an asset) never reaches `placeOrder`: its confirm shows the existing "Trader-index ticket — not in the demo yet" toast and creates nothing (VC-MKT-005 is P1).
- One scripted failure: a fixture asset (pick one from `trade_mock.dart`) whose price context is flagged `stale`; confirm returns `failed('Price expired')` with a Retry that refreshes the context and then succeeds. Insufficient funds stays as the second failure (already validated; make the message consistent).
- Money: cash, margin, fee, notional computed in int cents or `Decimal`-like fixed strings; display formatting via one helper. `double` allowed only for chart geometry and the one conversion below. Rounding (VC-ORD-003), done once in `Scenario.placeOrder` from the intent's units and reference price: `notionalCents = (units * price * 100).round()`, `marginCents = (notionalCents / leverage).round()`, `feeCents = notionalCents * feeBps ~/ 10000` with `feeBps` a fixture constant. Review sheet, receipt and Wallet display these stored cents; nothing recomputes them.
- Review and receipt show: instrument, direction, size, reference price, paper funds required, "Simulated — no real order".

## Acceptance

- [ ] Confirm → Wallet shows one new position, cash reduced by margin + fee; totals on review, receipt and Wallet agree to the cent. Test: `app/test/scenario_test.dart`, 'placeOrder rounds once and review, receipt and Wallet totals reconcile'.
- [ ] Cancel → nothing changes (test asserts store equality).
- [ ] Double-tap confirm → one position. Widget test `app/test/order_ticket_test.dart`, 'double tap confirm places one position': tap Confirm twice before pumping, assert one position and one cash debit. Store test in `app/test/scenario_test.dart`, 'placeOrder with a repeated actionId returns the first result'.
- [ ] Stale-price failure → no position; Retry succeeds once.
- [ ] Widget tests cover both tickets; existing overflow tests still pass.

## Out of scope
Trader-index tickets (VC-MKT-005), advanced order types, Arena participation (unit 04 wires it).
