# Rehearsal protocol (SP-07 Phase 1)

The ordered steps, the control inventory and the P0 and P1 ID lists that every M6 rehearsal record copies (`docs/specs/11-verification-and-packaging.md`, FR-8 to FR-12). This is a protocol, not a record: no field table, no build SHA. A rehearsal runs the whole table from step 1 on the iOS Simulator, built from `main` with no `--dart-define` flags, so J2 lists the market from scratch (DR-9); the seeded-market presentation is covered by a `flutter test --dart-define=HAS_MARKET=true` run the record cites. Every figure is the named persona's (DR-10): the creator is maya.eth with $12,480.00 paper cash, three seeded positions and three seeded open orders; the copier sam.sol starts with $1,000.00 and no positions or open orders. Control labels are the app's own strings; a label in quotes is what the screen shows. Market fills price at the live mark, so cash after a fill is checked against the receipt, not against a fixed number. Everything here is simulated: no order, listing or payment leaves the device.

Counts to carry through the table: `cash` (Wallet Portfolio balance), `positions` (Wallet "Positions · n"), `open orders` (Wallet "Open orders · n"), `receipts` (All receipts, PAPER ORDER RECEIPTS rows), `fees` (Fee ledger Total). Step 32 reconciles new positions above the three-position seed against new paper receipts.

