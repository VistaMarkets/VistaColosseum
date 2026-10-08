# M3 verification record: market and Wallet consistency

Milestone M3 from `docs/prd/2026-10-01-vc-hackathon-roadmap.md` (S04 and VC-REC-001). VC-MKT-003 is a P0 row of S04, so it is recorded here too, though the roadmap places its exit in M5 (`roadmap.md:32`, beside VC-ARN-004); M5's own record re-runs those rows at M5's revision. VC-MKT-002, -003, -004 and VC-REC-001 are built by units 02, 06 and 07. VC-MKT-001 has no spec yet; its rows record what the pre-existing screens do. Evidence is the widget and unit tests plus code reading at the revision below. No device run was made for this record.

Code paths are under `app/lib/`. Test names are as `flutter test` prints them (group, then test), in `app/test/<file>`. Each PRD ID is split into the checks its acceptance text names; one row per check.

| Field | Value |
|---|---|
| Build / revision | 7d39bffaa1e1e594dfccb6f39359b9d9038df4e7 (`main` 7d39bff; `app/` is identical to `main` 7a153be, `git diff 7a153be 7d39bff -- app` is empty) |
| Fixture version | `fixture-v1` (`scenario/scenario.dart:37`) |
| Target | `flutter test` headless widget tests, Flutter 3.47.5, Linux (WSL2) host. Not the iOS Simulator |
| Run date and start time | 2026-10-05, before 11:12-07:00 (PDT). The start time of the `flutter test` run (289 passed) was not recorded; 11:12 is the commit time of 137dae3, an upper bound |
| Flags | none |
| Test run | `cd app && flutter test`: **289 passed, 0 failed, 0 skipped** |
| Evidence | The tests named below; code citations as `file:line` |

## PRD IDs exercised

