# Multi-Agent Review: spec set: app_shell.dart + live_feed.dart + orders_state.dart + portfolio_mock.dart + feed_order_ticket.dart + order_ticket.dart + trade_mock.dart + scenario.dart + home_screen_test.dart + order_ticket_test.dart + scenario_test.dart

## Executive Summary
Five reviewers (all returned) reviewed phase 2 (spec 02, truthful order confirm) at b3215f3. The store core holds: one write path, int-cent rounding, a duplicate guard, a scripted stale-price failure, a green gate, and run rules 1 and 4 (no new deps, VC-DEM-004 not built). The one HIGH is that `FeedOrderTicket` has no trader-index guard, so the 7 trader-market cards on Home can fill or rest trader-index orders through `placeOrder`. The spec excludes that (VC-MKT-005), and it contradicts the baton-pass claim. All four severity-using reviewers and critical-thinking raised it. Eight MEDIUM findings follow, mostly rule 3 (truthful labels) and AC1's Wallet leg. Recommended action: fix the HIGH at the store boundary, then input validation, Wallet cash and Retry, before merge. No HIGH findings were demoted by the budget (cap 8, 1 HIGH).

## Critical Findings
None at merged severity. silent-failure-hunter and security-reviewer rated H1 CRITICAL. It is merged at HIGH; see H1 and Reviewer Disagreements.

## High Findings

