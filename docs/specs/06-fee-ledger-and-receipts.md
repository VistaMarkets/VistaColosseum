# 06: Fee ledger and call receipts

## Rules for this unit

Common rules for every unit: original lightweight code (CONTEXT.md), no new pub dependencies, money as `int` minor units or fixed-decimal strings (never new `double` money), every success message describes something that actually happened, keep the existing "— not in the demo yet" toast for anything you don't build. Run `scripts/gate.sh <log-dir>` before returning; it must print `GATE: PASS`. Every acceptance criterion names its test as `app/test/<file>.dart: <test name>` or is marked `manual, waived`; add the tests the spec names.

**PRD:** VC-MKT-004, VC-REC-001, VC-FED-003 (Call details). **Decisions (October 4):** O-05 — economic copy follows the video, so the 40% share is shown with a worked example and no demo-assumption label; O-06 — the ledger must carry a separately typed copy row that unit 09 writes to. **Gap:** fees are the constant `$42.80` (`portfolio_mock.dart:74`, `market_mock.dart:52`); "All receipts" is not-built ×3.

## Behavior
- `FeeEntry {id, kind: marketFee | copyFee, marketId?, eventTitle, amountCents, at, sourceCallId?, counterparty?}` seeded in `Scenario`: 4–6 `marketFee` entries and 1–2 `copyFee` entries (fixture copier handle, `amountCents: 500`, matching unit 09's `kCopyFeeCents`). The Wallet "Fees from your market" row and Your-market "earned in fees this week" show `sum(marketFee entries)`. Tapping opens a Ledger screen with two sections, "Market fees" and "Copy fees", each entry naming its demo market/event or source call and counterparty; footer shows the market-fee sum, the copy-fee sum and the total. Under the market section, one worked example of the video's 40% share (fee × 40%) with no demo-assumption label (O-05). Leave the listing flow line "You earn 40% of the fees from both" (`make_market_flow.dart:627`) as it is.
- `CallReceipt {id, author, asset, side, entryPrice, entryAt, rule, result, settledAt, provenance: 'fixture-v1'}` seeded from the existing record entries in `market_mock.dart:65-77`. Record lists resolve to these. Receipt detail screen shows all fields; a missing field renders "unavailable".
- Paper order receipts (unit 02) are a separate type and screen section; never shown as calls.
- Wire the three "All receipts" call sites to the receipts list, and the two "Call details" row taps (`profile_screen.dart:93`, `trader_market_screen.dart:275`) to the receipt of the call that backs the holding, or to an "unavailable" receipt when the fixture names none (VC-FED-003).

## Acceptance
- [ ] Ledger footer: market-fee sum equals the sum of `marketFee` rows, copy-fee sum equals the sum of `copyFee` rows, total equals both; the Wallet row equals the market-fee sum. Test: `app/test/receipts_test.dart: 'ledger sums by kind and Wallet row shows market fees only'`.
- [ ] A `copyFee` entry appended at runtime (as unit 09 will do) appears in the copy section and in the totals without a restart. Test: `app/test/receipts_test.dart: 'appended copy fee shows in ledger and totals'`.
- [ ] Every record item and both "Call details" rows open a receipt. Test: `app/test/receipts_test.dart: 'each record item opens its call receipt'`. Order receipts and call receipts are separate types and separate list sections. Test: `app/test/receipts_test.dart: 'order receipts and call receipts render in separate sections'`. Visual distinctness: manual, waived.
- [ ] `cd app && grep -rn "_notBuilt('All receipts')" lib` returns nothing (3 call sites today). Unit-scoped check run by the review unit, not by `scripts/gate.sh` (it fails on the tree before this unit).