Expected states are checks, not claims that current `main` passes. If a build still shows the known market-cap mismatch (#29), identical Following/For You content, or a copy credit without source-call attribution, record `failed` with evidence; do not mark the affected P0 clause passed. Clauses not exercised by these steps, including the AVAX order-failure recovery, zero-history and capital-independence examples, and the worked 40% market-fee example, remain `not run` unless separately evidenced in the rehearsal record.

## Step table

| Step | Screen | Persona | Action | Expected state | PRD IDs |
|---|---|---|---|---|---|
| 1 | Settings | creator | From the no-flags Home launch tap Wallet, Settings (gear), then "Reset demo"; reopen Settings, read "Demo persona", tap Back; in Wallet open "Open orders" and return to "Positions" | toast "Demo reset to fixture-v1"; every sheet and pushed route closes; reopened Settings reads "Creator"; Wallet shows Portfolio balance $12,480.00, "Make a market", Positions · 3 and Open orders · 3 | setup · VC-DEM-002, VC-DEM-004, VC-QA-003 |
| 2 | Settings | creator | Tap Settings (gear) from Wallet; turn the "Simulate load failure" switch on; tap Back | the switch reads on; no toast; Wallet figures unchanged | J1 · VC-DEM-004, VC-QA-002 |
| 3 | Explore | creator | Tap Explore; look at the failed state before touching anything; then tap "Retry" | before Retry: "Couldn't load markets" with the hint "Set by Simulate load failure in Settings" and no list; after Retry: the Assets list (BTC, ETH, SOL, ARB, AVAX) loads at its previous scroll offset; the Settings switch is now off; Positions remains 3 and no paper receipt was created | J1 · VC-QA-002, VC-DEM-001 |
| 4 | Home | creator | Tap Home; tap "For You", then "Following"; note a call unique to each view; return to "For You" for the named cards in steps 5–9 | each tab renders a call feed with intentionally different content, including at least one call absent from the other view; cards show author handle, ticker, direction, thesis, entry and age, demo mark and change; the "Simulated · fixture-v1" pill remains visible | J1 · VC-FED-001, VC-DEM-003 |
| 5 | Home | creator | Swipe (mouse drag or scroll wheel) to the next card and back | the first card returns with the same Like count and replays the same path from its entry with the scripted activity markers; no duplicate action | J1 · VC-FED-001, VC-FED-002 |
| 6 | Home | creator | On the kaito.eth ETH card tap Like, then "<n> in"; close the sheet; tap Arena and Home | the heart fills; the rounded display remains 4.4k because this fixture count has no exposed exact increment; the People in sheet lists participants and closing it returns to the same card; the Like survives the tab switch | J1 · VC-FED-003, VC-DEM-001 |
| 7 | Home | creator | Tap "Details" on the kaito.eth ETH card; tap Back | Asset market ETH: chart, Alerts and Book panels, callers list, "Long" and "Short" pills; its price is the card's mark; Back returns to the same card | J1 · VC-FED-002, VC-FED-003, VC-DEM-001 |
| 8 | Home | creator | Scroll to the kilo.sol SOL card; tap the handle kilo.sol; observe "Following"; tap it, then tap "Follow" to restore; tap Back, switch to Arena and Home, reopen the profile, then tap Back | Profile kilo.sol shows "Record since …", verdict dots (accessibility label "Last <n> verdicts"), Settled and Right counts, CALLS list; the seeded Following state changes to Follow and back, and Following persists across the tab switch | J1 · VC-FED-003, VC-REC-001 |
| 9 | Home | creator | Scroll to the two Maker cards (after the 0xreal BTC card and after the kilo.sol SOL card) | each reads "Maker suggestion · advisory" with asset, direction, rationale, an expiry line, "Maker · demo recommendation" and "Built from Aggro demo prices"; the live one offers "Trade this", the expired one a disabled "Expired"; viewing creates no order (Positions stays 3 at step 10) | J1 · VC-FED-004, VC-ORD-001 |
| 10 | Wallet | creator | Tap Wallet; tap each span chip (1h, 4h, 1D, 1W, 1M, All); tap "Deposit"; open "Open orders" then return to "Positions" | Portfolio balance $12,480.00 under maya.eth; the chart window and change line follow the chip; toast "Deposit (simulated) — not in the demo yet"; "Make a market" entry; Positions · 3; Open orders · 3 | J2 · VC-MKT-003, VC-DEM-004 |
| 11 | Wallet | creator | Tap "Make a market" | step 1 "Make a market": Ticker prefilled MAYA with "✓ Available", identity preview maya.eth, "One-line pitch" prefilled with its "<n>/140" counter, "Free to create · nothing is minted", "Continue with $MAYA" enabled | J2 · VC-LST-001 |
| 12 | Make a market | creator | Clear the Ticker field; type BTC; tap "Use $MAYA" | blank: status "2–8 letters" and Continue disabled; BTC: "× Taken" and Continue disabled; MAYA: "✓ Available" and Continue enabled; the pitch text is unchanged throughout | J2 · VC-LST-001 |
| 13 | Make a market | creator | Tap "Continue with $MAYA" | step 2 "Before you list": the explanation rows including "Trading your own market" "Not allowed"; three consent check rows and the "I agree to the Terms of Service and Market Listing Terms" row, all unchecked; "Create $MAYA" disabled | J2 · VC-LST-002 |
| 14 | Make a market | creator | Tap Back; on step 1 tap Close (×); on Wallet tap "Make a market" again, then "Continue with $MAYA" | after the close Wallet still shows "Make a market" and no "Your market" pill, so nothing was created; re-entry shows the defaults again | J2 · VC-LST-002, VC-LST-003 |
| 15 | Make a market | creator | Check all four rows; tap "Create $MAYA"; tap "Make your first call"; tap "Share $MAYA" | step 3 "Your market is open", "Your market cap is" $10,000 with the confetti burst; toasts "Make a call — not in the demo yet" and "Share — not in the demo yet"; no call and no second market exist | J2 · VC-LST-003, VC-LST-004, VC-DEM-004 |
| 16 | Make a market | creator | Tap Close (×); tap Home, then Wallet; drag the balance pager left, then right | Wallet shows "Fees from your market" $0.00 and the "Your market" pill where "Make a market" was; the listing survives the tab switch; the pager moves between the portfolio series and the market-cap series, each with its own title, unit and legend; the market cap equals the $10,000 listing-success value | J2 · VC-LST-003, VC-MKT-001 |
| 17 | Your market | creator | Tap "Your market"; read the Price, Skew and Open interest metrics; tap a span chip; tap "Make a call"; tap Back | Your market MAYA: Market cap equals the $10,000 success and Wallet values; the unit price times the stated supply equals that cap; three static metrics, "earned in fees this week" pill at $0.00, CALLS with "All receipts"; toast "Make a call — not in the demo yet"; Back returns to Wallet | J2 · VC-MKT-001, VC-MKT-002 |
| 18 | Arena | creator | Tap Arena | three battle cards (BTC, SOL, ETH): question, time left, BULL and BEAR callers with rationale, crowd and accuracy lines, "+<n> more opinions", "I'm with Bull" and "I'm with Bear"; the crowd panel reads "Crowd split 50/50 +" and "3 battles" over the histogram | J3 · VC-ARN-001, VC-ARN-005 |
| 19 | Arena | creator | Tap "Change", then "Funding", then "Volume" | the card order changes with each chip and is the same each time that chip is chosen; the count stays "3 battles" | J3 · VC-ARN-002 |
| 20 | Arena | creator | Drag the right thumb of the crowd-split range slider left by exactly three divisions | the panel label narrows and the card list and count fall from 3 to 2 battles, excluding SOL; the histogram highlight matches; no card's verdict or record text changes | J3 · VC-ARN-002, VC-ARN-005 |
| 21 | Arena | creator | Drag the range back to full and note "3 battles"; drag the two thumbs together until the list reads "No battles in this crowd split" and the panel reads "0 battles"; tap "Show all" | the panel returns to "Crowd split 50/50 +" and "3 battles" and all three cards are back; count before narrowing, at empty and after reset: 3, 0, 3 | J3 · VC-ARN-002, VC-QA-003 |
| 22 | Arena | creator | Type SOL in "Ask about a market"; replace it with DOGE; tap "Clear search" | SOL: one card and "1 battle"; DOGE: "No battles on “DOGE”" with the hint "Try BTC, ETH, SOL"; after Clear search the field is empty and "3 battles" show | J3 · VC-ARN-003 |
| 23 | Arena | creator | Tap "+<n> more opinions" on the BTC card; tap "Bull thesis", then "All"; tap Back | Opinions: the question, the "All", "Bull thesis", "Bear thesis" chips, the named sides' rationales and participants, "Follow Bull" and "Follow Bear"; Back returns to the same BTC card with sort and range intact | J3 · VC-ARN-003, VC-DEM-001 |
| 24 | Arena | creator | Tap the BEAR caller 0xreal on the BTC card; tap Back | Profile 0xreal opens; Back returns to Arena with the same sort chip and crowd range | J3 · VC-DEM-001, VC-FED-003 |
| 25 | Order ticket | creator | On the BTC card tap "I'm with Bull"; tap "Place market long"; on "Review order" tap "Cancel" (the cancel on the ticket); tap Wallet and inspect balance and "Positions"; tap "Open orders", then return to "Positions"; tap "Your market", "All receipts" and inspect PAPER ORDER RECEIPTS; tap Back twice, tap Arena and return to the BTC card | the ticket opens on BTC with Long selected and an editable Size; "Review order" lists Instrument, Direction, Size, Reference price, Margin, Fee, "Paper funds required" and "Simulated — no real order"; after Cancel: cash $12,480.00, Positions · 3, Open orders · 3, zero new paper receipts, and the BTC card still reads "I'm with Bull" with its crowd line unchanged | J4 · VC-ORD-001, VC-ORD-002, VC-ARN-004, VC-MKT-003 |
| 26 | Order ticket | creator | On the BTC card tap "I'm with Bull" again; type a Size; tap "Place market long" | entry: the ticket header names BTC with Long selected; review: the Instrument row ends "· BTC" and the Direction row starts "Long"; write down "Paper funds required" | J4 · VC-ORD-001, VC-ORD-003 |
| 27 | Order ticket | creator | Fast double-click "Confirm" | exactly one "Order filled"; Confirm is disabled while the fill runs; toast "<name> long filled · <paper funds required> from paper cash (simulated)" with "View in Wallet"; the result panel repeats Instrument BTC and Direction Long; the store half is proven by `app/test/order_ticket_test.dart:110` 'double tap confirm places one position' | J4 · VC-ORD-002, VC-DEM-003 |
| 28 | Order ticket | creator | Tap "View in Wallet" | Wallet: Positions · 4 (three seeded plus new Long BTC), Portfolio balance = $12,480.00 minus that receipt's Paper funds required; Open orders is checked at step 32 | J4 · VC-MKT-003, VC-ORD-003 |
| 29 | All receipts | creator | Tap "Your market", then "All receipts"; tap Back twice | PAPER ORDER RECEIPTS holds one row "Long BTC <n>x" whose paper fill price, notional, fee and total match the review; CALL RECEIPTS is a separate section | J4 · VC-ORD-003, VC-REC-001 |
| 30 | Arena | creator | Tap Arena | the BTC card's Bull button now reads "Joined Bull" and its Bull crowd line is one higher; the side agrees with the Wallet position (Long BTC); the SOL and ETH cards are unchanged | J4 · VC-ARN-004 |
| 31 | Asset market | creator | Tap Explore; tap the ETH row; tap "Long"; tap "Place market long"; tap "Confirm"; tap "Done"; tap Back; tap Arena | negative membership check: the fill succeeds (Positions · 5 at step 32) but the ETH card still reads "I'm with Bull", because a ticket opened from Explore carries no clash id | J4 · VC-ARN-004, VC-DEM-001 |
| 32 | Wallet | creator | Tap Wallet; read Portfolio balance and "Positions · n"; open "Open orders" and return to "Positions"; tap "Fees from your market", read Total, tap Back; tap "Your market", then "All receipts", count PAPER ORDER RECEIPTS, tap Back twice | cash = $12,480.00 minus receipt 1 total minus receipt 2 total; Positions · 5 = 3 seeded positions + 2 new fills, with 2 new paper receipts; Open orders · 3; Fee ledger shows "No fee credits yet" and Total $0.00 = Wallet "Fees from your market" $0.00; Wallet, Fee ledger and All receipts agree | J4 · VC-ORD-003, VC-MKT-003, VC-MKT-004, VC-DEM-002, VC-QA-003 |
| 33 | Settings | creator, then copier | Tap Settings (gear) from Wallet; tap "Demo persona"; tap Back; in Wallet open "Open orders" and return to "Positions" | toast "Now acting as sam.sol"; the row value reads "Copier"; Wallet shows sam.sol, Portfolio balance $1,000.00, Positions · 0 and Open orders · 0; nothing financial changed for either persona | copy · VC-DEM-004, VC-CPY-001 |
| 34 | Feed order ticket | copier | Tap Home; swipe back from the expired Maker card to the kilo.sol SOL card; tap "Long"; type an Amount of 100; tap "Long $100 · <n>x" | the ticket shows "Market" and "Limit", "Amount · you have $1,000.00", the leverage chips, "Details"; "Review order" lists "Copying @kilo.sol · $5.00 copy fee" and Paper funds required = Margin + Fee + $5.00 | copy · VC-CPY-001, VC-ORD-001 |
| 35 | Feed order ticket | copier | Tap "Confirm"; tap "View in Wallet" | one "Order filled" that repeats the copy line; toast "… long filled · <paper funds required> from paper cash (simulated)"; Wallet (sam.sol): Positions · 1 (Long SOL), Portfolio balance = $1,000.00 minus Paper funds required, copy fee included | copy · VC-CPY-001, VC-CPY-002 |
| 36 | Settings | copier, then creator | Tap Settings (gear); tap "Demo persona"; tap Back | toast "Now acting as maya.eth"; Wallet shows the step 32 figures unchanged (cash, Positions · 5) | copy · VC-DEM-004, VC-CPY-001 |
| 37 | Fee ledger | creator | Tap "Fees from your market"; tap Back | "Fee ledger" with "Illustrative demo ledger · 40% share is a demo assumption"; no market credit rows; COPY FEES has exactly one $5.00 row naming copier @sam.sol and source call kilo.sol/SOL; Total $5.00 = market credits $0.00 + copy fees; Wallet "Fees from your market" stays $0.00 (market credits only). If the source call is omitted or the only credited ledger belongs to another author, record VC-CPY-002 as failed | copy · VC-CPY-002, VC-MKT-004 |
| 38 | Call receipt | creator | Tap "Your market", then "All receipts"; under CALL RECEIPTS tap the SOL call; tap Back three times | Call receipt: Author maya.eth, Asset SOL, Direction, Entry price, Paper size, Entered, Rule, Result "Right", Settled, Market said, Provenance; a missing field reads unavailable; it is a call receipt, not a paper fill | J5 · VC-REC-001, VC-ARN-005 |
| 39 | Profile | creator | Tap Arena; tap the BULL caller kilo.sol on the ETH card; tap a span chip | Profile kilo.sol: illustrative index chart with span chips, "Record since …", Settled and Right counts, verdict dots (accessibility label "Last <n> verdicts"), CALLS with "All receipts"; the metrics come from the fixture's call results, not from paper size | J5 · VC-MKT-002, VC-REC-001 |
| 40 | Trader market | creator | Tap "market"; drag the chart sheet handle up; tap "All receipts ›"; tap Back three times | Trader market kilo.sol: the index series with its own title and unit, the Record panel with the same Settled and Right as the Profile, call receipts for kilo.sol with no paper section (another identity's receipts) | J5 · VC-MKT-001, VC-MKT-002, VC-REC-001 |
| 41 | Position sheet | creator | Tap Wallet; tap the Long BTC position; tap "Close" | Position sheet: "Unrealised P/L", size, live mark with entry, TP and SL track; the sheet closes and Wallet shows toast "Close position (simulated) — not in the demo yet"; trading P&L here, the call verdict on the Call receipt (step 38) and fee income on the Fee ledger (step 37) are three separate figures | J5 · VC-ARN-005, VC-MKT-003, VC-DEM-004 |

## Control inventory

Input kinds: tap, scroll, drag, type, swipe-with-mouse-equivalent. A chip or tab group is one row. The Journey column names the journey whose steps first use the control; "setup" and "copy" are the reset and copy-story steps.

| Row id | Journey | Screen | Control | Input kind |
|---|---|---|---|---|
| set-01 | setup | Settings | "Reset demo" row | tap |
| set-02 | setup | Settings | "Simulate load failure" switch | tap |
| set-03 | copy | Settings | "Demo persona" row | tap |
| set-04 | setup | Settings | Back | tap |
| set-05 | setup | Settings | settings list | scroll |
| home-01 | J1 | Home | Home nav item | tap |
| home-02 | J1 | Home | "Following" and "For You" tabs | tap |
| home-03 | J1 | Home | vertical card pager | swipe-with-mouse-equivalent |
| home-04 | J1 | Home | caller handle on a call card | tap |
| home-05 | J1 | Home | "Details" | tap |
| home-06 | J1 | Home | "Long" or "Short" side button on a call card | tap |
| home-07 | J1 | Home | Like | tap |
| home-08 | J1 | Home | "<n> in" (People in) | tap |
| home-09 | J1 | Home | "Share" | tap |
| home-10 | J1 | Home | Maker "Trade this" ("Expired" when disabled) | tap |
| home-11 | J1 | Home | "Simulated · fixture-v1" pill (opens the note with Reset demo) | tap |
| exp-01 | J1 | Explore | Explore nav item | tap |
| exp-02 | J1 | Explore | "Retry" (failed state) | tap |
| exp-03 | J1 | Explore | "Search markets" or "Search traders" field | type |
| exp-04 | J1 | Explore | "Assets" and "Traders" tabs | tap |
| exp-05 | J1 | Explore | sort chips (Volume, Change, Funding; Market cap, Change, Open calls, New) | tap |
| exp-06 | J1 | Explore | star on a market row | tap |
| exp-07 | J1 | Explore | Favorites rail (after a star) | scroll |
| exp-11 | J1 | Explore | Favorites "Edit" (after a star) | tap |
| exp-08 | J4 | Explore | market row (opens Asset market or Trader market) | tap |
| exp-09 | J1 | Explore | market list | scroll |
| exp-10 | J1 | Explore | bell (Notifications) | tap |
| ast-01 | J1 | Asset market | Back | tap |
| ast-02 | J1 | Asset market | star (favourite) | tap |
| ast-03 | J1 | Asset market | chart sheet handle ("Expand chart" or "Show panels") | drag |
| ast-04 | J1 | Asset market | panel pager (Alerts, Book) | swipe-with-mouse-equivalent |
| ast-05 | J4 | Asset market | "Long" pill | tap |
| ast-06 | J4 | Asset market | "Short" pill | tap |
| ast-07 | J1 | Asset market | callers list rows (handle opens Profile, call opens Caller play) | tap |
| ast-08 | J1 | Asset market | page body | scroll |
| pro-01 | J1 | Profile | Back | tap |
| pro-02 | J1 | Profile | "Follow" ("Following" once followed) | tap |
| pro-03 | J5 | Profile | "market" pill | tap |
| pro-04 | J5 | Profile | span chips on the index chart | tap |
| pro-05 | J5 | Profile | "All receipts" (CALLS) | tap |
| pro-06 | J5 | Profile | call row | tap |
| pro-07 | J1 | Profile | "Followers" chip | tap |
| pro-08 | J1 | Profile | "Share" and "More" | tap |
| pro-09 | J1 | Profile | page body | scroll |
| tm-01 | J5 | Trader market | Back | tap |
| tm-02 | J5 | Trader market | star (favourite) | tap |
| tm-03 | J5 | Trader market | chart sheet handle | drag |
| tm-04 | J5 | Trader market | panel pager (Record) | swipe-with-mouse-equivalent |
| tm-05 | J5 | Trader market | "All receipts ›" | tap |
| tm-06 | J5 | Trader market | "Long" and "Short" pills (trader index: closes with the not-in-demo toast) | tap |
| arn-01 | J3 | Arena | Arena nav item | tap |
| arn-02 | J3 | Arena | "Ask about a market" field | type |
| arn-03 | J3 | Arena | bell (Notifications) | tap |
| arn-04 | J3 | Arena | sort chips "Volume", "Change", "Funding" | tap |
| arn-05 | J3 | Arena | battle list | scroll |
| arn-06 | J3 | Arena | BULL or BEAR caller name on a card | tap |
| arn-07 | J3 | Arena | "+<n> more opinions" | tap |
| arn-08 | J4 | Arena | "I'm with Bull" ("Joined Bull" after a fill) | tap |
| arn-09 | J4 | Arena | "I'm with Bear" ("Joined Bear" after a fill) | tap |
| arn-10 | J3 | Arena | crowd-split range slider, both thumbs | drag |
| arn-11 | J3 | Arena | "Show all" (empty crowd split) | tap |
| arn-12 | J3 | Arena | "Clear search" (empty Ask) | tap |
| opn-01 | J3 | Opinions | Back | tap |
| opn-02 | J3 | Opinions | filter chips "All", "Bull thesis", "Bear thesis" | tap |
| opn-03 | J3 | Opinions | opinion author handle | tap |
| opn-04 | J3 | Opinions | "Follow Bull" and "Follow Bear" | tap |
| opn-05 | J3 | Opinions | opinions list | scroll |
| tkt-01 | J4 | Order ticket | "Long" and "Short" side buttons | tap |
| tkt-02 | J4 | Order ticket | "More order types" | tap |
| tkt-03 | J4 | Order ticket | "Size" field | type |
| tkt-04 | J4 | Order ticket | size slider | drag |
| tkt-05 | J4 | Order ticket | "Switch size unit" | tap |
| tkt-06 | J4 | Order ticket | "Leverage, <n>x" | tap |
| tkt-07 | J4 | Order ticket | "Place market long" or "Place market short" | tap |
| tkt-08 | J4 | Order ticket | "Cancel" (review) | tap |
| tkt-09 | J4 | Order ticket | "Confirm" (review) | tap |
| tkt-10 | J4 | Order ticket | "Retry" (only after "Order not placed" at an expired price) | tap |
| tkt-11 | J4 | Order ticket | "Done" (filled) | tap |
| tkt-12 | J4 | Order ticket | "View in Wallet" (filled panel and toast action) | tap |
| tkt-13 | J4 | Order ticket | sheet body | scroll |
| ftk-01 | copy | Feed order ticket | "Market" and "Limit" tabs | tap |
| ftk-02 | copy | Feed order ticket | leverage chips "<n>x" and "Custom leverage" | tap |
| ftk-03 | copy | Feed order ticket | "Amount · you have $<cash>" field | type |
| ftk-04 | copy | Feed order ticket | amount slider | drag |
| ftk-05 | copy | Feed order ticket | "Take profit / Stop loss" switch | tap |
| ftk-06 | copy | Feed order ticket | TP and SL track thumbs | drag |
| ftk-07 | copy | Feed order ticket | "Details" | tap |
| ftk-08 | copy | Feed order ticket | "Long $<amount> · <n>x" or "Short $<amount> · <n>x" | tap |
| ftk-09 | copy | Feed order ticket | review and result buttons, shared with tkt-08 to tkt-12 | tap |
| wal-01 | J2 | Wallet | Wallet nav item | tap |
| wal-02 | setup | Wallet | Settings (gear) | tap |
| wal-03 | J2 | Wallet | "Deposit" | tap |
| wal-04 | J2 | Wallet | balance and market-cap pager | swipe-with-mouse-equivalent |
| wal-05 | J2 | Wallet | span chips 1h, 4h, 1D, 1W, 1M, All | tap |
| wal-06 | J2 | Wallet | "Followers" and "Following" chips | tap |
| wal-07 | J2 | Wallet | "Make a market" | tap |
| wal-08 | J4 | Wallet | "Fees from your market" row | tap |
| wal-09 | J2 | Wallet | "Your market" pill | tap |
| wal-10 | J4 | Wallet | "Positions" and "Open orders" tabs | tap |
| wal-11 | J5 | Wallet | position card | tap |
| wal-12 | J2 | Wallet | page body | scroll |
| mkt-01 | J2 | Make a market | Close (×) on step 1 and step 3 | tap |
| mkt-02 | J2 | Make a market | Back on step 2 | tap |
| mkt-03 | J2 | Make a market | Ticker field | type |
| mkt-04 | J2 | Make a market | "Use $MAYA", "Use $MAYAETH", "Use $MYA", "Use $MACRO" | tap |
| mkt-05 | J2 | Make a market | "One-line pitch" field | type |
| mkt-06 | J2 | Make a market | "Change market image" | tap |
| mkt-07 | J2 | Make a market | "Continue with $<ticker>" | tap |
| mkt-08 | J2 | Make a market | three consent check rows | tap |
| mkt-09 | J2 | Make a market | "I agree to the Terms of Service and Market Listing Terms" | tap |
| mkt-10 | J2 | Make a market | "Create $<ticker>" | tap |
| mkt-11 | J2 | Make a market | "Make your first call" | tap |
| mkt-12 | J2 | Make a market | "Share $<ticker>" | tap |
| mkt-13 | J2 | Make a market | step bodies | scroll |
| ym-01 | J2 | Your market | Back | tap |
| ym-02 | J2 | Your market | "Share" (↗) | tap |
| ym-03 | J2 | Your market | span chips | tap |
| ym-05 | J5 | Your market | "earned in fees this week" pill | tap |
| ym-06 | J4 | Your market | "All receipts" | tap |
| ym-07 | J2 | Your market | "Make a call" | tap |
| ym-08 | J2 | Your market | page body | scroll |
| led-01 | J4 | Fee ledger | Back | tap |
| led-02 | J4 | Fee ledger | "Explore markets" (empty state) | tap |
| led-03 | J4 | Fee ledger | entries list | scroll |
| rcp-01 | J4 | All receipts | Back | tap |
| rcp-02 | J5 | All receipts | call receipt row | tap |
| rcp-03 | J4 | All receipts | "Explore markets" (empty state) | tap |
| rcp-04 | J4 | All receipts | list | scroll |
| cr-01 | J5 | Call receipt | Back | tap |
| cr-02 | J5 | Call receipt | fields list | scroll |
| pos-01 | J5 | Position sheet | "Close" (accessibility label "Close position"; "Edit" once a level changed) | tap |
| pos-02 | J5 | Position sheet | "Lower …" and "Raise …" steppers for take profit and stop loss | tap |
| pos-03 | J5 | Position sheet | scrim or drag handle to dismiss | tap |

## P0 IDs

31 IDs, one per `| P0 |` row of `docs/prd/2026-10-01-vc-hackathon-master-prd.md`. A record gives each at least one row with an outcome, one row per clause where an ID has several (FR-13).

- VC-DEM-001
- VC-DEM-002
- VC-DEM-003
- VC-DEM-004
- VC-FED-001
- VC-FED-002
- VC-FED-003
- VC-FED-004
- VC-LST-001
- VC-LST-002
- VC-LST-003
- VC-LST-004
- VC-MKT-001
- VC-MKT-002
- VC-MKT-003
- VC-MKT-004
- VC-ARN-001
- VC-ARN-002
- VC-ARN-003
- VC-ARN-004
- VC-ARN-005
- VC-ORD-001
- VC-ORD-002
- VC-ORD-003
- VC-REC-001
- VC-CPY-001
- VC-CPY-002
- VC-QA-001
- VC-QA-002
- VC-QA-003
- VC-QA-004

## P1 IDs

Four IDs from the roadmap's P1 tiers; a record lists each with an outcome, `deferred` unless built and exercised at the build SHA.

- VC-REC-002 (P1-A)
- VC-REC-003 (P1-A)
- VC-ARN-006 (P1-A)
- VC-MKT-005 (P1-B)
