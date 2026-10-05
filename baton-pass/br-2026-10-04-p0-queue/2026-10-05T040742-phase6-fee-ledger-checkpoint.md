---
source: baton-runner work unit, phase 6 of 8 (docs/specs/06-fee-ledger-and-receipts.md)
scope: br-2026-10-04-p0-queue
parent_session: 2026-10-04T205139-phase5-close.md
status: IN PROGRESS: RED recorded for every acceptance item; model layer (types, seeds, store fields) written; screens are empty stubs
---

# Phase 6 checkpoint: RED tests in place, model layer green

Branch `feat/br-2026-10-04-p0-queue/phase-6`, uncommitted. Raw logs: `baton-runner/br-2026-10-04-p0-queue/phase-6-red/`.

## RED evidence
- RED-1 (`red-1-compile.log`), `flutter test test/receipts_test.dart test/scenario_test.dart` before any lib code: compile fails,
  `Error when reading 'lib/features/market/receipt_screens.dart'`, `Type 'FeeEntry' not found`, `Type 'CallReceipt' not found`,
  `Member not found: 'feeEntries'`, `Member not found: 'callReceipts'`, `Undefined name 'LedgerScreen'`, `Undefined name 'CallReceiptScreen'`.
- RED-2 (`red-2-assertions.log`), after only the model (types, seeds, `Scenario.feeEntries/callReceipts`, empty screen stubs): +20 −8.
  Seed/reset test and all of scenario_test pass (round-trip covers the two new fields). Failures:
  - AC1 `ledger total equals the sum of listed entries`: `Found 0 widgets with type "LedgerScreen"` (Wallet fees row opens nothing).
  - AC1 `Your market fee chip shows the ledger sum and opens the ledger`: `Found 0 widgets with type "LedgerScreen"`.
  - AC1 `a market with no credits shows an empty ledger and zero`: `Bad state: No element` (no `$0.00` chip: still the `$42.80` literal).
  - AC1 `the 40% share is labelled a demo assumption, ...`: `Found 0 widgets with text "Illustrative demo ledger · 40% share is a ..."`.
  - AC1 `the ledger total stays above the simulation pill ...`: `Found 0 widgets with text "$42.80"`.
  - AC2 `each record item opens its call receipt`: `Found 0 widgets with type "CallReceiptScreen"`.
  - AC2 `order receipts and call receipts render in separate sections`: `Found 0 widgets with type "ReceiptsScreen"`.
  - AC3 `every All receipts link opens the receipts list`: `Found 0 widgets with type "ReceiptsScreen"`.
- AC3 grep before the unit: `_notBuilt('All receipts')` at profile_screen.dart:271, trader_market_screen.dart:288, your_market_screen.dart:112.

## Decisions so far
- `CallReceipt` replaces `RecordEntry` in `market_mock.dart` (YourMarketMock.record is now `List<CallReceipt>`, the seed); `FeeEntry` and the 5-entry `YourMarketMock.fees` seed (sum 4280 = the old $42.80) live there too.
- Nullable fields render `unavailable`; the record states no entry price or settlement time, so those stay null (not invented).
- `Scenario.marketFees` filters credits by `marketId`: a market listed under another ticker has no credits.
- Call details: backing call = the profile owner's open call on the holding's asset and side; none → unavailable receipt.

## Next
Build LedgerScreen / ReceiptsScreen / CallReceiptScreen in `lib/features/market/receipt_screens.dart`; wire Wallet row, Your-market chip + record items + All receipts, profile/trader-market All receipts + Call details (HoldingsTable passes the Holding), make-market 40% label; delete `YourMarketMock.feesThisWeek` and `PortfolioMock.fees`.
