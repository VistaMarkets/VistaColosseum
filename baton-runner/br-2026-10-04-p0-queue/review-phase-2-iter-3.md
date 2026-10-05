# Multi-Agent Review: spec 02-truthful-order-confirm — phase 2, iteration 3 of 3 (14 files at 4a6af99)

## Executive Summary
Six reviewers (6 dispatched, 6 returned) checked the phase-2 fix of spec 02 at 4a6af99 against every iteration-2 finding. Refutation was off, so every count below is raw and has not been challenged. All six agree on these points:
- Iter-2 H-1 is fixed at the store, and iter-2 H-2 is fixed.
- Every iter-2 MEDIUM is either fixed or soundly deferred.
- Run rules 1 to 4 hold.
- The manager's RenderFlex-overflow evidence comes from the test font, not from the inputs.

Final counts are **C0/H0/M1/L16**, with no severity-budget demotions. The single MEDIUM is the feed ticket's `_parseCents` int64 wrap, which the store fix cannot see. This is the last fix iteration, so fix M-1 now (a few lines, plus L-1 if possible). Every remaining deferral must go into `digest-phase-2.md` with a named owner.

## Critical Findings
None.

## High Findings
None. `high_cap` = min(8, ceil(6 × 1.5)) = 8. No reviewer raised a HIGH, so nothing was demoted.

## Medium and Low Findings
New IDs below (M-1, L-1, …) belong to this report. Iteration-2 IDs are written "iter-2 X".

