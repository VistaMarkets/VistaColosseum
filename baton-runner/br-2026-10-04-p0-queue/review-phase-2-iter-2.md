# Multi-Agent Review: spec set: app_shell.dart + arena_screen.dart + live_feed.dart + orders_state.dart + portfolio_mock.dart + feed_order_ticket.dart + order_ticket.dart + trade_mock.dart + scenario.dart + home_screen_test.dart + order_ticket_test.dart + scenario_test.dart

## Executive Summary
Six reviewers (critical-thinking, code-reviewer, fintech-engineer, silent-failure-hunter, tdd-guide, architect-reviewer) reviewed the 12 phase-2 files of spec 02 at iteration 2, after fix commit b4a7db7. All six confirm that H1 is resolved and that its tests fail when the fix is reverted.

Two HIGH findings remain open:
- **Int64 overflow.** A 1x order with a 13-digit size passes the funds check and credits about $92 quadrillion of paper cash.
- **AC1's Wallet requirement is unmet.** All six read AC1 as plainly requiring a cash figure on the Wallet that is exact to the cent.

There are also 6 MEDIUM and 12 LOW findings. The two leading MEDIUM findings were introduced by the fix itself: the re-quoting Retry can fail "Not enough funds" and still offer Retry, and it fills totals the user never reviewed.

Refutation was off, so every count here is raw and unchallenged. The severity budget demoted nothing (2 HIGH against a cap of 8).

Recommended action: fix the overflow and add an exact Wallet cash line before closing phase 2. Then limit Retry and give every remaining deferral a real owner.

ID convention: this report numbers its findings H-1, M-1, L-1 (with a hyphen). Iteration-1 IDs have no hyphen (H1, M1–M8, L1–L18).

## Critical Findings
None. No reviewer raised a CRITICAL finding.

## High Findings

