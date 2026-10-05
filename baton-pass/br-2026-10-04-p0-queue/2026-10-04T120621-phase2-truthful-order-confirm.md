---
source: baton-runner work unit, phase 2 of 8 (docs/specs/02-truthful-order-confirm.md)
scope: br-2026-10-04-p0-queue
parent_session: 2026-10-04T115639-phase2-order-store-checkpoint.md
status: COMPLETE: every acceptance item green; GATE: PASS; nothing committed (the manager owns git)
---

# Phase 2 complete: both tickets confirm through Scenario.placeOrder

Branch `feat/br-2026-10-04-p0-queue/phase-2`, uncommitted. A "filled" toast now always follows a real fill: cash debited by margin + fee, one position, one receipt.

## Acceptance criteria

| AC | State | Test | RED evidence (before the code) |
|---|---|---|---|
| 1. Confirm → Wallet shows one new position, cash − (margin + fee); review, receipt, Wallet agree to the cent | DONE | `app/test/scenario_test.dart: 'placeOrder rounds once and review, receipt and Wallet totals reconcile'` (0.12345 ETH @ $2,968.40, 10x → 36645 / 3665 / 18 cents, the margin rounds from rounded notional; Wallet shows `Positions · 4` and `$366.45 position`). UI level: `app/test/order_ticket_test.dart: 'double tap confirm places one position'` (review's "Paper funds required" == `formatCents(receipt.totalCents)`, shown again on the receipt) and `'feed ticket confirm adds a position and View in Wallet shows it'` | `Error: Type 'OrderIntent' not found.` / `Member not found: 'Scenario.placeOrder'.` / `Member not found: 'receipts'.` (compile, store absent). Widget: `Found 0 widgets with text "Review order" descending from widgets` |
| 2. Cancel → nothing changes (store equality) | DONE | `order_ticket_test.dart: 'cancel from review leaves the store unchanged'` (also asserts opening changes nothing; feed test asserts review changes nothing) | `The finder "Found 0 widgets with text "Cancel": []" (used in a call to "tap()") could not find any matching widgets.` |
| 3. Double-tap confirm → one position | DONE | `order_ticket_test.dart: 'double tap confirm places one position'` (two taps, then one pump); `scenario_test.dart: 'placeOrder with a repeated actionId returns the first result'` | widget: `Found 0 widgets with text "Review order"`; store: compile errors above |
| 4. Stale-price failure → no position; Retry succeeds once | DONE | `order_ticket_test.dart: 'a stale price fails with no position; Retry fills once'` (Retry tapped twice → one position); `scenario_test.dart: 'a stale price fails with no change; refreshed, the action fills once'` | `The finder "Found 0 widgets with text "Confirm": []" ... could not find any matching widgets.`; store: compile errors |
| 5. Widget tests cover both tickets; existing overflow tests pass | DONE | OrderTicket: tests above; FeedOrderTicket: `'feed ticket confirm adds a position and View in Wallet shows it'`; trader index: `'a trader-index ticket says so and creates nothing'`; all existing overflow tests green | feed: `Found 0 widgets with text "Review order"`; trader: `Found 0 widgets with text "Trader-index ticket — not in the demo yet"` |

Also added (green on first run, not RED-first; regression guards for the new sheet): `order_ticket_test.dart: 'review and receipt render without overflow on <phone>'` × 5; store tests `'more than cash covers fails and changes nothing'`, `'a limit intent rests in Open orders and moves no cash'` (written with the RED store batch).

## Verification (final)
- `scripts/gate.sh` → `PASS flutter-analyze`, `PASS flutter-test` (195 passed), `PASS pubspec-frozen`, `GATE: PASS`.
- `flutter test --dart-define=HAS_MARKET=true` → `+195: All tests passed!`
- `flutter analyze` → `No issues found!`. pubspec.yaml / pubspec.lock unchanged. No new dependencies.

## Files touched (10 + 1 new test)
`app/lib/scenario/scenario.dart`, `app/lib/features/trade/order_ticket.dart`, `app/lib/features/trade/feed_order_ticket.dart`, `app/lib/features/trade/trade_mock.dart`, `app/lib/features/portfolio/portfolio_mock.dart`, `app/lib/features/portfolio/orders_state.dart` (dead `add` removed), `app/lib/features/live/live_feed.dart`, `app/lib/app_shell.dart`, `app/test/scenario_test.dart`, `app/test/home_screen_test.dart`, new `app/test/order_ticket_test.dart`.

## Public surface added
- `scenario.dart`: `enum OrderKind {market, limit, stop}` (moved from order_ticket.dart); `const notEnoughFunds = 'Not enough funds'`;
  `class OrderIntent({actionId, symbol, name, side, units (double), price (double), leverage, kind = market, icon, takeProfit?, stopLoss?, reduceOnly = false, clashId?})` with `late final int notionalCents / marginCents / feeCents`, `int get totalCents`, `int get feeBps`, `int get unitDecimals`;
  `class OrderReceipt({id (= actionId), symbol, name, side, leverage, units, price, notionalCents, marginCents, feeCents, at, clashId?})` + `totalCents`;
  `sealed class OrderResult` = `OrderFilled(receipt) | OrderResting(order) | OrderFailed(reason)`.
- `Scenario`: fields `receipts<List<OrderReceipt>>` (seed `[]`, newest first), `stalePrices<Set<String>>` (seed `TradeMock.stalePrices` = {'AVAX'}); `static OrderResult placeOrder(OrderIntent)`, `static String? problem(OrderIntent)`, `static void refreshPrice(String)`, `static int maxMarginCents(int leverage, int feeBps)`. Both new fields are in `reset()`, `state()` and `mutateEverything()`.
- `PortfolioPosition`: required `id`, `notionalCents`, `marginCents`; optional `clashId`. Seeds p-eth 400000/80000, p-sol 50000/5000, p-0xreal 6750/6750.
- `TradeMock.takerFeeBps = 5`, `makerFeeBps = 2`, `stalePrices = {'AVAX'}`. `formatCents(int)` in `live_feed.dart` (integer-exact; the one helper for stored money).
- `AppShell.tab` (static `ValueNotifier<int>`, reset to the START_TAB value in the shell's initState) and `AppShell.wallet = 3`.
- Removed: `OrderTicket.available`, `OrdersState.add`.

## Decisions phases 03-06 must honour
- **One write path.** Cash, positions, receipts and resting orders change only in `Scenario.placeOrder`. Rounding lives on `OrderIntent` (late-final, computed once per intent): `notionalCents = (units*price*100).round()` (non-finite → 0, so a priceless trader-index ticket can't throw), `marginCents = (notionalCents/leverage).round()`, `feeCents = notionalCents*feeBps ~/ 10000`. Review shows the intent's cents; the receipt and position store them; nothing recomputes.
- **Duplicate guard derives from state:** a receipt or open order whose id == actionId means "already done" → returns it. Failures are not remembered, so Retry reuses the actionId. Unit 04 should key participation by the same actionId and increment only on `OrderFilled`; unit 04 sets `OrderIntent.clashId`, which already flows to the receipt and position.
- **Validation order** (market): size > 0, price > 0, margin + fee ≤ cash (`notEnoughFunds`), then stale price (`'Price expired'`). Limit/stop skip the stale check and debit nothing (unchanged behaviour).
- **Review flow:** a market order's Place button freezes `_review = _intent` and the ticket's sheet swaps to the shared private `_ReviewPanel` (order_ticket.dart): Review order → Confirm/Cancel; filled → "Order filled" + Done / View in Wallet + toast `'<Name> <side> filled · $X from paper cash (simulated)'` with a View in Wallet action; failed → "Order not placed", reason, Cancel/Retry. Retry calls `refreshPrice` then confirms the same intent at the reviewed price. The panel already shows "Simulated — no real order" (unit 03: verify, don't duplicate). Unit 05's "Trade this" can open either ticket; its expired state should disable the ticket's Place/Confirm.
- **Action ids** are `act-<n>` from a process counter, minted in each ticket's State field initializer (on open), never in a handler.
- **Trader-index tickets** (symbol not in `TradeMock.quotes`) never call the store; Place closes the ticket with "Trader-index ticket — not in the demo yet" (all kinds, so a limit on a trader market no longer rests).
- **Order receipts** are `Scenario.receipts`; unit 06's `CallReceipt` must stay a separate type and list section.

## Remaining / for review
- Feed ticket keeps `_fmtUsd`/`groupDigits(cents/100)` for its editable amount echo, button label ("Long $200 · 2x") and TP/SL projections; the money it validates and places is int cents (`_marginCents`, parsed by integer `_parseCents`). Converting the label to `formatCents` would churn many existing tests; flagged, not done.
- Wallet's cash headline (pager + top bar) still shows whole dollars (pre-existing design); exact cents agree at the store level and in the position sheet's size.
- A new position with no exits gets the tickets' default TP/SL (+7% / −2.1%) because `PositionDetail` requires both; sparkline is the generic `spark24UpA`; P&L shows `+$0.00`.
- The fill toast shows while the receipt sheet is still open (behind it); it is visible after Done.
- Feed ticket opens at a fixed $200 (the design's stake), not 20% of cash; slider stops are shares of real cash, and Max is capped by `maxMarginCents` so it stays placeable.
- Containment slip, fixed: one command's leftover `tee` wrote `/home/alex/VistaColosseum/.claude/worktrees/x` (a copy of `flutter test` output) outside the worktree; I deleted it at once (`rm`, confirmed gone). Nothing else outside the worktree was written. RED logs live in the session scratchpad and under `/tmp/claude-1000/p2red/` (store RED log).