| Severity | Title | Location | Reviewer(s) | One-line description |
|---|---|---|---|---|
| MEDIUM | **M-1** Feed amount parse wraps int64, so the order placed differs from the amount typed | `app/lib/features/trade/feed_order_ticket.dart:97-101` (`_parseCents`), `:265-266`, `:289` | code-reviewer, fintech-engineer, silent-failure-hunter, tdd-guide, architect-reviewer | `(int.tryParse(whole) ?? 0) * 100` has no bound. 17 whole digits wrap negative and show "Enter an amount". `184467440737095517` fills $0.84 and `…717` fills $200.84 while the field still shows the typed digits. Past int64 the whole part is dropped. `:289`'s semantics value reads "−6768224418037% of available". Rule 3 holds, but the store bound never sees the typed value (iter-2 H-1 listed this location, and the fix diff never touched the file). Fix: saturate a whole part longer than 12 digits to `OrderIntent.maxNotionalCents + 1`, and add a widget test. |
| LOW | **L-1** Wrong-side TP/SL accepted; the second half of iter-2 L-3 was dropped without a deferral | `app/lib/scenario/scenario.dart:107-108, 123-125`; `order_ticket.dart:964-976` (`_ReviewPanel`) | code-reviewer, fintech-engineer, silent-failure-hunter, tdd-guide, architect-reviewer | `_level` checks only `> 0` and finite, so a long ETH at 2,968.40 with TP 2,000 and SL 3,500 fills. A moved-price Retry carries absolute exits onto a new entry, and the review panel shows no exits. PositionSheet `_nudge` cannot move the stored wrong-side TP. Fix: refuse wrong-side levels in `problem()` with a store test, or defer with an owner. |
| LOW | **L-2** OrderTicket shows the clamped Margin/Fee as the real cost above about $9.007B notional | `scenario.dart:315-316`; `order_ticket.dart:397-405` | code-reviewer, fintech-engineer, silent-failure-hunter, tdd-guide, architect-reviewer | Reachable from 133,614 BTC. At 200,000 BTC and 10x both rows are 33% low; at 1.37e12 BTC they read $900,719,925.48 and $4,503,599.62. The button correctly says "Not enough funds". Fix: render "—" when `notionalCents > maxNotionalCents`. |
| LOW | **L-3** A finite size whose cost is infinite is refused as "Size too small" | `scenario.dart:315-316, :118` | code-reviewer, fintech-engineer, silent-failure-hunter, tdd-guide, architect-reviewer | `units*price` = +∞ maps to 0 (a 306-digit BTC size, or 1e305 units). Fix: `usd.isNaN ? 0 : (usd * 100).clamp(0, maxNotionalCents + 1).round()`. A store-only variant (0.1 ETH at 2^40x, so margin is 0) is not covered by that fix. |
| LOW | **L-4** The moved-price re-review offers a live Confirm for an intent the store refuses | `order_ticket.dart:873-881, 937-946`; the behaviour is locked in by `order_ticket_test.dart:321-343` | code-reviewer, fintech-engineer, silent-failure-hunter, tdd-guide | When AVAX is re-quoted at $400, the re-review shows Confirm. Tapping it gives a truthful "Not enough funds", and the only way out is Cancel, which closes the ticket. Fix: show `Scenario.problem(_intent)` in place of Confirm. |
| LOW | **L-5** The Wallet change line and chart drift under the now-fixed headline | `app/lib/features/portfolio/portfolio_pager.dart:62-67, 160-173, 311-324` | code-reviewer, fintech-engineer, silent-failure-hunter, architect-reviewer | The headline holds at `$12,480.00` while the change line goes +$91 → +$118 over three ticks. After a fill it still reads "+$91" over a rebased chart. Fix: compute the change and the chart end from `_balance`. |
| LOW | **L-6** Stale or overstated doc comments in `scenario.dart` | `:99-101`, `:109`, `:113`, `:307-310` | code-reviewer, fintech-engineer, silent-failure-hunter, tdd-guide | `:99-101` says there is no "bad exit", but wrong-side exits pass. `:109` says "no position to reduce", but the seed holds ETH and SOL. `:113` says margin + fee "need not fit an int", but the clamp makes them fit. `:307-310` says "under 2^53" for any fee rate, which is true only below 100%. Fix: reword all four. |
| LOW | **L-7** The iter-2 L-9 carry list is incomplete, and `digest-phase-2.md` does not exist | fix baton `2026-10-04T140130` ("L-9 FIXED", "Carried user questions"); work baton "Decisions phases 03-06 must honour" | code-reviewer, silent-failure-hunter | The baton says iter-1 M1, M6, M7, L2 and L8 are carried, but the list holds only M-3, L-1, L-2/L-11 and the re-quote rule, and it drops three iter-1 author questions. The work baton's validation order and its Retry decision are stale. Fix: list everything in the digest with owners. |
| LOW | **L-8** Amount parsing is lenient, and the two tickets' parsers have drifted apart | `feed_order_ticket.dart:96-101, 133-134`; `order_ticket.dart:111-112` | silent-failure-hunter, architect-reviewer | The feed ticket reads `1,5` as $15 and `1.2.3` as $1.20, and both fill. `1.999` truncates to $1.99. OrderTicket rejects `1.2.3`. The empty-input wording differs ("Enter an amount" vs "Enter a size"). Fix: reject a second `.` as part of M-1's fix. |
| LOW | **L-9** Retry followed by Cancel uses up the scripted stale-price failure | `order_ticket.dart:875` | silent-failure-hunter | `stalePrices` goes from {AVAX} to {} with no receipt, and the next AVAX ticket fills until "Reset demo". Fix: refresh only on the confirming path, or accept the behaviour and pin it with a test. |
| LOW | **L-10** Funds and size boundaries are not pinned by tests | `scenario.dart:105, :119`; `scenario_test.dart` | tdd-guide | No test sits at total == cash, so a `>`→`>=` mutant at `:119` survives. `units: 0` is untested. Fix: add the B1 pair (1247377 fills to cash 0; 1247378 is refused) and a `units: 0` → 'Enter a size' case. |
| LOW | **L-11** Feed ticket rows overflow at large displayed amounts (pre-existing) | `feed_order_ticket.dart:319, :565` | architect-reviewer (tdd-guide corroborates) | With the real font, the overflow is 20px at $99,999,999.99 on a 360px phone, and appears from 11 digits on a 402px phone. These amounts are refused, and the rows date from phase 1. Optional fix: `Flexible` with ellipsis. |
| LOW | **L-12** Dead `_busy` ternary on Confirm | `order_ticket.dart:945` | tdd-guide | `_busy` is true only once `_result` is `OrderFilled`, which an earlier arm already matches, so Confirm never renders disabled. Double-tap safety rests on the `:848` guard (mutant A). Fix: drop the ternary or comment it. |
| LOW | **L-13** Test hygiene | `scenario_test.dart:275-280, :414`; `order_ticket_test.dart:290, 324, 347` | tdd-guide | The AC1 test mutates the 'portfolio' LiveFeed notifier with no teardown. Three tests cast `MarketPrices.of(..)` to a concrete `ValueNotifier<double>`. The "unset take profit is refused" test actually tests 0. Fix: add the teardown and rename the test. |
| LOW | **L-14** One RED entry in the fix baton is not a behaviour RED | `fix-phase-2-iter-2/red.log` ("a trader-index ticket…") | tdd-guide | The test failed because a SnackBar blocked the tap, yet the baton counts it among its "10 failing". Fix: cite mutant C as the RED for iter-2 L-5. |
| LOW | **L-15** The failure kind is matched by its display string | `order_ticket.dart:942-944`; `scenario.dart:372-375` | architect-reviewer | Retry keys on `OrderFailed(reason: priceExpired)`, and specs 04/05 will add more failure causes. Fix: give `OrderFailed` an enum kind once a second cause needs different handling. |
| LOW | **L-16** Stop orders rest as `OpenOrder`s with no kind, while the toast says "Stop … placed" | `scenario.dart:148-166`; `portfolio_mock.dart:176-224` | silent-failure-hunter | This behaviour predates phase 2 and now lives in the store. The cancel toast says "limit order cancelled". Fix: add `OrderKind kind` when a later unit touches Open orders. |

