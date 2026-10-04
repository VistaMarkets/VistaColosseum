# 06: Fee ledger and call receipts

## Rules for this unit

Common rules for every unit: original lightweight code (CONTEXT.md), no new pub dependencies, money as `int` minor units or fixed-decimal strings (never new `double` money), every success message describes something that actually happened, keep the existing "— not in the demo yet" toast for anything you don't build. Run `scripts/gate.sh <log-dir>` before returning; it must print `GATE: PASS`. Every acceptance criterion names its test as `app/test/<file>.dart: <test name>` or is marked `manual, waived`; add the tests the spec names.

**PRD:** VC-MKT-004, VC-REC-001, VC-LST-002 (40% label), VC-FED-003 (Call details). **Gap:** fees are the constant `$42.80` (`portfolio_mock.dart:74`, `market_mock.dart:52`); "All receipts" is not-built ×3.

## Behavior
- `FeeEntry {id, marketId, eventTitle, amountCents, at}` seeded in `Scenario` (4–6 entries). The Wallet "Fees from your market" row and Your-market "earned in fees this week" both show `sum(entries)`; tapping opens a Ledger screen listing entries, each naming its demo market/event, with the sum as footer and the line "Illustrative demo ledger · 40% share is a demo assumption" plus one worked example (fee × 40%). The listing flow line "You earn 40% of the fees from both" (`make_market_flow.dart:627`) gets the same demo-assumption label (VC-LST-002).
- `CallReceipt {id, author, asset, side, entryPrice, entryAt, rule, result, settledAt, provenance: 'fixture-v1'}` seeded from the existing record entries in `market_mock.dart:65-77`. Record lists resolve to these. Receipt detail screen shows all fields; a missing field renders "unavailable".
- Paper order receipts (unit 02) are a separate type and screen section; never shown as calls.
- Wire the three "All receipts" call sites to the receipts list, and the two "Call details" row taps (`profile_screen.dart:93`, `trader_market_screen.dart:275`) to the receipt of the call that backs the holding, or to an "unavailable" receipt when the fixture names none (VC-FED-003).

## Acceptance
- [ ] Ledger total equals the sum of listed entries (test).
- [ ] Every record item and both "Call details" rows open a receipt. Test: `app/test/receipts_test.dart: 'each record item opens its call receipt'`. Order receipts and call receipts are separate types and separate list sections. Test: `app/test/receipts_test.dart: 'order receipts and call receipts render in separate sections'`. Visual distinctness: manual, waived.
- [ ] `cd app && grep -rn "_notBuilt('All receipts')" lib` returns nothing (3 call sites today). Unit-scoped check run by the review unit, not by `scripts/gate.sh` (it fails on the tree before this unit).
