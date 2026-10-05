---
source: baton-runner work unit, phase 7 of 8 (docs/specs/07-trader-record-panel.md), resumed after an interrupted unit
scope: br-2026-10-04-p0-queue
parent_session: 2026-10-05T050809-phase6-close.md
status: IN PROGRESS: inherited diff assessed (all 11 files kept; 2 tests to finish); 2 of 274 tests red at start
---

# Phase 7 checkpoint: inherited diff assessed

Branch `feat/br-2026-10-04-p0-queue/phase-7`, worktree `.worktrees/br-2026-10-04-p0-queue`, all changes uncommitted.
The previous unit left 11 modified app files, an untracked `app/test/trader_record_test.dart` and RED logs in
`baton-runner/br-2026-10-04-p0-queue/phase-7-red/` (`01-compile-red.log`, `02-assertions-red.log`), but no baton.
`baton-runner/.../log.md` also shows a manager-written RESUME line; not mine, left alone.

## Tree at start of this unit
- `flutter analyze`: `No issues found!`
- `flutter test`: `+272 -2: Some tests failed.`
  - `trader_record_test.dart: the record panel renders without overflow at 1.3x on every phone, its last call clear of the pill`:
    `Bad state: No element` from `scrollUntilVisible`. Cause (probed): `pumpApp` re-pumps the same widget type per phone, so
    the ListView keeps the previous phone's scroll offset (bottom); `scrollUntilVisible` only scrolls down, and the caption
    above is never built. A test bug, not a product bug.
  - `receipts_test.dart: each record item opens its call receipt`: `Expected: exactly 2 ... Found 3 widgets with text "unavailable"`.
    Cause: the new `Paper size` receipt row reads "unavailable" on maya.eth's calls (no size in her fixture). Expected
    change from the new field; the count must move to open ? 2 : 3.

## Assessment of the inherited diff (per file)
| File | Verdict | Why |
|---|---|---|
| `lib/scenario/scenario.dart` | KEEP | `RecordMetrics` typedef + `Scenario.record(author)`: counts right/wrong/open from `callReceipts`, null result excluded, `hitRatePct = (right*100 + settled~/2) ~/ settled` (int half-up), null when nothing settled, `asOf = clock.value`. Doc comment states it never reads size. Seed/reset now `seedCalls`. Matches spec + digest 6 rules. |
| `lib/features/market/market_mock.dart` | KEEP | `CallReceipt.sizeCents` (int?, the paper size behind a call); `traderCalls`: kilo.sol + lunaq same outcomes call for call (R, W, R, open) at different sizes, kestrel one open call, nara's 4 graded calls (were the private-profile sample); `seedCalls` = user's record + traderCalls. Dropped static `YourMarketMock.recordSummary` (digest 6 carried it to phase 7). |
| `lib/features/market/receipt_screens.dart` | KEEP | `CallRecordList(author)` (per-author `CallRecordItem`s from the store) and `TraderRecordPanel(handle)` (caption "Illustrative index · based on N settled calls · as of <clock>", counts, `Hit rate N%`; zero settled → "No settled calls yet — record unavailable"). Receipt gains a `Paper size` row (every field shown, phase-6 rule). Tokens only. |
| `lib/features/market/trader_market_mock.dart` | KEEP | Retires the generic `record`/`recordSummary`/`openCalls` sample (CF-1). |
| `lib/features/market/trader_market_screen.dart` | KEEP | Record panel = `TraderRecordPanel` + `CallRecordList` for `widget.handle`; "N open calls" chip derived from `Scenario.record`. |
| `lib/features/market/your_market_screen.dart` | KEEP | Static summary → `TraderRecordPanel`; inline list → `CallRecordList` (same spacing, `VistaSpace.xl`). |
| `lib/features/profile/profile_mock.dart` | KEEP | Retires hard-coded `settled '62'`/`right '36'` (the spec's Gap), the shared `receipts` sample (calls AND the arena items) and its `All 65/Calls 51/Arena 14` filter counts; `PrivateProfile` keeps followers + bio only. Decision flagged below. |
| `lib/features/profile/profile_screen.dart` | KEEP, tidy | Settled/Right stats from `Scenario.record`; the market header + chart (`ProfileIndexChart`, was private `_ProfileChart`) render only when settled > 0, then `TraderRecordPanel`; CALLS = `CallRecordList`; verdicts icon hidden with nothing settled. One over-long doc-comment line to reflow. |
| `lib/features/profile/private_profile_screen.dart` | KEEP | nara's stats and calls from her receipts. |
| `test/home_screen_test.dart` | KEEP | The old Arena-filter assertions targeted the retired sample; now asserts lunaq's own last call and that the sample is gone. |
| `test/receipts_test.dart` | FINISH | Unavailable count +1 for the `Paper size` row. |
| `test/trader_record_test.dart` (untracked) | FINISH | Spec-named tests present with exact names; fix the scroll carry-over in `pumpApp`; add the verdict-icon assertion. |

## Decision flagged for review
- Arena receipts on profiles are retired with the call sample. They were the same Figma sample under every handle (on lunaq's
  own profile one read "took the other side of lunaq"), no store holds per-trader arena receipts, and CF-1 says "arena items
  in CALLS are not calls". The All/Calls/Arena filter counted that sample, so it goes too. Rebuilding arena receipts per
  trader would need a new fixture type no spec asks for.

## Next
Finish the two tests, mutation-prove the metrics tests, then the full gate (`flutter analyze`, `flutter test`,
`flutter test --dart-define=HAS_MARKET=true`) and the final baton.