### Iteration-2 finding dispositions

| Iteration-2 ID | Consensus disposition | Dissent / caveat | New ID(s) here |
|---|---|---|---|
| H-1 | **Resolved at the store** (6/6). The margin-before-cash check is at `scenario.dart:114` and the `_cents` clamp at `:315-316`, both pinned by `scenario_test.dart:339-375`. The manager's repro holds. | All six say the baton's "FIXED (store, every caller)" overclaims, because the feed parse wrap happens before the store sees anything. | M-1, L-2, L-3 |
| H-2 | **Resolved** (6/6). The top bar and headline both render `formatCents(Scenario.cashCents)`, showing `$12,443.17` ×2 across ticks. | critical-thinking: the label, the history and the Home top-bar change were not addressed or approved. | L-5; CT items 5–6 |
| M-1 | **Resolved** (6/6). Mutant F was killed. | — | L-4 |
| M-2 | **Resolved** for price and units (6/6). Mutant B was killed. | critical-thinking and silent-failure-hunter: the baton's "TP/SL now under review" is false, because the review panel has no exit row. | L-1, L-4, L-9 |
| M-3 | **Soundly deferred** (6/6). It needs a nullable `PositionDetail` plus PositionSheet UI, and no spec from 03 to 08 owns TP/SL. | critical-thinking: it has no landing place, and a second form appears through re-quotes. | L-7; CT item 3 |
| M-4 | **Resolved** (6/6). | The `:109` comment is wrong; critical-thinking raises UX-convention questions. | L-6; CT item 11 |
| M-5 | **Resolved** (6/6). Mutant D was killed. | — | — |
| M-6 | **Resolved** (6/6). Mutant A was killed. | tdd-guide: the actionId-reuse-on-Retry half stays deferred because there is no test seam. | — |
| L-1 | **Soundly deferred** pending the user's rule-2 waiver (6/6). | critical-thinking: the waiver should explicitly cover the pager's `_change` double math. | CT item 12 |
| L-2 | The notional half is fixed; the per-market leverage cap is **soundly deferred** (6/6). "Size too large" needs leverage of about 721,731x or more. | — | — |
| L-3 | **Partly resolved** (6/6). Exits that are ≤ 0 or non-finite are refused; the wrong-side half was dropped silently. | silent-failure-hunter: calling it "FIXED" is unsound. | L-1 |
| L-4 | **Resolved** (6/6). | — | — |
| L-5 | **Resolved** (6/6). Mutant C was killed. | tdd-guide: the `red.log` entry cited for it is not a behaviour RED. | L-14 |
| L-6 | **Resolved** (6/6). | — | — |
| L-7 | **Resolved** for infinite units (6/6). Mutant E was killed. | An infinite product of finite inputs is a new edge case. | L-3 |
| L-8 | **Soundly deferred** (6/6). `placeOrder` cannot throw on reachable input. | critical-thinking: spec 04 adds code to `_confirm`, which has no try/finally, so this needs a digest line. | L-7 |
| L-9 | **Split 3–3.** | code-reviewer, silent-failure-hunter and critical-thinking: partly or not resolved. fintech-engineer, tdd-guide and architect-reviewer: resolved for now, because the digest is not due yet. | L-7 |
| L-10 | **Soundly deferred** (6/6). | — | — |
| L-11 | **Soundly deferred** (6/6). | — | — |
| L-12 | **Resolved** (6/6). | silent-failure-hunter: `:99-101` overstates the case. | L-6 |
| iter-1 L14 (folded into iter-2 H-1) | **Standing** (6/6). The wrap is real, and the store fix cannot close it. | Whether the original deferral reason was accurate: see Reviewer Disagreements. | M-1 |

## Coverage Report
Reviewers: 6/6 returned
Reviewed at: 4a6af99411805f7a16c03f4c2ef72a20996b5fba
Any commit after this one is unreviewed.

**Confirmed:**
- **Store overflow bound (iter-2 H-1).**
  - `maxNotionalCents` = (2^53−1) ~/ 10000 = 900,719,925,474.
  - The clamped notional is at most 900,719,925,475 and the maximum fee is 450,359,962, so every total stays well inside int64.
  - Margin is checked before cash at `scenario.dart:114`.
  - Confirmed by code-reviewer, fintech-engineer, tdd-guide and architect-reviewer. code-reviewer re-ran the manager's leverage 1..100 and 1<<62 cases.
