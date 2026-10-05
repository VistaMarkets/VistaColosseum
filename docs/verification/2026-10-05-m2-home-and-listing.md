# M2 verification record: Home and creator-listing journeys

Milestone M2 from `docs/prd/2026-10-01-vc-hackathon-roadmap.md` (S02 and S03). This is the O-08 coverage record for VC-FED-001/002 and VC-LST-001/003/004, which pre-date the plan and have no unit spec, plus the spec-backed VC-FED-003/004 and VC-LST-002. Evidence is the widget and unit tests plus code reading at the revision below. No device run was made for this record; the iOS Simulator run is M1's.

Code paths are under `app/lib/`. Test names are as `flutter test` prints them (group, then test), in `app/test/<file>`. Each PRD ID is split into the checks its acceptance text names; one row per check.

| Field | Value |
|---|---|
| Build / revision | `chore/m2-m4-verification-records` @ 7d39bff; `app/` is identical to `main` 7a153be (`git diff 7a153be HEAD -- app` is empty) |
| Fixture version | `fixture-v1` (`scenario/scenario.dart:37`) |
| Target | `flutter test` headless widget tests, Flutter 3.47.5, Linux (WSL2) host. Not the iOS Simulator |
| Run date | 2026-10-05 |
| Test run | `cd app && flutter test`: **289 passed, 0 failed, 0 skipped** |
| Evidence | The tests named below; code citations as `file:line` |

## PRD IDs exercised

