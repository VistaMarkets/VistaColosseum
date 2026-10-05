---
source: baton-runner work unit, phase 6 of 8 (docs/specs/06-fee-ledger-and-receipts.md)
scope: br-2026-10-04-p0-queue
parent_session: 2026-10-05T040742-phase6-fee-ledger-checkpoint.md
status: COMPLETE: all 3 acceptance items green; gate PASS (261), HAS_MARKET=true 261/261, All-receipts grep empty; uncommitted
---

# Phase 6: fee ledger and call receipts

Branch `feat/br-2026-10-04-p0-queue/phase-6`, worktree `.worktrees/br-2026-10-04-p0-queue`, all changes uncommitted.
Logs: `baton-runner/br-2026-10-04-p0-queue/phase-6-red/` (RED, GREEN, mutants), `.../gate-phase-6-work/` (gate, HAS_MARKET run, grep).

## Criteria and evidence (all tests in `app/test/receipts_test.dart`)
RED-1 (`red-1-compile.log`), before any lib code: compile fails, `Error when reading 'lib/features/market/receipt_screens.dart'`,
`Type 'FeeEntry' not found`, `Type 'CallReceipt' not found`, `Member not found: 'feeEntries'` / `'callReceipts'`, `Undefined name 'LedgerScreen'`.
RED-2 (`red-2-assertions.log`), after the model layer only (types, seeds, store fields, empty screen stubs): +20 −8; every UI test failed on an assertion:

