# dw-review — `feat/br-2026-10-04-p0-queue/phase-6` (fee ledger and call receipts, spec 06)

- **Target:** `feat/br-2026-10-04-p0-queue/phase-6`, phase 6 of baton-runner run `br-2026-10-04-p0-queue`: the fee ledger and call receipts (`docs/specs/06-fee-ledger-and-receipts.md`; PRD VC-MKT-004, VC-REC-001, VC-LST-002, VC-FED-003). It replaces the constant `$42.80` with seeded `FeeEntry` credits in `Scenario`, adds a Ledger screen with the "40% share is a demo assumption" label and one worked example, and replaces `RecordEntry` with `CallReceipt`. It also adds a receipts list with call receipts and the user's paper order receipts in separate sections, plus a call receipt screen. It wires the three "All receipts" links and the two "Call details" row taps. The branch is stacked on `feat/br-2026-10-04-p0-queue/phase-5` (`9bf4364d88afe69e18c52fcb636501cf4bcb4b9a`), which is draft [VistaColosseum#16](https://github.com/VistaMarkets/VistaColosseum/pull/16), itself on `feat/br-2026-10-04-p0-queue/phase-4`, draft [VistaColosseum#15](https://github.com/VistaMarkets/VistaColosseum/pull/15). Phases 1-3 are on main as [VistaColosseum#10](https://github.com/VistaMarkets/VistaColosseum/pull/10), [VistaColosseum#12](https://github.com/VistaMarkets/VistaColosseum/pull/12) and [VistaColosseum#13](https://github.com/VistaMarkets/VistaColosseum/pull/13). Diff reviewed: `feat/br-2026-10-04-p0-queue/phase-5...feat/br-2026-10-04-p0-queue/phase-6` (56 files; 12 under `app/`, 10 in `lib`, 2 in `test`). The fix commit adds a 13th, `app/lib/features/account/account_state.dart`.
- **Commit reviewed:** the review ran at `5fd70c1fb51518a21896593040cfd3176bcfcf53`. The fixes landed at `30e54c051ba7020df49504e3dd504bbf06c2217f`.
- **Date:** 2026-10-04 (the run date). The review, the fixes, the close gate and this record were done on 2026-10-05 UTC (run log 2026-10-05T04:28:52Z to 05:03:41Z). Skill `dw-review`, run by `baton-runner-managed`. Workflow runs `wf_2a2b3c86-2fb` (review) and `wf_f71ac46f-eb4` (finding-fixer).
- **Lanes:** money-rounding 1, tautology-hunt 9, receipts-truthfulness 3 (raw 13), plus the fixed skeptic. Merges: 0 (12 confirmed + 1 refuted = 13 raw). Confirmed: 12 (2 MEDIUM, 10 LOW; the skeptic demoted F3 from MEDIUM to LOW). Refuted: 1. Checked claims that were wrong: 0. None is marked before-merge.
- **Disposition:** 12 of 12 dispositioned: 12 applied, 0 annotated, 0 skipped, 0 unreported (fixer coverage: failedGroups [], unreported []). Every adjudicator verdict was fix-here. F3, F4 and F5 change product code (`receipt_screens.dart`, `scenario.dart`, `account_state.dart`, `market_mock.dart`), each behind a test that ran red first. F1, F2 and F6-F12 are test-strength fixes in `receipts_test.dart`. Each is mutation-proven: the named mutant survived the old test and the new test kills it.
  - Manager's decisions (run log 2026-10-05T04:37:03Z), verbatim: "F3 fix = copy says "No open call in fixture-v1 backs this holding" (match the documented open-only lookup; no fallback to settled calls). F4 fix = Scenario records the listing instant at listMarket and marketFees counts credits at or after it; the HAS_MARKET seed's listing instant is the fixture start so the seeded credits still show there. F5 fix = the worked example prints the listed credit (formatCents of amountCents) as its result and derives the fee from it, never the reverse. F1, F2, F6-F12 are test-strength: mutation-proven or not done."
  - F4 as built: `YourMarketMock.listedAt` is `TradeMock.chartEnd` minus 7 days (`market_mock.dart:124`). That is a week before the fixture's now, so every seeded credit (chartEnd minus 3 h to 4 days) still counts under `HAS_MARKET=true`. A fresh listing records `Scenario.clock` and shows `$0.00` until a credit dated at or after it lands.
  - CF-1, carried to phase 7 (ruling in `baton-pass/br-2026-10-04-p0-queue/2026-10-05T041752-phase6-review-iter1.md`): the Profile CALLS list and the trader-market Record panel are one generic sample shown under every handle. Phase 6 does not make them receipt-backed, though their "All receipts" links are wired. Phase 7's first job is to rebuild both from per-trader `Scenario.callReceipts`, render each call with `CallRecordItem` so every item opens its receipt, retire the sample call items in `TraderMarketMock.record` / `ProfileMock.receipts`, and add an item-tap assertion for a non-user trader. Spec 07's acceptance names no item-tap test, so this obligation lives only in the carry-forward.