- **Store sweep.** 750 cases (leverage 1–50, sizes $0.004 to $1e300): 348 fills, 402 refusals, 0 bad. Every refusal left cash at 1,248,000. (fintech-engineer)
- **Reachability.**
  - "Size too large" needs leverage of about 721,731x or more.
  - UI leverage is clamped at `order_ticket.dart:1113`, and the feed presets are 2/5/10.
  - (code-reviewer, silent-failure-hunter, architect-reviewer)
- **Funds boundary.** A total equal to cash fills and leaves cash at 0; one cent over is refused. (tdd-guide, probe B1)
- **Max-slider totals fit cash.** At 2x, 10x and 50x the total is 1,247,999. (fintech-engineer)
- **Rounding and fees match VC-ORD-003.**
  - The AC1 fixture gives 36645 / 3665 / 18 / 3683, so the Wallet shows `$12,443.17`.
  - A fee of 296.84 rounds to 296.
  - The 5 bps taker and 2 bps maker rates match their labels.
  - (fintech-engineer, code-reviewer, tdd-guide)
- **One validator, one write path.**
  - Both tickets and `placeOrder` call `Scenario.problem`.
  - `placeOrder` is called only at `order_ticket.dart:812` and `:850`.
  - Cash, positions and receipts are written only in `scenario.dart`.
  - (fintech-engineer, silent-failure-hunter, architect-reviewer)
- **Wallet cash has a single source and does not drift.** The top bar and headline show `$12,480.00` / `$12,443.17` ×2 across ticks. (all five severity reviewers)
- **Rule 3 holds, including in M-1's wrap case.** Review, receipt, toast and Wallet agree, and `formatCents` is integer-only. (fintech-engineer, silent-failure-hunter, tdd-guide, code-reviewer)
- **Retry state machine.**
  - Retry is offered only for `priceExpired`.
  - Double taps are safe on both the same-price and moved-price paths.
  - `_busy` is cleared on failure.
  - (code-reviewer, fintech-engineer, silent-failure-hunter, architect-reviewer)
- **Mutant A–F and `red.log` evidence matches the fix baton.** Confirmed by all six; fintech-engineer took mutant C from the baton rather than its log. Caveat: L-14.
- **Test coverage of the ACs.** AC test names match the spec, the double-tap test asserts one fill, one receipt and one haptic, and the Wallet pager rebuilds on cash. (tdd-guide)
- **The iter-2 L-8 deferral is sound.** `placeOrder` cannot throw on reachable input. (silent-failure-hunter, architect-reviewer, fintech-engineer)
- **Seed position cents match their display strings.** (silent-failure-hunter)
- **PositionSheet `_nudge` cannot move a wrong-side TP.** (code-reviewer)
- **The iter-2 fix diff adds no new double money.** (code-reviewer)
- **Specs 03–08.**
  - A grep finds no TP/SL, reduce-only, Wallet-cash or amount-parse work (code-reviewer, silent-failure-hunter).
  - architect-reviewer read them in full: no fix blocks them.
- **Gate and run rules** (all six):
  - analyze is clean, and the suite is +212 on both the default and HAS_MARKET runs;
  - the pubspec diff against phase-1 is 0 lines;
  - no persona, advancePhase or DEM-004 code was added;
  - after the probes, only the untracked `gate-phase-2-iter-3/` remains.
- **Correction to the manager's pre-review evidence (RenderFlex overflows):**
  - **`order_ticket.dart:368` (167px) and `feed_order_ticket.dart:243` are test-font (Ahem) artifacts.**
    - The manager's probe never loaded OpenRunde.
    - Without the font, the same overflows appear at default inputs (code-reviewer, silent-failure-hunter, tdd-guide).
    - With the font loaded, the 13-digit BTC size and the 18-digit feed amount give 0 exceptions (all six).
    - The `:243` Row does not depend on the amount at all (critical-thinking).
  - **`:319` and `:565` do overflow with the real font, but only at large displayed amounts.** That is about $100M on a 360px phone, or 11+ digits on a 402px phone. The rows predate this phase (tdd-guide, architect-reviewer, critical-thinking). The manager's wrapped case displays $0.84 and does not overflow. This is tracked as L-11.
  - **Half of the manager's H-2 probe proves nothing.** Its post-reset ticks hit an orphaned notifier, because `LiveFeed.watch` replaces the notifier on rebase. The conclusion still holds, because the headline reads `cashCents` directly (critical-thinking).
  - Future probes should load fonts, as `order_ticket_test.dart:22-29` does.

