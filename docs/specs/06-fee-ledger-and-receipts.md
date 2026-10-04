# 06 — Fee ledger and call receipts

**PRD:** VC-MKT-004, VC-REC-001. **Gap:** fees are the constant `$42.80` (`portfolio_mock.dart:74`, `market_mock.dart:52`); "All receipts" is not-built ×3.

## Behavior
- `FeeEntry {id, marketId, eventTitle, amountCents, at}` seeded in `Scenario` (4–6 entries). The Wallet "Fees from your market" row and Your-market "earned in fees this week" both show `sum(entries)`; tapping opens a Ledger screen listing entries, each naming its demo market/event, with the sum as footer and the line "Illustrative demo ledger · 40% share is a demo assumption" plus one worked example (fee × 40%).
- `CallReceipt {id, author, asset, side, entryPrice, entryAt, rule, result, settledAt, provenance: 'fixture-v1'}` seeded from the existing record entries in `market_mock.dart:65-77`. Record lists resolve to these. Receipt detail screen shows all fields; a missing field renders "unavailable".
- Paper order receipts (unit 02) are a separate type and screen section; never shown as calls.
- Wire the three "All receipts" call sites to the receipts list.

## Acceptance
- [ ] Ledger total equals the sum of listed entries (test).
- [ ] Every record item opens a receipt; order receipts and call receipts are visually and type-distinct.
- [ ] No "All receipts — not in the demo yet" remains.
