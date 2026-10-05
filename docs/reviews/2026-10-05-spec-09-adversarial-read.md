# Spec 09 adversarial read (2026-10-05)

Target: `docs/specs/09-copy-story.md` on `main` @ 7d39bff. Read-only; the spec is unchanged. The spec 09 build (`.worktrees/br-2026-10-05-copy-story`) should wait until this record has been read.

**Tags:** `[M]` mechanical, fixable in the spec by editing words. `[D]` decision-shaped, the user picks.

**Summary:** the spec cannot be built as written. It leans on unit-06 types that are not on `main` (`FeeEntry.kind`, `sourceCallId`, `counterparty`, a ledger copy section). It names a type (`Receipt`) and a test file (`feed_order_ticket_test.dart`) that do not exist. The feed card has no call id to copy from. The biggest risk is `[D]`: "creator" is defined as a persona, not as the author of the copied call, so the credit lands in the wrong ledger.

## Step 1a. Mechanical grep

`grep -nE 'TBD|TODO|FIXME|\bXXX\b|<[A-Za-z][A-Za-z -]*>|\.\.\.'` on the spec: 3 hits, all `[M]`-clean format placeholders, none a TBD.

| Line | Hit | Disposition |
|---|---|---|
| 5 | `<file>`, `<test name>`, `<log-dir>` | Template notation in the common-rules boilerplate. Fine. |
| 11 | `<name>` in "Now acting as <name>" | Intentional, but the names are never defined (see S1c, P1). |
| 14 | `<handle>`, `<asset>` | Intentional, but the copier handle and which asset are never defined (see S1c, P1 and G-ledger-string). |

No `TBD`, `TODO`, `FIXME`, `XXX` or `...` hits.

## Step 1b. Semantic placeholders

