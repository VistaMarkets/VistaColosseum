---
source: baton-runner work unit, phase 7 of 8 (docs/specs/07-trader-record-panel.md), resumed after an interrupted unit
scope: br-2026-10-04-p0-queue
parent_session: 2026-10-05T053614-phase7-trader-record-checkpoint.md
status: COMPLETE: criteria 3/3 + CF-1 green; gate PASS (274), HAS_MARKET=true 274/274; 9/9 mutants killed; uncommitted
---

# Phase 7: trader record panel (capital-independent metrics) + CF-1

Branch `feat/br-2026-10-04-p0-queue/phase-7`, worktree `.worktrees/br-2026-10-04-p0-queue`, all changes uncommitted.
Logs: `baton-runner/br-2026-10-04-p0-queue/phase-7-red/` (`01-compile-red.log`, `02-assertions-red.log` from the
interrupted unit; `03-mutants.log` from this one), `baton-runner/br-2026-10-04-p0-queue/gate-phase-7-work/` (gate logs +
`has-market.log`). `baton-runner/.../log.md` carries a manager RESUME line I did not write.

## Inherited diff: verdict per file
All 11 inherited app files KEPT; none backed out. Full reasoning per file is in the parent checkpoint.
- KEPT as-is: `lib/scenario/scenario.dart`, `lib/features/market/market_mock.dart`, `lib/features/market/receipt_screens.dart`,
  `lib/features/market/trader_market_mock.dart`, `lib/features/market/your_market_screen.dart`,
  `lib/features/profile/profile_mock.dart`, `lib/features/profile/private_profile_screen.dart`, `test/home_screen_test.dart`.
- FINISHED:
  - `lib/features/profile/profile_screen.dart`: reflowed the over-long `ProfileIndexChart` doc comment.
  - `lib/features/market/trader_market_screen.dart`: moved the added `scenario.dart` import into order.
  - `test/receipts_test.dart`: the new `Paper size` receipt row reads "unavailable" on maya.eth's calls (no size in her
    fixture). Counts go open ? 1 : 2 → 2 : 3 and 7 → 8 on the unavailable receipt, plus an explicit `Paper size` row check.
  - `test/trader_record_test.dart` (untracked, inherited): `pumpApp` now pumps an empty tree first. The 1.3x test failed
    with `Bad state: No element` because each phone re-pumped the same screen with the previous phone's scroll offset at
    the bottom, and `scrollUntilVisible` only scrolls down (a test bug, probed). Added `Last 10 verdicts` assertions (shown
    for the pair, absent for kestrel) and the trader-market Record panel to the 1.3x loop.

## Acceptance criteria (tests in `app/test/trader_record_test.dart`)
| # | Criterion | Status | Evidence |
|---|---|---|---|
| AC1 | Two traders, same outcomes, different sizes → equal metrics | MET | `two traders, same outcomes, different sizes → equal metrics` (:109). Asserts the outcomes match call for call, every size is stated, sizes differ, a size-weighted share WOULD differ, and `Scenario.record(kilo.sol) == Scenario.record(lunaq) == (settled 3, right 2, wrong 1, open 1, hitRatePct 67, asOf clock)`. RED (02 log): `Expected: non-empty  Actual: []` (no trader fixtures). Mutants `record-weights-size`, `hit-rate-truncates`, `as-of-wall-clock` KILLED. UI side: `both traders' panels show the same sample size, hit rate and as-of time above the index chart` (:174); RED (02): `Found 0 widgets with text "Illustrative index · based on 3 settled calls · as of 26 Sep 14:45"`. |
| AC2 | Zero-history trader → unavailable state, no crash | MET | `zero-history trader → unavailable state, no crash` (:186): kestrel (one open call) at 1.3x on all 5 phones shows `No settled calls yet — record unavailable`, no `ProfileIndexChart`, no `Last 10 verdicts`, no "Illustrative index"/"Hit rate"; no exception; the open call is listed clear of the pill; the trader-market Record panel says the same. RED (02): `Expected: non-empty  Actual: []` at :185 (no kestrel calls). Mutants `zero-history-rate-0`, `zero-history-shows-chart`, `verdicts-always` KILLED. |
| AC3 | Trader link from feed card and Arena card lands on the panel | MET | `feed card trader link opens the record panel` (:309) and `Arena card trader link opens the record panel` (:323), names exact. RED (02): both `Found 0 widgets with text "Illustrative index · based on 3 settled calls · as of 26 Sep 14:45"` (the links already opened `ProfileScreen`; the panel was missing). Mutant `profile-panel-wrong-handle` KILLED both. Links are pre-existing: `home_screen.dart:111` and `arena_screen.dart:153` → `ProfileScreen.route(handle)`. |

