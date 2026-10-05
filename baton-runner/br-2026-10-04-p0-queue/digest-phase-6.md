# Phase 6 digest: fee ledger and call receipts (spec 06) — APPROVE at 30e54c0 (dw-review 12 confirmed, 12 applied; gate PASS 265, HAS_MARKET 265)

## Public surface
- `FeeEntry{id, marketId, eventTitle, amountCents (int), at (DateTime)}` (`market_mock.dart:84`). Seed `YourMarketMock.fees`: 5 MAYA credits, 1240+860+1016+640+524 = 4280 cents, chartEnd −3h…−4d, newest first. `creatorSharePct = 40`, `shareLabel = '40% share is a demo assumption'`.
- `CallReceipt{id, author, asset, side?, entryPrice? (fixed-decimal String), entryAt?/settledAt? (fixture labels), rule?, result? (CallOutcome), odds?, provenance = Scenario.fixtureVersion}` (`market_mock.dart:17`); replaces `RecordEntry`. `const unavailable = 'unavailable'` (`:11`). Seed `YourMarketMock.record` = maya.eth's 3 calls (SOL $300 Right, ETH $4,000 Oct 2 Wrong, ETH $4,000 Oct 10 Open).
- `Scenario.feeEntries`, `Scenario.callReceipts` (ValueNotifiers; initializer + `reset()` + `state()` + `mutateEverything()`).
- `Scenario.listedAt` (`ValueNotifier<DateTime?>`, `scenario.dart:41`), the listing instant: `AccountState.listMarket` sets it to `Scenario.clock`; the `HAS_MARKET` seed is `YourMarketMock.listedAt` (chartEnd − 7 days); null while unlisted.
- `Scenario.marketFees` (`:118`): credits with `marketId == Scenario.marketId` and `at >= listedAt`, `[]` while unlisted. `marketFeesCents` (`:128`) folds them in int cents. A fresh listing shows $0.00 until a credit lands; `HAS_MARKET` shows $42.80.
- `LedgerScreen()` + `.route()` (`receipt_screens.dart`): "Illustrative demo ledger · 40% share is a demo assumption", rows (event, `MAYA · <when>`, amount), footer `Total` = `formatCents(marketFeesCents)`, empty `No fee credits yet`.
- `LedgerScreen.example(FeeEntry)`: fee = credit ÷ 40% in int cents, rounded half up `(amountCents*100 + pct~/2) ~/ pct`; the result printed is the listed credit itself, never recomputed.
- `ReceiptsScreen({author})` + `.route(author)`: CALL RECEIPTS (that author's calls), then PAPER ORDER RECEIPTS (`OrderReceipt`s) only for `PortfolioMock.handle`. Empty: `No call receipts for <author> in fixture-v1`, `No paper orders yet`.
- `CallReceiptScreen({receipt})` + `.route` + `.forHolding(author, Holding)`: the author's OPEN call on the same asset AND side, else an unavailable receipt (`id: 'none'`, header "No open call in fixture-v1 backs this holding"). Every field shown; a missing one reads "unavailable". `CallRecordItem({receipt})` is the tappable timeline entry. `HoldingsTable.onRowTap` is `ValueChanged<Holding>?`.
- Wired: All receipts ×3 (`your_market_screen:116`, `profile_screen:274`, `trader_market_screen:294`); Call details ×2 (`profile_screen:95`, `trader_market_screen:279`); Wallet row and Your-market chip show `marketFeesCents` and open the ledger.

## Decisions 07 trader record and 08 empty states must honour
- **CF-1 is phase 7's first job:** wire the Profile CALLS list and the trader-market Record panel items to per-trader `CallReceipt`s. Rebuild both from `Scenario.callReceipts` by author, render each call with `CallRecordItem`, retire the sample calls in `TraderMarketMock.record` / `ProfileMock.receipts` (arena items in CALLS are not calls), and add an item-tap test for a non-user trader. Spec 07 names no such test.
- Record metrics come from `Scenario.callReceipts` per author: right/wrong = settled, open = unsettled, null result = unavailable (exclude). No size field, and paper fills are `OrderReceipt`s, so size-independence holds by construction.
- New traders' calls: concatenate fixture lists into the `callReceipts` seed; `reset()` assigns the same object (seed test checks `same`). An open call seeded for a trader makes their Call details resolve with no UI change. Keep the open-only rule.
- Never render an `OrderReceipt` as a call; the paper section stays on the user's own list.
- Fee totals are folds over `marketFees` via `formatCents`; never store a total. 40% copy uses `creatorSharePct` / `shareLabel`.
- The ledger, Wallet row and chip listen on `[feeEntries, marketId]`, not `listedAt`. Every writer today also sets `marketId`; a new writer of `listedAt` alone must join the listeners.
- The 40%-label test recomputes the seed's fee by truncation; keep the newest seeded credit even-cent or switch that test to half-up.
- Spec 08: restyle, don't duplicate, the empty states above. New screens use the private `_page` shell (footer `safe + VistaSpace.xxl`). Direct-copy credits (VC-MKT-004 S08) need a `FeeEntry` kind; none exists.

## Open / carried
- Phase 3 F1 MEDIUM, OPEN, user's design call: pill tap target 30px < 44. Do not fix inside another phase.
- LiveFeed drift after reset (phase 1 M, phase 2 L-5): open; `resetDemo` is where the rebase goes.
- Phase 4: the Change↔Funding chip-label order in `ArenaMock.sorts` is unpinned.
- Phase 5: the Maker "Trade this" ticket prices at the live mark (`MarketPrices.now`), not the suggestion's reference price (author call vs VC-ORD-001).
- Phase 6: Your market `recordSummary` is static (phase 7); trader-market "All receipts ›" keeps a bare 14px tap target; fixture dates (ETH Oct 2 settled on a 26 Sep clock; SOL $300 Right while SOL marks $214.90); receipt `id` not shown (iter-1 L3); other traders' empty "All receipts" beside a sample panel (iter-1 L5, ends with CF-1).

Records: `docs/reviews/2026-10-04-dw-review-phase-6-fee-ledger-and-receipts.md`, `review-phase-6-dw.json`, `fixer-phase-6.json`, `baton-pass/br-2026-10-04-p0-queue/2026-10-05T050809-phase6-close.md`.
