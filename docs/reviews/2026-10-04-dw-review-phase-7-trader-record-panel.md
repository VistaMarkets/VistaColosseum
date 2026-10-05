# dw-review — `feat/br-2026-10-04-p0-queue/phase-7` (trader record panel, spec 07)

- **Target:** `feat/br-2026-10-04-p0-queue/phase-7`, phase 7 of baton-runner run `br-2026-10-04-p0-queue`: the trader record panel (`docs/specs/07-trader-record-panel.md`; PRD VC-MKT-002, VC-FED-003). It derives each trader's record (settled, right, wrong, open, hit rate, as of the demo clock) from `Scenario.callReceipts`, never from paper size. It seeds kilo.sol and lunaq with the same outcomes behind different sizes and kestrel with nothing settled, adds `TraderRecordPanel` with the "Illustrative index · based on N settled calls · as of <clock>" copy, and does CF-1 from phase 6: Profile CALLS and the trader-market Record panel now list that trader's own receipts, each opening its receipt. The branch is stacked on `feat/br-2026-10-04-p0-queue/phase-6` (`3a29ada462a4ba6465c36fa4243f520495088662`), which is draft [VistaColosseum#17](https://github.com/VistaMarkets/VistaColosseum/pull/17), itself on [VistaColosseum#16](https://github.com/VistaMarkets/VistaColosseum/pull/16) and [VistaColosseum#15](https://github.com/VistaMarkets/VistaColosseum/pull/15). Phases 1-3 are on main as [VistaColosseum#10](https://github.com/VistaMarkets/VistaColosseum/pull/10), [VistaColosseum#12](https://github.com/VistaMarkets/VistaColosseum/pull/12) and [VistaColosseum#13](https://github.com/VistaMarkets/VistaColosseum/pull/13). Diff reviewed: `feat/br-2026-10-04-p0-queue/phase-6...feat/br-2026-10-04-p0-queue/phase-7`, 12 files under `app/` at review time. The fix commit brings it to 20 (17 in `lib`, 3 in `test`).
- **Commit reviewed:** the review ran at `c2b1566eb958ff783732bf5c2ed55a27baf4540a`. The fixes landed at `229ab638793c74456b7723c8909c27a33f470599`.
- **Date:** 2026-10-04 (the run date). The review, the fixes, the close gate and this record were done on 2026-10-05 UTC (run log 2026-10-05T06:05:45Z to 06:45:22Z, then this closing unit). Skill `dw-review`, run by `baton-runner-managed`. Workflow runs `wf_75cbb468-61c` (review) and `wf_a8995126-4a9` (finding-fixer).
- **Lanes:** tautology-hunt 6, metrics-single-source 7, wiring-ux 8 (raw 21), plus the fixed skeptic. Merges: 6 duplicate filings folded into 5 findings (F1 2→1, F2 3→1, F3 2→1, F4 2→1, F5 2→1), so 21 raw = 12 confirmed + 3 refuted + 6 merged. Confirmed: 12 (1 HIGH, 4 MEDIUM, 7 LOW; the skeptic ranked F5 MEDIUM to match F1's class, where the iter-1 review had it LOW). Refuted: 3. Checked claims that were wrong: 0. None is marked before-merge.
- **Disposition:** 12 of 12 dispositioned: 12 applied, 0 annotated, 0 skipped, 0 unreported (fixer coverage: failedGroups [], unreported []). Every adjudicator verdict was fix-here. The HIGH (F1) was fixed in this phase, not carried. F1, F2, F5, F8, F10, F11 and F12 change product code, each behind a test that ran red first (F12 is dead-code deletion, proven by `flutter analyze`). F9 corrects doc comments. F3, F4, F6 and F7 are test-strength fixes, each mutation-proven: the named mutant survived the old test and the new test kills it.
  - Manager's decisions (run log 2026-10-05T06:15:40Z), verbatim: "F1 = add an unavailable count to RecordMetrics, keep it out of settled and hit rate, show "N unavailable" in the panel when >0, flip the pinning test. F2 = Arena side and opinion-subtitle accuracy derive from Scenario.record(caller).hitRatePct at render, "no record yet" when null. F5 = the verdicts strip renders the trader's actual settled receipts (up to 10, newest last) titled "Last N verdicts", hidden at zero. F8 = hide the CALLS heading when the trader has no receipts (phase 8 may swap in the shared empty state). F9 = the trader-market chart is the market price series, keep it; fix the doc comment that called it the index. F10 = "Record since" derives from the earliest receipt's entryAt, hidden when none. F11 = record() counts a receipt as settled only when settledAt is at or before Scenario.clock; later-settled receipts count as open at that clock. F12 = delete the unreferenced VistaReceipt, VistaVersus and rail asset constants (asset files stay). F3, F4, F6, F7 test-strength: mutation-proven."
  - Earlier decision (run log 2026-10-05T06:04:14Z), verbatim: "accept the ruling; Arena side accuracy must derive from the same record metrics (or be removed) in this phase."
  - F11 as built goes one step past the decision: a verdict with no settlement date in the "Sep 12" form cannot be placed against the clock, so it counts as unavailable. That moves maya.eth's two verdicts and nara's "Tue 16:00" Right to unavailable (see "What the fixes now reject"). F5's strip goes through the same rule (`Scenario.outcomeAt`), so its count always equals the header's Settled.
  - F3 as built: under F11, nara's Right is unavailable at the seed clock, so the writer narrowed the nara guard to `[m.settled, m.open]`. The writer names the remaining weakness: a private-header Right hard-coded to '0' would survive.
  - CF-1 (carried from phase 6) is done: see the closing baton for the per-criterion evidence.

## Verdict: MERGE-WITH-FIXES

"Scope check passed. phase-7 resolves to c2b1566, which is the worktree HEAD and matches the gate SHA. phase-6 resolves to 3a29ada. The three-dot diff touches 12 files under app/. Twelve of the filed findings survive after merging duplicates. One is HIGH: Scenario.record drops receipts that have a null result with a bare `case null: break;`. RecordMetrics has no field for those calls, and the unit test at trader_record_test.dart:157 pins the drop. The fail-safe rule makes this class HIGH. It is latent, though: no seeded receipt has a null result, and callReceipts is written only at init and in reset. Four are MEDIUM. Arena accuracy is hard-coded (the known F1). The profile header stats are unpinned (the known F2). The panel copy is tested only on the pair at the seed clock, so a hard-coded caption or hit rate, swapped right/wrong labels, the wrong handle on Your market or the private profile, or a dropped clock listener would all stay green. The static 'Last 10 verdicts' icon (7 right, 3 wrong) sits above derived figures of 3 settled, and this diff gated it and pinned it with a test. Seven are LOW. I refuted three: the share card and the Markets rows are outside this diff (the share preview is a declared queue residual), and the nara 'Illustrative index' copy is what the spec requires; the feed also opens a nara trader market (mock_trade_idea.dart:324). Nothing in this diff freezes at merge, so no finding is must-fix-before-merge. The HIGH is a three-line fix and the reviewers recommend doing it in this phase."

Every confirmed finding, F1 through F12, was applied at 229ab63 and the full gate passed there, so the merge-with-fixes condition is met.

## Confirmed findings

### F1 HIGH — Scenario.record silently drops a call receipt with a null result: no count, no trace, and the panel cannot reconcile with the list under it

**Location:** app/lib/scenario/scenario.dart:161-162 (RecordMetrics typedef :16-23; panel app/lib/features/market/receipt_screens.dart:207-252; pinned by app/test/trader_record_test.dart:157) at c2b1566. Now: `app/lib/scenario/scenario.dart:166-167` (`case null: unavailable++;`), `RecordMetrics.unavailable` (`:24`); panel `app/lib/features/market/receipt_screens.dart:222-226` (empty branch) and `:244-245` (the Wrap).

CallReceipt.result is nullable, and status/color/rail render null as 'unavailable' (market_mock.dart:62-82). CallOutcome has no void value, so an unknown or voided call can only be null. record() runs `case null: break;` and RecordMetrics has nowhere to count it. Example: a kilo.sol receipt with result null. CallRecordList shows 5 items, one marked 'unavailable', while TraderRecordPanel still reads '3 settled · 2 right · 1 wrong · 1 open · Hit rate 67%' with nothing to say a call is missing. The test feeds author 'x' one null receipt and expects it gone from every count. Latent today: every seeded receipt has a result, and callReceipts is written only at scenario.dart:100 (init) and :351 (reset).

**Fix asked for:** Add `int unavailable` to RecordMetrics and count `case null` into it. Keep it out of settled and the hit rate. When it is above 0, show '$unavailable unavailable' in the panel's Wrap. Change the test at :161-168 to expect unavailable: 1 instead of the drop.

**Applied:** Added an `unavailable` count to RecordMetrics. Scenario.record counts a null outcome as unavailable instead of dropping it. The panel shows 'N unavailable' in the Wrap when the count is above 0, and '<note> · N unavailable' in the empty branch. The pinned silent-drop test now expects unavailable: 1, and there is a new widget test covering both branches. Note: the red was a runtime record-shape mismatch, not a compile failure, because expect() takes dynamic.

**Test:** `app/test/trader_record_test.dart: the hit rate is an integer percent rounded half up, read from the call receipts and the clock at the time of asking` (`:156`, now expects `unavailable: 1`); `app/test/trader_record_test.dart: a call with no outcome shows in the panel as unavailable, never dropped` (`:259`).

Red output, verbatim from the writer:

```text
Expected: ({DateTime asOf, int hitRatePct, int open, int right, int settled, int unavailable, int wrong}):<(asOf: 2026-09-26 14:45:00.000, hitRatePct: 67, open: 1, right: 2, settled: 3, unavailable: 0, wrong: 1)>
    Actual: ({DateTime asOf, int hitRatePct, int open, int right, int settled, int wrong}):<(asOf: 2026-09-26 14:45:00.000, hitRatePct: 67, open: 1, right: 2, settled: 3, wrong: 1)>
  test/trader_record_test.dart 135:5                  main.<fn>
  Expected: ({DateTime asOf, int hitRatePct, int open, int right, int settled, int unavailable, int wrong}):<(asOf: 2026-09-26 16:45:00.000, hitRatePct: 13, open: 1, right: 1, settled: 8, unavailable: 1, wrong: 7)>
    Actual: ({DateTime asOf, int hitRatePct, int open, int right, int settled, int wrong}):<(asOf: 2026-09-26 16:45:00.000, hitRatePct: 13, open: 1, right: 1, settled: 8, wrong: 7)>
  test/trader_record_test.dart 162:5                  main.<fn>
Expected: exactly one matching candidate
  Actual: _DescendantWidgetFinder:<Found 0 widgets with text "1 unavailable" descending from widgets
   Which: means none were found but one was expected
  file:///home/alex/VistaColosseum/.worktrees/br-2026-10-04-p0-queue/app/test/trader_record_test.dart line 198
  a call with no outcome shows in the panel as unavailable, never dropped
```

### F2 MEDIUM — Arena sides and opinion subtitles hard-code accuracy that contradicts the derived record (known F1, confirmed)

**Location:** app/lib/features/arena/arena_mock.dart:143,151,162,174 (also :107,117,200,208,219) at c2b1566. Now: `app/lib/features/arena/arena_screen.dart:148-155` (`withLines(crowd: …, accuracy: accuracyLine(caller))`), listening on `Scenario.callReceipts` and `Scenario.clock` (`:74-75`); `app/lib/features/arena/opinions_screen.dart:13-16` (`accuracyLine`) and `:133` (subtitle); `app/lib/design_system/components/vista_battle.dart:40` (`withLines`). The stored `accuracy:` strings and subtitle percentages are gone from `arena_mock.dart`, and `@bitcoinninja`'s `hitRate: '80%'` from `opinions_mock.dart`.

The eth-4k battle card shows kilo.sol '71% accuracy' and lunaq '77% accuracy'. Tapping either name (the AC3 path, arena_screen.dart:153) opens a panel that reads 'Hit rate 67%' for both, since each derives (3,2,1,1,67). So the VC-MKT-002 equal pair looks unequal one tap before the screen that shows them equal. maya.eth shows '82%' against a derived 50%. mirin, renatafx and 0xreal show figures but have no receipts, so their panels read 'record unavailable'. The Arena AC3 test (trader_record_test.dart:323-331) never compares the card figure with the panel.

**Fix asked for:** Derive the side and subtitle accuracy from Scenario.record(caller).hitRatePct at render time, showing 'no record yet' when it is null. Then assert in the Arena test that the tapped side's percent equals the panel's.

**Applied:** Deleted the stored accuracy figures and the role-subtitle percentages. Added accuracyLine(handle), which derives the line from Scenario.record. withCrowd becomes withLines(crowd, accuracy). The Arena now listens to callReceipts and clock. Opinion subtitles append the derived accuracy. Deleted @bitcoinninja's stored '80%' hitRate line (the line was removed, not left blank). The Arena test checks that the card's percent equals the panel's, before and after a receipt change. home_screen_test checks 'Sniper · 67% accuracy'.

**Test:** `app/test/trader_record_test.dart: Arena card trader link opens the record panel` (`:487`); `app/test/home_screen_test.dart: a battle's opinions trade that battle's asset and clash` (`:1165`, assertion at `:1176`).

Red output, verbatim from the writer:

```text
[trader_record_test Arena card trader link]
Expected: exactly one matching candidate
  Actual: _DescendantWidgetFinder:<Found 0 widgets with text "67% accuracy" descending from widgets
   Which: means none were found but one was expected
  file:///home/alex/VistaColosseum/.worktrees/br-2026-10-04-p0-queue/app/test/trader_record_test.dart line 407
00:01 +0 -1: Some tests failed.
[home_screen_test a battle's opinions trade]
Expected: exactly one matching candidate
  Actual: _TextWidgetFinder:<Found 0 widgets with text "Sniper · 67% accuracy": []>
   Which: means none were found but one was expected
  file:///home/alex/VistaColosseum/.worktrees/br-2026-10-04-p0-queue/app/test/home_screen_test.dart line 1156
00:01 +0 -1: Some tests failed.
```

### F3 MEDIUM — Profile and private-profile header Settled / Right / Open calls values are unpinned (known F2, confirmed)

**Location:** app/lib/features/profile/profile_screen.dart:202,205; app/lib/features/profile/private_profile_screen.dart:143-170 at c2b1566. Now: Header code unchanged (`profile_screen.dart` `_stats`, `private_profile_screen.dart:140-170`); the fix is test-only.

Revert '${m.settled}' / '${m.right}' to '62' / '36', the constants spec 07's Gap names, or set the private header's Open calls to a constant. The suite stays green. The pair test scopes '3 settled' to inPanel, so the header's VistaCountStat value is never read. The nara private-profile test (home_screen_test.dart:562-573) asserts only the 'Open calls' label and one list item.

**Fix asked for:** In the pair profile test, assert that VistaCountStat 'Settled' shows '3' and 'Right' shows '2' for kilo.sol. In the nara private-profile test, assert Settled '2', Right '1' and Open calls '2'.

**Applied:** Added a countStat finder and header Settled/Right checks on the pair (3/2) and on kestrel (0/0). The nara private-header leg follows Scenario.record, then drops nara's receipts and expects zeros. Adapted from the adjudicated text: under F11, nara's 'Tue 16:00' Right is unavailable, so m.right == 0 at the seed clock. The edit's guard `expect([m.settled, m.right, m.open], everyElement(greaterThan(0)))` would always fail, so it is narrowed to `[m.settled, m.open]`, with a comment. Remaining weakness: on the private header, a Right hard-coded to '0' would survive. Mutation-proven: profile_screen Settled→'62' and Right→'36' plus private_profile Open calls→'2' left the old trader_record_test and home_screen_test green (00:37 +209: All tests passed!). The new tests failed on them. Settled hard-coded to '3' was caught by the kestrel leg (line 284). All mutations reverted, then green (+209).

**Test:** `app/test/trader_record_test.dart: both traders' panels show the same sample size, hit rate and as-of time below the index chart` (`:237`); `app/test/trader_record_test.dart: zero-history trader → unavailable state, no crash` (`:313`); `app/test/home_screen_test.dart: a private account without a market opens the private layout` (`:562`, header checks at `:581` and `:594`).

Red output, verbatim from the writer:

```text
[mutations: Settled '62', Right '36' (profile_screen), Open calls '2' (private_profile_screen); old tests] 00:37 +209: All tests passed!
[same mutations, new tests]
Expected: exactly one matching candidate
  Actual: _WidgetPredicateWidgetFinder:<Found 0 widgets with widget matching predicate: []>
   Which: means none were found but one was expected
  file:///home/alex/VistaColosseum/.worktrees/br-2026-10-04-p0-queue/app/test/trader_record_test.dart line 241
Expected: exactly one matching candidate
  Actual: _WidgetPredicateWidgetFinder:<Found 0 widgets with widget matching predicate: []>
   Which: means none were found but one was expected
  file:///home/alex/VistaColosseum/.worktrees/br-2026-10-04-p0-queue/app/test/trader_record_test.dart line 284
Expected: exactly one matching candidate
  Actual: _WidgetPredicateWidgetFinder:<Found 0 widgets with widget matching predicate: []>
   Which: means none were found but one was expected
  file:///home/alex/VistaColosseum/.worktrees/br-2026-10-04-p0-queue/app/test/home_screen_test.dart line 594
00:40 +206 -3: Some tests failed.
[mutation: Settled '3' only, new tests]
  Actual: _WidgetPredicateWidgetFinder:<Found 0 widgets with widget matching predicate: []>
  file:///home/alex/VistaColosseum/.worktrees/br-2026-10-04-p0-queue/app/test/trader_record_test.dart line 284
00:03 +10 -1: Some tests failed.
```

### F4 MEDIUM — Panel copy is tested at one data point only: a hard-coded caption or hit rate, swapped right/wrong labels, the wrong handle on Your market or the private profile, a dropped clock listener, or a constant open-calls chip all stay green

**Location:** app/lib/features/market/receipt_screens.dart:217-246; app/lib/features/market/your_market_screen.dart:118; app/lib/features/profile/private_profile_screen.dart:243; app/lib/features/market/trader_market_screen.dart:46-50 (tests app/test/trader_record_test.dart:38-39,174-331) at c2b1566. Now: Panel code unchanged (`receipt_screens.dart:207-262`); the fix is test-only.

Every widget assertion on panel text uses kilo.sol or lunaq at the seed clock, and the two have identical metrics. Each of these mutations survives: (a) replace the caption, '$n settled' and 'Hit rate $pct%' with the literals 'Illustrative index · based on 3 settled calls · as of 26 Sep 14:45', '3 settled' and 'Hit rate 67%', keeping the pct==null gate; (b) swap the '${m.right} right' and '${m.wrong} wrong' labels, since '2 right', '1 wrong' and '1 open' are never asserted; (c) TraderRecordPanel(handle: 'kilo.sol') on Your market or nara's private profile; (d) listen only to callReceipts, since no test moves Scenario.clock with a panel mounted; (e) a constant in _openCalls, since 'open call' never appears in a test. Mutation (a) is exactly the 'stored constant' the invariant forbids. The hit-rate unit test pins Scenario.record, not what the panel renders.

**Fix asked for:** Add one widget assertion at a second data point: on Your market, expect 'Hit rate 50%' and 'based on 2 settled calls' in panelFor('maya.eth'), and nara's '2 settled'/'Hit rate 50%' on the private profile. With a panel mounted, move Scenario.clock forward, pump, and expect the new 'as of' caption. Assert '2 right', '1 wrong' and '1 open' inside the pair panel, and find.text('1 open call') on TraderMarketScreen('kilo.sol').

**Applied:** Added three tests: each panel shows its own trader's record (right/wrong/open apart, nara derived, Your market handle); a mounted panel follows the clock; and the open-calls chip counts a second open call. Mutation-proven against a temporary copy of the pre-F4 file, since deleted. Mutations b (swapped labels), c1 (Your market panel handle 'kilo.sol'), c2 (private panel handle 'kilo.sol'), d (listenable = callReceipts only) and e (constant '1 open call') each passed the old file and failed the new tests. Mutation a (hard-coded caption, '3 settled', 'Hit rate 67%') was already caught by the old file, through F2's rewritten Arena test ('Hit rate 100%'), and the new tests catch it too. Every mutation was reverted.

**Test:** `app/test/trader_record_test.dart: each panel shows its own trader's record, right and wrong apart` (`:518`); `app/test/trader_record_test.dart: a mounted panel follows the demo clock` (`:563`); `app/test/trader_record_test.dart: the trader market's open-calls chip counts the trader's open calls` (`:580`).

Red output, verbatim from the writer:

```text
== b_swapped
  OLD: 00:03 +14: All tests passed!
  NEW: FAIL: each panel shows its own trader's record, right and wrong apart
     Expected: exactly one matching candidate
     Actual: _DescendantWidgetFinder:<Found 0 widgets with text "2 right" descending from widgets with
== c1_yourmarket
  OLD: 00:03 +14: All tests passed!
  NEW: FAIL: each panel shows its own trader's record, right and wrong apart
     Actual: _WidgetPredicateWidgetFinder:<Found 0 widgets with widget matching predicate: []>
== c2_private
  OLD: 00:03 +14: All tests passed!
  NEW: FAIL: a mounted panel follows the demo clock; FAIL: each panel shows its own trader's record, right and wrong apart
     Actual: _DescendantWidgetFinder:<Found 0 widgets with text containing based on 1 settled call
     Actual: _DescendantWidgetFinder:<Found 0 widgets with text containing as of 27 Sep 16:45
== d_listenable
  OLD: 00:03 +14: All tests passed!
  NEW: FAIL: a mounted panel follows the demo clock
     Actual: _DescendantWidgetFinder:<Found 0 widgets with text containing as of 27 Sep 16:45
== e_opencalls
  OLD: 00:04 +14: All tests passed!
  NEW: FAIL: the trader market's open-calls chip counts the trader's open calls
     Actual: _TextWidgetFinder:<Found 0 widgets with text "2 open calls": []>
== a_hardcoded
  OLD: FAIL Arena card trader link opens the record panel (already caught via F2)
  NEW: FAIL Arena card trader link; a mounted panel follows the demo clock; each panel shows its own trader's record
     Actual: _DescendantWidgetFinder:<Found 0 widgets with text containing based on 1 settled call
```

### F5 MEDIUM — Static 'Last 10 verdicts' icon (10 dots, 7 right) sits above derived Settled 3 / Right 2, and this diff gated it and pinned it with a test

**Location:** app/lib/features/profile/profile_screen.dart:152-160 (test app/test/trader_record_test.dart:182) at c2b1566. Now: `app/lib/features/profile/profile_screen.dart:20-66` (`VerdictStrip`), mounted at `:219`; `VistaAssets.verdictsLast10` deleted (the svg file stays).

This diff wraps the header in a callReceipts listener and shows VistaAssets.verdictsLast10 whenever m.settled > 0. On kilo.sol's, lunaq's or maya.eth's profile, a fixed 10-verdict strip labelled 'Last 10 verdicts' sits directly over derived stats of 3 settled (or 2 for maya.eth). That is a stored second copy of the record next to the derived one, the same stale-duplicate class as F1, and the test at :182 asserts it is present.

**Fix asked for:** Drop the icon until a derived version exists (building dots from receipts would be new UI, which the spec excludes), and update the test at :182 to expect it absent. Or draw min(10, settled) dots from the receipts with a 'Last N verdicts' label.

**Applied:** Replaced the static 10-dot asset with VerdictStrip. It shows the trader's settled receipts in store order, keeps the last 10, takes each dot's colour from its receipt, and is labelled 'Last N verdicts'. It hides itself when there are none. As the adjudicator advised, settled is decided through Scenario.outcomeAt (F11's clock rule), so the strip's N always equals the header's Settled. Deleted VistaAssets.verdictsLast10; the svg file stays. `verdicts` is now a RegExp, the pair asserts 'Last 3 verdicts', and there is a new strip order/cap/open-exclusion test.

**Test:** `app/test/trader_record_test.dart: the verdicts strip shows the trader's last 10 settled calls, oldest to newest, and no open call` (`:278`); `app/test/trader_record_test.dart: both traders' panels show the same sample size, hit rate and as-of time below the index chart` (`:237`, `Last 3 verdicts`).

Red output, verbatim from the writer:

```text
test/trader_record_test.dart:292:25: Error: Undefined name 'VerdictStrip'.
  Compilation failed for testPath=/home/alex/VistaColosseum/.worktrees/br-2026-10-04-p0-queue/app/test/trader_record_test.dart: test/trader_record_test.dart:292:25: Error: Undefined name 'VerdictStrip'.
00:00 +0 -1: Some tests failed.
```

### F6 LOW — The 'rounded half up' test cannot tell half-up from ceiling or from a double-based .round()

**Location:** app/test/trader_record_test.dart:145-171 (code app/lib/scenario/scenario.dart:171) at c2b1566. Now: `app/lib/scenario/scenario.dart:178` unchanged (`(right * 100 + settled ~/ 2) ~/ settled`); the fix is test-only.

Every hit rate the suite asserts has a fractional part of 0 or at least .5: 1/8 = 12.5, 2/3 = 66.7, 1/2 = 50. Ceiling `(right*100 + settled-1) ~/ settled` gives 13, 67 and 50. `(right*100/settled).round()` gives 13, 67 and 50 too, and it puts a double back on the display path. Both stay green. With ceiling, 1 right of 3 would show 34% instead of 33%.

**Fix asked for:** Add a case below .5, for example 1 right and 2 wrong expecting hitRatePct 33.

**Applied:** Added the 1-right-of-3 case, expecting hitRatePct 33. Mutation-proven: with scenario.dart's hit rate changed to the ceiling form `(right * 100 + settled - 1) ~/ settled`, the old test file passed (00:03 +10: All tests passed!). The new assertion failed on the same mutation. The mutation was then reverted and the file passed (+10).

**Test:** `app/test/trader_record_test.dart: the hit rate is an integer percent rounded half up, read from the call receipts and the clock at the time of asking` (`:156`, assertion at `:190`).

Red output, verbatim from the writer:

```text
[mutation: ceiling rounding, old tests] 00:03 +10: (tearDownAll)
00:03 +10: All tests passed!
[same mutation, new assertion]
  Expected: <33>
    Actual: <34>
  test/trader_record_test.dart 177:5                  main.<fn>
00:03 +9 -1: Some tests failed.
```

### F7 LOW — Test title says the caption is 'above the index chart', but it renders below and nothing checks the order (known F5)

**Location:** app/test/trader_record_test.dart:174-175 at c2b1566. Now: `profile_screen.dart` `_record()` unchanged (`:288`); the fix is test-only.

ProfileScreen._record() builds _market(), which holds ProfileIndexChart, first and TraderRecordPanel after it (profile_screen.dart:235-241). So the caption is under the chart, and the test only checks that both exist.

**Fix asked for:** Rename the test to '... with the index chart', or assert the vertical order with getRect.

**Applied:** Retitled the test to say 'below the index chart' and added the check panel.top >= chart.bottom. Mutation-proven: with _record's children swapped (panel above _market()), the pre-F7 file passed (00:04 +17: All tests passed!). The new check failed on that mutation. The mutation was reverted and the file passed (+17).

**Test:** `app/test/trader_record_test.dart: both traders' panels show the same sample size, hit rate and as-of time below the index chart` (`:237`).

Red output, verbatim from the writer:

```text
[mutation: panel above chart, pre-F7 test] 00:04 +17: All tests passed!
[same mutation, new test]
Expected: a value greater than or equal to <657.0>
  Actual: <401.0>
   Which: is not a value greater than or equal to <657.0>
  file:///home/alex/VistaColosseum/.worktrees/br-2026-10-04-p0-queue/app/test/trader_record_test.dart line 247
00:04 +16 -1: Some tests failed.
```

### F8 LOW — Profile CALLS section is an empty heading for traders with no receipts

**Location:** app/lib/features/market/receipt_screens.dart:181-203 (used at app/lib/features/profile/profile_screen.dart:304) at c2b1566. Now: `app/lib/features/profile/profile_screen.dart:352-377`: `_calls()` listens on `Scenario.callReceipts` and returns `SizedBox.shrink()` when the trader has no receipts.

Opening a profile for kaito.eth, 0xreal or deltaone (feed callerHandles) or mirin/renatafx/0xreal (Arena sides) shows 'CALLS · All receipts' with nothing under it, because CallRecordList returns an empty Column. ReceiptsScreen already has an empty line ('No call receipts for $author in ...', receipt_screens.dart:288); the new list does not. Correction to the filing: maya.eth is not in this set. It is PortfolioMock.handle and has 3 seeded receipts.

**Fix asked for:** When no receipt matches the author, have CallRecordList render the same empty line ReceiptsScreen uses.

**Applied:** Profile _calls now listens to callReceipts and hides the CALLS heading and list when the trader has no receipts. No empty-state widget was built. New test: kaito.eth has no CALLS heading, with lunaq as the positive control. The profile leg of receipts_test moved from kaito.eth to kestrel.

**Test:** `app/test/trader_record_test.dart: a trader with no call receipts gets no CALLS heading` (`:387`); `app/test/receipts_test.dart: every All receipts link opens the receipts list` (`:436`, profile leg now kestrel at `:451`).

Red output, verbatim from the writer:

```text
Expected: no matching candidates
  Actual: _TextWidgetFinder:<Found 1 widget with text "CALLS": [
   Which: means one was found but none were expected
  file:///home/alex/VistaColosseum/.worktrees/br-2026-10-04-p0-queue/app/test/trader_record_test.dart line 387
00:00 +0 -1: Some tests failed.
```

### F9 LOW — Zero-history trader: Profile hides the index chart, but the trader-market route still draws the market price chart that this diff's own doc calls the index (known F11)

**Location:** app/lib/features/market/trader_market_screen.dart:62-66 at c2b1566. Now: Doc comments at `app/lib/features/profile/profile_screen.dart:286-287` (`_record`) and `:380-382` (`ProfileIndexChart`). The trader-market chart is unchanged: the manager ruled it is the market's price series and stays.

Lunaq's feed card at mock_trade_idea.dart:276 has ticker 'kestrel' with traderMarket true; its Details button, or the Profile 'Market' stat, opens TraderMarketScreen('kestrel'). That screen draws TraderMarketChart. Swipe to Record and the panel says 'No settled calls yet — record unavailable' under the chart. The diff's ProfileIndexChart doc says 'the trader's illustrative index (their market's price) chart', so the spec's 'no index chart' holds on Profile only.

**Fix asked for:** Gate the chart on Scenario.record(handle).settled > 0 with a placeholder, or reword the ProfileIndexChart doc if the market chart is deliberately not the index.

**Applied:** Corrected the _record and ProfileIndexChart doc comments. The index chart is no longer equated with the market price chart, and the docs say the trader-market route's chart plots the market's price series.

**Test:** none named; the adjudicator's testProof reads "n/a - doc comments only; nothing executable changes (flutter analyze clean in a scratch copy)." Writer: "n/a - doc comments only; flutter analyze clean".

### F10 LOW — Zero-history profile keeps 'Record since Jun 2026 · 14 mo' beside 'record unavailable' (known F9)

**Location:** app/lib/features/profile/profile_screen.dart:140-143 at c2b1566. Now: `app/lib/features/profile/profile_screen.dart:193-211`; `ProfileMock.recordSince` deleted.

kestrel's profile shows ProfileMock.recordSince above a panel that says 'No settled calls yet — record unavailable'. The zero-history state is new in this diff.

**Fix asked for:** Hide the recordSince line when Scenario.record(handle).settled == 0.

**Applied:** 'Record since' now comes from the entryAt of the trader's first receipt and is hidden when there are none; its gap moved into a Padding. Deleted ProfileMock.recordSince. New test covers kilo.sol ('Record since Sep 8') and kaito.eth (no line).

**Test:** `app/test/trader_record_test.dart: Record since dates from the trader's first call, and a trader with no calls has no Record since line` (`:462`).

Red output, verbatim from the writer:

```text
Expected: exactly one matching candidate
  Actual: _TextWidgetFinder:<Found 0 widgets with text "Record since Sep 8": []>
   Which: means none were found but one was expected
  file:///home/alex/VistaColosseum/.worktrees/br-2026-10-04-p0-queue/app/test/trader_record_test.dart line 455
00:00 +0 -1: Some tests failed.
```

### F11 LOW — Your market's panel says 'as of 26 Sep 14:45' but counts maya-eth-4000-oct2, a call dated Oct 2 and settled Wrong

**Location:** app/lib/features/market/market_mock.dart:163-170 (copy at app/lib/features/market/receipt_screens.dart:225-230) at c2b1566. Now: `app/lib/scenario/scenario.dart:188-201` (`Scenario.outcomeAt`), used by `record()` (`:160`) and `VerdictStrip`; `monthAbbrs` made public in `app/lib/charting/time_marks.dart:53`; `CallReceipt` doc at `app/lib/features/market/market_mock.dart:41-44`.

Scenario.clock seeds to TradeMock.chartEnd = 2026-09-26 14:45. record() counts every receipt, so 'based on 2 settled calls · as of 26 Sep 14:45' includes a verdict on 'ETH reaches $4,000 by Oct 2' (entryAt 'Oct 2'). That verdict could not exist yet at the stated as-of time. The fixture dates from phase 6; the as-of claim is new here.

**Fix asked for:** Re-date that fixture to settle before Sep 26, or make it open.

**Applied:** Scenario.record now counts each receipt by its outcome at the clock. A verdict settled after the clock is open. A verdict with no settlement date, or a date not in the 'Sep 12' form, is unavailable. Month parsing reuses time_marks' list, renamed to the public monthAbbrs. To merge with F5, the helper was made public as `Scenario.outcomeAt` instead of `_outcomeAt`, so VerdictStrip goes through the same rule. The CallReceipt doc is updated. The maya 50% line is removed, the synthetic `call` helper now carries settledAt 'Sep 20', and there is a new clock-gate test.

**Test:** `app/test/trader_record_test.dart: a call settled after the clock is open at the clock; a verdict with no settlement date is unavailable` (`:196`).

Red output, verbatim from the writer:

```text
  Expected: ({DateTime asOf, Null hitRatePct, int open, int right, int settled, int unavailable, int wrong}):<(asOf: 2026-09-26 14:45:00.000, hitRatePct: null, open: 1, right: 0, settled: 0, unavailable: 2, wrong: 0)>
    Actual: ({DateTime asOf, int hitRatePct, int open, int right, int settled, int unavailable, int wrong}):<(asOf: 2026-09-26 14:45:00.000, hitRatePct: 50, open: 1, right: 1, settled: 2, unavailable: 0, wrong: 1)>
  test/trader_record_test.dart 191:5                  main.<fn>
00:04 +10 -1: Some tests failed.
```

### F12 LOW — Retiring the old record lists left VistaReceipt, VistaVersus and the record/arena rail asset constants unreferenced

**Location:** app/lib/design_system/components/vista_profile.dart:161-170; app/lib/design_system/vista_assets.dart:71-75,106-108 at c2b1566. Now: Deleted from `vista_profile.dart` and `vista_assets.dart`. A grep of `app/lib` and `app/test` at 229ab63 for `VistaReceipt`, `VistaVersus`, `railCall`, `railArena`, `railRecord` and `opponentAvatar` finds nothing.

Nothing breaks at runtime. These are dead design-system symbols whose last callers this diff removed (profile_screen, trader_market_screen, private_profile_screen).

**Fix asked for:** Delete them, or keep them on purpose for Figma parity and say so.

**Applied:** Deleted VistaVersus and VistaReceipt, plus the now-unused vista_icon import. Deleted the railCall*, railArena* and railRecord* constants, and opponentAvatarLong/Short, which were dead with VistaVersus. The svg files stay, and flutter analyze is clean.

**Test:** none named; the adjudicator's testProof reads "n/a - dead-code deletion; nothing executable that any path reaches changes. The proof is `flutter analyze` (the gate's flutter-analyze step) staying clean, which fails if any remaining file referenced a deleted symbol or if the unused vista_icon import were left behind. Verified clean in a scratch copy." Writer: "n/a - dead-code deletion; proof is flutter analyze clean".

## What the fixes now reject

Three adjudicator `rejectsValidInput` answers are not none: F7, F8 and F11. F2 answered none, but its answer names a visible change, so it is quoted too. The other eight (F1, F3, F4, F5, F6, F9, F10, F12) answered none; F5 and F10 add caveats that no seeded input reaches.

**F11**, verbatim:

> Settled receipts whose settledAt is null or not in the 'Mon d' form no longer count as settled. The record now shows them as unavailable. That covers maya-sol-300-fri, maya-eth-4000-oct2 and nara-btc-66k-tue in the seed. The weekday form is valid input by the fixture's own documentation: market_mock.dart:41-42 says settledAt is written 'as the fixture states them ("Thu 14:32")'. That doc is the producing procedure, so this fix updates it to say the record reads only the 'Sep 12' form. YourMarketMock's doc at market_mock.dart:149-151 ('The record states no entry prices or settlement times') explains why maya's verdicts have no date. Fixture dates are read in the clock's year, so a December date against a January clock would be misplaced. No seed crosses a year.

Document check: the producing procedure was the `CallReceipt` doc at `market_mock.dart:41-42` (at c2b1566), which said entry and settlement times are written "as the fixture states them ("Thu 14:32")". The fix commit rewrote that doc in the same change (now `app/lib/features/market/market_mock.dart:41-44`): the record reads a settlement time in the "Sep 12" form only, and a verdict whose settlement time is missing or in another form counts as unavailable. `YourMarketMock`'s doc (`market_mock.dart:150-152`) says maya.eth's record states no settlement times. Spec 06 (`docs/specs/06-fee-ledger-and-receipts.md:11`) lists `settledAt` with no format and says a missing field renders "unavailable". No document left in the tree teaches a human to write a settled verdict without a "Sep 12" date and expect it counted.

**F2**, verbatim:

> None. Checked:
> - VistaBattleSide.accuracy goes from required to defaulting to '', so every existing constructor call still compiles. The only one outside the fixture is the home_screen_test.dart:985-986 reuse of `ArenaMock.battles.first.bull/bear`, which is unaffected.
> - `withCrowd` has exactly one caller (arena_screen.dart:146-147), and it is rewritten. grep finds no other.
> - No test asserts any of the removed strings, the BTC opinion subtitles or the '80%' badge (grep of app/test for accuracy, streak, 'sniper of charts' and 80% finds none).
>
> One visible display change: BTC opinions now end in ' · no record yet'. That is a display change only, and maxLines 1 with ellipsis in VistaSideDetail keeps it from overflowing. No document tells a human to produce a stored accuracy string. Spec 07 and PRD VC-MKT-002 require it to be derived.

Document check: none. Spec 07 ("Derive record metrics from unit-06 `CallReceipt`s per trader") and PRD VC-MKT-002 require the figure to be derived. No document tells a human to write a stored accuracy string.

**F8**, verbatim:

> One previously valid path is removed. On a profile with no call receipts, the user could tap 'All receipts ›' and land on ReceiptsScreen's 'No call receipts for <handle> in fixture-v1' line. receipts_test.dart:436 'every All receipts link opens the receipts list' (lines 449-455) is the document that teaches and exercises that path. The edit below updates it: the profile leg now uses kestrel, a trader with receipts, and the empty-list case stays covered from the trader market, where the link remains. No spec or doc prose describes the profile path; rule 13 is the decision.

Document check: the one teaching document was the test `app/test/receipts_test.dart: every All receipts link opens the receipts list` (`:436`), which walked a no-receipts profile into the empty receipts list. The fix moved its profile leg to kestrel (`:451`), and the empty list stays reachable and covered from kaito.eth's trader market later in the same test (`:463-472`, `No call receipts for kaito.eth in fixture-v1`). No spec or doc prose describes the profile path.

**F7**, verbatim:

> Pins the current layout: panel below the index chart on Profile. Spec 07 does not fix the order ("Panel copy: ... Reuse the existing profile/record widgets"), so a deliberate future move of the panel above the chart would need this assertion changed. No document instructs producing that layout today.

Document check: none. Spec 07 says only "Reuse the existing profile/record widgets" and fixes no order. No document instructs the panel-above-chart layout.

Nothing in the fixer run executed a rejected input. A grep of `app/test` at 229ab63 for `Hit rate 50`, `based on 2 settled` and `settled: 2` finds nothing, so no test still expects maya.eth's undated verdicts to count as settled. The new F11 test feeds undated and late verdicts on purpose and asserts unavailable and open. No test opens "All receipts ›" from a profile with no receipts (the F8 test asserts it is absent on kaito.eth), no test places the panel above the chart, and no test asserts a stored accuracy string. All of it passes in the close gate.

## Refuted: 3

- **Share-card record is a per-handle hash that contradicts the derived record** Skeptic: "share_call_card.dart is not in this diff. docs/specs/00-baton-queue.md row 7 lists the share preview as a declared VC-FED-003 residual, and the filing itself calls it carry-forward. Out of scope for phase 7."

- **Markets Traders rows hard-code call and open counts that disagree with the receipts** Skeptic: "markets_mock.dart is not in this diff and its rows are unchanged. Before this diff the trader-market chip was a single TraderMarketMock.openCalls constant for every trader, so the rows and the chip already disagreed. This diff did not create the mismatch. It is pre-existing and belongs with the F1 fix-shape decision, not with this phase."

- **Private profile shows 'Illustrative index' copy for an account that has no market or index** Skeptic: "Spec 07 mandates the panel copy 'Illustrative index · based on N settled calls · as of <clock>' with no private-account exemption. The premise that no index exists is not established either: the feed opens TraderMarketScreen('nara') from kilo.sol's trader-market card (mock_trade_idea.dart:324, ticker 'nara', traderMarket true). The real issue is a pre-existing fixture contradiction (private notice versus a nara market), not this diff's copy."

## Checked claims that were wrong: 0

The skeptic spot-checked the lanes' "verified as correct" claims against the tree, and they held. Its `checkedClaimsThatAreWrong` list is empty.

## Residual risk (verbatim)

- No mutation was run by me: I stayed read-only and created no mutated copy. Survival claims rest on an exhaustive grep of test assertions plus the prior reviewer's mutate-run logs for the mutants it recorded. (tautology-hunt)
- Unchanged widgets the AC3 tests reach (home_screen.dart feed link, arena_screen.dart onCaller, VistaBattleCard side-to-handle mapping) were read only far enough to confirm the tap reaches ProfileScreen.route(handle). (tautology-hunt)
- scenario_test.dart reset-snapshot comparison logic beyond the mutateEverything list (lines 35-80). (tautology-hunt)
- Behaviour at text scale 1.3 on the Your market and private-profile panels; covered only by the probe, not by me. (tautology-hunt)
- Did not run flutter test or the gate. Relied on the stated gate pass at c2b1566 (274 tests, plus HAS_MARKET) and read the code instead. (metrics-single-source, wiring-ux)
- Did not check pixel layout or the 30 px simulation-pill clearance myself. The iter-1 probe logs report it; I did not re-run them. (metrics-single-source)
- Did not review the Arena card's tap target wiring (arena_screen.dart) or the feed card link beyond the test that exercises them. (metrics-single-source)
- Opinion hitRate '80%' on @bitcoinninja (opinions_mock.dart:93) is a handle with no receipts. I did not judge whether it should read 'no record'. (metrics-single-source)
- TraderMarketScreen header '_openCalls' chip and ProfileScreen._record listen to callReceipts only via rebuilds. Today only reset writes callReceipts, and reset pops every route, so I could not build a concrete stale-render path. (wiring-ux)
- Did not measure on-device pixel positions myself. The below-the-fold landing at 360x640/375x667 (iter1 F6) is a claim I did not re-verify. (wiring-ux)
- Metric arithmetic, capital-independence and reset exactness belong to the data lane. I checked them only where they feed the panel display. (wiring-ux)
- Markets Traders rows and the share card's synthesized records (iter1 F7/F8) are outside my lane files and I did not re-verify them. (wiring-ux)

## Verification after the fixes

finding-fixer verification (`scripts/gate.sh baton-runner/br-2026-10-04-p0-queue/gate-phase-7-fixer/`), verbatim:

```text
=== gate: flutter-analyze: flutter analyze ===
PASS flutter-analyze
=== gate: flutter-test: flutter test ===
PASS flutter-test
=== gate: pubspec-frozen: git diff --exit-code c95349cc2a9a40be16d4bddee74c512129ac0114 -- pubspec.yaml pubspec.lock ===
PASS pubspec-frozen
----
GATE: PASS
```

Full gate after commit (`baton-runner/br-2026-10-04-p0-queue/gate-phase-7-close/`: `gate-stdout.log` `GATE: PASS` / `exit=0`, `flutter-test.log` `+282: All tests passed!`, `flutter-analyze.log` `No issues found!`, `has-market-tail.log` `00:40 +282: All tests passed!`). The closing unit re-ran one file at 229ab63: `cd app && flutter test test/trader_record_test.dart --reporter expanded` → `00:03 +17: All tests passed!`, exit 0 (`baton-runner/br-2026-10-04-p0-queue/close-phase-7/trader-record-test-expanded.log`).

GATE: PASS exit 0 at 229ab63, 282 tests, HAS_MARKET=true 282