Also pinned: `the hit rate is an integer percent rounded half up, read from the call receipts and the clock at the time of asking` (:145): 1/8 → 13 (truncation gives 12), open and null-result calls excluded, as-of follows a moved clock, nothing settled → `hitRatePct` null. Its only RED was compile-only (01: `Member not found: 'Scenario.record'`); mutation-proven by `hit-rate-truncates` and `as-of-wall-clock`.
`the record panel renders without overflow at 1.3x on every phone, its last call clear of the pill` (:223): Profile and trader-market Record panel, 5 phones, `expectPillClear` on the last `CallRecordItem`.

## CF-1 (from phase 6): DONE
- Profile CALLS, the trader-market Record panel, Your market's RECORD and the private profile all render
  `CallRecordList(author)` = that author's `Scenario.callReceipts` as `CallRecordItem`s, each opening its `CallReceiptScreen`.
- Generic samples retired: `TraderMarketMock.record/recordSummary/openCalls` + `RecordCall`; `ProfileMock.settled/right/summary/receipts/filters` + `ProfileReceipt`/`ReceiptKind`; `PrivateProfile` sample stats/calls; `YourMarketMock.recordSummary` (the digest-6 "static recordSummary" item).
- Non-user item-tap tests: `Profile CALLS lists the trader's own call receipts and each opens its receipt` (:257, lunaq, every item, receipt shows rule, author, status, paper size) and `the trader-market Record panel lists the trader's call receipts and an item opens its receipt` (:286, kilo.sol). RED (02): sample `SOL loses $190 by Sep 15` still present / caption missing. Mutants `list-ignores-author`, `trader-market-list-wrong-author` KILLED.

## Verification (this unit, final tree)
- `scripts/gate.sh baton-runner/br-2026-10-04-p0-queue/gate-phase-7-work` → `GATE: PASS`, exit 0: `flutter analyze` `No issues found!`; `flutter test` `00:40 +274: All tests passed!`; pubspec-frozen PASS.
- `cd app && flutter test --dart-define=HAS_MARKET=true` → `00:41 +274: All tests passed!`, exit 0 (`gate-phase-7-work/has-market.log`).
- Mutants (`phase-7-red/03-mutants.log`, harness restores and byte-checks each file): 9/9 KILLED, 0 compile errors.
- House-rule grep over added lib lines: no `double`, `toDouble(`, `toStringAsFixed`, `Color(0x`, raw `Colors.`, `fontSize`, `TextStyle(`, persona/advance, `DateTime.now`, `_notBuilt`. pubspec.yaml/.lock unchanged.

## Files touched (phase 7 total, inherited + this unit)
`app/lib/scenario/scenario.dart`, `app/lib/features/market/{market_mock,receipt_screens,trader_market_mock,trader_market_screen,your_market_screen}.dart`,
`app/lib/features/profile/{profile_mock,profile_screen,private_profile_screen}.dart`, `app/test/{home_screen_test,receipts_test,trader_record_test}.dart`.

