# Phase 2 digest: truthful order confirm (spec 02) — CLEAN at 4a6af99 (review iter 3: C0/H0/M1/L16, gate PASS)

## Public surface (`app/lib/scenario/scenario.dart` unless noted)
- `Scenario.placeOrder(OrderIntent) → OrderResult` (sealed: `OrderFilled(receipt)`, `OrderResting(order)`, `OrderFailed(reason)`) is the ONE write path for cash, positions, receipts, open orders. Market: debits `totalCents` (margin + fee), prepends one `PortfolioPosition` + one `OrderReceipt`. Limit/stop: prepends an `OpenOrder` (`OrdersState.add` removed; `remove/insert` stay for cancel/Undo).
- actionId guard: a repeat `actionId` matching a receipt or open order returns the first result, changes nothing; failures are not remembered (retryable). Tickets mint it once at open (`_newActionId()`, `order_ticket.dart:788`, both tickets), never in the confirm handler.
- `Scenario.problem(intent) → String?` validates for both tickets' Place buttons and `placeOrder`, in order: trader index, leverage<1, size, price, TP/SL ≤0/non-finite, reduce-only market ('Reduce only — not in the demo yet'), margin > cash (`notEnoughFunds`), notional > `OrderIntent.maxNotionalCents` ('Size too large'), margin ≤ 0 ('Size too small'), margin+fee > cash.
- `OrderIntent{actionId, symbol, name, side, units, price (double inputs), leverage, kind=OrderKind.market, icon, takeProfit?, stopLoss?, reduceOnly, clashId?}` rounds once: `notionalCents=_cents(units*price)` clamped to [0, maxNotionalCents+1], `marginCents=(notional/leverage).round()`, `feeCents=notional*feeBps~/10000` (`TradeMock.takerFeeBps=5`, `makerFeeBps=2` for limit), `totalCents`.
- `OrderIntent.maxNotionalCents = 900719925474` (~$9B, (2^53−1)~/10000): no cent getter can wrap; BTC 1.37e12 units at 1x → 'Not enough funds', cash unchanged (re-verified iter 3).
- `OrderReceipt{id=actionId, symbol, name, side, leverage, units, price, notionalCents, marginCents, feeCents, at=clock, clashId?, totalCents}`; `PortfolioPosition` gained `id, notionalCents, marginCents, clashId?`.
- Store fields `receipts` (seed []) and `stalePrices` (seed `TradeMock.stalePrices={'AVAX'}`); `refreshPrice(symbol)`; consts `notEnoughFunds`, `priceExpired`, `traderIndexNotBuilt`; `maxMarginCents(lev, feeBps)` sizes Max.
- Trader-market guard: `Scenario.tradable(symbol)` = has a `TradeMock.quotes` entry; both tickets toast "Trader-index ticket — not in the demo yet" before review/rest; the store refuses too.
- `formatCents(int)` (`features/live/live_feed.dart:68`) is the one integer-only money formatter. Wallet headline and `AccountTopBar` show `formatCents(Scenario.cashCents)` with no feed drift (Home top bar now shows cents too).
- `_ReviewPanel` (shared): Retry only for `OrderFailed(priceExpired)`; Retry refreshes + re-quotes, fills at once if price/units unchanged, else returns to review. Other failures: reason + Cancel. `AppShell.tab`/`AppShell.wallet` back "View in Wallet".

## Conventions phases 03-08 must honour
- Write cash/positions/receipts/openOrders only in `scenario.dart`; new refusals are `problem()` lines + consts. New store field: initializer, `reset()` line, `state()` + `mutateEverything()` in `scenario_test.dart`.
- Store money is int cents, shown via `formatCents`, never recomputed. Unbuilt features keep "— not in the demo yet".
- Unit 04: keep `clashId` in ticket state so `requote` carries it; a replay returns an identical `OrderFilled` (iter-1 L8), so participation keyed by actionId must dedupe; `_confirm` has no try/finally (iter-2 L-8).
- Rounding lives in `OrderIntent` getters, not inside `placeOrder` (iter-1 L2, accepted deviation, same behavior).
- Widget probes must load OpenRunde (the Ahem test font fakes RenderFlex overflows); also run `flutter test --dart-define=HAS_MARKET=true`.

## Carried forward (report `review-phase-2-iter-3.md`; none is CRITICAL/HIGH)
- M-1 (MEDIUM, standing): feed `_parseCents` (`feed_order_ticket.dart:97-101`) wraps int64 for 17-18 digit amounts; '184467440737095517' places $0.84 while the field shows the typed digits. Saturate >12 digits to maxNotionalCents+1, test it.
- L-1: wrong-side TP/SL accepted by `problem()` (iter-2 L-3's second half, dropped without deferral).
- L-2/L-3: clamped Margin/Fee rows shown as real above $9B; an infinite cost (1e305 units) says 'Size too small'.
- L-4: moved-price re-review shows a live Confirm for an intent the store refuses (truthful failure after).
- L-5: Wallet change line and chart still follow the drifting feed under the exact headline.
- L-8: lenient feed amount parse ('1.2.3' → $1.20, '1,5' → $15); tickets' parsers differ.
- L-9: Retry then Cancel consumes the scripted AVAX stale flag until Reset demo (AC2 reading for the author).
- L-10/L-12/L-13/L-14: total==cash and units 0 unpinned; dead `_busy` ternary; test hygiene; one non-behavioral RED log.
- L-6: four stale doc comments in `scenario.dart` (:99-101, :109, :113, :307-310).
- L-11/L-15/L-16: feed rows overflow ≥$100M (pre-existing); failure kind matched by string; stop orders carry no kind.
- User: M-3 fills invent +7%/−2.1% TP/SL when exits are off (needs nullable exits + PositionSheet UI); no spec owns it.
- User: rule-2 waiver for double-dollar sizing (feed `_margin/_notional`, OrderTicket `_maxNotional`, pager `_change`)?
- User: store-owned per-market leverage cap? Is `TradeMock.quotes` authoritative for `tradable`?
- User: OrderTicket re-quotes fixed units, feed ticket fixed dollars; and live-app AC4 is Retry → review → Confirm (two taps).
- User: Wallet "My portfolio"/"Portfolio balance" label a cash-only figure; Home top bar now shows cents (design sign-off).
- Author: iter-1 M1 (double tap on Place skips review), M6 (`AppShell.tab` import cycle), M7 (store builds presentation).