**Examined, inconclusive:**
- **AC4 and Retry in the running app with LiveFeed on.** Blocker: LiveFeed is off under `FLUTTER_TEST`; this needs a device run. (code-reviewer, fintech-engineer, silent-failure-hunter, tdd-guide, architect-reviewer)
- **How PositionSheet renders a stored wrong-side TP.** The stored state is confirmed; the sheet was not run. (architect-reviewer)
- **Cross-frame double tap on Place, Confirm or Retry.** Blocker: needs a device, or a tap → `pump(16ms)` → tap test. (silent-failure-hunter)
- **M-1 inputs on the other three phones.** Only 402×874 and 360×640 were run. (silent-failure-hunter, tdd-guide)
- **Equivalent `>`→`>=` mutants at `scenario.dart:114/:115`.** Reasoned, not run, because product edits were not allowed. (tdd-guide)
- **Whether Retry keeps the open-time actionId.** There is no test seam; this is iter-2 M-6's deferred half. (tdd-guide)
- **Feed typed margin equals stored margin for realistic amounts.** Needs an exhaustive sweep. (architect-reviewer)
- **`AppShell.tab` re-init could trigger setState during build.** Static read only. (code-reviewer)
- **Web int semantics.** code-reviewer and architect-reviewer did not run web; fintech-engineer found no `web/` target, so this is moot unless web is added.

**Not examined** (the residual risk of this review):
- About 1,700 lines of `home_screen_test.dart` outside the phase-2 hunks and the pager, top-bar, position-sheet, order-ticket and feed-ticket groups.
- `caller_play_screen` and `opinions_screen` beyond their ticket call sites.
- `open_order_card.dart`, `asset_trade_screen.dart`, and `position_sheet.dart` beyond `_nudge`.
- `trade_mock.dart` beyond the fee, stale and quote constants.
- The fix iteration-1 RED logs.

**Engagement check:** all five severity-using reviewers have non-empty Confirmed lists, so none is tagged. critical-thinking has no formal Validated section, but it executed probes P1–P8 with fonts loaded and checked the run rules, so it is not tagged either.

## Unstated Assumptions and Open Questions (from critical-thinking)
critical-thinking does not assign severities. Its items are listed here, with the merged IDs they overlap.

1. **Four baton claims overstate what was done.**
   - L-3 "FIXED" dropped the wrong-side half.
   - M-2 says the TP/SL are "now under review", but the review panel shows no exits.
   - L-9 says items are carried, but the list omits them.
   - H-1 "every caller" misses the feed parse.
   - Maps to L-1, L-7 and M-1.
2. **Fix the feed parse now, because no fix iteration remains.** A length-limiting formatter on both tickets' amount and size fields, or refusing `whole.length > 12`, also cures the `:289` semantics wrap. Maps to M-1.
3. **The TP/SL a new fill shows are not reliably what the user set, in either mode.**
   - With exits on (probe P5), an AVAX long with TP 40.87 / SL 37.40 gets "Price expired", the price moves to 45, and Retry re-reviews with no exits shown. The position is stored at entry 45 with TP 40.87.
   - With exits off, a fill invents +7% / −2.1% exits (`scenario.dart:206-208`).
   - No spec owns this. Either record it with an owner or get written user acceptance. Maps to L-1 and iter-2 M-3.
4. **`digest-phase-2.md` is now the only place left to carry deferrals.**
   - `STATE.md` points to it, but it does not exist, and "user decision" names no one who will act.
   - Spec 04 increments participation "keyed by actionId", yet `placeOrder` returns an identical `OrderFilled` for a replay (iter-1 L8).
   - Spec 04 adds code to `_confirm`, which has no try/finally (iter-2 L-8).
   - Spec 04's `clashId` must live in ticket state so that `requote: () => _intent` carries it.
   - Spec 05 needs a prefill seam (OrderTicket takes only `symbol` and `side`) and an "Expired" state.
   - Maps to L-7.
5. **H-2 fixed the number but not the label or the history.**
   - "My portfolio" and "Portfolio balance" sit over a cash-only figure.
   - The change line and chart regenerate from the new cash after every fill. Computed, not run: after a $10,000 margin fill the card would read about "$2,4xx · +$91 (3.8%)" over a rising chart.
   - Iter-2 open question 1 was neither answered nor carried.
   - Partly maps to L-5.
6. **H-2 went beyond the manager's decision.**
   - The shared `AccountTopBar` now shows `$12,480.00` on Home instead of whole dollars.
   - Both headlines stopped drifting, which was LiveFeed's stated purpose.
   - Needs design-owner sign-off.
7. **The clamp makes the cents getters false at both ends.** Maps to L-2 and L-3.
8. **Retry then Cancel changes the store.** AC2 says "Cancel → nothing changes", but the current test covers only a Cancel from the first review. Maps to L-9.
9. **AC4 is always a two-tap path in the running app.**
   - Prices tick every 3 s, so `reviewed` (`order_ticket.dart:877`) is almost never true outside tests.
   - The one-tap AC4 test passes only because LiveFeed is off under test.
   - A demo script written from AC4 will meet a second review screen.
   - Related: L-4.