1. [x] **Ledger total equals the sum of listed entries.**
   - `ledger total equals the sum of listed entries`. RED-2: `Found 0 widgets with type "LedgerScreen"`. Green: Wallet row shows `formatCents(sum)`, opens the ledger, every entry and its amount listed, footer `Total` = sum; dropping an entry updates the ledger and the Wallet row.
   - `Your market fee chip shows the ledger sum and opens the ledger`. RED-2: `Found 0 widgets with type "LedgerScreen"`.
   - `a market with no credits shows an empty ledger and zero`. RED-2: `Bad state: No element` (chip was still the `$42.80` literal).
   - `the 40% share is labelled a demo assumption, with one worked example, in the ledger and the listing flow`. RED-2: `Found 0 widgets with text "Illustrative demo ledger · 40% share is a ..."`.
   - `the ledger total stays above the simulation pill on a small phone at 1.3x text` (360x640, `expectPillClear`). RED-2: `Found 0 widgets with text "$42.80"`.
   - Seed test `the store seeds 4-6 fee entries and the record's call receipts; reset restores both` passed at RED-2 (it drove the model; its RED was RED-1's compile failure).
2. [x] **Every record item and both Call details rows open a receipt; order and call receipts are separate types and sections.**
   - `each record item opens its call receipt`. RED-2: `Found 0 widgets with type "CallReceiptScreen"`. Covers the 3 Your-market record items, profile Call details (maya.eth ETH → her open ETH call; BTC → unavailable, 7 × "unavailable"), trader-market Call details (kaito.eth SOL and ETH → unavailable).
   - `order receipts and call receipts render in separate sections`. RED-2: `Found 0 widgets with type "ReceiptsScreen"`. Visual distinctness: manual, waived (per spec).
3. [x] **`_notBuilt('All receipts')` gone.** Before: profile_screen.dart:271, trader_market_screen.dart:288, your_market_screen.dart:112. After: `grep -rn "_notBuilt('All receipts')" lib` exits 1, no output (`gate-phase-6-work/grep-all-receipts.log` empty).
   - Behavior test `every All receipts link opens the receipts list`. RED-2: `Found 0 widgets with type "ReceiptsScreen"`.

Mutation probes (`phase-6-red/mutant-*.log`), each restored after: M1 footer shows stored `formatCents(4280)` → killed by the ledger test (and the empty-ledger test);
M2 Call details ignores author → killed by `each record item...` (assertion added for this: kaito.eth's ETH holding must not resolve to maya.eth's call);
M3 paper orders on every author's list → killed by `every All receipts link...`; M4 credits not filtered by market → killed by `a market with no credits...`.

## Final checks (run from app/)
- `flutter analyze`: No issues found.
- `flutter test`: +261, All tests passed (252 before + 9 new). `scripts/gate.sh baton-runner/br-2026-10-04-p0-queue/gate-phase-6-work`: GATE: PASS (analyze, test, pubspec-frozen).
- `flutter test --dart-define=HAS_MARKET=true`: +261, All tests passed.
- `cd app && grep -rn "_notBuilt('All receipts')" lib`: nothing.

## Files touched (12 code files)
New: `app/lib/features/market/receipt_screens.dart`, `app/test/receipts_test.dart`.
Changed: `app/lib/scenario/scenario.dart`, `app/lib/features/market/market_mock.dart`, `app/lib/features/portfolio/portfolio_mock.dart` (deleted `fees`),
`app/lib/features/portfolio/portfolio_screen.dart`, `app/lib/features/market/your_market_screen.dart`, `app/lib/features/make_market/make_market_flow.dart`,
`app/lib/features/profile/profile_screen.dart`, `app/lib/features/profile/holdings_table.dart`, `app/lib/features/market/trader_market_screen.dart`, `app/test/scenario_test.dart`.
pubspec.yaml / pubspec.lock unchanged.

## Public surface added
- `market_mock.dart`: `CallReceipt{id, author, asset, side?, entryPrice? (fixed-decimal String), entryAt? / settledAt? (fixture labels, not DateTime), rule?, result? (CallOutcome), odds?, provenance = Scenario.fixtureVersion}` with getters `status`, `color`, `rail`, `detail` (null-safe). It REPLACES `RecordEntry` (deleted).
  `FeeEntry{id, marketId, eventTitle, amountCents (int), at (DateTime)}`. `const unavailable = 'unavailable'` (the one missing-evidence string).
  `YourMarketMock.record` is now `List<CallReceipt>` (3 seeds: maya.eth SOL $300 Right, ETH $4,000 Oct 2 Wrong, ETH $4,000 Oct 10 Open; all long; no entry price or settlement time).
  `YourMarketMock.fees` (5 credits on MAYA, 1240+860+1016+640+524 = 4280 cents, chartEnd −3h…−4d, all even cents), `creatorSharePct = 40`, `shareLabel = '40% share is a demo assumption'`. `feesThisWeek` deleted.
- `Scenario.feeEntries` (`ValueNotifier<List<FeeEntry>>`), `Scenario.callReceipts` (`ValueNotifier<List<CallReceipt>>`), both with initializer + `reset()` line + `state()` + `mutateEverything()`.
  `Scenario.marketFees` (credits whose `marketId == Scenario.marketId.value`), `Scenario.marketFeesCents` (their fold). Listen on `Listenable.merge([feeEntries, marketId])`.
- `receipt_screens.dart`: `LedgerScreen()` + `.route()` + `static example(FeeEntry)`; `ReceiptsScreen({author})` + `.route(author)`; `CallReceiptScreen({receipt})` + `.route(receipt)` + `.forHolding(author, Holding)`; `CallRecordItem({receipt})` (tappable timeline entry).
- `HoldingsTable.onRowTap` is now `ValueChanged<Holding>?` (was `VoidCallback?`).

## Decisions phases 07-08 must honour
- Phase 7 derives record metrics from `Scenario.callReceipts` filtered by `author`. Settled = `result` right/wrong; `open` is unsettled; `null` is unavailable (exclude). CallReceipt has no size field and paper fills are `OrderReceipt`s in `Scenario.receipts`, so size-independence holds by construction.
- New traders' calls: add a fixture list and seed `callReceipts` from the concatenation; `reset()` must assign the same seed object (the seed test checks `same(...)`). `YourMarketMock.record` stays the user's own (Your market lists `author == PortfolioMock.handle`).
- Call details resolve through `CallReceiptScreen.forHolding`: the author's OPEN call on the holding's asset and side, else an unavailable receipt (`id: 'none'`, text `No call in fixture-v1 backs this holding`). Seeding an open call for a trader makes their rows resolve with no UI change.
- `ReceiptsScreen(author)` lists only that author's calls; the paper-order section appears only for `PortfolioMock.handle`. Never render an `OrderReceipt` as a call.
- Empty states already present (phase 8 may restyle, not duplicate): `No call receipts for <author> in fixture-v1`, `No paper orders yet`, `No fee credits yet`.
- Any 40% copy uses `YourMarketMock.creatorSharePct` / `shareLabel`. Fee totals are folds over `marketFees`, shown via `formatCents`; never store a total.
- New screens use the private `_page` shell: list padded `safe + gutter`, footer padded `safe + VistaSpace.xxl` (the 14px gap above the strip, phase 3 F1 note).

## Remaining / for the reviewer
- Scope reading (reviewer judgment): "every record item" = the record seeded from `market_mock.dart` (Your market). Profile CALLS (`ProfileMock.receipts`) and the trader-market Record panel (`TraderMarketMock.record`) items are still not tappable: they show the same sample for every handle, and they conflict with the seed (`SOL reaches $300 by Fri` is Right in YourMarketMock, Open "2d left" in the other two). Phase 7's per-trader record panel is the natural owner. Their "All receipts" links ARE wired.
- Your market `recordSummary` ('62 settled · 36 right · 26 wrong · 9 open') is still static: phase 7.
- Pre-existing fixture dates untouched: "ETH reaches $4,000 by Oct 2" is settled while the clock is Sat 26 Sep 2026; "SOL reaches $300" is Right while SOL marks $214.90.
- VC-MKT-004's direct-copy credits (S08) are out of scope; `FeeEntry` has no kind field yet.
- Import cycle `scenario.dart` ↔ `market_mock.dart` (for the provenance default); legal in Dart, analyzer clean.
- Trader-market "All receipts ›" keeps its pre-existing small tap target (bare 14px text). Phase 3 F1 (pill tap target) still open; not touched.
- `_page` uses the null-aware list element `?footer` (Dart 3.8+); the project's SDK accepts it (analyze clean).
- No new dependencies needed.

## Next
Review unit: dw-review of the phase-6 diff against `docs/specs/06-fee-ledger-and-receipts.md`, then commit on `feat/br-2026-10-04-p0-queue/phase-6`.