- Line 15: "Reuse the existing "— not in the demo yet" toast if a control is needed as a placeholder." Leaves the implementer to decide which controls need one. `[M]`
- Line 14: "its copy section" and line 13 "(type from unit 06)" point at things unit 06 did not build (S1c). `[M]`
- Line 14: "Receipt shows the same" does not say which screen (review panel's filled state, `ReceiptsScreen` rows, or both). `[M]`
- No "handle edge cases" or "similar to" phrases found.

## Step 1c. Name consistency against `app/lib` on main

| Spec symbol | On main? | Evidence |
|---|---|---|
| `Scenario.activePersona` | No. Expected (spec adds it). | no hit in `app/lib` |
| `OrderIntent` | Yes | `app/lib/scenario/scenario.dart:404` |
| `OrderIntent.sourceCallId`, `sourceAuthorHandle` | No. Expected (spec adds). | no hit |
| `kCopyFeeCents` | No. Expected (spec adds). | no hit |
| `FeeEntry` | Yes, but without `kind`, `sourceCallId`, `counterparty`. Fields: `id, marketId (required), eventTitle, amountCents, at`. **Finding.** | `app/lib/features/market/market_mock.dart:91-110` |
| `FeeEntry kind copyFee` ("type from unit 06") | **No.** Unit 06's spec (line 10) promises it; the build did not add it. **Finding.** | grep `copyFee` in `app/lib`: no hit |
| `Receipt.copyFeeCents` | **No such type.** The type is `OrderReceipt`. **Finding.** | `app/lib/scenario/scenario.dart:472` |
| `Scenario.placeOrder` | Yes | `scenario.dart:272` |
| `actionId` guard | Yes. It scans `receipts.value` then `openOrders.value`. | `scenario.dart:273-281`; field `scenario.dart:421` |
| unit-02 money helper | Exists as `formatCents`. Spec does not name it. `[M]` | `app/lib/features/live/live_feed.dart:68` |
| Settings "Reset demo" row | Yes | `app/lib/features/settings/settings_screen.dart:123` |
| "Demo persona" row | No. Expected (spec adds). | no hit |
| Ledger "copy section" | **No.** `LedgerScreen` renders `Scenario.marketFees` only; footer is `marketFeesCents`. **Finding.** | `app/lib/features/market/receipt_screens.dart:58-150`; `scenario.dart:137-148` |
| `app/test/feed_order_ticket_test.dart` | **Does not exist.** **Finding.** Tests: charting, empty_states, home_screen, order_ticket, receipts, replay_live, rolling_number, scenario, trader_record. | `ls app/test` |
| Call id on the feed card | **None.** `TradeIdea` has `callerHandle`, `ticker`, `side`, no id. `showFeedOrderTicket` takes `symbol, side, onDetails`. **Finding.** | `app/lib/features/home/mock_trade_idea.dart:7-50`; `app/lib/features/trade/feed_order_ticket.dart:10-23`; call sites `home_screen.dart:110,136`, `caller_play_screen.dart:43` |

## Step 2. Subagent report (verbatim)

One general-purpose subagent, critical-thinking role pasted, told read-only and to verify against `app/`. Its report follows unedited, apart from the `[M]`/`[D]` tags I add in the classification table after it.

---

READ-ONLY review of docs/specs/09-copy-story.md against app/lib and app/test on main. I did not read or touch .worktrees/. A grep for "copyFee" also surfaced matches under /home/alex/VistaColosseum/.claude/worktrees/, a different directory from .worktrees/. I read none of those files.

## Verified facts (your starting list)
- CONFIRMED: `activePersona`, `sourceCallId`, `sourceAuthorHandle`, `kCopyFeeCents`, `copyFee` and `copyFeeCents` appear nowhere in app/. The only hits on main are in docs/specs/06 and 09.
- CONFIRMED, the unit-06 gap:
  - `FeeEntry` on main (app/lib/features/market/market_mock.dart:91-110) has only `id`, `marketId` (required, non-null), `eventTitle`, `amountCents` and `at`.
  - There is no `kind`, `sourceCallId` or `counterparty`.
  - Spec 06 line 10 promises all of them, plus 1-2 seeded `copyFee` rows. Seeding is at market_mock.dart:135-148 and has 5 market-fee rows only.
  - `LedgerScreen` (receipt_screens.dart:58-150) renders `Scenario.marketFees` as one list with no "copy section", and its footer is `marketFeesCents`.
  - The spec says "type from unit 06" and "its copy section" as if these exist. They do not.
- CONFIRMED: the type is `OrderReceipt` (scenario.dart:~384). `Receipt.copyFeeCents` names a nonexistent type.
- CONFIRMED: app/test/feed_order_ticket_test.dart does not exist. The test dir has charting, empty_states, home_screen, order_ticket, receipts, replay_live, rolling_number, scenario and trader_record tests. Feed-ticket widget tests live in home_screen_test.dart (~2487-2620), and the file is named `order_ticket.dart` with `feed_order_ticket.dart` as `part of` it (feed_order_ticket.dart:1).

## 1. PASSES-BUT-WRONG
All 7 checkboxes can go green while the on-screen story is untrue.

1. **The credit lands in the wrong ledger.**
   - The feed has no calls by the creator (maya.eth) that can be copied (item 2, "Source calls").
   - Copying `kaito.eth`'s call, the spec still credits "the creator ledger", which is maya's (PortfolioMock.handle, portfolio_mock.dart:84).
   - PRD VC-CPY-002 says the creator is the author of the copied call. The spec's own tests use "creator ledger" without ever asserting the author of the call.
   - Why does the spec define "creator" as a persona rather than as the call's author?

2. **The default persona is `creator`.**
   - Spec line 12: "A call whose author is the active persona places an ordinary order; any other call is a copy".
   - Taken literally, a presenter who forgets to switch and taps kaito.eth's card as `creator` triggers a copy in which maya pays maya (debit and credit to the same wallet) or pays kaito with no ledger.
   - No acceptance criterion covers the creator persona copying a third party.

3. **The Wallet shows the creator's chrome while acting as the copier.**
   - The top bar hard-codes `PortfolioMock.handle` (account_top_bar.dart:39).
   - The Wallet 24h change is a fixed "+$91 (0.73%)" series built from `Scenario.cashCents` (portfolio_pager.dart:55-62, with `_cap = 44.0e6` and `_balanceMoves` fixtures).
   - The market cap shown is the creator's own.
   - The "Fees from your market" row appears for the copier whenever `hasMarket` is true (portfolio_screen.dart:89).
   - The ledger and all balances stay "the creator's". The copier therefore sees maya.eth's name and chart over $1,000 of cash. Tests that read the stores directly will not notice.

4. **The ledger may be unreachable or empty.**
   - `marketFees` (scenario.dart:~135) returns `[]` when `listedAt == null` (the default; HAS_MARKET is false by default).
   - It also filters `e.marketId == marketId.value && !e.at.isBefore(since)`.
   - A copy credit appended while the creator has not listed a market is invisible, so the presenter's story ends with nothing to show.
   - Entry points exist only when listed: portfolio_screen.dart:89 gates the fees row on `hasMarket`, and your_market_screen.dart:171-176 is the other.

5. **The fill toast overstates or understates cost.**
   - `_ReviewPanel._confirm` toasts `formatCents(r.totalCents)` "from paper cash" (order_ticket.dart:~864).
   - `OrderReceipt.totalCents` is margin + fee (scenario.dart:~395).
   - If the copy fee is added to the debit but not to `totalCents`, the toast is untrue. If it is added to `totalCents`, `joins`, tests and the "Paper funds required" row all shift. The spec does not say which.

6. **Arena shows mixed persona data.**
   - `participation` (scenario.dart:~84) is global, but `joins()` counts `receipts.value` (scenario.dart:~213).
   - If receipts are keyed by persona, then after a switch Arena shows `joined` (global) with counts from the other persona's receipts (arena_screen.dart:72-73, 135, 157).
   - The spec lists `participation` in neither the keyed nor the shared set.

7. **The "ordinary order" path is hard to reach.**
   - Maya's only feed idea is a trader-market card (`ticker: 'deltaone'`, `traderMarket: true`, mock_trade_idea.dart:~252). It is not tradable (`Scenario.tradable`, scenario.dart:~207) and shows "not in the demo yet".
   - The 'own call places an ordinary order' test can only be a store call. No on-screen path exercises it.

8. **A copied limit order leaves no mark of its source.**
   - `placeOrder` rests limit/stop orders without attribution (`OpenOrder` has no source field). Copy-fee-on-fill never happens, because limit execution is deferred.
   - The feed ticket has a Limit toggle (feed_order_ticket.dart:55, `_limit`; `_place` calls `_rest` for it).
   - A presenter can click "Limit" on a copied call and see "Limit placed · in Open orders" with no copy line and no fee. That is internally consistent but not the story.

## 2. GUESSABLE GAPS (the implementer must decide each)

- **Persona identity.**
  - "Now acting as <name>": the names, handles and the copier's `counterparty` handle are unspecified.
  - Unit 06 says "fixture copier handle" but none exists on main.
  - The only handle constant is `PortfolioMock.handle = 'maya.eth'` (portfolio_mock.dart:84).
  - Where does the copier handle live? Which persona sees the Settings wallet address (settings_mock)?
  - Who is `creator`: always maya.eth, or the author of the copied call?

- **Source calls (card to `sourceCallId`).**
  - `TradeIdea` has `callerHandle`, `ticker`, `side` and `age` (mock_trade_idea.dart:7, 74+) and no `id`.
  - `CallReceipt.id`s are slugs like 'kilo-sol-180-sep12' (market_mock.dart:193+), with authors maya.eth, kilo.sol and lunaq only (market_mock.dart:143-290).
  - Feed callers are kaito.eth, 0xreal, kilo.sol, lunaq, nara, deltaone, kestrel and maya.eth (mock_trade_idea.dart:76-321), and some have no `CallReceipt`.
  - `showFeedOrderTicket(symbol, side, onDetails)` (feed_order_ticket.dart:~14-23) takes no call or author. Its three call sites are home_screen.dart:~110, 136 and caller_play_screen.dart:43.
  - The Maker `Suggestion` card (home_screen.dart:~110) is also a `showFeedOrderTicket` caller and has no author. Is it a copy?
  - The spec says "sets both from the call it opened from" without choosing the mapping, so the ledger row "names the source call" with an invented id.

- **Which UI re-reads on switch.**
  - Readers of `Scenario.cashCents`: account_top_bar.dart:47, portfolio_pager.dart:62/93/169, feed_order_ticket.dart:80.
  - Readers of `Scenario.positions`: portfolio_screen.dart:256.
  - Readers of `Scenario.openOrders`: orders_state.dart:10.
  - Readers of `Scenario.receipts`: receipt_screens.dart:281/306/312, arena_screen.dart:72.
  - If these remain `ValueNotifier<int/List>` and the persona swaps their values, then "Switching never mutates financial state" is only true if the swap stashes and restores. That is not specified. If they become per-persona maps, ~100 test and lib sites break (see section 4).

- **Where the copier sees the receipt and the order receipts.**
  - `ReceiptsScreen` shows paper-order receipts only when `author == PortfolioMock.handle` (receipt_screens.dart:279).
  - Under persona-keyed receipts, the copier's receipts would appear under maya.eth's receipts list, with no entry point for the copier handle.
  - The spec's "Receipt shows the same" is undefined: the filled state in the review panel (order_ticket.dart:~900-986), the `ReceiptsScreen` rows, or both? Neither screen renders a copy line today.

- **`FeeEntry.marketId` for a copy row.**
  - It is `required String marketId` on main. Unit 06 says `marketId?`.
  - If null, `marketFees` and `LedgerScreen.example` skip it.
  - If the creator's market id, it is summed as a market fee and the 40%-share worked example (receipt_screens.dart:~64-75, `fee = amount*100/40`) could be built on a $5.00 copy row.
  - The spec does not say.

- **Unit-06 dependency.**
  - Should unit 09 retrofit `kind`, `sourceCallId`, `counterparty`, the copy section, the footer split and the seeded copy rows?
  - Or is unit 06 expected to be rebuilt first?
  - The roadmap marks M3/unit 06 delivered.

- **Ledger display string.** "Copy fee · @copier · <asset>": which asset, the source call's asset, `intent.symbol` or `eventTitle`? `FeeEntry.eventTitle` is required, so what is it for a copy row?

- **Limit-order copy.** The ticket can place a limit; the spec says only that `resting` writes no fee. It does not say whether the review line appears, or whether a copied limit order is allowed at all.

- **"Would fill" ordering.**
  - In `placeOrder`, the stale-price failure (scenario.dart:~270, `stalePrices.contains`) comes after `problem()` and before the fill.
  - The copy fee check must go inside `problem()` (which the ticket button also uses, feed_order_ticket.dart:137) or beside it, but the spec says "inside placeOrder, when the order would fill".
  - If the spec's validation runs after the stale check but the button reads `problem()`, the button enables and confirm then fails with "Not enough funds".
  - The slider "Max" (`maxMarginCents`, scenario.dart:~257, `_marginCents` limits at feed_order_ticket.dart:~280) never reserves the $5 either.

- **Persona switch mid-ticket.** `OrderIntent` is built in `_FeedOrderTicketState._intent` and the `_review` state holds it. If persona changes while a ticket or review is open (Settings is a route, but the pill sheet's Reset demo pops to root), an intent built for one persona may fill under another. The spec does not bind intent to persona.

- **Settings control.** "Row above Reset demo" in settings_screen.dart (Reset is at :123 inside a column), but VC-DEM-004 says presenter controls "outside the normal product journey". Settings is a normal-journey screen. The widget type (toggle versus VistaSettingRow tap) is also unspecified.

- **Money in the review line.** "$5.00" is hard-coded text in the spec, while the totals use `formatCents(kCopyFeeCents)`.

- **Seeded copier state.** An empty positions list and `100000` cents. The copier's open orders and receipts seeds are unspecified (presumably empty, but `OpenOrdersMock.orders` is the creator's seed).

## 3. STRAWMAN DECISIONS
- **Flat 500 cents.** This is not a strawman. O-06 and VC-CPY-002 fix it ($5.00 flat, "editable in SP-10"). The real alternative is whether `kCopyFeeCents` is a single constant editable in one place. The spec says "fixture constant", so it is fine, but nothing ties the "$5.00" review string to it.

- **Copier seed of 100000 cents.** The rejected alternative is to share the creator's $12,480 wallet and re-label the persona.
  - A competent engineer would weigh it. A single wallet makes all Wallet and Arena readers work untouched, and the "separate positions" in VC-CPY-001 become a filter.
  - It saves the whole keyed-state change (the biggest cost in section 4) but it fails "separate creator/copier positions" if cash is shared.
  - A second seed also makes the copier's balance chart and "+$91" label wrong (item 1.3), because the Wallet chart fixture is built from $12,480.
  - $1,000 is also small. A default feed ticket opens with a $200 stake (feed_order_ticket.dart:~66, `20000`) at 2x, so five copies is about the ceiling. The "Max" stop then makes the insufficient-funds path easy to hit by accident.

- **Ledger stays the creator's.** The rejected alternative is attributing the credit to the call's author. A competent engineer would weigh this. It is the real PRD behavior ("creator receives the full amount", "names the source call and copier").
  - The spec's choice is simpler (one ledger, one market) but breaks for any call not authored by maya.eth (item 1.1).
  - Cost to do it right: a per-author ledger, or a rule that copy credits only apply for calls with an author who owns a ledger. No author other than maya.eth has a ledger in the app.

- **State keyed by persona.**
  - Alternatives: (a) swap the active values in the existing static notifiers on switch (stash and restore, minimal diff, lowest risk to tests); (b) make `Scenario` instance-based; (c) per-persona maps with an `active*` getter facade.
  - A competent engineer would weigh (a)/(c) seriously because of the ~100 direct-write sites in tests (section 4).
  - The spec states the result ("keyed by persona") without comparing, and (a) is in tension with "Switching never mutates financial state".

- **`activePersona` ValueListenable with two enum values.** Not a strawman, but "persona" and the copy decision collide: should the author-versus-active-persona rule be a function of persona or of handle? The copier needs a handle anyway.

- **Settings "Demo persona" row versus the simulation pill sheet.** The pill sheet already hosts Reset demo (simulation_indicator.dart:11, 27) and is global. A competent engineer would weigh placing the presenter control there, as VC-DEM-004 says "outside the normal product journey". The spec offers only Settings.

## 4. COMPOSITION
- **Unit 01 (store/reset).**
  - `test/scenario_test.dart:27-47` has a `state()` helper that deep-compares every Scenario field, and `mutateEverything` (line ~51+) changes each one. Its own comment says a new field "must be added here".
  - Per-persona storage means both persona slots, the active persona and any persona-keyed participation must be added. The reset test (acceptance 6) will only be valid if the helper covers both seeds.
  - `reset()` (scenario.dart:~365) writes each notifier in sequence. With `activePersona` plus swapped notifiers, the order of "restore creator" versus "restore seeds" matters: if the persona resets first and the stash swap runs, cash can end up as the copier's value.
  - Tests also write the notifiers directly: scenario_test.dart:53-54, 201, 219-220, 241; empty_states_test.dart:54-56; home_screen_test.dart:368; order_ticket_test.dart (many reads). If `cashCents`, `positions`, `receipts`, `openOrders` stop being plain `ValueNotifier`s, these break. The spec does not say they stay.

- **Unit 02 (`placeOrder`, `actionId`).**
  - The duplicate guard (scenario.dart:~277-283) scans `receipts.value` and `openOrders.value`. If those are the active persona's lists, the same `actionId` re-confirmed after a persona switch will not be recognised and will fill a second time under the other persona. The spec says the guard is global ("existing guard") but does not say so for the keyed storage.
  - Copy fee debit, `FeeEntry` append and receipt stamp must be all-or-nothing around a stale-price failure. `OrderFailed(priceExpired)` happens at ~line 296 after `problem()`, so the fee has to be applied after that, in the same write as `cashCents.value -= receipt.totalCents` (~line 330). Any exception between the cash debit and the ledger append would break "one credit per action".
  - A failed copy "may be retried" with the same actionId. Fine, since a failure writes nothing (docstring ~line 268).
  - `problem()` (scenario.dart:~219-245) compares `intent.totalCents` to `cashCents.value` at two points and is also what the ticket button shows. The copy fee must be added there too or the UI disagrees with the store (item 2).
  - The copy test says "Cancel → store unchanged (deep equality)". Cancel is UI-only today (`placeOrder` is never called on cancel), so that test is vacuous unless it opens a ticket.

- **Unit 06 (ledger, `FeeEntry`, `marketFees`).**
  - `marketFees` requires `e.marketId == marketId.value` and `e.at >= listedAt`. A copy row with `marketId = null` is dropped; with the creator's id it is mis-summed as a market fee.
  - Wallet row (portfolio_screen.dart:242-246) and Your-market chip (your_market_screen.dart:171-176) both show `marketFeesCents`. Unit 06's spec says they show market fees only and the ledger footer has three sums. Neither is built on main, so adding `kind` must change `marketFeesCents` to filter by kind or the Wallet row would include $5 copy credits.
  - `receipts_test.dart:97-214` constructs `FeeEntry(...)` without `kind`. Making `kind` required, as the spec implies, breaks those tests. A default would silently classify copy rows as market fees.
  - `LedgerScreen.example(entries.first)` uses the first listed entry. With copy rows sorted newest-first at the head (spec says "newest first"), the 40%-share worked example may be computed from a $5.00 copy credit.
  - Appending a `FeeEntry` while the listing is absent (item 1.4): the ledger and the Wallet row are blank/hidden.

- **Cross-reader hazards.**
  - `joins` and `participation` (item 1.6).
  - `ReceiptsScreen` `own` check (item 2).
  - `LiveFeed.watch('portfolio', _balance, 9)` (portfolio_pager.dart:~66) is created from `_balance` at build time. A persona switch while the Wallet tab is mounted leaves a live series seeded from the other persona's cash unless it rebuilds.
  - `AccountState`/`OrdersState` facades (orders_state.dart:10 `static get open => Scenario.openOrders`) hold a reference to the notifier, so a swap-in-place keeps them live but a replacement of the notifier object would not.

## 5. INTENT DRIFT
- **PRD VC-CPY-002 (line 160).**
  - "the creator receives the full amount as one ledger credit tagged `copy`".
  - "The ledger row names the source call and copier."
  - Spec: `counterparty: copier handle` plus `sourceCallId`, and the display string "Copy fee · @copier · <asset>". The display shows the copier and an asset but not the source call, so it drifts narrower than "names the source call and copier".
  - "Creator" in the PRD is the call's author. The spec silently narrows it to the single creator persona (item 1.1). That is the largest narrowing.

- **PRD VC-CPY-001 (line 159).**
  - "A second persona selects a public copyable call". The spec accepts any feed call. There is no notion of "copyable".
  - "Retain source-call attribution". Attribution is stored on the receipt, but the position (`PortfolioPosition`) is not stamped, so the Wallet position list shows no source. The phrase "separate creator/copier positions" is delivered only as per-persona lists.
  - "Use a persona switch within the same simulated device". OK.

- **PRD VC-MKT-004 (line 117): "Direct-copy credits from S08 appear in the same ledger as a separately typed row so the two mechanisms are distinguishable."** The spec delegates to unit 06's copy section but unit 06 as built has no copy section (verified).

- **PRD VC-DEM-004 (line 84).** "persona and scenario phase outside the normal product journey". Settings is in the normal journey. Spec has no scenario phase control (out of scope per O-10, P1).

- **Roadmap M5 (line 32).** "Persona switch, copied order and one `copy` ledger credit ... cancel produces no credit. Wallet/receipt/ledger values reconcile. J1-J5 plus the copy story run from reset". The spec has no end-to-end walkthrough from reset and no reconciliation criterion across Wallet/receipt/ledger. The acceptance covers store tests only and one widget test on the review sheet.

- **O-06 / SP-10 (roadmap line 70).** Fee "editable in SP-10": the constant exists, but nothing exposes it.

- **Widening.** The spec adds a Settings control, per-persona storage of receipts and open orders, and a second seeded wallet. None is in the PRD text. PRD only requires "separate creator/copier positions".

- **PRD "tagged `copy`" versus the spec's `kind: copyFee`.** Fine, but unit 06 says the ledger copy section is titled "Copy fees".

## 6. SINGLE LARGEST RISK
**The creator is a persona, not the author of the copied call.** The whole story (who is paid, whose ledger, whether an order is a copy) hangs on `sourceAuthorHandle` versus the active persona. On main the feed's callers (kaito.eth, 0xreal, kilo.sol, lunaq, nara, deltaone, kestrel) are not maya.eth. The default persona is `creator` = maya.eth, so the first copy a presenter makes is either maya copying a third party (pays and credits herself, or credits no one real) or a copier paying maya for a call she did not make. The credit then lands in maya's ledger, which is hidden unless she has listed a market.

This risk is not named in the spec. It states "the ledger belongs to the creator" as a given. The spec's own "Gap" line (line 7) does not mention the missing author-to-ledger mapping. A smaller second risk is persona-keyed storage breaking the ~100 direct notifier writes in tests and the global `participation`.

## 7. UNVERIFIED CAPABILITY CLAIMS
- "`Scenario` gains `activePersona` ... as a `ValueListenable`". Style claim only. Every Scenario field is a `ValueNotifier`; nothing says whether UI listens to it or whether a rebuild occurs on screens that read `Scenario.cashCents` etc. (section 4).
- "Switching never mutates financial state". Unverified and implementation-dependent (swap-in-place versus keyed maps).
- "The feed ticket sets both from the call it opened from". False as the code stands: `showFeedOrderTicket` (feed_order_ticket.dart:~14) and `FeedOrderTicket` take only `symbol`, `side` and `onDetails`. No call object exists at the call sites besides `idea.callerHandle` and `idea.ticker`. Three call sites need plumbing (home_screen.dart:~110/136, caller_play_screen.dart:43).
- "unit-02 money helper". It exists as `formatCents` (live_feed.dart:68), documented "Every stored money figure ... is shown through this". The spec does not name it, and nothing says a unit-02 helper is distinct from it. It is also used on the review panel and ledger, so fine.
- "existing `actionId` duplicate guard" covers copies. The guard (scenario.dart:277-283) scans `receipts` and `openOrders`, so it covers copies only if those lists are global or if copies are guarded across personas (section 4).
- "`Settings row above 'Reset demo'`". Valid location (settings_screen.dart:123), but the screen is a `VistaSettingRow` column and the row must rebuild on a persona change; no existing row listens to a Scenario field except the `marketsLoadFails` switch (settings_screen.dart:80, 132).
- "Viewing, liking, following and opening the ticket never call `placeOrder`". Plausible. `placeOrder` is called from `_ReviewPanel._confirm` (order_ticket.dart:~861) and `_rest` (order_ticket.dart:~823) only, plus tests. I did not find any like/follow path calling it, but no acceptance test asserts this either (the spec's tests do not cover "viewing never submits" even though VC-CPY-001 requires it).
- "`Receipt` ... copier's `Receipt`". The type is `OrderReceipt`.
- "type from unit 06" for `FeeEntry{kind: copyFee, ...}`. False on main (see Verified facts).
- "creator ledger (unit 06) ... in its copy section". No such section exists on main.
- "Review sheet adds the line ... to the paper-funds-required total". Only the asset-ticket `_ReviewPanel` (order_ticket.dart:~900-986) has "Paper funds required"; the feed ticket reuses that panel via `part of`. The spec does not say whether the asset ticket (reached from AssetTradeScreen, not from a call) gets the line. That ticket has no source call.
- "`app/test/feed_order_ticket_test.dart`". Does not exist.

Files consulted: /home/alex/VistaColosseum/docs/specs/09-copy-story.md, docs/specs/06, docs/specs/02, the PRD and roadmap, and under app/lib: scenario/scenario.dart, features/market/{market_mock,receipt_screens,your_market_screen}.dart, features/trade/{feed_order_ticket,order_ticket,caller_play_screen}.dart, features/home/{home_screen,mock_trade_idea}.dart, features/portfolio/{portfolio_screen,portfolio_pager,portfolio_mock,orders_state}.dart, features/account/account_top_bar.dart, features/settings/settings_screen.dart, features/simulation/simulation_indicator.dart, features/live/live_feed.dart. Tests consulted: app/test/scenario_test.dart and a grep of the others.

---

## Step 3. Classification of every finding

Line numbers marked `~` in the report are the subagent's approximations; I confirmed only those cited in Step 1c myself. The rest are unverified by me.

| Finding | Tag |
|---|---|
| Verified facts: `Receipt` is `OrderReceipt`; `feed_order_ticket_test.dart` missing | `[M]` |
| Verified facts: unit-06 types and ledger copy section absent on main. Naming the dependency is `[M]`; whether 09 retrofits them or unit 06 is reopened is `[D]` (S2 "Unit-06 dependency") | `[M]` + `[D]` |
| S1.1 credit lands in the wrong ledger (creator = persona, not call author) | `[D]` |
| S1.2 default persona `creator` copying a third party | `[D]` (needs a rule); an acceptance row is `[M]` |
| S1.3 Wallet chrome (handle, chart, market-cap, fees row) stays the creator's | `[D]` (fix it, or accept and say so in the demo script) |
| S1.4 ledger invisible when no market is listed | `[D]` |
| S1.5 toast and `totalCents` with the copy fee | `[M]` (say which) |
| S1.6 `participation` global vs receipts keyed | `[M]` (list it as shared or keyed) |
| S1.7 own-call path unreachable on screen | `[D]` (waive manually, or add a fixture call) |
| S1.8 copied limit order | `[D]` |
| S2 persona identity (names, handles) | `[D]` for the story, `[M]` for fixture naming once chosen |
| S2 source calls: card to `sourceCallId` mapping, Maker card | `[D]` |
| S2 which UI re-reads on switch; keyed vs swap | `[D]` (S3 strawman) |
| S2 where receipt shows ("Receipt shows the same") | `[M]` |
| S2 `FeeEntry.marketId` for a copy row | `[M]` |
| S2 ledger display string and `eventTitle` for a copy row | `[M]` |
| S2 limit-order copy | `[D]` |
| S2 "would fill" ordering, `problem()` placement, Max stop | `[M]` |
| S2 persona switch mid-ticket | `[M]` |
| S2 Settings control: location and widget type | `[D]` (pill sheet vs Settings, S3) |
| S2 `$5.00` hard-coded text vs `formatCents(kCopyFeeCents)` | `[M]` |
| S2 copier open-orders and receipts seeds | `[M]` |
| S3 flat 500 | no change (fixed by O-06) |
| S3 copier seed 100000 | `[D]` |
| S3 ledger stays the creator's | `[D]` |
| S3 keyed state | `[D]` |
| S3 persona keying by enum vs handle | `[D]` |
| S3 Settings vs pill sheet | `[D]` |
| S4 unit 01: `state()` helper, `mutateEverything`, reset order, direct test writes | `[M]` |
| S4 unit 02: guard scope across personas, fee write atomicity, `problem()`, vacuous cancel test | `[M]` |
| S4 unit 06: `kind` default vs required, `marketFeesCents` filter by kind, `example(entries.first)`, `receipts_test.dart` constructors | `[M]` |
| S4 cross-reader: live series, `AccountState`/`OrdersState` facades | `[M]` |
| S5 drift: display string omits source call | `[M]` |
| S5 drift: "copyable" call, position not stamped, DEM-004 "outside the normal journey", no end-to-end criterion, fee not editable | `[D]` for copyable and DEM-004; `[M]` for the rest |
| S6 largest risk: creator is a persona, not the call's author. Not named in the spec. | `[D]` |
| S7 unverified claims (all listed there) | `[M]` |

## My recommendation (mine, after the list)

1. Do not start the spec 09 build as written. Edit the spec first.
2. The user's call is the one big decision: who "creator" is. Either (a) the call's author, which means one fixture creator whose calls are copyable, or (b) keep the single `creator` persona and make the copyable calls that persona's. I recommend (b): add one fixture call authored by the creator persona to the feed, so the demo needs one ledger and no per-author ledgers. The cut-order note makes this the first P0 item to drop, so keep it small.
3. Recommend swap-in-place or a thin `active*` facade over per-persona maps, so the roughly 100 notifier sites stay untouched. Pick one in the spec and say how `reset()` orders it.
4. Retrofit the unit-06 types inside unit 09, listed as files, rather than reopening unit 06. Say `kind` has no default.
5. Fix the mechanical items in one spec edit: `OrderReceipt`, the real test file, `formatCents(kCopyFeeCents)`, `problem()` carrying the fee, a global `actionId` guard, `participation` listed, a copy row's `marketId` and `eventTitle`, and the `example()` first-entry fix. Add acceptance rows for creator copying a third party, switching mid-ticket, and "viewing never calls `placeOrder`".
6. Add one end-to-end acceptance row from reset, tying Wallet, receipt and ledger to the same cents (M5's exit text asks for it).