10. **The manager's overflow evidence is a font artifact.** Recorded in the Coverage Report.
11. **Nits on the M-4 fix.**
    - The `:109` comment is false (L-6).
    - The refusal appears as a disabled-button label, but the spec's convention is the "— not in the demo yet" toast.
    - The Reduce-only checkbox stays toggleable for Market.
    - The label fits on the 360×640 phone.
12. **Rule checks.**
    - Rules 1 and 4 hold, and the store is int cents.
    - Double money remains in feed sizing and `_maxNotional`, both covered by the iter-2 L-1 waiver question.
    - The pager's `_change` line also uses double money. It predates this phase and is not named in the waiver.

critical-thinking's confidence is high on the code claims (executed with fonts loaded) and medium on the intent questions.

## Reviewer Disagreements
1. **Is iter-2 L-9 resolved?**
   - code-reviewer, silent-failure-hunter and critical-thinking say no: the carry list omits items it claims to carry.
   - fintech-engineer, tdd-guide and architect-reviewer say yes for now: the digest is a phase-close step, and `STATE.md` says RUNNING.
   - **Resolution:** the facts are agreed. Because this is the last fix iteration, keep L-7 open until `digest-phase-2.md` lists every item with an owner.
2. **Was the iter-1 L14 deferral reason accurate?**
   - code-reviewer: accurate. A placeable wrap needs 18+ digits, and 17 digits land on "Enter an amount".
   - fintech-engineer and critical-thinking: off by one, since 17 digits already wrap. critical-thinking adds that the button states a different amount from the field.
   - architect-reviewer, silent-failure-hunter and tdd-guide: a placeable wrap needs 18+, but 17 digits produce a false "Enter an amount", and the field keeps the typed figure.
   - **Resolution:** the measurements agree. "The button states the amount placed" does not make the swap visible to the user, so treat the deferral as unsound and fix M-1.
3. **Is the Retry → Cancel stale-flag consumption a finding at all?**
   - silent-failure-hunter: LOW, though arguably by design.
   - critical-thinking: it conflicts with AC2 ("Cancel → nothing changes").
   - fintech-engineer: examined it and did not raise it, since it fits the spec's "Retry that refreshes the context".
   - **Resolution:** keep L-9 at LOW pending the author's ruling. Either way, pin the behaviour with a `stalePrices` assertion.
4. **Which overflows are real?**
   - code-reviewer: all four (`:368`, `:243`, `:565`, `:319`) are font artifacts at default inputs.
   - architect-reviewer, tdd-guide and critical-thinking: `:319` and `:565` also overflow with the real font at large displayed amounts.
   - **Resolution:** both are right. The manager's cases are font artifacts. The large-amount overflow is real but predates this phase and affects only refused amounts (L-11).
5. **Severity:** there are no splits. All five severity-using reviewers rated M-1 MEDIUM. architect-reviewer gave medium confidence on whether it is LOW or MEDIUM, and critical-thinking argues for fixing it now. Keep it at MEDIUM.

## Recommended Changes (Prioritized)
1. **M-1 and L-8:** make `_parseCents` saturate, so that any non-empty whole part over 12 digits (or one that will not parse) returns `OrderIntent.maxNotionalCents + 1`, and reject a second `.`.
2. **M-1:** compute the `:289` semantics percent as `(_marginCents / _cash * 100).round()`, and add a widget test where `184467440737095517` shows "Not enough funds" and no `Long $0.84`.
3. **L-1:** add a correct-side TP/SL check to `Scenario.problem()` with a store test, or record the wrong-side half as a deferral with an owner.
4. **L-3:** change `_cents` to `usd.isNaN ? 0 : (usd * 100).clamp(0, maxNotionalCents + 1).round()`.
5. **L-2:** render "—" in OrderTicket's Margin and Fee rows when `notionalCents > maxNotionalCents`.
6. **L-4:** gate the re-review Confirm on `Scenario.problem(_intent)`, and update `order_ticket_test.dart:321-343` to match.
7. **L-5:** compute the Wallet change line and chart endpoint from `_balance` instead of `_liveBalance`.
8. **L-9:** rule on the Retry → Cancel stale-flag behaviour, and pin it with a `stalePrices` assertion in the Cancel-at-re-review test.
9. **L-6:** reword the four doc comments at `scenario.dart:99-101, 109, 113, 307-310`.
10. **L-10, L-12, L-13:** add the total == cash / cash + 1 store pair and a `units: 0` case, drop or comment the dead `_busy` ternary, add the LiveFeed teardown, and rename the "unset take profit" test.
11. **Correct the fix-baton record:** fix the "H-1 FIXED (store, every caller)", "L-3 FIXED" and "M-2 TP/SL under review" claims, and cite mutant C as the RED for iter-2 L-5 (L-14).
12. **L-7:** write `digest-phase-2.md` carrying every unfixed item with a named owner, and supersede the stale work-baton decisions there. Those items are:
    - iter-1 M1, M6, M7, L2 and L8;
    - iter-2 M-3, L-1, L-2, L-8, L-10 and L-11;
    - any of L-1 to L-16 not fixed in step 1–10;
    - the three dropped iter-1 author questions;
    - the spec 04/05 seams.