## Verdict: APPROVE

"Scope checked. Both refs resolve: phase-6 is 5fd70c1, the same as worktree HEAD, and phase-5 is 9bf4364. The three-dot diff lists 56 files, 12 of them under app/ (10 in lib, 2 in test). The commits in range are 5fd70c1, ef02185, 63c6002 (the feature) and 09ae74d. Of the 13 findings, 12 survive and 1 is refuted. None is CRITICAL or HIGH, and nothing freezes at merge, so everything can be fixed after merge. The production code does what the spec asks: fee totals are computed in int cents from the listed entries, the 40% label appears in both places, unavailable fields render, paper orders and calls stay separate, and all 5 call sites are wired. The survivors are mostly test gaps. Three of them are backed by recorded surviving mutants (ledger-footer-no-safe, profile-wrong-handle, ledger-entry-no-market in mutate-run-1.txt). There are also two copy and data truthfulness issues (the maya.eth SOL Call details header, and credits dated before listing) and one latent rounding issue in the worked example. Before-merge: none. After merge: in priority order, the pill-clearance test, the order-leak test, then the rest."

## Confirmed findings

### F1 MEDIUM — Pill-clearance test passes with the ledger footer's safe-area padding deleted, and never runs at 375x667

**Location:** app/test/receipts_test.dart:193-206 (impl app/lib/features/market/receipt_screens.dart:132) at 5fd70c1. Now `app/test/receipts_test.dart:257-271` (loops 360x640 and 375x667; `bottom <= pillTop` for the total and `Total`); footer padding unchanged at `app/lib/features/market/receipt_screens.dart:133` at 30e54c0. Raised by tautology-hunt.

Mutate the footer padding at :132 to `VistaSpace.xxl`. VistaSpace.xxl is 14, below SimulationIndicator.slot (30), so the total drops into the reserved strip; the mutant is not equivalent. expectPillClear (home_screen_test.dart:57-66) checks only rect overlap. The pill is centred and the total is right-aligned at the gutter, so the two never overlap and the test passes. mutate-run-1.txt line 3 records ledger-footer-no-safe as SURVIVED. The test pumps only Size(360,640); 375x667 is never exercised.

**Applied:** The import now also shows pill. The ledger pill test loops over 360x640 and 375x667, and asserts that the total and the 'Total' label both have bottom <= the pill's top, on top of expectPillClear.

**Test:** `app/test/receipts_test.dart: the ledger total stays above the simulation pill on a small phone at 1.3x text`.

Red output, verbatim from the writer:

```text
Mutation: `MediaQuery.paddingOf(context).bottom + VistaSpace.xxl,` -> `VistaSpace.xxl,` in the ledger footer.
Old test under the mutant: SURVIVED
00:00 +1: (tearDownAll)
00:00 +1: All tests passed!
New test under the same mutant: KILLED
The following TestFailure was thrown running a test:
Expected: a value less than or equal to <610.0>
  Actual: <626.0>
   Which: is not a value less than or equal to <610.0>
...
  file:///home/alex/VistaColosseum/.worktrees/br-2026-10-04-p0-queue/app/test/receipts_test.dart line 255
00:00 +0 -1: the ledger total stays above the simulation pill on a small phone at 1.3x text [E]
00:00 +0 -1: Some tests failed.
Mutation reverted; the test then passed.
```

### F2 MEDIUM — "Never the user's orders" on another trader's receipts list is checked with no order in state

**Location:** app/test/receipts_test.dart:289-310 (code receipt_screens.dart:213-254) at 5fd70c1. Now `app/test/receipts_test.dart:443` (paper order placed before the kaito.eth lists), assertions `:453-454` and `:471-472`; product unchanged (`receipt_screens.dart:214`, paper section under `if (own)`) at 30e54c0. Raised by tautology-hunt.

setUp calls Scenario.reset, which sets receipts.value = const [] (scenario.dart:289). The kaito.eth test places no order. If the `for (final r in Scenario.receipts.value)` loop is moved after the `if (own) ...[ ]` block, kaito's list would render the user's paper fills. Nothing renders while state is empty, so the test passes. The 'separate sections' test only opens the user's own list, where the moved rows still sit below the PAPER ORDER RECEIPTS header, so it passes too.

**Applied:** Added the onList helper. 'every All receipts link opens the receipts list' now places a paper order before opening kaito.eth's lists. On both the profile list and the trader-market list it asserts that neither 'Long ETH 10x' nor 'Paper fill' renders.