**H-1. Int64 overflow lets a 1x order pass the funds check and credit cash (iteration-1 M5 is only partly fixed; L14's deferral reason fails)**
- **Location:**
  - Cents getters: `app/lib/scenario/scenario.dart:283-292`. Funds check: `:106`. Debit: `:195`.
  - OrderTicket route: `app/lib/features/trade/order_ticket.dart:188-191` and `:647` (size field with no length cap), with 1x selectable at `:1104`.
  - Feed route: `app/lib/features/trade/feed_order_ticket.dart:96-101, 152-165` (typed amount plus custom 1x).
- **What happens:** On the Dart VM, `(usd*100).round()` stops at int64 max instead of throwing, and int addition wraps around.
  - BTC at 1x with about 1.37e12 units (13 digits) gives notional = margin = 9,223,372,036,854,775,807 and fee = 922,337,203,685,477.
  - `totalCents` wraps to −9,222,449,699,651,090,332. `problem()` returns null, the order fills, and cash becomes 9,222,449,699,652,338,332 cents.
  - The review shows "Paper funds required −$92,224,496,996,510,903.32". The toast says "filled · −$92,224,… from paper cash" while cash rises. This breaks run rules 2 and 3.
  - `maxMarginCents` then overflows too, so later tickets open at garbage sizes until reset.
  - At 2x and above, the same size is correctly refused.
- **Why the checks miss it:** The spec's rule is "margin ≤ cash". The code checks margin + fee, which is exactly the sum that wraps. L14's deferral premise ("needs 18+ digits") is also wrong: the overflow happens in the store, and 13 digits are enough.
- **Evidence:** code-reviewer, fintech-engineer and tdd-guide ran the expressions verbatim on Dart 3.13.4. silent-failure-hunter traced them from SDK source. The widget path (type the size, pick 1x, Confirm) is a static trace only.
- **Suggested fix:**
  - In `Scenario.problem`, refuse `marginCents > cashCents.value` before summing.
  - Also reject notionals the cent arithmetic cannot hold, for example `notionalCents >= 1 << 53`. In my reading (not from a reviewer), the margin check alone assumes a leverage cap that the store lacks (L-2).
  - Add a store test: BTC 1.37e12 units at 1x → `OrderFailed(notEnoughFunds)`, with `state()` unchanged.
- **Raised by:**
  - fintech-engineer: HIGH.
  - code-reviewer, tdd-guide: MEDIUM.
  - silent-failure-hunter: MEDIUM, though "HIGH on the merits"; it rated lower only because it could not execute the case.
  - Rendered HIGH under the higher-severity rule.

**H-2. AC1's Wallet requirement is unmet, and deferring M4 as an open "author question" does not hold**
- **Location:**
  - `app/lib/features/portfolio/portfolio_pager.dart:61-66, 168`: `formatUsd` at 0 decimals, plus `LiveFeed.watch(..., 9)`.
  - `app/lib/features/account/account_top_bar.dart:44-55`: `LiveUsd`, which drifts.
  - `app/test/scenario_test.dart:233-274`: the named AC1 test.
- **What happens:**
  - After the AC1 fill (3,683 cents), cash is $12,443.17. The Wallet shows "$12,443", and in the running app that figure random-walks ±$9 every 3 s.
  - The default feed order ($200 at 2x, 20,020 cents) shows "$12,280" on the Wallet, while the feed ticket says "you have $12,279.80".
  - No Wallet surface shows cash, margin or fee to the cent.
  - The AC1 test asserts only `$366.45 position`, which is notional. It asserts no cash at all.
  - The headline is labelled "My portfolio" / "Portfolio balance" but shows cash only, so every fill now drops "portfolio" by the full margin.
- **Prelude question 4 (all six agree):** AC1 is not ambiguous about precision.
  - "Cash reduced by margin + fee" and "totals on review, receipt and Wallet agree to the cent" require an exact cash figure on the Wallet.
  - The Behavior bullet ("Wallet display these stored cents; nothing recomputes them") confirms it.
  - The named test is a `testWidgets` that already pumps the Wallet, so "it's a store test" does not narrow the AC.
  - Only the placement is the author's call: the headline, or a separate line. The work baton should not mark AC1 DONE.
- **Suggested fix:** Render `formatCents(Scenario.cashCents.value)` on the Wallet with no drift, as the headline or as a separate "Paper cash" line. Extend the AC1 test to find "$12,443.17".
- **Raised by:**
  - fintech-engineer: HIGH.
  - code-reviewer, silent-failure-hunter, tdd-guide, architect-reviewer: MEDIUM.
  - Rendered HIGH.

## Medium and Low Findings

| Severity | Title | Location | Reviewer(s) | One-line description |
|---|---|---|---|---|
| MEDIUM | M-1 Re-quoted Retry can fail "Not enough funds" and still offers Retry (new in b4a7db7) | `order_ticket.dart:122-139, 871-876, 937` | architect-reviewer, code-reviewer, fintech-engineer (MEDIUM); silent-failure-hunter, tdd-guide (LOW) | OrderTicket re-prices fixed units at the live price. AVAX at 10x and 100% (total 1,247,999 vs cash 1,248,000) fails after one up-tick, and Retry then loops. This breaks AC4 in the app, clears the stale flag without filling, and voids the fix baton's "Price expired is the only failure" refutation (computed; LiveFeed is off under test). |
| MEDIUM | M-2 Retry fills a total the user never reviewed | `order_ticket.dart:871-876, 880-886, 964-967` | fintech-engineer (MEDIUM); architect-reviewer, tdd-guide (LOW) | Retry re-quotes and fills in one tap. The repo's own test reviews $3,120.00 and debits $3,267.01 (+4.7%), so review and receipt disagree for a retried fill, and typed TP/SL carry over unchanged to the new entry. |
| MEDIUM | M-3 Fills invent TP/SL (iteration-1 M3); deferring it to spec 03 is unsound | `scenario.dart:189-191`; `position_sheet.dart:42-43, 180-216` | code-reviewer, fintech-engineer, silent-failure-hunter, architect-reviewer (MEDIUM); tdd-guide (LOW) | With exits off, this spec's fill writes +7% / −2.1% levels that the Wallet sheet shows as real. No spec from 03 to 08 mentions TP/SL (grep), and "not a small fix" is a cost argument, not a scope one. |
| MEDIUM | M-4 A "Reduce only" market order opens new exposure | `order_ticket.dart:134, 379-383`; `scenario.dart:151-198` | fintech-engineer, architect-reviewer | The market branch ignores `reduceOnly` and the review hides the flag, so the order fills as a plain open (or an opposite-side position). This is new because phase 2 made market orders fill, and the spec says unbuilt features toast "— not in the demo yet". |
| MEDIUM | M-5 No test pins the fee floor rule (`~/ 10000`, VC-ORD-003) | `scenario.dart:285`; `scenario_test.dart:246` | fintech-engineer, tdd-guide | Every filled fixture has a fee fraction below .5, so a `.round()` mutant passes all 201 tests. Iteration-1 recommendation 8 asked for this fixture, and the fix baton neither added nor deferred it. |
| MEDIUM | M-6 `_busy` guards are unpinned; half of the M8 deferral is unsound | `order_ticket.dart:846-853, 871-876` | tdd-guide (MEDIUM); silent-failure-hunter (LOW) | `_busy` can be observed without a test seam through the repo's haptic capture (`home_screen_test.dart:1595-1610`). Removing `_retry`'s guard passes every test, yet lets a post-fill re-quote make the receipt panel show a different reference price than the fill. |
| LOW | L-1 Rule-2 residual (iteration-1 L3/L4): double dollars still drive sizing | `feed_order_ticket.dart:78-79, 87`; `order_ticket.dart:138-142`; `portfolio_pager.dart:61` | code-reviewer, fintech-engineer, tdd-guide, architect-reviewer | "No drift in 8.4M cases" shows the doubles are harmless, not that the code complies. Fix by sizing in int cents or by recording an explicit user waiver. architect-reviewer adds the "one formatting helper" rule (`_fmtUsd`/`groupDigits`, `formatUsd`). |
| LOW | L-2 The store sets no upper bounds (per-market leverage cap, notional) | `scenario.dart:100-107` | fintech-engineer, architect-reviewer | The store accepts 1000x on ETH; the cap lives only in the tickets. The notional cap is part of the H-1 fix. |
| LOW | L-3 TP/SL inputs are unvalidated and now persisted | `order_ticket.dart:132-133`; `scenario.dart:144-145, 190-191` | fintech-engineer, architect-reviewer | With exits on and an empty TP field, the fill stores TP $0 (the sheet shows "$0 / −100%"). Levels on the wrong side of entry are accepted. |
| LOW | L-4 The feed ticket's `requote` is untested, and its re-quote rule differs from OrderTicket's | `feed_order_ticket.dart:87, 214` | fintech-engineer, architect-reviewer | The feed ticket keeps dollars fixed; OrderTicket keeps units fixed. `() => _review!` passes every test. L11's "same `_ReviewPanel`" reason no longer covers this per-ticket closure. |
| LOW | L-5 OrderTicket's trader-index refusal on Limit/Stop has no widget test | `order_ticket.dart:214`; `order_ticket_test.dart:208-223` | tdd-guide | A mutant that calls `_notBuilt` only for market orders passes. Limit then reaches `_rest`, toasts the same text and leaves the ticket open. |
| LOW | L-6 No per-phone overflow test for the feed review (L11 partly open) | `feed_order_ticket.dart:199-214` | tdd-guide | The feed wraps the panel in a different container (0.92 height, 16+safe padding). The five overflow tests render only OrderTicket's container. |
| LOW | L-7 The `units.isFinite` clause is masked | `scenario.dart:103`; `scenario_test.dart:359-360` | code-reviewer, fintech-engineer, silent-failure-hunter, tdd-guide, architect-reviewer | Infinite units make `_cents` return 0, so the dust branch returns the same 'Enter a size' and deleting the clause passes. The dust message is also misleading (architect suggests "Size too small"). |
| LOW | L-8 `_confirm` has no try/finally | `order_ticket.dart:846-853` | silent-failure-hunter | If `placeOrder` throws, `_busy` stays true and Confirm goes silently dead. No input throws today, but units 04/05 add code on this path. |
| LOW | L-9 Deferrals point at owners that don't exist, and no phase-2 digest records them | fix baton: M1, M6, M7, L2, L8 | code-reviewer, fintech-engineer, architect-reviewer | M1 cites "author or spec 03", and spec 03 has no confirm-arming. Record each item with a real owner in `digest-phase-2`. |
| LOW | L-10 The trader-index branch is duplicated in both tickets, and the copies already differ | `order_ticket.dart:120, 207, 214`; `feed_order_ticket.dart:130-138, 172` | architect-reviewer | OrderTicket skips every check (size 0 still shows a live Place), while the feed ticket runs its amount and limit checks first. Unit 05 would add a third copy. |
| LOW | L-11 `Scenario.tradable` reports any unquoted symbol as a trader index | `scenario.dart:95, 101` | architect-reviewer | Correct for every current entry point, but a typo or a new asset would get the trader toast. |
| LOW | L-12 Doc nit: "Tickets show it on their button" is false for `traderIndexNotBuilt` | `scenario.dart:97-99` | fintech-engineer | Both tickets suppress that reason. |

## Coverage Report
Reviewers: 6/6 returned
Reviewed at: 02c61e6396f8d07e7a7115b4db47e092d27384d4
Any commit after this one is unreviewed.

**Confirmed**
- **H1 is resolved** (all six).
  - `scenario.dart:101` refuses `!tradable` before any other check, for every order kind.
  - Both tickets branch to `_notBuilt` before review or rest (`order_ticket.dart:120, 207, 214`; `feed_order_ticket.dart:130, 136, 172`).
  - The only `placeOrder` callers are `order_ticket.dart:812, 849`, and every asset entry point uses a quoted ticker.
  - The probe log ends "+10: All tests passed!".
- **The H1 tests fail on revert or mutation** (all six).
  - Store test: maya.eth, 1000 units at 0.44, 2x, total 22,022, would fill.
  - Home-card feed test: Market would open review; Limit would toast but leave the ticket open.
  - OrderTicket trader test: the `_live <= 0` mutant hides "Place market long".
- **`tradable` equals today's asset set:** `TradeMock.quotes` keys match the `MarketsMock.assets` ids (BTC, ETH, SOL, ARB, AVAX), and Arena and Opinions use BTC (code-reviewer, silent-failure-hunter, tdd-guide, architect-reviewer).
- **The M2 re-quote is fixed** (all six).
  - `_retry` refreshes the price, then calls `widget.requote()`.
  - The panel renders `_intent` (`order_ticket.dart:880, 964`), and the actionId is reused.
  - The test fails on revert (38.2 ≠ 40).
- **M5 is fixed at the low end:** leverage is checked before the cents getters (`scenario.dart:102`). 4-cent dust, leverage 0 and ∞ price each fail their test without their guard (code-reviewer, fintech-engineer, silent-failure-hunter, tdd-guide, architect-reviewer).
- **The L1 refutation is sound:** the pin test passes, and `NavigatorState._cancelActivePointers` absorbs the second tap (all six; tdd-guide cites `navigator.dart:5161, 5908-5920`).
- **L7 is fixed** at `arena_screen.dart:83-84` (all six).
- **There is one write path:** the only writers of cash, positions, receipts, openOrders and stalePrices are in `scenario.dart`, plus `OrdersState.remove/insert` (fintech-engineer, tdd-guide, architect-reviewer).
- **The new store fields are wired in:** `receipts` and `stalePrices` each have an initializer, a `reset()` line, and entries in `state()` and `mutateEverything()` (code-reviewer, fintech-engineer, architect-reviewer).
- **Cent arithmetic is right on normal flows** (code-reviewer, fintech-engineer, architect-reviewer).
  - AC1 gives 36645 / 3665 / 18 / 3683. The feed default gives 20020, BTC at 25% gives 312000, and feed Max at 2x gives 1,246,753 = "$12,467.53".
  - `formatCents` uses integers only (`live_feed.dart:68-76`).
  - The toast amount equals the debit.
- **Dart VM `round()` stops at int64 max:** `1e20.round()` = 9223372036854775807 on 3.13.4. code-reviewer, fintech-engineer and tdd-guide executed it; silent-failure-hunter traced it in the SDK source; critical-thinking replayed it.
- **`_busy` behaves as designed:** it is set before `placeOrder`, cleared on failure and kept after a fill. The duplicate guard runs before validation and does not remember failures (code-reviewer, fintech-engineer).
- **Flutter idioms hold** (code-reviewer, tdd-guide):
  - `mounted` is checked after both `showModalBottomSheet` awaits.
  - `_confirm` and `_retry` are synchronous.
  - The SnackBar captures `nav` before pop.
  - `_notBuilt` can safely use `context` after `pop()`.
- **The feed cancel test is real:** `before` is taken before pumping (silent-failure-hunter, tdd-guide, architect-reviewer).
- **Run rules 1 and 4 hold:** the pubspec diff is 0 lines, and there is no persona, phase-advance or DEM-004 code (all six). The fix commit adds no new double money (silent-failure-hunter).
- **Tests pass:**
  - `order_ticket_test` + `scenario_test`: 27/27 (all six).
  - `flutter analyze` is clean (code-reviewer).
  - The full suite with `HAS_MARKET=true` gives +201 (architect-reviewer).
- **Later specs don't cover the deferred items:** a grep of specs 03–08 finds no TP/SL, confirm-arming or Wallet-cash work (all six).
- **Wallet cash is whole dollars, and the AC1 test asserts no cash** (fintech-engineer, tdd-guide).

**Iteration-1 dispositions (prelude question 1)**

| Item | Verdict | Dissent |
|---|---|---|
| H1 | Resolved | none |
| M1 | Deferring as an author call is acceptable; "spec 03" is the wrong owner (L-9) | tdd-guide, silent-failure-hunter: sound as is |
| M2 | Re-quote fixed; the "Retry for every reason" refutation is now false (M-1) | none |
| M3 | Standing (M-3) | tdd-guide: reason fine, owner wrong |
| M4 | Standing (H-2) | none on substance |
| M5 | Partly fixed; overflow still open (H-1) | architect-reviewer: fixed |
| M6, M7 | Sound deferrals once recorded in the digest | critical-thinking: no landing place |
| M8 | The actionId-at-open half is sound; the `_busy` half is unsound (M-6) | code-reviewer, fintech-engineer, silent-failure-hunter: the whole deferral is sound |
| L1 | Refutation sound | none |
| L2, L8 | Sound once recorded in the digest | — |
| L3 | Standing against rule 2 (L-1) | silent-failure-hunter: sound |
| L4 | Sound; its Wallet-cash part is H-2 | architect-reviewer: the "one helper" part is still standing (L-1) |
| L5, L6, L9, L10, L12, L13, L15, L16, L18 | Sound | — |
| L7 | Fixed | none |
| L11 | Partly fixed: the feed cancel test was added; feed requote and feed layout are still untested (L-4, L-6) | code-reviewer, silent-failure-hunter: acceptable |
| L14 | Unsound for the store overflow (H-1) | silent-failure-hunter: holds for its own field |
| L17 | Accepted on the baton's RED evidence (logs not re-read) | — |

**Examined, inconclusive**
- **H-1 through the widgets** (13-digit BTC size, 1x, Confirm). Blocker: no test file could be written. `flutter test /dev/stdin` reported "No tests ran", and `flutter test <(…)` failed to compile. tdd-guide notes that long review rows may raise a RenderFlex overflow in debug, which would not disable Confirm.
- **M-1 in the running app** (AVAX at 100%, an up-tick, then Retry). LiveFeed is off under FLUTTER_TEST, so this is computed only.
- **M1 double tap across a frame.** Needs a device, or a tap → `pump()` → tap test.
- **The Home trader-card test's Limit iteration (code-reviewer).** The Market iteration's SnackBar may still be visible, so the toast assert alone may not discriminate. Its `findsNothing` and `state()` asserts still catch realistic mutants.
- **The `.round()` fee mutant and the `_busy`-removal mutants (tdd-guide).** Their survival is reasoned from the assertions, not run.

**Not examined (residual risk)**
- How a position renders after an overflow fill or with TP $0 (Wallet list, position sheet, chart scale). Four reviewers named it and none covered it.
- The feed review layout on the five phones. No test exists, and no reviewer ran it.
- The fix baton's RED logs. They were accepted on the baton's word and nobody re-read them.
- The phase-1 LiveFeed rebase carry-over in `live_feed.dart`.
- Other areas no reviewer read beyond their call sites or diff hunks:
  - `home_screen_test.dart` outside the phase-2 hunks and the ticket groups.
  - `caller_play_screen` and `opinions_screen` beyond their call-site lines.
  - Open-orders rendering of stop orders (an unchanged path).
- Specs 04–08 beyond grep, so the "unit 04 owns it" claims (L8) rest on grep alone.

**Engagement check:** all five severity-using reviewers have substantive Confirmed lists, so none is tagged [DID NOT ENGAGE]. critical-thinking is exempt, and it also supplied a dispositions table.

## Unstated Assumptions and Open Questions (from critical-thinking)
critical-thinking assigns no severities. Each item notes where the rest of the panel landed.

1. **The store's input checks stop at "finite and at least 1 cent".** At 1x an oversized order overflows and credits cash, and there is no per-market leverage cap. *Question:* what magnitude limits does the store own? (→ H-1, L-2)
2. **The premise of M2's sub-refutation is gone.** Re-quoting makes "Not enough funds" reachable on Retry. *Question:* should Retry be offered after a failure it cannot fix? (→ M-1)
3. **One panel follows two price policies.** Confirm honours the reviewed price however old it is. Retry discards it and fills in the same tap, and the baton gives no reason for preferring AC4's letter over showing the re-quoted cost. *Question:* why is review required before the first confirm but not before the re-quoted one? (→ M-2)
4. **The two tickets re-quote differently** (fixed units vs fixed dollars), and only OrderTicket's version is tested. *Question:* was this divergence chosen? (→ L-4)
5. **M3's "spec 03" owner does not exist.** *Question:* which unit owns the invented exits, or is the author accepting them as truthful? (→ M-3)
6. **AC1 is not ambiguous about the cent;** only the placement is open. *Question:* will AC1 be reopened until the author picks the surface? (→ H-2)
7. **The tests have realness gaps.**
   - The fill toast's dollar amount is never asserted: `order_ticket_test.dart:117` checks only "Bitcoin long filled". Toasting the margin instead of the total would pass, and that amount is rule 3's core claim. No other reviewer raised this.
   - The fee rounding mode is unpinned (M-5).
   - The units-finiteness check is masked (L-7).
   - The actionId reuse on re-quote is unpinned, because `_busy` absorbs the second Retry.
   - *Question:* why were the toast-amount and fee-fixture asks dropped along with M8?
8. **Who waived rule 2?** The OrderIntent doc claims to be "the only conversion from double" (`scenario.dart:233`), and that is false. (→ L-1)
9. **Author questions were dropped between iterations.** The fix baton carries only M4 and M1/M3 from iteration 1's nine author questions. These are missing:
   - The duplicate guard ignores failures.
   - Limit/stop orders are now gated by margin + fee and the dust check, although the spec says "unchanged path".
   - The feed trader ticket shows a live "Long $200 · 2x" button that can never place.
   - Whether the stored cents should drive the Wallet.

   L2 and L8 say "record in the digest", and no phase-2 digest exists. (→ L-9)
10. **"Outside a fix unit" is a drop unless it lands somewhere.** M1, M6 and M7 have no owner, and units 04–06 build on the position's clashId and the receipts list. (→ L-9)
11. **`tradable` means "has a quote".** Unit 05 opens tickets prefilled from suggestions. *Question:* is `TradeMock.quotes` the authoritative asset list? (→ L-11)

## Reviewer Disagreements
1. **Does the funds check catch the overflow?**
   - architect-reviewer (examined, inconclusive) traced that it "catches it either way" and did not verify VM saturation.
   - code-reviewer, fintech-engineer and tdd-guide executed the case on Dart 3.13.4 and saw `problem()` return null.
   - Resolution: the executed result stands. The architect's trace missed the margin + fee wrap.
2. **H-1 severity.**
   - fintech-engineer rated it HIGH.
   - code-reviewer and tdd-guide rated it MEDIUM (absurd input, paper money).
   - silent-failure-hunter rated it MEDIUM only because it could not execute the case.
   - Resolution: HIGH. The arithmetic was executed, and it breaks rules 2 and 3 plus the invariant the M5 fix claimed.
3. **H-2 severity.** fintech-engineer rated it HIGH and four others MEDIUM, with all six agreeing on substance. Resolution: HIGH, because an AC marked DONE is unmet.
4. **M-1 severity.**
   - silent-failure-hunter and tdd-guide rated it LOW: the messages stay truthful and no money moves.
   - architect-reviewer, code-reviewer and fintech-engineer rated it MEDIUM: AC4's "Retry succeeds once" fails in the app.
   - Resolution: MEDIUM.
5. **M-2 severity.**
   - silent-failure-hunter accepted the one-tap Retry as a documented design choice.
   - fintech-engineer rated it MEDIUM; architect-reviewer and tdd-guide rated it LOW.
   - critical-thinking asks why review applies only to the first confirm.
   - Resolution: MEDIUM, with the choice put to the author.
6. **M3.** tdd-guide called it LOW (the reason is fine, the owner is wrong). Four others called it MEDIUM and in this spec's scope. Resolution: MEDIUM, because this spec's fill path writes the values.
7. **M8.**
   - tdd-guide says `_busy` can be observed via the haptic capture.
   - code-reviewer, fintech-engineer and silent-failure-hunter accept the whole "no seam" deferral.
   - Resolution: each side is right about a different half. The actionId-at-open half stays deferred, and `_busy` gets the haptic test.
8. **M1.**
   - tdd-guide and silent-failure-hunter judge the deferral sound.
   - code-reviewer, fintech-engineer, architect-reviewer and critical-thinking accept the author-call deferral, but say "spec 03" is no owner.
   - Resolution: keep the deferral and name a real owner.
9. **M6/M7.**
   - code-reviewer, fintech-engineer, silent-failure-hunter and tdd-guide judge them sound.
   - architect-reviewer judges them sound only if recorded.
   - critical-thinking judges them unsound.
   - Resolution: sound once written into `digest-phase-2` with an owner.
10. **L3 (rule 2).** silent-failure-hunter judges the deferral sound; five others say it is still standing. Resolution: standing until the user waives it, because a fix unit cannot waive a user rule.
11. **L11.**
    - code-reviewer and silent-failure-hunter find it acceptable.
    - fintech-engineer, architect-reviewer, critical-thinking and tdd-guide say the requote closure is per ticket since b4a7db7, and the feed layout differs.
    - Resolution: add the feed tests (L-4, L-6).
12. **L14.**
    - silent-failure-hunter says it holds for its own field.
    - fintech-engineer and critical-thinking say it is unsound.
    - tdd-guide says it understates the store overflow.
    - Resolution: close it through the H-1 store fix.
13. **M5.** architect-reviewer judges it fixed; five others judge it partly fixed. Resolution: partly fixed (see disagreement 1).

## Recommended Changes (Prioritized)
1. In `Scenario.problem`, refuse `marginCents > cashCents.value` before summing and reject notionals the cent math cannot hold (e.g. `notionalCents >= 1 << 53`), with a store test for BTC 1.37e12 units at 1x expecting `notEnoughFunds` and an unchanged `state()`.
2. Show paper cash on the Wallet via `formatCents(Scenario.cashCents.value)` with no drift, extend the AC1 test to find "$12,443.17", and mark AC1 open in the baton until both land.
3. Offer Retry only for 'Price expired', and when the re-quoted cents differ from the reviewed intent, return to "Review order" with the new figures instead of filling; add an AVAX 100%-size up-tick test.
4. Refuse market + `reduceOnly` in `Scenario.problem` with a "— not in the demo yet" reason (or hide the checkbox for Market), and add a store test.
5. Make `PositionDetail.takeProfit/stopLoss` nullable and hide the rows and chart lines when unset, or record M3 in the phase-2 digest with a named owner.
6. Add a fee fixture with a fraction of .5 or more (e.g. notional 39,999 cents → fee 19) and assert the fill toast's dollar amount, so both the `.round()` and the margin-instead-of-total mutants fail.
7. Pin `_busy` with a haptic-capture double-tap test, and have the receipt panel read units and price from the fill.
8. Add a feed-ticket stale-AVAX Retry test that pins the feed `requote` (receipt price, margin unchanged, actionId reused).
9. Loop the OrderTicket trader-index widget test over Market, Limit and Stop, asserting that the ticket closes.
10. Add per-phone overflow tests for the feed review container.
11. Move the per-market leverage cap and TP/SL validation (finite, > 0, correct side) into `Scenario.problem`.
12. Either size the feed ticket and `_maxNotional` in int cents or record the user's explicit rule-2 waiver.
13. Drop the masked `units.isFinite` clause (or give it a distinct reason), and consider "Size too small" for the dust case.
14. Reset `_busy` when `placeOrder` throws in `_confirm`.
15. Write `digest-phase-2` listing M1, M3 (if unfixed), M6, M7, L2, L8 and the dropped iteration-1 author questions, each with an owner.
16. Fix the `scenario.dart:97-99` doc comment, and consider routing both tickets' trader-index branch through `Scenario.problem`.

## Open Questions for the Author
1. **AC1 placement.** Which Wallet surface carries the exact cash figure: the designed headline or a separate line? Should the cash-only headline keep its "My portfolio" label and its ±$9 drift?
2. **Retry.**
   - Should a re-quote that changes the total go back to review, or is the one-tap fill (AC4's letter) intended?
   - Should OrderTicket re-quote at fixed units, or at fixed dollars like the feed ticket?
3. **Invented TP/SL.** Fix it in this spec, or accept it and name an owner?
4. **Rule 2.** Does the user waive double-dollar sizing in `_maxNotional` and the feed ticket?
5. **Store limits.** Which magnitude limits does the store own (notional, per-market leverage), given that its doc says no caller can place a bad size?
6. **Asset list.** Is `TradeMock.quotes` the authoritative asset list, or should the trader-index check use trader-market identity?
7. **Iteration-1 questions the fix baton dropped:**
   - The duplicate guard ignores failures, although the spec says "no-op returning the first result".
   - Limit/stop orders are now gated by margin + fee and the dust check, although the spec says "unchanged path".
   - The feed trader ticket shows a live "Long $200 · 2x" button that can never place.
8. **M1.** Must the review be impossible to skip with a fast double tap?

## Notes
- The roster came from context-aware selection, not from the fallback roster used in the phase-1 and phase-2 iteration-1 reviews. The lanes were:
  - L-ADVERSARIAL → critical-thinking
  - L-BASELINE → code-reviewer
  - L-FINANCE → fintech-engineer
  - L-RESILIENCE → silent-failure-hunter
  - L-TEST → tdd-guide
  - L-ARCH → architect-reviewer
- L-LANG:dart and L-NUMERIC had no agent in the pool and fell back to the baseline lane. code-reviewer was told to own Dart/Flutter idiom, and fintech-engineer to own int-cent arithmetic.
- No risk flag fired (the money is simulated, there are no keys and no external I/O), so no security lane (security-reviewer, penetration-tester) was selected.
- All six rostered agents and the synthesizer are parked and were not registered in this session. Each ran by the paste method as a general-purpose subagent, with an explicit read-only prohibition, on the orchestrator's model rather than its frontmatter model.
- The per-reviewer recovery checkpoints under `.claude/reviews/<slug>/` were not written, because the caller's containment allowed writing only the report file.
- Refutation (`--adversarial`) was off, so all finding counts are raw and unchallenged.
- No reviewer could write files, so no widget test was added.
  - The overflow arithmetic was run on the Dart VM through stdin or ad-hoc scripts that wrote nothing.
  - The widget-level paths (a 13-digit size at 1x through Confirm; an AVAX max-size Retry after an up-tick) are static traces with computed values.
  - Tool failures: code-reviewer's `flutter test /dev/stdin` reported "No tests ran", and silent-failure-hunter's `flutter test <(…)` failed to compile.
- critical-thinking returned no severities, as its lane is exempt. The run notes say it returned no `### Validated` section, but its report as received does carry a `### Validated` table of iteration-1 dispositions and the commands it ran. That table is aggregated above.

## Report Audit

1. **M-2's reviewer list leaves out code-reviewer (class 6).**
   - Report, M-2 table row: "fintech-engineer (MEDIUM); architect-reviewer, tdd-guide (LOW)". Disagreement 5 also leaves code-reviewer out.
   - Source, code-reviewer M-B (MEDIUM): "A smaller related point: within funds, Retry still fills at a total the user never reviewed."

2. **The M8 dissent leaves out critical-thinking (class 6).**
   - Report, dispositions table, M8 row: "The actionId-at-open half is sound; the `_busy` half is unsound (M-6) | code-reviewer, fintech-engineer, silent-failure-hunter: the whole deferral is sound". Disagreement 7 names the same three.
   - Source, critical-thinking's Validated table: "M8 | actionId/`_busy` part soundly deferred for today's synchronous path". So critical-thinking also holds the `_busy` half sound, but it is not listed as a dissenter.

3. **critical-thinking is credited with accepting the M1 deferral (class 6).**
   - Report, Disagreement 8: "code-reviewer, fintech-engineer, architect-reviewer and critical-thinking accept the author-call deferral, but say 'spec 03' is no owner."
   - Source, critical-thinking's Validated table: "M1, M3, M6, M7, L3, L11, L14 | Deferrals unsound or incomplete". Item 10 asks "is 'outside a fix unit' a plan, or a drop?" critical-thinking never says it accepts the author-call part.

4. **The L14 dissent leaves out code-reviewer (class 6).**
   - Report, dispositions table, L14 row: "Unsound for the store overflow (H-1) | silent-failure-hunter: holds for its own field". Disagreement 12 lists silent-failure-hunter, fintech-engineer, critical-thinking and tdd-guide only.
   - Source, code-reviewer: "Deferrals I judge sound (not re-raised): … L2, L4–L6, L8–L10, L12–L18". That range includes L14. Its M-A adds that L14's reason "does not cover this, because the overflow is in the store". This is the same split position the report gives silent-failure-hunter.

5. **The "later specs" Confirmed entry is tagged "all six", which overstates who checked it (class 5/6).**
   - Report, Confirmed: "Later specs don't cover the deferred items: a grep of specs 03–08 finds no TP/SL, confirm-arming or Wallet-cash work (all six)."
   - Source:
     - architect-reviewer mentions spec 03 only ("Spec 03 only adds the simulation pill…"; "Spec 03 does not own it"). It never mentions grepping specs 04–08.
     - Only tdd-guide reports "no take-profit, stop-loss or Wallet-cash work".
     - Confirm-arming is checked only against spec 03 (critical-thinking: "spec 03 has no confirm-arming"; code-reviewer: "spec 03 has no such item").

6. **The MEDIUM rationale for H-1 is credited to tdd-guide, which gave none (class 6).**
   - Report, Disagreement 2: "code-reviewer and tdd-guide rated it MEDIUM (absurd input, paper money)."
   - Source: only code-reviewer gives that reason: "MEDIUM because the input is absurd and the money is paper." tdd-guide's MEDIUM 1 states no reason for its severity.