## Public surface added
- `typedef RecordMetrics = ({int settled, int right, int wrong, int open, int? hitRatePct, DateTime asOf})` (`scenario.dart:16`).
- `Scenario.record(String author) → RecordMetrics` (`scenario.dart:150`): derived from `callReceipts` at call time; right/wrong = settled, open = unsettled, null result = unavailable (excluded); `hitRatePct = (right*100 + settled~/2) ~/ settled` (int half-up), null when settled == 0; `asOf = clock.value`. Doc comment states it never reads size.
- `CallReceipt.sizeCents` (`int?`, `market_mock.dart:57`): the paper trade behind a call, shown as `Paper size` on the receipt (`receipt_screens.dart:375`), never read by the record.
- `traderCalls` (`market_mock.dart:190`): kilo.sol and lunaq (R, W, R, open, call for call; sizes $500/$1,200/$800/$500 vs $40,000/$90,000/$1,000/$25,000), kestrel (one open BTC call), nara (2 open, 1 right, 1 wrong; no sizes). `seedCalls` (`:350`) = `YourMarketMock.record` + `traderCalls`, the `callReceipts` seed and reset value.
- `CallRecordList({author})` (`receipt_screens.dart:181`), `TraderRecordPanel({handle})` + `TraderRecordPanel.unavailableNote` (`:207`). Panel listens on `[callReceipts, clock]`; copy `Illustrative index · based on N settled call(s) · as of <d MMM HH:mm>`, then `N settled · R right · W wrong · O open · Hit rate P%`.
- `ProfileIndexChart` (`profile_screen.dart:313`, was private `_ProfileChart`). Profile `_record()` (`:229`) shows the market header + chart only when settled > 0, then the panel.

## Decisions phase 08 must honour
- Record metrics are only ever `Scenario.record(handle)`; never store a count or rate. A trader with calls but none settled has NO record (null rate, unavailable note, no index chart, no verdicts icon), never "0%".
- Spec 08 empty states: restyle, don't duplicate, `TraderRecordPanel.unavailableNote`. `CallRecordList` renders nothing for an author with no calls (e.g. kaito.eth); the profile CALLS head then sits over an empty list. That empty state is phase 8's to add.
- Profile arena receipts and the All/Calls/Arena filter are retired with the generic sample (no per-trader arena-receipt store; CF-1: "arena items in CALLS are not calls"). Re-adding them needs a new fixture type and a spec.
- New traders' calls go into `traderCalls`; `reset()` keeps `same(seedCalls)` (receipts_test:118). Keep kilo.sol/lunaq outcomes identical and sizes different, or AC1's test fails by design.
- Size-independence holds by construction: paper fills stay `OrderReceipt`s, and `record()` reads only `author` and `result`.

## Remaining / for the manager (none blocks spec 07)
- Arena sides hard-code `71% accuracy` (kilo.sol) and `77% accuracy` (lunaq) (`arena_mock.dart:143,151`) beside the names the AC3 tests tap, while both derived records are 67%. Not in spec 07's acceptance; deriving them is a follow-up (VC-MKT-002 consistency). Feed cards carry no accuracy constant (grep of `mock_trade_idea.dart`/`home_screen.dart` for accuracy/rate: none).
- The `Last 10 verdicts` icon is a static Figma vector (10 verdicts) shown for any trader with ≥1 settled call; only zero-history hides it. `ProfileMock.recordSince` ("Record since Jun 2026 · 14 mo") and the market header/price are still the shared sample.
- The trader-market screen keeps its price chart for kestrel: that is the market, not the record panel's index chart.
- `TraderMarketScreen._openCalls` reads `Scenario.record` at build without listening to `callReceipts`; only reset changes that list, and reset pops to root. LOW.
- Copy pluralises: "1 settled call". No seeded trader has exactly 1.
- Not checked: landscape, tablets. Nara's private profile has no dedicated test (shares the tested widgets).

## Next
Manager: review unit / dw-review on the phase-7 tree, then close. No new dependency needed.