| ID | Check | Outcome | Evidence |
|---|---|---|---|
| VC-MKT-001 | Own-market access shows a market series and settled-call examples | passed | `features/market/your_market_screen.dart:62-64,118-120`. `home_screen_test.dart` "your market opens from Portfolio and goes back" ("Market cap"); "your market renders without overflow on $name" (last record entry reachable); `receipts_test.dart` "each record item opens its call receipt" |
| VC-MKT-001 | Own-market access shows creator identity | not run | Code: header subtitle `'${PortfolioMock.handle} · your market'` (`your_market_screen.dart:46`). No test asserts it. To prove: open Your market and assert `find.text('maya.eth · your market')` |
| VC-MKT-001 | Wallet switches between the portfolio series and the market series; switching back restores the right one | passed | `features/portfolio/portfolio_pager.dart:135-344`. `home_screen_test.dart` "portfolio pager swiping the chart moves to the market cap and back"; "portfolio pager a short drag snaps back to where it started" |
| VC-MKT-001 | Each series has a distinct title, unit and legend | not run | Code: captions "My portfolio" and "$TICKER market cap" (`portfolio_pager.dart:167,181`); the muted line behind each chart has no legend. No test asserts title, unit and legend per page. To prove: on each pager page assert the caption, the value's unit and a legend naming the muted series |
| VC-MKT-001 | Values stay arithmetically consistent across every screen that shows them | failed | Code inspection: the cap is a constant $44.0M (`portfolio_pager.dart:63,183`, `your_market_screen.dart:152`) whatever is listed, while the listing success screen says $10,000 (`features/make_market/make_market_mock.dart:27`). The M1 recording shows the same mismatch at ~0:40. See Defects |
| VC-MKT-002 | Two traders with the same outcomes and different paper sizes get the same record | passed | `Scenario.record` reads outcomes only (`scenario/scenario.dart:150-186`); fixture pair `features/market/market_mock.dart:188-294`. `trader_record_test.dart` "two traders, same outcomes, different sizes → equal metrics"; "both traders' panels show the same sample size, hit rate and as-of time below the index chart" |
| VC-MKT-002 | Sample count and as-of time are shown | passed | `features/market/receipt_screens.dart:230-260`. Same panel test; "a mounted panel follows the demo clock"; "the hit rate is an integer percent rounded half up, read from the call receipts and the clock at the time of asking" |
| VC-MKT-002 | Zero settled calls shows unavailable or insufficient history | passed | `receipt_screens.dart:212,221-228`. `trader_record_test.dart` "zero-history trader → unavailable state, no crash"; "a call settled after the clock is open at the clock; a verdict with no settlement date is unavailable" |
| VC-MKT-003 | Wallet shows paper cash, positions and an open-orders view | passed | `features/portfolio/portfolio_screen.dart:66-108`. `scenario_test.dart` "Home, detail, Arena and Wallet read one position from Scenario"; "Wallet lists the positions held in Scenario"; `home_screen_test.dart` "open orders cards show the order details; Cancel removes, Undo restores" |
| VC-MKT-003 | A confirmed order adds exactly one position and debits cash consistently | passed | `Scenario.placeOrder` (`scenario/scenario.dart:272-358`). `scenario_test.dart` "placeOrder rounds once and review, receipt and Wallet totals reconcile"; "placeOrder with a repeated actionId returns the first result"; `order_ticket_test.dart` "double tap confirm places one position"; "feed ticket confirm adds a position and View in Wallet shows it" |
| VC-MKT-003 | Cancellation changes nothing | passed | `order_ticket_test.dart` "cancel from review leaves the store unchanged"; "feed ticket cancel from review leaves the store unchanged" |
| VC-MKT-003 | At least two chart ranges show their fixture windows | passed | `home_screen_test.dart` "make a market the span drives the portfolio chart and its change" (24h and 1W) |
| VC-MKT-003 | Seeded open orders, or an honest empty state | passed | `home_screen_test.dart` "open orders cards show the order details; Cancel removes, Undo restores"; `empty_states_test.dart` "every core list renders an emptied scenario without overflow or exception on $name at 1.3x" ("No open orders") |
| VC-MKT-003 | Deposit and withdraw entries explain the demo boundary and imply no funding | not run | Code: Deposit toasts "Deposit (simulated) — not in the demo yet" (`features/account/account_top_bar.dart:61-64`, `app_shell.dart:65-68`); there is no Withdraw entry. To prove: tap Deposit, assert that toast and that `Scenario.cashCents` is unchanged |
| VC-MKT-004 | Inspectable fee ledger, separate from trading P&L; each credit names its market and event | passed | `LedgerScreen` (`receipt_screens.dart:58-180`), seed `market_mock.dart:132-149`. `receipts_test.dart` "ledger total equals the sum of listed entries" |
| VC-MKT-004 | Total equals the ledger sum; Wallet and Your market rows show the same sum | passed | `Scenario.marketFeesCents` (`scenario/scenario.dart:137-148`). `receipts_test.dart` "ledger total equals the sum of listed entries"; "Your market fee chip shows the ledger sum and opens the ledger"; "a fresh listing earns nothing until a credit lands after it; the HAS_MARKET seed counts its week; reset restores both"; "a market with no credits shows an empty ledger and zero" |
| VC-MKT-004 | The video's 40% creator share with one consistent worked example | passed | `LedgerScreen.example` (`receipt_screens.dart:67`). `receipts_test.dart` "the 40% share is labelled a demo assumption, with one worked example, in the ledger and the listing flow"; "the worked example prints the listed credit for an odd-cent entry". The "demo assumption" label contradicts spec 06; see Defects |
| VC-MKT-004 | Copy credits appear in the same ledger as a separately typed row | failed | Code inspection: `FeeEntry` has no kind (`market_mock.dart:91-109`) and `LedgerScreen` has no copy section. Spec 06 names `receipts_test.dart` "ledger sums by kind and Wallet row shows market fees only" and "appended copy fee shows in ledger and totals"; neither test exists. Spec 09, which writes copy credits, is unbuilt |
| VC-REC-001 | Seeded call receipts carry author, asset, direction, entry and time, rule, result and time, provenance | passed | `CallReceipt` (`market_mock.dart:17-87`), seed `:151-355`, held in `Scenario.callReceipts` (`scenario/scenario.dart:104`). `receipts_test.dart` "the store seeds 4-6 fee entries and the record's call receipts; reset restores both"; "each record item opens its call receipt" |
| VC-REC-001 | Record panels resolve to these receipts | passed | `receipts_test.dart` "the record and receipts lists read the call receipt store"; `trader_record_test.dart` "Profile CALLS lists the trader's own call receipts and each opens its receipt"; "the trader-market Record panel lists the trader's call receipts and an item opens its receipt" |
| VC-REC-001 | A saved call is not labelled a fill; paper order receipts stay separate | passed | `ReceiptsScreen` sections (`receipt_screens.dart:268-340`). `receipts_test.dart` "order receipts and call receipts render in separate sections"; "every All receipts link opens the receipts list" |
| VC-REC-001 | Missing evidence is marked unavailable | passed | `receipt_screens.dart:350-437`. `receipts_test.dart` "each record item opens its call receipt"; `trader_record_test.dart` "a call with no outcome shows in the panel as unavailable, never dropped" |