| ID | Check | Outcome | Evidence |
|---|---|---|---|
| VC-FED-001 | At least three seeded calls spanning long and short and two or more traders | passed | 12 calls, long and short, 8 callers (`features/home/mock_trade_idea.dart:97-339`). `home_screen_test.dart` "markets everywhere the feed has one call on every market Explore offers" pins the set |
| VC-FED-001 | Card shows author, asset, direction, current mark and change | passed | `features/home/trade_idea_card.dart:105-290`. `home_screen_test.dart` "share call Share opens the sheet with what the recipient will see" (kaito.eth, ETH, long, +5.97%); "replay moves the header price with the chart, events get haptics, and it lands on the live figures" (mark and "% since call") |
| VC-FED-001 | Card shows thesis and entry/time | not run | Code: question at `trade_idea_card.dart:186`, "Called $X · 5h ago" tag at `features/home/replay_script.dart:78,173`. No test asserts either. To prove: in `home_screen_test.dart`, find `mockTradeIdea.question` and `'Called \$2,801.10 · 5h ago'` on the first card after `pumpAndSettle` |
| VC-FED-001 | Following and discovery views contain different content | failed | Code inspection: the Following/For You switch sets `_feed` (`features/home/home_screen.dart:80-83`) but `_feedItems` (`:67`) ignores it, so both tabs show `homeFeed`. See Defects |
| VC-FED-001 | Swiping away and back does not duplicate actions or reset card state unexpectedly | not run | Likes live in `Scenario.liked` (`scenario/scenario.dart:60`), so a swipe cannot duplicate them; the replay re-traces on return by design. To prove: like card 0, swipe to card 1 and back, assert the like is still on and `Scenario.liked` has one entry |
| VC-FED-002 | Deterministic replay anchored to the call's entry price and age, with scripted activity markers | passed | `ReplayScript.generate` (`features/home/replay_script.dart:93-188`) from `callPrice` and `age`. `home_screen_test.dart` "markets everywhere generated replays are repeatable and fit the frame"; "chart replay traces on open, then holds the finished design" |
| VC-FED-002 | Restarting the replay reproduces the path | passed | `home_screen_test.dart` "chart replay replays when the next card is swiped into view"; the repeatability test above regenerates each path and compares |
| VC-FED-002 | Detail reads the same price source as the card | passed | `MarketPrices.of` in the card (`trade_idea_card.dart:197-200`) and trade page (`features/trade/asset_trade_screen.dart:189-191`). `home_screen_test.dart` "markets everywhere one ETH price on Home, Explore and the trade page" |
| VC-FED-002 | Ticket reads the same price source | not run | Code: `features/trade/feed_order_ticket.dart:70` and `features/trade/order_ticket.dart:104` read `MarketPrices.now`. To prove: move `MarketPrices.of('ETH')`, open the card's ticket, assert the review's reference price shows the moved value |
| VC-FED-002 | Missing history gives an explicit missing-data state | failed | Code inspection: every `TradeIdea` generates a script (`mock_trade_idea.dart:24-32`); no fixture lacks history and no missing-data branch exists in `signal_replay_chart.dart` or `trade_idea_card.dart` |
| VC-FED-002 | History is identified as simulated | passed | App-wide pill, not a per-card label. `home_screen_test.dart` "simulation indicator the pill shows on every tab and inside both order tickets on iPhone 14 390x844" |
| VC-FED-003 | Details opens the call's own market (asset or trader market) | passed | `home_screen.dart:126-130`. `home_screen_test.dart` "asset trade Home Details opens the asset on the Market panel"; "markets everywhere a trader-market card opens that trader market". It opens the market page, not a call view |
| VC-FED-003 | Trader link opens that trader's record panel with sample size and settled examples | passed | `trader_record_test.dart` "feed card trader link opens the record panel"; "the verdicts strip shows the trader's last 10 settled calls, oldest to newest, and no open call" |
| VC-FED-003 | Follow state is local and survives navigation | passed | `scenario_test.dart` "Follow buttons read and write the follows in Scenario" (list, then profile, agree) |
| VC-FED-003 | Like state survives section navigation | not run | Code: `features/home/likes_state.dart` forwards to `Scenario.liked`. `home_screen_test.dart` "people in Like starts as an outline and turns red when pressed" toggles in place only. To prove: like on Home, tap Explore then Home, assert the heart is still filled |
| VC-FED-003 | Sharing shows a local preview, no external post | passed | `home_screen_test.dart` "share call Share opens the sheet with what the recipient will see" |
| VC-FED-003 | Empty-following state has a way back | passed | `features/people/follow_list_screen.dart:114`. `empty_states_test.dart` "every core list renders an emptied scenario without overflow or exception on $name at 1.3x" ("Not following anyone yet"). Its action is "Explore markets", not the Home feed |
| VC-FED-003 | Unavailable-call state | passed | `features/market/receipt_screens.dart:358-370` (an "unavailable" receipt when no call backs a holding). `receipts_test.dart` "each record item opens its call receipt" (BTC holding) |
| VC-FED-004 | Attributed, advisory Maker suggestion in the feed with rationale, asset, direction, expiry and availability | passed | `features/home/maker_suggestion.dart:10-136`, placed at `home_screen.dart:16-22`. `home_screen_test.dart` "maker suggestion two are seeded on the demo clock, one live and one expired, each from Maker and between two idea cards"; "maker suggestion both cards render without overflow on $name at ${scale}x text"; "maker suggestion a card follows the demo clock, and Trade this opens the ticket on that suggestion's asset and side" |
| VC-FED-004 | An expired suggestion cannot confirm | passed | `home_screen_test.dart` "maker suggestion an expired suggestion says Expired, is disabled and opens no ticket, so nothing can be confirmed" |
| VC-FED-004 | Viewing a suggestion never creates an order | passed | `home_screen_test.dart` "maker suggestion viewing both suggestions and opening the ticket leave the store untouched" |
| VC-LST-001 | Wallet exposes market creation before listing | passed | `features/portfolio/portfolio_screen.dart:89,143`. `home_screen_test.dart` "make a market without a market Portfolio offers Make a market" |
| VC-LST-001 | Ticker suggestions and availability; a duplicate blocks Continue | passed | `features/make_market/make_market_flow.dart:49-50,360-475`, taken set `make_market_mock.dart:13-24`. `home_screen_test.dart` "make a market create → consent → live lists the market" (BTC shows "× Taken", Continue does nothing; "Use $MACRO" fixes it) |
| VC-LST-001 | Blank input blocks Continue | not run | Code: `_tickerOk` needs two or more characters (`make_market_flow.dart:50`), wired to `enabled` at `:218`. To prove: enter `''` in the ticker field, assert "2–8 letters" and that tapping Continue leaves "Before you list" absent |
| VC-LST-001 | Identity preview and short pitch; an invalid ticker preserves the other fields | not run | Code: name row and live preview card (`make_market_flow.dart:188-199,230`), pitch field with 140 limit (`:476-520`). To prove: edit the pitch, enter a taken ticker, then a valid one, assert the edited pitch is unchanged and the preview shows the ticker's initial |
| VC-LST-002 | Explanation covers both sides, public records, no own-market trading, illustrative fee share | passed | `make_market_flow.dart:526-730` ("Trading your own market · Not allowed" at `:720`; consents `make_market_mock.dart:29-33`). `home_screen_test.dart` "make a market create → consent → live lists the market" ("Your market has two sides"); `receipts_test.dart` "the 40% share is labelled a demo assumption, with one worked example, in the ledger and the listing flow" |
| VC-LST-002 | Acknowledgments start unchecked; Create is disabled until all are checked | passed | `make_market_flow.dart:32,766`. Same "create → consent → live" test: Create does nothing until all four boxes are ticked |
| VC-LST-002 | Closing returns without creating a market | not run | Code: Close on step 1 pops (`make_market_flow.dart:110`); Back on consent returns to step 1 (`:67-69,585`). To prove: open the flow, tap Close, assert `Scenario.hasMarket` is false and "Make a market" still shows |
| VC-LST-003 | Confirming creates one local market and Wallet swaps the creation entry for own-market access | passed | `features/account/account_state.dart:17-22`. `home_screen_test.dart` "make a market create → consent → live lists the market" ("Your market", "$MACRO market cap", no "Make a market") |
| VC-LST-003 | Repeated confirmation cannot create a duplicate | not run | Listing is one scalar set of values (`scenario/scenario.dart:54-57`), so a second `listMarket` rewrites the same market. Untested. To prove: tap "Create $MACRO" twice before `pumpAndSettle`, assert one listing and `listedAt` unchanged |
| VC-LST-003 | Success state links to the new market's view | failed | Code inspection: the success step offers "Make your first call" and "Share" (both toasts) and Close (`make_market_flow.dart:777-880`); no link to the market. J2 still reaches it via Close, then "Your market" |
| VC-LST-003 | Listing persists across tab changes until reset | passed | `scenario_test.dart` "Home, detail, Arena and Wallet read one position from Scenario" (ZED listed, survives Home, detail, Arena, Wallet); `home_screen_test.dart` "portfolio pager a reset that unlists the market returns to My portfolio" |
| VC-LST-004 | First-call entry is shown after success | not run | Code: "Make your first call" at `make_market_flow.dart:866-869`. No test taps or finds it. To prove: after Create, find "Make your first call" |
| VC-LST-004 | Without S07, it explains composition is outside the demo and offers a seeded call | failed | Code inspection: the button toasts "Make a call — not in the demo yet" (`make_market_flow.dart:52-56,868`) and offers no seeded call |
| VC-LST-004 | Does not claim a call was published | not run | Code: only a toast; `Scenario.callReceipts` is untouched. To prove: tap "Make your first call", assert the toast text and that `Scenario.callReceipts.value` is unchanged |