**Test:** `app/test/receipts_test.dart: every All receipts link opens the receipts list`.

Red output, verbatim from the writer:

```text
Mutation: moved the order rows out of the `if (own) ...[` spread in ReceiptsScreen, as the adjudicator specified.
Old test under the mutant: SURVIVED
00:01 +1: (tearDownAll)
00:01 +1: All tests passed!
New test under the same mutant: KILLED
Expected: no matching candidates
  Actual: _DescendantWidgetFinder:<Found 1 widget with text "Long ETH 10x" descending from widget
with type "ReceiptsScreen": [ ... ]>
   Which: means one was found but none were expected
...
  file:///home/alex/VistaColosseum/.worktrees/br-2026-10-04-p0-queue/app/test/receipts_test.dart line 398
00:01 +0 -1: Some tests failed.
Mutation reverted; the test then passed.
```

### F3 LOW — Call details for maya.eth's SOL long says 'No call in fixture-v1 backs this holding' although fixture-v1 has her SOL long call (settled Right)

**Location:** app/lib/features/market/receipt_screens.dart:272-284, 310-313 at 5fd70c1. Now `app/lib/features/market/receipt_screens.dart:313` (header copy); `app/test/receipts_test.dart:85` (`noCall`), maya.eth SOL block `:328-334` at 30e54c0. Raised by receipts-truthfulness.

Home -> maya.eth idea (mock_trade_idea.dart:254) -> ProfileScreen('maya.eth'), which is public -> HOLDING NOW -> SOL (Long 5x). forHolding requires result == open. maya-sol-300-fri is CallOutcome.right, so the lookup falls through to the id 'none' receipt with the noCall header. The same profile's All receipts list shows 'SOL reaches $300 by Fri - Right'. receipts_test never taps SOL on maya's profile.

Skeptic's note, verbatim: "Demoted from MEDIUM: the fixture never links holdings to calls, and the open-only rule is documented on forHolding, so this is imprecise copy, not a wrong lookup."

**Applied:** Header copy now reads 'No open call in ${Scenario.fixtureVersion} backs this holding' (F3.1). Test constant noCall updated (F3.2). New maya SOL block in 'each record item opens its call receipt' (F3.3) checks that her settled SOL call does not back the SOL holding, so the noCall header shows and sol.rule is absent. Also app/test/receipts_test.dart.

**Test:** `app/test/receipts_test.dart: each record item opens its call receipt`.

Red output, verbatim from the writer:

```text
Test edits applied first, run against the old lib (flutter test test/receipts_test.dart --plain-name 'each record item opens its call receipt'):
══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞════════════════════════════════════════════════════
The following TestFailure was thrown running a test:
Expected: exactly one matching candidate
  Actual: _DescendantWidgetFinder:<Found 0 widgets with text "No open call in fixture-v1 backs this
holding" descending from widgets with type "CallReceiptScreen": []>
   Which: means none were found but one was expected
...
This was caught by the test expectation on the following line:
  file:///home/alex/VistaColosseum/.worktrees/br-2026-10-04-p0-queue/app/test/receipts_test.dart line 239
00:01 +0 -1: each record item opens its call receipt [E]
00:01 +0 -1: Some tests failed.
```

### F4 LOW — Listing MAYA fresh shows $42.80 earned, made of five credits dated before the market existed

**Location:** app/lib/scenario/scenario.dart:111-118 with market_mock.dart:124-139 at 5fd70c1. Now `app/lib/features/account/account_state.dart:19` (records the listing instant); `app/lib/scenario/scenario.dart:41`, `:95-96`, `:118-125`, `:293`; `app/lib/features/market/market_mock.dart:124` (`YourMarketMock.listedAt`); `app/test/scenario_test.dart:34`; test `app/test/receipts_test.dart:185` at 30e54c0. Raised by receipts-truthfulness.

Start without HAS_MARKET, list with the suggested ticker MAYA. AccountState.listMarket sets marketId to 'MAYA', and marketFees then matches all five seeded MAYA credits, dated 22-26 Sep 11:45. Scenario.clock is 26 Sep 14:45, so every credit predates the listing. The Wallet row and the Your market chip show $42.80 with no 'illustrative' cue.

**Applied:** Added Scenario.listedAt (ValueNotifier<DateTime?>), seeded from _seedListedAt and restored in reset() (F4.1, F4.2, F4.4). marketFees now returns no entries while listedAt is null and counts only credits with !e.at.isBefore(listedAt) (F4.3). AccountState.listMarket records Scenario.clock.value before it sets marketId (F4.5, account_state.dart). New fixture constant YourMarketMock.listedAt = chartEnd - 7 days (F4.6, market_mock.dart). scenario_test state() now includes listedAt (F4.7). Added the account_state import and the fresh-listing test to receipts_test.dart (F4.8, F4.9). Grep found no other writers of marketId or hasMarket in lib besides listMarket. Test-only writers: receipts_test ZED test and scenario_test mutateEverything; both still pass. Also passes with --dart-define=HAS_MARKET=true on receipts_test and scenario_test (+32).

**Test:** `app/test/receipts_test.dart: a fresh listing earns nothing until a credit lands after it; the HAS_MARKET seed counts its week; reset restores both`.

Red output, verbatim from the writer:

```text
New test run against the old lib (before F4.1-F4.7):
00:00 +0: a fresh listing earns nothing until a credit lands after it; the HAS_MARKET seed counts its week; reset restores both
00:00 +0 -1: a fresh listing earns nothing until a credit lands after it; the HAS_MARKET seed counts its week; reset restores both [E]
  Expected: empty
    Actual: [
              Instance of 'FeeEntry',
              Instance of 'FeeEntry',
              Instance of 'FeeEntry',
              Instance of 'FeeEntry',
              Instance of 'FeeEntry'
            ]
  
  package:matcher                                     expect
  package:flutter_test/src/widget_tester.dart 473:18  expect
  test/receipts_test.dart 181:5                       main.<fn>
00:00 +0 -1: Some tests failed.
```

### F5 LOW — Ledger worked example recomputes the credit from a backed-out fee; off by one cent for odd-cent credits

**Location:** app/lib/features/market/receipt_screens.dart:63-71 at 5fd70c1. Now `app/lib/features/market/receipt_screens.dart:63-72`; test `app/test/receipts_test.dart:240` at 30e54c0. Raised by money-rounding.

fee = amountCents*100 ~/ 40, and the credit shown is fee*40 ~/ 100. For 1241 that is fee 3102 and credit 1240, so the example says $12.40 while the row lists $12.41. Today's seed values (1240, 860, 1016, 640, 524) are all even and round-trip exactly, so this is latent. Only the doc comment guards it, and nothing in lib writes feeEntries.

**Applied:** LedgerScreen.example now derives the fee as (amountCents*100 + pct~/2) ~/ pct, which rounds half up in int cents. It prints formatCents(e.amountCents) as the result instead of recomputing the credit from the fee, and the doc comment states the rounding rule. Added the odd-cent test 'the worked example prints the listed credit for an odd-cent entry' (amountCents 1241) to app/test/receipts_test.dart.

**Test:** `app/test/receipts_test.dart: the worked example prints the listed credit for an odd-cent entry`.

Red output, verbatim from the writer:

```text
New test run against the old lib:
00:00 +0: the worked example prints the listed credit for an odd-cent entry
00:00 +0 -1: the worked example prints the listed credit for an odd-cent entry [E]
  Expected: contains 'traders paid $31.03 in fees. 40% of $31.03 = $12.41,'
    Actual: 'Example: Odd session on MAYA: traders paid $31.02 in fees. 40% of $31.02 = $12.40, its credit below.'
     Which: does not contain 'traders paid $31.03 in fees. 40% of $31.03 = $12.41,'
  
  package:matcher                                     expect
  package:flutter_test/src/widget_tester.dart 473:18  expect
  test/receipts_test.dart 204:5                       main.<fn>
00:00 +0 -1: Some tests failed.
```

### F6 LOW — Profile Call details is tested only on the user's own profile, so a hardcoded handle survives

**Location:** app/test/receipts_test.dart:230-242 (code profile_screen.dart:94-95) at 5fd70c1. Now `app/test/receipts_test.dart:336-341` (kaito.eth profile, ETH Call details); wiring unchanged at `app/lib/features/profile/profile_screen.dart:95` at 30e54c0. Raised by tautology-hunt.

Replacing widget.handle with PortfolioMock.handle in forHolding leaves the test green. On kaito.eth's profile, ETH would then open maya's Oct 10 call.

**Applied:** Added the kaito.eth ProfileScreen ETH Call details block. Merged with F3.3: the block goes after the maya SOL block, not directly after the BTC back(). Otherwise the SOL block would run on kaito's profile and no longer test maya's SOL holding.

**Test:** `app/test/receipts_test.dart: each record item opens its call receipt`.

Red output, verbatim from the writer:

```text
Mutation: profile_screen.dart `.push(CallReceiptScreen.forHolding(widget.handle, h)),` -> `.push(CallReceiptScreen.forHolding(PortfolioMock.handle, h)),`.
Old test under the mutant: SURVIVED
00:01 +1: (tearDownAll)
00:01 +1: All tests passed!
New test under the same mutant: KILLED
Expected: exactly one matching candidate
  Actual: _DescendantWidgetFinder:<Found 0 widgets with text "kaito.eth" descending from widgets
with type "CallReceiptScreen": []>
   Which: means none were found but one was expected
...
  file:///home/alex/VistaColosseum/.worktrees/br-2026-10-04-p0-queue/app/test/receipts_test.dart line 309
00:01 +0 -1: Some tests failed.
Mutation reverted; the test then passed.
```

### F7 LOW — Ledger rows naming their market is satisfied by the worked-example sentence alone

**Location:** app/test/receipts_test.dart:128 (code receipt_screens.dart:108) at 5fd70c1. Now `app/test/receipts_test.dart:136-139`; row subtitle unchanged at `app/lib/features/market/receipt_screens.dart:109` at 30e54c0. Raised by tautology-hunt.

Dropping marketId from the row subtitle still passes: textContaining('MAYA') findsWidgets matches the example's 'on MAYA'.

**Applied:** The market-name assertion now counts textContaining('MAYA · ') == entries.length, one per ledger row.

**Test:** `app/test/receipts_test.dart: ledger total equals the sum of listed entries`.

Red output, verbatim from the writer:

```text
Mutation: `Text('${e.marketId} · ${_when(e.at)}', style: muted),` -> `Text(_when(e.at), style: muted),`.
Old test under the mutant: SURVIVED
00:01 +1: (tearDownAll)
00:01 +1: All tests passed!
New test under the same mutant: KILLED
Expected: exactly 5 matching candidates
  Actual: _TextContainingWidgetFinder:<Found 0 widgets with text containing MAYA · : []>
   Which: means none were found but some were expected
...
  file:///home/alex/VistaColosseum/.worktrees/br-2026-10-04-p0-queue/app/test/receipts_test.dart line 136
00:01 +0 -1: Some tests failed.
Mutation reverted; the test then passed.
```

### F8 LOW — Receipt detail values the fixture states (Direction, Entered, Market said, Not settled yet) are never asserted

**Location:** app/test/receipts_test.dart:211-221 (code receipt_screens.dart:291-305) at 5fd70c1. Now `app/test/receipts_test.dart:289-301` (Direction, Entered, Market said, `Not settled yet`, exact unavailable count) at 30e54c0. Raised by tautology-hunt.

Set ('Entered', null) or ('Market said', null). The record loop asserts only rule, author, asset, status and provenance, plus 'unavailable' findsWidgets, which entryPrice already satisfies. The BTC 7-count is unaffected because the BTC fields are already null.

**Applied:** The record loop now asserts Direction (side label), Entered, Market said, 'Not settled yet' on the open call only, and an exact unavailable count (1 open, 2 settled). The F8.1 import was already added by F12.1 and is not duplicated.

**Test:** `app/test/receipts_test.dart: each record item opens its call receipt`.

Red output, verbatim from the writer:

```text
Old test under each mutant: SURVIVED
mutated 1
00:01 +1: All tests passed!
mutated 2
00:01 +1: All tests passed!
mutated 3
00:01 +1: All tests passed!
mutated 4
00:01 +1: All tests passed!
New test under each mutant: KILLED
mutated 1
Expected: exactly one matching candidate
  Actual: _DescendantWidgetFinder:<Found 0 widgets with text "Thu 14:32" descending from widgets
   Which: means none were found but one was expected
#4      main.<anonymous closure> (file:///home/alex/VistaColosseum/.worktrees/br-2026-10-04-p0-queue/app/test/receipts_test.dart:280:7)
00:00 +0 -1: Some tests failed.
mutated 2
Expected: exactly one matching candidate
  Actual: _DescendantWidgetFinder:<Found 0 widgets with text "22%" descending from widgets with type
   Which: means none were found but one was expected
#4      main.<anonymous closure> (file:///home/alex/VistaColosseum/.worktrees/br-2026-10-04-p0-queue/app/test/receipts_test.dart:281:7)
00:00 +0 -1: Some tests failed.
mutated 3
Expected: exactly one matching candidate
  Actual: _DescendantWidgetFinder:<Found 0 widgets with text "Long" descending from widgets with
   Which: means none were found but one was expected
#4      main.<anonymous closure> (file:///home/alex/VistaColosseum/.worktrees/br-2026-10-04-p0-queue/app/test/receipts_test.dart:279:7)
00:00 +0 -1: Some tests failed.
mutated 4
Expected: exactly one matching candidate
  Actual: _DescendantWidgetFinder:<Found 0 widgets with text "Not settled yet" descending from
   Which: means none were found but one was expected
#4      main.<anonymous closure> (file:///home/alex/VistaColosseum/.worktrees/br-2026-10-04-p0-queue/app/test/receipts_test.dart:287:7)
00:00 +0 -1: Some tests failed.
(1 = Entered->null, 2 = Market said->null, 3 = Direction->null, 4 = Settled->r.settledAt.) Mutations reverted; the test then passed.
```

### F9 LOW — A real call receipt showing the noCall header is never ruled out

**Location:** app/test/receipts_test.dart:211-236 (code receipt_screens.dart:310-313) at 5fd70c1. Now `app/test/receipts_test.dart:283-287` (record loop) and `:316-320` (own-profile ETH) at 30e54c0. Raised by tautology-hunt.

A header that always reads noCall passes. noCall is asserted present only on 'none' receipts and never asserted absent on real ones.

**Applied:** In the record loop and on the own-profile ETH Call details path, a real call's receipt must not show noCall and must show 'A published call, not an order fill'.

**Test:** `app/test/receipts_test.dart: each record item opens its call receipt`.

Red output, verbatim from the writer:

```text
Mutation: `          r.rule == null\n` -> `          true\n` in the CallReceiptScreen header.
Old test under the mutant: SURVIVED
00:01 +1: All tests passed!
New test under the same mutant: KILLED
Expected: no matching candidates
  Actual: _DescendantWidgetFinder:<Found 1 widget with text "No open call in fixture-v1 backs this
holding" descending from widget with type "CallReceiptScreen": [ ... ]>
   Which: means one was found but none were expected
...
  file:///home/alex/VistaColosseum/.worktrees/br-2026-10-04-p0-queue/app/test/receipts_test.dart line 278
00:00 +0 -1: Some tests failed.
Mutation reverted; the test then passed.
```

### F10 LOW — Worked example is checked only against today's seed

**Location:** app/test/receipts_test.dart:155-184 (code receipt_screens.dart:65-71, 88-91) at 5fd70c1. Now `app/test/receipts_test.dart:150-151` (example follows the dropped entry) and `:180` (ZED ledger shows no seeded example) at 30e54c0. Raised by tautology-hunt.

(a) A literal example string equal to today's output passes: the 'ledger total' test drops entries.first but never re-checks the example. (b) Building the guard and example from feeEntries.value instead of marketFees shows an example on the ZED ledger; that test uses exact find.text on event titles, which does not match the example sentence.

**Applied:** 'ledger total' now checks that after the newest credit is dropped, the worked example cites rest.first and no longer entries.first. The ZED test asserts that no seeded credit's worked example renders. Both go through LedgerScreen.example.

**Test:** `app/test/receipts_test.dart: ledger total equals the sum of listed entries`; `app/test/receipts_test.dart: a market with no credits shows an empty ledger and zero`.

Red output, verbatim from the writer:

```text
Old tests under each mutant: SURVIVED
== old tests vs (a)
mutated F10a
00:01 +1: All tests passed!
== old tests vs (b)
mutated F10b
00:00 +1: All tests passed!
New tests under each mutant: KILLED
== new tests vs (a)
mutated F10a
Expected: no matching candidates
  Actual: _TextWidgetFinder:<Found 1 widget with text "Example: Saturday trading session on MAYA:
   Which: means one was found but none were expected
#4      main.<anonymous closure> (file:///home/alex/VistaColosseum/.worktrees/br-2026-10-04-p0-queue/app/test/receipts_test.dart:150:5)
00:01 +0 -1: Some tests failed.
== new tests vs (b)
mutated F10b
Expected: no matching candidates
  Actual: _TextWidgetFinder:<Found 1 widget with text "Example: Saturday trading session on MAYA:
   Which: means one was found but none were expected
#4      main.<anonymous closure> (file:///home/alex/VistaColosseum/.worktrees/br-2026-10-04-p0-queue/app/test/receipts_test.dart:180:7)
00:00 +0 -1: Some tests failed.
Mutations reverted; both tests then passed.
```

### F11 LOW — No test proves the record and receipts lists read Scenario.callReceipts rather than the static seed

**Location:** app/test/receipts_test.dart:208-223 (code your_market_screen.dart:122-135, receipt_screens.dart:196) at 5fd70c1. Now `app/test/receipts_test.dart:415-430` at 30e54c0. Raised by tautology-hunt.

Iterating YourMarketMock.record directly passes every test. The only writes to callReceipts are in the pure seed test and in mutateEverything, and the widget tests that call mutateEverything never show YourMarketScreen or ReceiptsScreen.

**Applied:** Added the test 'the record and receipts lists read the call receipt store'. It drops the first call from Scenario.callReceipts and asserts that both Your market's record and the All receipts list (via onList) follow the store.

**Test:** `app/test/receipts_test.dart: the record and receipts lists read the call receipt store`.

Red output, verbatim from the writer:

```text
Old suite under each mutant: SURVIVED
== old suite vs (a)
mutated F11a
00:02 +12: All tests passed!
== old suite vs (b)
mutated F11b
00:02 +12: All tests passed!
New test under each mutant: KILLED
== new test vs (a)
mutated F11a
Expected: no matching candidates
  Actual: _TextWidgetFinder:<Found 1 widget with text "SOL reaches $300 by Fri": [
   Which: means one was found but none were expected
#4      main.<anonymous closure> (file:///home/alex/VistaColosseum/.worktrees/br-2026-10-04-p0-queue/app/test/receipts_test.dart:421:5)
00:00 +0 -1: Some tests failed.
== new test vs (b)
mutated F11b
Expected: no matching candidates
  Actual: _DescendantWidgetFinder:<Found 1 widget with text "SOL reaches $300 by Fri" descending
   Which: means one was found but none were expected
#4      main.<anonymous closure> (file:///home/alex/VistaColosseum/.worktrees/br-2026-10-04-p0-queue/app/test/receipts_test.dart:426:5)
00:00 +0 -1: Some tests failed.
(a = your_market_screen.dart `for (final c in calls)` -> YourMarketMock.record; b = ReceiptsScreen calls from YourMarketMock.record.) Mutations reverted; the full receipts file then passed (+13).
```

### F12 LOW — forHolding's side match is untested

**Location:** app/lib/features/market/receipt_screens.dart:276 at 5fd70c1. Now `app/test/receipts_test.dart:359-383`; product unchanged at `app/lib/features/market/receipt_screens.dart:277` at 30e54c0. Raised by tautology-hunt.

Removing `c.side == holding.side &&` passes everything. Every seeded call is long and on SOL or ETH, the only short holding is BTC, and there is no BTC call. This cannot misfire on today's data; only a future short holding would expose it.

**Applied:** Added the design_system.dart and profile_mock.dart imports. Merged with F8.1, which needed the same design_system import, so it is added only once. Added the test 'Call details match the holding side: a short ETH holding is not backed by an open ETH long'.

**Test:** `app/test/receipts_test.dart: Call details match the holding side: a short ETH holding is not backed by an open ETH long`.

Red output, verbatim from the writer:

```text
Mutation: deleted `c.side == holding.side &&` in receipt_screens.dart forHolding.
Old suite under the mutant (flutter test test/receipts_test.dart): SURVIVED
00:02 +10: (tearDownAll)
00:02 +10: All tests passed!
New test under the same mutant: KILLED
The following TestFailure was thrown running a test:
Expected: 'none'
  Actual: 'maya-eth-4000-oct10'
   Which: is different.
          Expected: none
            Actual: maya-eth-4 ...
                    ^
           Differ at offset 0
...
  file:///home/alex/VistaColosseum/.worktrees/br-2026-10-04-p0-queue/app/test/receipts_test.dart line 308
00:00 +0 -1: Some tests failed.
Mutation reverted; the full receipts file then passed (+11).
```

## What the fixes now reject

Two adjudicator `rejectsValidInput` answers are not none: F4 and F7. The other ten (F1, F2, F3, F5, F6, F8, F9, F10, F11, F12) answered none.

**F4** (the listing-instant gate), verbatim:

> Checked. After the fix, a fresh listing shows $0.00 instead of $42.80. Re-listing an already listed market would also hide its earlier credits, but there is no UI path for that: the Make a market button only renders when no market is listed.
>
> Tests: home_screen_test.dart:95 and order_ticket_test.dart:103 list MAYA fresh in setUp. A grep of app/test for '42.80', 'Fees from your market', 'earned in fees', formatCents(0), LedgerScreen and matchesGoldenFile outside receipts_test finds nothing, so no test depends on fees after a fresh listing. receipts_test runs `Scenario.reset(withMarket: true)` in setUp, and the new seed instant keeps every existing fee assertion there at the seeded total.
>
> Documents: none outside run bookkeeping tells a human to list fresh and expect $42.80. ARCH.md:63 and :351 only say HAS_MARKET=true starts with a market listed, and that path still shows $42.80. The baton-pass notes that mention $42.80 are run bookkeeping and describe the HAS_MARKET path.

Document check: no document teaches a human to produce this input. Outside run bookkeeping, these are the docs that touch the fee figure. `docs/specs/06-fee-ledger-and-receipts.md:7` names the `$42.80` constant as the gap to remove. Line `:10` says the Wallet row and the Your-market chip show `sum(entries)`, and they still show the fold of exactly the entries the ledger lists. PRD VC-MKT-004 (`docs/prd/2026-10-01-vc-hackathon-master-prd.md:117`) asks only that the total equal the ledger sum. `ARCH.md:63` and `:351` say only that `HAS_MARKET=true` starts with a market listed, and that path still shows `$42.80`. Nothing tells a human to list a market fresh and expect `$42.80`.

**F7** (the ` · ` row separator), verbatim:

> A row subtitle that names the market without the house ' · ' separator (e.g. 'MAYA, 26 Sep') would now fail. No doc asks for that format. The ' · ' separator is the house pattern (receipt_screens.dart:108, :238 and the 'Illustrative demo ledger · ...' label), and spec 06 does not specify the subtitle format. In practice nothing valid is rejected.

Document check: none. Spec 06 asks only that each entry name its demo market and event, and gives no subtitle format. The one ledger row builder uses the ` · ` separator (`app/lib/features/market/receipt_screens.dart:109`).

Nothing in the fixer run executed a rejected input. The suite's other fresh listings are the `setUp` calls at `app/test/home_screen_test.dart:95` and `app/test/order_ticket_test.dart:103` (MAYA, no fee assertions), plus `app/test/scenario_test.dart:57` and `:219` (ZED, which has no seeded credits before or after the fix). All of them pass in the close gate. The new F4 test lists fresh and asserts the zero on purpose. No test builds a ledger row without the ` · ` separator.

## Refuted: 1

**The made-up 'unavailable' receipt still says Provenance fixture-v1, contradicting its header** (raised by receipts-truthfulness).

The skeptic's reason, verbatim: "The header itself scopes the claim to fixture-v1 ('No call in fixture-v1 backs this holding'). Provenance fixture-v1 names the fixture that statement of absence is made against, so the two agree. Rendering provenance as 'unavailable' would hide where the lookup ran. This is a wording preference, not a defect, and the 7-count test pins correct behaviour."

## Checked claims that were wrong: 0

The skeptic spot-checked the lanes' "verified as correct" claims against the tree, and they held. Its `checkedClaimsThatAreWrong` list is empty.

## Residual risk (verbatim)

- money-rounding: Did not run flutter test or the gate. I relied on the stated 5fd70c1 gate pass (261 tests) and read the code instead.
- money-rounding: Out of my money lane and not reviewed in depth: layout and pill-clearance tests at 375x667, the CallReceipt detail-screen header text, the Call details forHolding matching in profile_screen and trader_market_screen, and the review-iter1 items about the receipt id not being shown, an empty All receipts list, and credits dated before listing.
- money-rounding: Process note: to check the arithmetic I wrote one scratch Dart file (ex.dart) in my session scratchpad, outside the repo. The worktree and git state were not touched.
- tautology-hunt: No mutants were run by me (read-only lane; running one requires writing a mutated copy). Survival claims for my new findings rest on reading the test assertions and code paths. The prior review's runs are cited where they apply.
- tautology-hunt: No test runs this session. The gate result (261 tests) was taken as given.
- tautology-hunt: Implementation-lane issues (money rounding in example(), L3 receipt id not shown, L4 header keyed on rule==null, L6 credit dates) were not re-litigated here beyond how the tests cover them.
- tautology-hunt: Tests elsewhere that may touch the changed screens indirectly (home_screen_test, portfolio tests) were not audited for new tautologies. Only receipts_test.dart and the scenario_test.dart hunk were in scope.
- tautology-hunt: Profile CALLS list and trader-market Record panel tap coverage were not reviewed (carried to phase 7 by the run manager).
- receipts-truthfulness: Did not run any flutter test or render at 375x667 / 1.3x. Pill clearance is judged from the padding code plus the iter-1 probe numbers, not re-measured.
- receipts-truthfulness: Did not review receipts_test.dart test strength (iter-1 M1/L1/L2 mutant claims) beyond confirming the missing SOL coverage.
- receipts-truthfulness: make_market_flow.dart, your_market_screen.dart and design-system token use are outside my file list. I only read the 40% label lines and the record/chip wiring there.
- receipts-truthfulness: Record-panel and Profile CALLS item tappability was ruled carry-forward to phase 7 and was not assessed.

## Verification after the fixes

finding-fixer verification (`scripts/gate.sh baton-runner/br-2026-10-04-p0-queue/gate-phase-6-fixer/`), verbatim:

```text
=== gate: flutter-analyze: flutter analyze ===
PASS flutter-analyze
=== gate: flutter-test: flutter test ===
PASS flutter-test
=== gate: pubspec-frozen: git diff --exit-code c95349cc2a9a40be16d4bddee74c512129ac0114 -- pubspec.yaml pubspec.lock ===
PASS pubspec-frozen
----
GATE: PASS
exit=0
(extra: cd app && flutter test --dart-define=HAS_MARKET=true test/receipts_test.dart test/scenario_test.dart -> 00:03 +32: All tests passed!)
```

Full gate after commit (`baton-runner/br-2026-10-04-p0-queue/gate-phase-6-close/`; the closing unit re-ran `cd app && grep -rn "_notBuilt('All receipts')" lib` at 30e54c0: no output, exit 1):

GATE: PASS exit 0 at 30e54c0, 265 tests, HAS_MARKET=true 265, All-receipts grep empty