**H1. The feed ticket lets trader-index markets reach `placeOrder` and fill or rest**
- **Location:** `app/lib/features/trade/feed_order_ticket.dart:129-168` (`_problem`, `_place`; no trader-index check). Reached from `app/lib/features/home/home_screen.dart:86-89` (`onTrade`, no `traderMarket` branch) and `app/lib/features/home/trade_idea_card.dart:92`. Data: `mock_trade_idea.dart:190-327` (`mockFeed[5..11]`: maya.eth, 0xreal, lunaq, deltaone, kestrel, kilo.sol, nara, all `traderMarket: true`) and `market_prices.dart:11-24` (non-zero prices, e.g. maya.eth 0.44).
- **Description:** The spec says the trader-market entry "never reaches `placeOrder`" and puts VC-MKT-005 out of scope. Only `OrderTicket` has the guard (`order_ticket.dart:120, 207, 214-218`). Because these handles have real prices, `Scenario.problem` passes. Long → Confirm on maya.eth returns `OrderFilled`: cash goes from 1,248,000 to 1,227,980 cents, a position and a receipt are added, and the toast says "maya.eth long filled · $200.20". The Limit tab rests an open order. The same handle opened from `trader_market_screen.dart:79` refuses the order, so the two entry points disagree. The baton-pass claim "Trader-index tickets … never call the store" is false for this ticket. No test taps Long/Short on a trader card (`home_screen_test.dart:1799` taps only Details).
- **Evidence status:** a deterministic static trace by four reviewers, who agree to the cent. Not executed, because containment forbade adding a test.
- **Suggested fix:** Add a refusal in `Scenario.problem`/`placeOrder` when `!TradeMock.quotes.containsKey(intent.symbol)`, so every caller (units 04/05 included) inherits it. Mirror `OrderTicket`'s branch in `FeedOrderTicket._place` (pop plus the "Trader-index ticket — not in the demo yet" toast). Add a widget test on Home card 5 (maya.eth) asserting `state()` is unchanged.
- **Attribution and ratings:**
  - silent-failure-hunter: CRITICAL (deterministic, so a static trace is conclusive).
  - security-reviewer: CRITICAL (contradicts spec scope and the author's claim).
  - architect-reviewer: MEDIUM ("HIGH on its merits", lowered only because not executed).
  - penetration-tester: MEDIUM ("HIGH once reproduced").
  - critical-thinking also raised it (unrated).

## Medium and Low Findings

| Severity | Title | Location | Reviewer(s) | One-line description |
|---|---|---|---|---|
| MEDIUM | Double-tap on Place skips the review | `order_ticket.dart:211-224, 241, 411-436, 920-930, 962-968`; `feed_order_ticket.dart:162-168, 204, 610-660` | architect-reviewer | Confirm appears exactly where Place was. A tap, then a frame, then a second tap places the order without the review being seen. After a fill, the same spot becomes "View in Wallet". |
| MEDIUM | Retry fills at the price it just declared expired | `scenario.dart:89-91, 143-145`; `order_ticket.dart:862-867, 928` | architect-reviewer, penetration-tester | `refreshPrice` only clears a flag, so the frozen intent fills at the stale reference price. Retry is also offered for every failure reason. |
| MEDIUM | Fills invent TP/SL the user never set | `scenario.dart:176-183`; `position_sheet.dart:180-217` | architect-reviewer, penetration-tester | With exits off, the store writes +7% / −2.1% levels, and the Wallet position sheet shows them as real (rule 3). |
| MEDIUM | AC1 "Wallet agrees to the cent" is not met for cash | `portfolio_pager.dart:61, 66, 168`; `account_top_bar.dart:46-55`; `scenario_test.dart:233-274` | architect-reviewer, penetration-tester | Wallet cash shows whole dollars and random-walks ±$9 every 3 s (off under FLUTTER_TEST). The AC1 test never asserts Wallet cash. |
| MEDIUM | Store validation checks double units and price, not cents or finiteness | `scenario.dart:95-100, 272-277`; `order_ticket.dart:111-112, 188-191` | architect-reviewer, security-reviewer, penetration-tester | A dust size ("0.04" USD at 10x) or an Infinity/NaN size fills at $0.00, and leverage ≤ 0 throws `UnsupportedError` instead of returning `OrderFailed`. penetration-tester: HIGH once reproduced. |
| MEDIUM | Import cycle, plus a static mutable `AppShell.tab` | `order_ticket.dart:6, 800-804`; `app_shell.dart:15-17, 37-55` | architect-reviewer | The ticket imports `app_shell`, which imports `home_screen`, which imports the ticket. A global notifier any sheet writes and every shell mount resets. |
| MEDIUM | Store builds presentation and imports UI modules | `scenario.dart:3-5, 153-186` | architect-reviewer (MEDIUM), penetration-tester (LOW) | It hard-codes `spark24UpA` (rising on shorts too), `+$0.00`, 'just now' and the size strings. Exit defaults live in three places and can drift. |
| MEDIUM | AC3 widget test is masked by two guards; actionId-at-open is untested | `order_ticket_test.dart:88-104, 130-137`; `order_ticket.dart:74, 839-846` | architect-reviewer (MEDIUM), penetration-tester (LOW) | It fails only if both `_busy` and the store scan are removed. Minting the id in `_confirm`/`_retry` passes every test. |
| LOW | Limit/stop Place has no in-flight guard | `order_ticket.dart:211-224, 806-818`; `feed_order_ticket.dart:163-168` | silent-failure-hunter (MEDIUM), architect-reviewer, penetration-tester (LOW) | Two taps in the same frame call `Navigator.pop()` twice and may pop the route below. Money and state stay correct. |
| LOW | Rounding lives in `OrderIntent` getters, not `placeOrder` | `scenario.dart:272-277` | architect-reviewer (LOW), security-reviewer (MEDIUM) | Differs from the spec's letter; behaviour is equivalent. |
| LOW | Double money drives order sizing (rule 2, letter only) | `feed_order_ticket.dart:78-79, 87`; `order_ticket.dart:138-139, 151, 190, 195` | architect-reviewer, penetration-tester | Units come from double dollars. A security-reviewer sweep of 8.4M cases found no cent drift. |
| LOW | Three money formatters; feed button omits the fee | `feed_order_ticket.dart:113-114, 287, 324, 613`; `portfolio_pager.dart:168` | architect-reviewer, penetration-tester | `formatCents`, `formatUsd` and `_fmtUsd` all render money; "Long $200 · 2x" hides the $0.20 fee. |
| LOW | The "unchanged" limit path changed display decimals | `scenario.dart:120-135` | architect-reviewer, penetration-tester | BTC/ETH prices now show 0 decimals (was 2); ARB and sub-$1 quantity decimals changed. |
| LOW | Review Size row doesn't multiply out | `order_ticket.dart:950-954` | architect-reviewer, penetration-tester | Rounded units × price ≠ displayed notional (0.4605 BTC shows $31,044.78; the product is $31,043.23). |
| LOW | Stale comment | `arena_screen.dart:83` | architect-reviewer, penetration-tester | Says "joining a side places nothing", but it now fills a paper position. |
| LOW | A replay is indistinguishable from a first fill | `scenario.dart:113-118` | architect-reviewer | Side effects a later unit adds outside `placeOrder` would double-count. |
| LOW | Store update isn't atomic | `scenario.dart:187-189` | architect-reviewer | A cash listener sees the debit before the position exists. |
| LOW | Duplicated `unitDecimals`; hard-coded fee labels | `scenario.dart:262-268`; `order_ticket.dart:103-109, 407` | architect-reviewer, penetration-tester | Unit-decimal logic is copied 2–3 ways; the 'taker 0.05%' and 'maker 0.02%' labels duplicate TradeMock bps. |
| LOW | Feed ticket test coverage is thin | `order_ticket_test.dart:139-162` | architect-reviewer, penetration-tester | No cancel, double-tap, stale-price, trader-card or per-phone review overflow tests. `before` is captured after the ticket opens. |
| LOW | Fill toast shows behind the receipt sheet | `order_ticket.dart:851-859` | architect-reviewer, penetration-tester | The toast and its "View in Wallet" action usually expire unseen. |
| LOW | TP/SL edit toast writes nothing | `position_sheet.dart:249-262` | architect-reviewer | A phase-1 issue that now applies to positions this unit creates. |
| LOW | `_parseCents` parses leniently | `feed_order_ticket.dart:96-101` | silent-failure-hunter, security-reviewer, penetration-tester | Truncates a third decimal, accepts "1.2.3", and an 18-digit input overflows int64 to $0.84. |
| LOW | Confirm shows no visual busy state | `order_ticket.dart:893-930` | security-reviewer | Only `onTap` is nulled; colours are unchanged. |
| LOW | `_rest` toasts "placed" on any non-failure | `order_ticket.dart:809-817` | penetration-tester | A reused actionId returning `OrderFilled` would say "in Open orders". Unreachable today. |
| LOW | Store RED evidence is compile-level only | `/tmp/claude-1000/p2red/red-store.log` | penetration-tester | The assertions were never seen failing against a wrong implementation. |
| LOW | `LiveFeed.watch` leaks notifiers (carried forward) | `live_feed.dart:27-33` | penetration-tester | Replaces the notifier without disposing the old one; every fill now triggers it. |

## Coverage Report
Reviewers: 5/5 returned
Reviewed at: b3215f3b21d7082d4dafce1614762238f3ccca41
Any commit after this one is unreviewed.

**Engagement check:** No reviewer is tagged `[DID NOT ENGAGE]`. architect-reviewer, silent-failure-hunter, security-reviewer and penetration-tester all have substantive Confirmed lists. critical-thinking returned no `### Validated` section and no severities, so the rule does not apply to it. Its summary confirms run rules 1 and 4, and its items cite line-level traces and mutations. No emptiness or docs-only claims were made.

**Confirmed:**
- **Pubspec frozen:** empty `pubspec.yaml`/`.lock` diff; the gate's `pubspec-frozen` check passes. All five.
- **VC-DEM-004 not built:** grep of the diff for persona, phase advance and DEM-004 finds nothing. All five.
- **One write path:** grep for writers of `cashCents|positions|receipts|openOrders|stalePrices` outside `scenario.dart` finds only the Open-orders cancel/undo. architect-reviewer, penetration-tester.
- **Duplicate guard placement:** it scans receipts and open orders before validation; failures are not remembered, so Retry can re-run (`scenario.dart:112-118`). architect-reviewer, silent-failure-hunter, security-reviewer, penetration-tester.
- **Failures change nothing:** the dedupe, `problem()` and the stale check all return before the first write (`scenario.dart:140, 187`). penetration-tester, security-reviewer.
- **actionId minted at open:** in State field initializers (`order_ticket.dart:74`, `feed_order_ticket.dart:50`); the review freezes the intent. architect-reviewer, penetration-tester.
- **Open, Cancel and Done make no store call:** `initState` only reads; Cancel and Done are `Navigator.pop`; asserted by `state()` equality. architect-reviewer, silent-failure-hunter, security-reviewer, penetration-tester.
- **Rounding arithmetic:** 0.12345 × 2968.40 gives 36645 / 3665 / 18 / 3683, matching `scenario_test.dart:244-258`. security-reviewer confirmed Dart rounds half away from zero. architect-reviewer, silent-failure-hunter, security-reviewer, penetration-tester.
- **`maxMarginCents(2, 5)` = 1,246,753:** worst-case total stays ≤ cash. architect-reviewer, security-reviewer, penetration-tester.
- **Feed $200 at 2x totals 20020 cents.** security-reviewer (and the architect-reviewer trace).
- **No cent drift in the feed round trip:** a sweep of 8.4M margin/leverage/price combinations found zero round-trip cent mismatches. security-reviewer.
- **`formatCents` is integer-exact** (`~/` and `%` only). architect-reviewer, penetration-tester.
- **Validation order:** size, price, funds, then stale (market orders only); limit and stop debit nothing. architect-reviewer, security-reviewer, penetration-tester.
- **`receipts`/`stalePrices` continuity:** each has an initializer, a reset line, and entries in `state()` and `mutateEverything()`. architect-reviewer, penetration-tester.
- **`OrderTicket` trader-index guard:** correct for all order kinds; the Arena and `trader_market_screen.dart:79` call the guarded ticket. architect-reviewer, silent-failure-hunter, security-reviewer, penetration-tester.
- **Success messages match results:** toast amount equals the debit, and the old untruthful "filled" toasts are removed. architect-reviewer, penetration-tester.
- **Review panel content:** instrument, direction, size, price, margin, fee, funds and "Simulated" all present. penetration-tester.
- **"Not enough funds" unified** across both tickets and the store. architect-reviewer, silent-failure-hunter.
- **`OrderTicket.initState` NaN guard:** `_live > 0` prevents a NaN unit count. security-reviewer.
- **View in Wallet:** reaches Wallet (no nested navigators; the listener is added and removed correctly). penetration-tester.
- **Tests re-run:** `order_ticket_test` 10/10 and `scenario_test` 11/11. architect-reviewer, silent-failure-hunter, penetration-tester.
- **Gate:** analyze clean, +195 passed, the HAS_MARKET run passed, GATE: PASS. architect-reviewer, silent-failure-hunter, security-reviewer, penetration-tester.
- **Diff stat** is 11 files, +1074/−240, matching the claim. security-reviewer.
- **Store RED log exists** (compile-level errors). architect-reviewer, penetration-tester.
- **Seed cents match the seed display strings.** architect-reviewer.
- **Baton-pass containment claim:** the stray worktree is gone. penetration-tester.

**Examined, inconclusive:**
- **H1 runtime fill on a trader card** (architect-reviewer, security-reviewer, penetration-tester): blocked because no test file could be written.
- **Double-tap across a frame onto Confirm** (architect-reviewer): needs a device, or a tap → `pump()` → tap test.
- **`double.tryParse` of 309+ digits returning +∞** (architect-reviewer, penetration-tester): needs a runtime check. The dust branch does not depend on it.
- **20+ digit finite sizes overflowing int64** (penetration-tester): whether the Dart VM saturates or throws is unverified.
- **Limit/stop double `Navigator.pop()`** (architect-reviewer, silent-failure-hunter, penetration-tester): depends on frame timing against the closing route's IgnorePointer.
- **AC3 toast assert under mutation (a)** (architect-reviewer): relies on `scaffold.dart:441-459` behaviour; not executed.
- **`AppShell.tab` listener leak across tests** (silent-failure-hunter): believed safe; not instrumented.
- **`caller_play_screen.dart:43`, a second `showFeedOrderTicket` site** (security-reviewer): whether trader ideas reach it was not traced.
- **`OrderTicket._fraction` staying in [0, 1]** for all leverage caps and low-priced assets (security-reviewer): not executed.
- **Action snackbar persistence behind a modal** (penetration-tester): depends on the Flutter version.

**Not examined (residual risk):**
- How new positions render in the PortfolioScreen and the position-sheet chart (sparkline, P&L), including trader-index, dust and infinite positions.
- Feed-ticket review layout across the five phone sizes (no test exists).
- HAS_MARKET-specific UI paths beyond the gate's pass line.
- Arena flows beyond the ticket call sites.
- `asset_trade_screen`, `trader_market_screen` and `opinions_screen` beyond their call-site lines.
- Slider, leverage-sheet and TP/SL track painting.
- Widget RED evidence (in the implementer's scratchpad, not accessible).
- Specs 03–08, beyond a grep for trader-index scope.

**Acceptance-test realness:**

| AC | Test(s) | Verdicts and mutation reasoning |
|---|---|---|
| AC1 confirm → cash − (margin + fee), totals to the cent | `scenario_test` 'placeOrder rounds once…' | **architect-reviewer:** REAL for rounding and debit (raw-units margin gives 3664; a margin-only debit fails), WEAK for the review and Wallet legs. **penetration-tester:** WEAK (review never rendered; Wallet cash never asserted). **critical-thinking:** not met as written. **silent-failure-hunter:** REAL. **security-reviewer:** REAL (claims the `$366.45 position` assert catches stored/displayed divergence). See Disagreements. |
| AC2 cancel → nothing changes | `order_ticket_test` 'cancel from review…' | REAL according to all four severity-using reviewers (`state()` equality on open and after Cancel). Feed ticket MISSING (architect-reviewer, penetration-tester, critical-thinking). |
| AC3 double-tap → one position | widget 'double tap confirm…'; store 'repeated actionId…' | **Store test:** REAL according to all (deleting the receipts scan fails `same` and the counts). **Widget test:** WEAK or masked according to architect-reviewer, penetration-tester and critical-thinking (fails only with both guards removed; id-in-handler not caught). **silent-failure-hunter:** REAL with a caveat. **security-reviewer:** REAL, compound by spec design. See Disagreements. |
| AC4 stale price fails; Retry fills once | widget and store stale tests | REAL according to all (removing the stale check hides 'Price expired'; a no-op refresh hides 'Order filled'). The UI "once" is WEAK (two-guard masking, architect-reviewer). Neither test can see the Retry-at-expired-price finding, because LiveFeed is off. |
| AC5 both tickets covered; overflow passes | feed 'confirm adds a position…'; 5× overflow | Feed happy path and overflow REAL (architect-reviewer, penetration-tester). **silent-failure-hunter, security-reviewer:** WEAK overall. **critical-thinking:** one happy-path feed test only. The feed trader-card path is MISSING according to all. |
| Behavior: trader index never reaches `placeOrder` | 'a trader-index ticket says so…' | REAL for `OrderTicket` according to architect-reviewer, silent-failure-hunter, security-reviewer and penetration-tester. **critical-thinking:** WEAK, because kaito.eth's price is 0, so mutating the guard to `_live <= 0` still passes. architect-reviewer notes the guard is caught "partly through the button text". `FeedOrderTicket` MISSING according to all. |

## Unstated Assumptions and Open Questions (from critical-thinking)
1. **Trader cards fill via the feed ticket** (see H1). Did the spec's single named entry, `trader_market_screen.dart:79`, silently narrow the rule? If not, the guard belongs at the shared boundary.
2. **The trader-index test uses kaito.eth (price 0).** `_traderIndex` → `_live <= 0` passes, which would let priced handles reach the store via card Details → TraderMarketScreen. Re-point the test at a priced handle.
3. **AC1 is marked DONE without the Wallet showing the debit to the cent.** Which Wallet figure is AC1 about, and is a drifting cash headline acceptable in a truthful-money unit?
4. **Write-only cent fields.** `PortfolioPosition.notionalCents`, `marginCents`, `clashId` and `Scenario.receipts` are read by no screen. The Wallet shows a `detail.size` string frozen at fill. Should the Wallet read the ints, or should the reason they exist be recorded?
5. **The double-tap test needs both guards removed to fail.** Minting the id in `_place` passes every test. Is `_busy` meant to carry weight for unit 04+ latency? If so, it needs its own test.
6. **A real double tap spans a frame**, so the second tap lands on "View in Wallet", pops to root and switches tabs. Is that intended?
7. **Retry fills at the expired price.** Does "refreshes the context" include re-quoting, with new cents and a return to review?
8. **Failures are excluded from the duplicate guard**, against the spec's literal "no-op returning the first result". It is justified only in the baton-pass. Confirm with the spec owner and record the deviation.
9. **The duplicate guard depends on state surviving.** Cancelling a resting order (`OrdersState.remove`) erases its memory, and the same id with different content silently returns the old result. Units 04/06 could break it. Record the invariant, or keep a separate completed-actions set.
10. **Rounding happens in `OrderIntent`, and the ticket's `_intent` getter re-rounds on every build.** Record this; units 04/05 inherit it.
11. **No fixture tells floor from round on the fee** (18.3225 and exactly 20). `~/` → `.round()` passes every test. Add a case at ≥ .5 of a cent.
12. **The fill toast amount is never asserted**; only 'Bitcoin long filled' is checked.
13. **The store RED evidence is compile errors only.** The tests were never seen discriminating a wrong implementation.
14. **Double money outside the allowance** (feed `_notional`, `_maxNotional`, the cash headline), and three formatters against the spec's "one helper". Is units-from-double-dollars within the allowance? Are the cash displays exempt?
15. **The "unchanged" limit/stop path changed:**
    - validation went from margin ≤ $1,000 to margin + fee ≤ cash (the spec says margin ≤ cash);
    - cash is unreserved across resting orders;
    - the message changed;
    - decimals changed.
    Accept and record each change, or revert it.
16. **Retry is offered for every failure.** `notEnoughFunds` would loop forever; it is unreachable today only because Place is disabled first.
17. **Staleness is a fixture flag only.** A presenter lingering on BTC fills at an old live price.
18. **Fills invent state:** TP/SL, 'just now', `+$0.00` forever, and identical receipt timestamps (unit 06 will sort them).
19. **The store imports UI modules** and writes display strings. Is that acceptable before units 03–06 add fields?
20. **The fill toast shows behind the sheet.** Does a toast the user may never see count as "say what happened"?
21. **A same-frame double tap on Place** (limit/stop or trader-index) may pop two routes. Not reproduced.
22. **Cancel closes the whole ticket rather than returning to edit.** That silent decision is what keeps "one actionId = one review" safe; revisit it if Cancel changes.
23. **AC5 rests on one happy-path feed-ticket test**, and the feed ticket is the one with the trader-index hole.
24. **The trader-index `OrderTicket` stays interactive with validation off** (`_problem` returns `''`) and refuses only at Place. The spec called that toast "existing", but the author created it. Should it say so at open?

## Reviewer Disagreements
- **H1 severity.**
  - silent-failure-hunter and security-reviewer: CRITICAL.
  - architect-reviewer and penetration-tester: MEDIUM, explicitly only because not executed; both say HIGH on the merits.
  - **Resolution: HIGH.** The trace is deterministic and four reviewers agree to the cent, so the missing execution should not discount it. It is paper money with no security or data-loss risk, which keeps it out of CRITICAL under the severity table.
- **H1 fix location.**
  - silent-failure-hunter: mirror `_traderIndex` in `FeedOrderTicket`.
  - security-reviewer: a single check in `Scenario.problem`/`placeOrder`.
  - architect-reviewer and penetration-tester: both.
  - **Resolution:** a store-level refusal as the root fix, plus a feed-ticket branch so the user gets the "not in the demo yet" toast rather than a generic failure.
- **Limit/stop double-pop severity.**
  - silent-failure-hunter: MEDIUM.
  - architect-reviewer and penetration-tester: LOW.
  - **Resolution: LOW.** No money or state impact, it needs both taps in one frame, and penetration-tester notes it predates phase 2.
- **Rounding-location severity.**
  - security-reviewer: MEDIUM.
  - architect-reviewer: LOW.
  - **Resolution: LOW.** security-reviewer itself calls it non-functional, and its 8.4M sweep found zero impact.
- **Store-builds-presentation severity.**
  - architect-reviewer: MEDIUM.
  - penetration-tester: LOW.
  - **Resolution: MEDIUM.** A maintainability concern with an observable drift risk (exit defaults in three places) and user-visible effects (a rising sparkline on shorts).
- **Test-masking severity.**
  - architect-reviewer: MEDIUM.
  - penetration-tester: LOW.
  - **Resolution: MEDIUM.** The spec's actionId-at-open rule has no test, and later units depend on it.
- **What the AC3 widget test catches.**
  - silent-failure-hunter: its independent value is catching actionId instability across taps.
  - architect-reviewer, penetration-tester and critical-thinking: an id minted in the handler passes, because `_busy` absorbs the second tap.
  - **Resolution:** the majority is right. Checked at `order_ticket.dart:836-846`: `_busy = result is OrderFilled` stays true after a fill, so a per-confirm id never gets a second placement.
  - security-reviewer's view that the two-test design follows the spec is also true. Both points hold: the design is intended, and the actionId rule is still untested.
- **AC1 realness.**
  - silent-failure-hunter and security-reviewer: REAL.
  - architect-reviewer and penetration-tester: WEAK. critical-thinking: not met.
  - **Resolution: WEAK.** The `$366.45 position` assert security-reviewer relies on checks the notional size string, not cash. Wallet cash is whole dollars and drifts. Only the store reconciliation is real.

## Recommended Changes (Prioritized)
1. Refuse non-`TradeMock.quotes` symbols in `Scenario.problem`/`placeOrder`, and branch `FeedOrderTicket._place` to the existing "Trader-index ticket — not in the demo yet" toast.
2. Add a widget test (Home card 5, maya.eth, Long → Confirm → `state()` unchanged) and re-point the `OrderTicket` trader-index test at a priced handle.
3. In `Scenario.problem`, reject non-finite units or price, leverage < 1, and `notionalCents`/`marginCents` ≤ 0. Drop the non-finite → 0 branch. Add store tests for the 4-cent, infinite and leverage-0 intents.
4. Render Wallet cash with `formatCents(Scenario.cashCents)` without drift, and extend the AC1 test to assert the Wallet cash text equals `formatCents(seed − 3683)`.
5. On Retry, rebuild the intent at `MarketPrices.now(symbol)` with the same actionId and return to review; offer Retry only for retriable failures.
6. Make `PositionDetail.takeProfit`/`stopLoss` nullable and hide them when unset, and keep the TP/SL edit toast out until it writes state.
7. Stop the review bypass: ignore taps on Confirm and View in Wallet briefly after they appear (or move Confirm), with a tap → `pump()` → tap test.
8. Add tests that pin actionId-at-open (the Retry receipt id equals the failed attempt's id) and `_busy` on its own, a fee fixture with a fractional cent ≥ .5, and an assert on the toast amount.
9. Add a `_placing` guard to the limit/stop Place, and toast "placed" only on `OrderResting`.
10. Add feed-ticket tests for cancel, double-tap, stale AVAX and per-phone review overflow.
11. Pass navigation into the ticket as a callback instead of importing `app_shell`. Move `formatCents` to a dependency-free money file, and map fills to presentation types in the portfolio layer.
12. Clear the LOW items: integer-cent sizing, one money formatter, `_parseCents` bounds, review Size rounding, the stale Arena comment, duplicated unit decimals and fee labels, and `LiveFeed.watch` disposal.
13. Record the spec deviations in the digest: rounding on `OrderIntent`, failures excluded from the guard, the limit-path validation changes, and the guard's dependence on receipts and open orders surviving.

## Open Questions for the Author
- Was the trader-index exclusion meant to cover every entry point, or only `trader_market_screen.dart:79`?
- Which Wallet figure does AC1 mean, and may a displayed balance drift?
- Should Retry re-quote and send the user back to review?
- Do you accept "failures are not remembered by the duplicate guard" as a recorded deviation from the spec text?
- Are the limit/stop changes intended: margin + fee ≤ cash, unreserved cash across resting orders, and the new decimals?
- Is units-from-double-dollars within rule 2's allowance, and are the cash headlines exempt as "display"?
- Should the stored cent fields drive the Wallet, or why do they exist?
- Is `_busy` meant to protect a future async path (unit 04+)?
- Should the trader-index `OrderTicket` announce its limitation when it opens rather than at Place?

## Notes
- All five rostered agents and the synthesizer are parked (`~/.claude/agents-parked/`), not registered in this session. Each ran by the paste method as a `general-purpose` subagent, with its agent body as the role and an explicit read-only prohibition. Per their frontmatter, silent-failure-hunter and security-reviewer ran on sonnet; the other three inherited the orchestrator's model. The roster is the same five as the phase-1 reviews.
- The per-reviewer recovery checkpoints under `.claude/reviews/<slug>/` were not written: the caller's containment allowed writing only this report file.
- Refutation (`--adversarial`) was off, so the finding counts are raw and unchallenged.
- Reviewers could not write files, so none could add the widget test that would execute the trader-card, double-tap-across-a-frame, dust-size or limit double-pop paths. Those findings are static traces with computed values, and each says so. Several reviewers rated a finding lower for that reason alone and said what it would be once reproduced.
- critical-thinking returned no `### Validated` section and no severities. Its confirmations come from its summary, and its items appear only in their own section above.

## Report Audit

I checked attribution, dedupe, severity, the budget, coverage, and how the findings were carried into the report. Two minor defects turned up. Nothing changes a severity bucket, and no reviewer finding was lost. Every reviewer finding from the source reached a section, including all 24 critical-thinking items. The budget line is correct: "cap 8, 1 HIGH". Each severity change has a reason based on merit.

1. **The Executive Summary describes the MEDIUM set inaccurately (failure class 4)**
   - **Report, Executive Summary:** "Eight MEDIUM findings follow, mostly rule 3 (truthful labels) and AC1's Wallet leg."
   - **Report, MEDIUM table:** only one of the eight rows cites rule 3: "Fills invent TP/SL the user never set … (rule 3)". Only one is AC1: "AC1 'Wallet agrees to the cent' is not met for cash". The other six are:
     - "Double-tap on Place skips the review" (bypassing the review step)
     - "Store validation checks double units and price, not cents or finiteness" (input validation)
     - "Import cycle, plus a static mutable `AppShell.tab`" (layering)
     - "Store builds presentation and imports UI modules" (layering)
     - "AC3 widget test is masked by two guards" (test realness)
     - "Retry fills at the price it just declared expired"
   - **Source:** architect-reviewer files these under separate headings: "Layering problems: an import cycle … and the store now depends on presentation code", "The AC3 widget test can't tell which double-tap guard is working", and "The store accepts non-finite input".
   - **Why it matters:** "mostly rule 3 and AC1" covers about two of the eight. The count of eight is correct.

2. **Rationale wrongly credited to security-reviewer in the H1 ratings (failure class 6)**
   - **Report, H1 "Attribution and ratings":** "security-reviewer: CRITICAL (contradicts spec scope and the author's claim)."
   - **Source, security-reviewer:** its CRITICAL says "Home-feed trader-market cards can place real (simulated) orders through `Scenario.placeOrder`". Its failure line ends "toast truthful about a trade that should be impossible." It never mentions the author's or baton-pass claim.
   - **Who did raise it:** architect-reviewer ("this contradicts the baton-pass claim 'Trader-index tickets never call the store'") and critical-thinking ("Baton-pass claim true only for OrderTicket").
   - **Not a condensation effect:** the source says the security-reviewer body was condensed only in formatting.
   - **Impact:** low. The CRITICAL rating itself is credited correctly. Only the stated reason is misattributed.

**Summary:** The report is a faithful rendering of what the reviewers produced. The only problems are a loose description of the MEDIUM set in the Executive Summary and one reason credited to the wrong reviewer.

**Orchestrator note (added by the review orchestrator, not by the auditor):** Audit item 2 is wrong, and the mistake is the orchestrator's, not the synthesizer's. The copy of security-reviewer's report that the orchestrator gave the auditor was condensed. It dropped two phrases, and the orchestrator wrongly described that condensation as formatting only. The original security-reviewer CRITICAL title ends "contradicting the spec's explicit scope boundary and the author's own claim". Its failure scenario says "the baton-pass note ("Trader-index tickets… never call the store") is false for this entry point". The report's H1 attribution is therefore correct, so disregard item 2. Item 1 stands. The auditor saw condensed copies of all five reviewer reports, critical-thinking's and penetration-tester's most heavily. Its attribution and loss checks are therefore weaker than an audit against verbatim sources would be.