## Roadmap exit criteria

| Criterion | Outcome | Evidence |
|---|---|---|
| J1 can browse, open detail and replay | passed | VC-FED-001/002/003 rows above |
| Listing completes once and updates the Wallet entry | passed | "make a market create → consent → live lists the market". The "once" half is untested (VC-LST-003 duplicate row) |
| Duplicate ticker path is demonstrable | passed | Same test, "× Taken" |
| Blank ticker path is demonstrable | not run | VC-LST-001 blank row |
| Unchecked acknowledgment path is demonstrable | passed | Same test, Create blocked |
| First-call control truthfully routes to a fixture or optional composer | failed | Truthful toast, no fixture (VC-LST-004) |
| Maker-style content is clearly attributed and advisory | passed | VC-FED-004 rows |

## Defects observed

- **Home's Following and For You tabs show the same feed** (`features/home/home_screen.dart:67,80-83`). VC-FED-001 wants different content, and Home's "No calls to show" empty state cannot be reached in the app (carried from `baton-runner/br-2026-10-04-p0-queue/digest-phase-8.md`, P8).
- **No missing-history state for a call replay.** Every card generates a replay, so VC-FED-002's missing-data state has no fixture and no code path.
- **"Make your first call" offers no seeded call** (`make_market_flow.dart:866-869`). VC-LST-004 asks for one when S07 is out.
- **The listing success screen has no link to the new market** (`make_market_flow.dart:777-880`).
- **A fresh listing's market cap disagrees across screens.** Success says "Your market cap is $10,000" (`make_market_mock.dart:27`), then Wallet and Your market show the constant $44.0M (`features/portfolio/portfolio_pager.dart:63,183`, `features/market/your_market_screen.dart:152`). This explains the M1 recording defect at ~0:40; tracked as a VC-MKT-001 failure in the M3 record.
- **Maker "Trade this" opens the ticket at the live mark**, not the suggestion's reference price: only symbol and side are passed (`home_screen.dart:110-116`). Carried from digest P5; affects VC-ORD-001, not VC-FED-004.

## Verdict

**M2 not exited.** Maker attribution (VC-FED-004), the listing acknowledgments (VC-LST-002), the core listing path and J1 browse, detail and replay are proven by tests. Four checks fail on code inspection: identical Following/For You tabs, no missing-history state, no market link on the success screen, and no seeded call behind "Make your first call". Ten checks have code but no test; each row says what test would prove it.