## Roadmap exit criteria

| Criterion | Outcome | Evidence |
|---|---|---|
| J2 ends in the listed creator's market | passed | `home_screen_test.dart` "make a market create → consent → live lists the market"; `scenario_test.dart` "Home, detail, Arena and Wallet read one position from Scenario" opens Your market for the listed ticker. The route is what this criterion names and the tests prove it; the cap figure on that page is the VC-MKT-001 consistency failure recorded above, not a J2 routing failure |
| Chart and portfolio switching works | passed | "portfolio pager swiping the chart moves to the market cap and back" |
| Sample-count and receipt explanation supports J5 on the fixture traders | passed | VC-MKT-002 and VC-REC-001 rows |
| Sample-count and receipt explanation supports J5 on the user's own market | failed | Code inspection: maya.eth's panel says "No settled calls yet — record unavailable · 2 unavailable" above Right and Wrong items for the same calls (`receipt_screens.dart:221-228`, `market_mock.dart:154-174`, `scenario/scenario.dart:193-205`). No test renders it. See Defects |
| Fee total equals the demo ledger | passed | VC-MKT-004 total row |
| Index, P&L and cash have distinct labels and units | not run | No test asserts the three side by side. To prove: on Wallet assert the cash headline, the market-cap caption and a position's P&L each carry their own label and unit |
| Insufficient-history example is honest | passed | "zero-history trader → unavailable state, no crash" |

## Defects observed

| row or step | class | fix commit or open | follow-up |
|---|---|---|---|
| VC-MKT-001 (consistent values): the market cap is one constant; Wallet and Your market show $44.0M for any listed ticker (`features/portfolio/portfolio_pager.dart:63,183`, `features/market/your_market_screen.dart:152`) while the success screen of a fresh listing says $10,000 (`features/make_market/make_market_mock.dart:27`); this is the M1 recording defect, and VC-MKT-001 requires consistent values | misrepresents a financial action | f12f982, 5a72ba6 for the success step, Wallet and Your market (spec 12, db0573f); open on five out-of-set screens and further surfaces that still show maya.eth's market at $44.0M / $0.4400 (re-verified in `2026-10-07-m2-m4-reverification.md`) | none |
| VC-MKT-002 (J5 exit criterion): the user's own record contradicts itself; Your market shows "No settled calls yet — record unavailable · 2 unavailable" (`receipt_screens.dart:221-228`) above "Right" and "Wrong" items for the same calls, because the seed gives maya.eth's settled calls no settlement date (`market_mock.dart:154-174`) and `Scenario.outcomeAt` counts them unavailable (`scenario/scenario.dart:193-205`); code inspection, no test renders maya.eth's panel | cosmetic | f12f982, 5a72ba6 (re-verified in `2026-10-07-m2-m4-reverification.md`) | none |
| VC-MKT-004 (copy credits): no typed copy row in the ledger; `FeeEntry` lacks the `kind` that spec 06 (as amended Oct 4 for O-06) requires, and the two tests spec 06 names are missing; phase 6 was built before that amendment (`baton-runner/br-2026-10-04-p0-queue/digest-phase-6.md:23`) and spec 09 depends on it. After this build, a5eb544bbdc1542a69562719499bba52621ba9e3 on `main` added `FeeKind` and a copy section, but the two named tests still do not exist | cosmetic | open | none |
| VC-MKT-004 (40% share): the share is labelled "a demo assumption" (`market_mock.dart:123-126`, shown at `receipt_screens.dart:87` and `make_market_flow.dart:637`); spec 06 says to show it with no demo-assumption label (O-05), and the test pins the old wording | cosmetic | f12f982, 5a72ba6 (re-verified in `2026-10-07-m2-m4-reverification.md`) | none |
| VC-MKT-003 (deposit and withdraw): Deposit is a not-built toast and there is no Withdraw entry; truthful, but untested | cosmetic | open | none |

## Verdict

**M3 not exited.** Records, receipts, the fee ledger total, order consistency and the insufficient-history state are proven by tests. Two checks fail on code inspection: the market cap disagrees across screens for a fresh listing, and the ledger has no typed copy row. Two checks and one exit criterion have code but no test. The own-market record contradiction should be fixed before J5 is recorded.