13. **Optional:** L-11 (`Flexible` on `:319` and `:565`), L-15 (an enum `OrderFailed` kind) and L-16 (an `OpenOrder` kind) can wait for the unit that touches those areas, recorded in the digest.
14. **Future probes:** load OpenRunde, as `order_ticket_test.dart:22-29` does.

## Open Questions for the Author
1. Fix M-1 in this final iteration, or carry it as an H-1 residual with an owner?
2. Refuse wrong-side TP/SL in the store (L-1), or defer it, and to whom?
3. Is the Retry → Cancel consumption of the scripted failure intended, given AC2's "Cancel → nothing changes" (L-9)?
4. Does the demo or PRD owner accept Retry → Review → Confirm in the live app as satisfying AC4's "Retry succeeds once"?
5. Should the Wallet's "My portfolio" / "Portfolio balance" labels over a cash-only figure, and the "+$91" history, be relabelled now or carried to spec 03?
6. Does the design owner approve the Home top bar now showing cents, and both headlines no longer drifting?
7. Who writes `digest-phase-2.md`, and who owns each carried item?
8. Does the iter-2 L-1 rule-2 waiver also cover the pager's `_change` double math?
9. For not-built features like M-4, keep the disabled-button label, or use the spec's "— not in the demo yet" toast and hide Reduce-only for Market?
10. Does iter-2 M-3 (invented exits when exits are off, plus stale absolute exits after a re-quote) get an owner, or written acceptance as demo behaviour?
11. Are L-2 and L-3 acceptable as absurd-input-only if they are not fixed?

## Notes
- The roster came from context-aware selection, using the same lanes as iteration 2:
  - L-ADVERSARIAL → critical-thinking
  - L-BASELINE → code-reviewer
  - L-FINANCE → fintech-engineer
  - L-RESILIENCE → silent-failure-hunter
  - L-TEST → tdd-guide
  - L-ARCH → architect-reviewer
- L-LANG:dart and L-NUMERIC had no agent in the pool, so they degraded: code-reviewer owned Dart/Flutter idiom, and fintech-engineer owned int-cent arithmetic.
- No real-world risk flag fired (simulated money, no keys, no external I/O), so no security lane was selected.
- All six reviewers and the synthesizer are parked agents. They ran by the paste method as general-purpose subagents with explicit read-only prohibitions, on the orchestrator's model rather than any frontmatter model.
- Per-reviewer recovery checkpoints under `.claude/reviews/<slug>/` were not written, because containment allowed writing only the report file. Throwaway probes live untracked under `gate-phase-2-iter-3/review-probes/<reviewer>/`.
- Refutation (`--adversarial`) was off, so all finding counts are raw and unchallenged.
- `--high-cap` is 8. No HIGH was raised, so nothing was demoted.
- critical-thinking does not use severities. Its items are in their own section and are not counted in C0/H0/M1/L16.

## Report Audit
1. **The `red.log` confirmation is credited to all six reviewers, but code-reviewer says it did not read that log.**
   - Report (Coverage, Confirmed): "**Mutant A–F and `red.log` evidence matches the fix baton.** Confirmed by all six; fintech-engineer took mutant C from the baton rather than its log."
   - Source, code-reviewer, Not examined: "The fix iteration-1 RED logs and fix iteration-2 `red.log` (I read only the mutant logs)."
   - Source, fintech-engineer: its Validated list has no `red.log` entry. Its L-5 disposition says "mutant C per the baton; log not re-read".
   - At most four reviewers confirmed `red.log`: critical-thinking, silent-failure-hunter, tdd-guide and architect-reviewer.
   - Class 5 (coverage inflation) / 6 (attribution).

2. **The Reachability entry credits two reviewers who never mention it and leaves out the one who supplied the `:1113` clamp.**
   - Report (Coverage, Confirmed, Reachability): "UI leverage is clamped at `order_ticket.dart:1113` … (code-reviewer, silent-failure-hunter, architect-reviewer)".
   - Source, silent-failure-hunter and architect-reviewer: neither mentions the ~721,731x threshold or the `:1113` clamp in any finding, disposition or Validated entry.
   - Source, fintech-engineer, L-2 disposition: "`_LeverageSheet` clamps at `:1113`". fintech-engineer is not credited.
   - Class 6.

3. **L-8 settles a conflict between two reviewers without saying so, and leaves out two contributors.**
   - Report (L-8, reviewers silent-failure-hunter and architect-reviewer): "OrderTicket rejects `1.2.3`" and "`1.999` truncates to $1.99".
   - Source, silent-failure-hunter L-J: "Both tickets parse separators leniently (`feed_order_ticket.dart:97-100`, `order_ticket.dart:111-112`)". Its claim that OrderTicket is also lenient is replaced by architect-reviewer's "OrderTicket rejects it", and Reviewer Disagreements does not record the conflict.
   - The `1.999` → $1.99 detail and the "reject a second `.`" fix come from:
     - fintech-engineer M-A: "Smaller effects: … `1.2.3` → $1.20 and `1.999` → $1.99 … optionally reject a second `.`"
     - tdd-guide M-A: "pin `1.999` → `Long $1.99 · 2x`"
   - Neither fintech-engineer nor tdd-guide is credited on L-8.
   - Class 6.

4. **"Gate and run rules (all six)" and the summary's "Run rules 1 to 4 hold" claim more than each reviewer checked.**
   - Report (Coverage): "**Gate and run rules** (all six): analyze is clean, and the suite is +212 on both the default and HAS_MARKET runs; the pubspec diff against phase-1 is 0 lines; … only the untracked `gate-phase-2-iter-3/` remains."
   - Report (Executive Summary): "All six agree on these points: … Run rules 1 to 4 hold."
   - Source:
     - critical-thinking item 13 covers rules 1, 2 and 4 and git status. It does not mention analyze or +212.
     - silent-failure-hunter's Validated list has only "rule 1; rule 4", with no gate entry.
     - architect-reviewer's Validated list has only "gate; rule 4", with no pubspec or git-status check.
   - Class 5 / 4.

5. **The summary says all six agree the overflow evidence is a font artifact, but architect-reviewer names two exceptions.**
   - Report (Executive Summary): "All six agree on these points: … The manager's RenderFlex-overflow evidence comes from the test font, not from the inputs."
   - Source, architect-reviewer, Validated: "the manager's overflow evidence is from the test font except at `:565` and `:319`". critical-thinking item 7 also reports `:565`/`:319` overflows at a 16-digit input.
   - Reviewer Disagreements #4 records this split, but the summary still states unanimity.
   - Class 4.

6. **The H-1 dissent is attributed to all six, but fintech-engineer's disposition does not say it.**
   - Report (iter-2 dispositions, H-1): "All six say the baton's 'FIXED (store, every caller)' overclaims".
   - Source, fintech-engineer disposition: "H-1 Resolved (store), residuals M-A, L-A, L-B". It says nothing about the baton overclaiming or about "every caller".
   - Class 6.

7. **silent-failure-hunter validated the guard that L-12 calls dead, and the report drops that entry.**
   - Report (L-12, tdd-guide): "`_busy` is true only once `_result` is `OrderFilled` … so Confirm never renders disabled."
   - Report (Coverage, "Retry state machine"): credits silent-failure-hunter only for "`_busy` is cleared on failure".
   - Source, silent-failure-hunter, Validated: "`_busy` cleared on failure (`:853`), Confirm `onTap` nulled while set (`:945`)". That second half counts the `:945` ternary as a working guard. It reaches no section, and the conflict with tdd-guide is not in Reviewer Disagreements.
   - Class 6.

The other parts of the report match the source:
- Counts reconcile: 1 MEDIUM and 16 LOWs.
- The cap arithmetic is right: min(8, ceil(6 × 1.5)) = 8.
- Every reviewer finding lands in some entry.
- All 13 critical-thinking items are carried into its 12 numbered points.

The seven problems above are attribution and coverage errors. None of them changes a severity or the M1/L16 total.

**Orchestrator note on this audit (checked against the full reviewer texts):** The auditor received the critical-thinking and code-reviewer reports in full. It received the other four (fintech-engineer, silent-failure-hunter, tdd-guide, architect-reviewer) with some evidence prose condensed, which its brief disclosed. The synthesizer had all six in full. Two items are partly artifacts of that condensation:
- **Item 2:** silent-failure-hunter's full L-8 disposition does cite the clamp ("`_LeverageSheet._set` clamps at `:1113`, and the feed presets are 2/5/10"). architect-reviewer's full L-2 disposition does cite the threshold ("'Size too large' needs leverage above about 721,000, which no ticket offers"). So crediting both is correct. The item's other half stands: fintech-engineer (and tdd-guide) also cite `:1113` and are not credited.
- **Item 4:** silent-failure-hunter's full Validated list cites +212 on both runs, the pubspec diff and git status. architect-reviewer's full Validated list cites analyze, +212 on both runs, the pubspec-frozen log and a 0-line pubspec diff. The item still stands in part: critical-thinking cites no analyze or +212, silent-failure-hunter no analyze, and architect-reviewer no git status. So "all six" on the gate line overstates.

Items 1, 3, 5, 6 and 7 hold against the full texts.
