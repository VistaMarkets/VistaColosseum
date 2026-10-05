# Multi-Agent Review: spec set: account_state.dart + account_top_bar.dart + likes_state.dart + live_feed.dart + follow_list_screen.dart + orders_state.dart + portfolio_mock.dart + portfolio_pager.dart + portfolio_screen.dart + private_profile_screen.dart + profile_screen.dart + settings_screen.dart + watchlist_state.dart + scenario.dart + home_screen_test.dart + scenario_test.dart

## Executive Summary
Five reviewers checked the phase-1 scenario-store diff (`main...HEAD -- app/`, 16 files) against `docs/specs/01-scenario-store.md`. All five agree on the basics:
- the store has the right shape;
- cash is stored as int cents;
- `reset()` covers all 13 fields;
- pubspec is frozen and the gate is clean;
- nothing out of scope was built.

There are 3 HIGH findings, each reproduced:
1. Reset demo leaves the Wallet stuck on a market-cap page.
2. Tests can no longer force the no-market state when `--dart-define=HAS_MARKET=true` is set.
3. Your market still shows the hard-coded "MAYA" title after the user lists a different ticker.

Recommended action: fix the 3 HIGH findings and the cheap MEDIUM ones (follow filter, Settings toast, vacuous Arena check) before merge, and settle cash vs. portfolio value before unit 02 starts. No refutation pass ran, so the counts are raw: 3 HIGH, 8 MEDIUM, 13 LOW after dedupe. No severity-budget demotions were needed (cap 8).

## Critical Findings
None. No reviewer raised a CRITICAL.

## High Findings

**H1. Reset demo leaves the Wallet stuck on a market-cap page for a market that no longer exists**
- **Location:** `app/lib/features/portfolio/portfolio_pager.dart:84-96` (there is no `didUpdateWidget`). Triggered from `app/lib/scenario/scenario.dart:84` and `app/lib/features/settings/settings_screen.dart:120-127`.
- **Description:** Reset is the first path that turns `hasMarket` from true back to false. When it does:
  - `_page` stays at 1;
  - the drag handlers become null, so the user can't swipe back;
  - the Wallet shows "$MAYA market cap" next to a "Make a market" button and hides the balance.

  This was reproduced: after reset, the cap page is still at opacity 1.0 and "My portfolio" at 0.0, even after a 300px drag. It is the exact presenter flow.
- **Fix:** In `didUpdateWidget`, set `_page.value = 0` when `!widget.hasMarket`, or pass `key: ValueKey(hasMarket)` at `portfolio_screen.dart:73`. Add a widget test: list a market, swipe, reset, assert "My portfolio" is in focus.
- **Raised by:** architect-reviewer.

**H2. `Scenario.reset()` dropped the `withMarket` override, so tests break under `HAS_MARKET=true`** _(severity disputed; see Reviewer Disagreements)_
- **Location:** `app/lib/scenario/scenario.dart:79-94`; `app/lib/features/account/account_state.dart` (the old `reset({bool withMarket})` was removed); `app/test/home_screen_test.dart:1280`; `app/test/scenario_test.dart:41-53, 77`.
- **Description:** The make-a-market group used to force `withMarket: false`. It now relies on the define being unset. Measured with `--dart-define=HAS_MARKET=true`:
  - `scenario_test.dart` fails 1 test (`field 3 unchanged`);
  - the make-a-market group fails 7 of 8 tests.

  The gate doesn't use the define, so it still passes. The spec says to honour `HAS_MARKET` "as today".
- **Fix:** Add `Scenario.reset({bool? withMarket})`, or set `hasMarket.value = false` in that group's `setUp`. Make `mutateEverything` flip `hasMarket` to the opposite of its seed value.
- **Raised by:** security-reviewer (HIGH), architect-reviewer (L5, LOW), penetration-tester (L5, LOW), critical-thinking (question).

**H3. The listing ticker has a second source: Your market shows "MAYA" after listing another ticker**
- **Location:** `app/lib/features/market/your_market_screen.dart:40` (`YourMarketMock.symbol`); `app/lib/features/make_market/make_market_flow.dart:29` (pre-fills `MakeMarketMock.defaultTicker`); `app/lib/scenario/scenario.dart:29-32`.
- **Description:** AC1 requires listing values to come from one source. Reproduced: after `listMarket('ZED')` or `listMarket('MACRO')`, Wallet shows the new ticker while Your market shows "MAYA" (new ticker: 0 matches). The doc comment at `scenario.dart:29-30` says the ticker is "suggested before listing", but nothing reads it before listing. The bug predates this unit, but this unit's AC1 claims the listing is covered.
- **Fix:** Wrap the Your market title in a `ValueListenableBuilder` on `Scenario.ticker`, and seed the make-a-market field from `Scenario.ticker.value`.
- **Raised by:** penetration-tester (HIGH), architect-reviewer (M2, MEDIUM), critical-thinking (question).

## Medium and Low Findings

| Severity | Title | Location | Reviewer(s) | One-line description |
|---|---|---|---|---|
| MEDIUM | Follows have a second source in the asset-trade "Following" filter | `app/lib/features/trade/asset_trade_screen.dart:478-482`; `trade_mock.dart:47` | architect (M1), pen-tester (M2), critical-thinking | The filter reads `TradeMock.callers[].following` (lunaq, maya.eth, 0xreal, deltaone) while the store has `{lunaq, kilo.sol, mirin}`, and toggling follow or Reset never updates the filter; filter on `Scenario.followed` instead. |
| MEDIUM | "Demo reset to fixture-v1" toast overclaims: Settings survive reset | `settings_screen.dart:120-127`; `settings_state.dart:64-70` | pen-tester (M3), architect (L6, LOW), critical-thinking | Reproduced: trading permission and trade visibility stay `false` after Reset; call `SettingsState.reset()` or narrow the toast text. |
| MEDIUM | AC1 test's Arena step can't fail | `app/test/scenario_test.dart:171-174` | pen-tester (M4), architect (L4, LOW), critical-thinking | Arena never shows cash, so `findsNothing` on `$12,480` always passes, and the position is checked only on Wallet; remove the step or rename the test. |
| MEDIUM | Seed declared twice plus a hand-kept test copy | `scenario.dart:21-57` vs `:80-94`; `scenario_test.dart:23-53` | architect (M3), silent-failure (M2), critical-thinking | A new field with an initializer but no reset line still passes every test; use one seed path or a field registry that both `reset()` and the test walk. |
| MEDIUM | `LiveFeed.watch` now replaces the notifier when the base changes, and doesn't dispose the old one | `app/lib/features/live/live_feed.dart:29-40` | architect (M4), security (MEDIUM), pen-tester (L9, LOW), critical-thinking | The old shared-feed guarantee is gone, so a future caller with a different base forks a feed and freezes its listeners; keep `watch` idempotent, add an explicit rebase, and dispose replaced notifiers. |
| MEDIUM | Store exposed as writable `ValueNotifier`s; mutators split across `Scenario` and the forwarders | `scenario.dart:21-57, 72-77`; `account_state.dart:16-20`; `orders_state.dart:12-29`; `watchlist_state.dart:25-42`; `likes_state.dart:17` | architect (M5), pen-tester (L8, LOW), critical-thinking | Any caller can write `hasMarket` or `cashCents` directly; spec 02's `placeOrder` and its margin ≤ cash check need a single write path. |
| MEDIUM | "Portfolio balance" / "My portfolio" are bound to cash | `account_top_bar.dart:45-50`; `portfolio_pager.dart:60-66, 156-163` | architect (M6), pen-tester (L10, LOW), critical-thinking | Once spec 02 debits margin, the headline drops by the whole margin even though equity only moves by the fee; relabel it, or add a derived equity value. |
| MEDIUM | `_change()` divides by zero and renders "Infinity%" | `app/lib/features/portfolio/portfolio_pager.dart:69-76` | silent-failure (M1), critical-thinking | Cash is now mutable; if it lands on a `_balanceMoves` value, `start == 0` and the label silently reads "Infinity%" (negative cash gives the wrong sign); guard `start == 0`. |
| LOW | Store gives two answers to "who does the user follow" | `scenario.dart:48-69`; `follow_mock.dart:80-125` | pen-tester (L7), architect (L2), critical-thinking | 6 of the 9 people in `Scenario.following` are not in `followed`, and `toggleFollow` never updates `FollowPerson.following` or the lists. |
| LOW | `PositionDetail.price` is dead and contradicts "prices are not in the store" | `portfolio_mock.dart:49, 62` | architect (L2), critical-thinking | Nothing reads it; a later unit could pick up a stale price from it. |
| LOW | `Scenario.clock` and `Scenario.marketId` have no readers | `scenario.dart:33, 57`; `candle_chart.dart:38`; `trader_market_screen.dart:65` | architect (L9), silent-failure (L3), pen-tester (L6), critical-thinking | Charts still read `TradeMock.chartEnd`, so there are two clocks; `marketId` is written but never read. |
| LOW | Listing is three notifiers for one concept | `scenario.dart:31-33`; `account_state.dart:17-19` | architect (L1) | `marketId` always equals `ticker` when listed; derive it or merge the three into one record. |
| LOW | Cents-to-dollars `/ 100` done in two places | `account_top_bar.dart:50`; `portfolio_pager.dart:61` | architect (L3), security (LOW), critical-thinking | Display-only, but spec 02 asks for one formatting helper. |
| LOW | Reset demo has no confirmation step | `settings_screen.dart:114-127` | security (LOW), critical-thinking | It matches the spec, but a mis-tap mid-demo wipes all state. |
| LOW | Reset action is inline in `onTap` | `settings_screen.dart:123-126` | architect (L7) | Spec 03 adds a second Reset button; extract one shared action. |
| LOW | Store types live in `*_mock.dart` files; package-level cycle | `scenario.dart:3-6` | architect (L8), critical-thinking | The store imports `trade_mock.dart` (which pulls in charting) just for `chartEnd`; this grows as units 04–06 add types. |
| LOW | `_seedFollowed` "last entry wins" merge is silent and untested | `scenario.dart:62-69` | silent-failure (L4), critical-thinking | No conflict exists in today's data; a future one would be resolved by list order without any warning. |
| LOW | `_loadFonts()` duplicated across two test files | `scenario_test.dart:60-66`; `home_screen_test.dart:58-65` | silent-failure (L5) | Maintainability nit. |
| LOW | Position sheet "TP/SL updated" toast doesn't touch the store | `position_sheet.dart:250-262` (outside the materials) | pen-tester (L11) | The levels live only in sheet-local state and revert when the sheet reopens; no queued spec owns this. |
| LOW | `MarketsMock.traders` is a growable `static final` list that screens read | `markets_mock.dart:160`; `markets_screen.dart:40`; `edit_favorites_screen.dart:24` | pen-tester (L12) | Breaks the letter of "no mutable mock reads"; wrap it in `List.unmodifiable`. |
| LOW | Import-order nit | `account_top_bar.dart:5`; `portfolio_screen.dart:14` | architect (L10) | The `scenario` import is out of order; analyze is clean. |

## Coverage Report
Reviewers: 5/5 returned
Reviewed at: 234b9d73d943bad98c464a193590d0628c9d1091
Any commit after this one is unreviewed.

**Confirmed:**
- **Pubspec unchanged:** `git diff` on `pubspec.yaml` and `pubspec.lock` is empty. (architect, silent-failure, security, pen-tester)
- **`flutter analyze` clean:** run directly. (silent-failure, security)
- **Tests pass:**
  - full suite 176/176 (security);
  - `scenario_test.dart` 6/6 and `home_screen_test.dart` 156/156 (silent-failure).
- **AC4 grep:** `PortfolioMock.positions` matches only `scenario.dart:23, 82` in `lib`. (all four severity reviewers)
- **Reset completeness:** `reset()` assigns all 13 notifiers; `state()` lists the same 13; `fixtureVersion` is a const. (architect, security, pen-tester)
- **Removed APIs have no callers left:** the four old `reset()` methods, `parseUsd` and `PortfolioMock.balance`. (silent-failure, security, pen-tester)
- **No in-place mutation:** every mutation replaces the whole value with an unmodifiable list or set; the seed sources are `const`. (silent-failure, security, pen-tester)
- **No direct writes** to store notifiers outside `scenario.dart` and the forwarders. (architect)
- **Money:** `cashCents` is `ValueNotifier<int>` seeded from `1248000`. Doubles appear only at display, and they replace the older `parseUsd` double. (architect, silent-failure, security, pen-tester)
- **Follow seed:** `{lunaq, kilo.sol, mirin}`, worked out independently from the mocks; no handle has conflicting `following` flags. (architect, security, pen-tester, silent-failure, critical-thinking via script)
- **Follow buttons:** all three `VistaFollowButton` sites read `Scenario.followed`; no widget-local follow bools remain. (architect, pen-tester)
- **Settings row:** Reset sits after Log out, and the toast uses `fixtureVersion`. A widget test asserts the toast and seed equality after the tap. (architect, silent-failure, pen-tester)
- **`HAS_MARKET`:** honoured in both seed and reset. (architect, pen-tester)
- **Out of scope respected:** no persona switch, phase advance, persistence or network code. (silent-failure, security, pen-tester)
- **No error-handling or logging surface:** no try/catch, async or logging in the 16 files. (silent-failure)
- **LiveFeed today:** every caller passes the same base per key, so nothing thrashes yet. (architect, pen-tester)
- **Imports:** no file-level import cycle. (architect)
- **Reproductions:**
  - H1 (architect);
  - H3 (architect, pen-tester);
  - H2 (security, pen-tester);
  - Settings surviving Reset, Arena showing 0 cash, follow-filter mismatch (pen-tester);
  - the "Infinity" string, via a standalone script (silent-failure).

**Examined, inconclusive:**
- **LiveFeed with live timers across a cash change or reset:** `LiveFeed.enabled` is false under `flutter test`, so this needs a device run. (architect, pen-tester)
- **Disposal of replaced LiveFeed notifiers:** not run under `LeakTesting`. (security)
- **Intermediate states during `reset()`:** the 13 sequential notifies would be visible to non-widget listeners. None exist today, but this is unproven for unit-02 code. (architect)
- **"Infinity%" through a real code path:** arithmetic only; unreachable until unit 02 debits cash. (silent-failure)
- **`marketId`/`clock` seed values vs. what a later unit expects:** no later spec in the materials. (silent-failure)
- **`_seedFollowed` under a future conflicting fixture:** no test exists. (silent-failure)

**Not examined (residual risk):**
- `home_screen_test.dart` assertion by assertion (2212 lines): it was run, and parts were read, but nobody read every assertion.
- Full read of the `OrdersState.add` paths in `order_ticket.dart` and `feed_order_ticket.dart`. (They were grep-only; the `available` double is a known spec-02 deferral.)
- `main.dart`, and `home_screen.dart` in full.
- Whether any CI job runs tests with `--dart-define=HAS_MARKET=true`. If one does, H2 is a currently broken CI path.
- A device run of Reset demo with live timers enabled, and a leak-tracking run.
- Golden or visual rendering of the Reset row, accessibility beyond the existing tests, and the iOS/Android folders.

**Engagement check:** All five reviewers engaged; none is tagged `[DID NOT ENGAGE]`. critical-thinking doesn't use severities and has no Validated section, but it cites file:line throughout and verified the follow data with a script.

## Unstated Assumptions and Open Questions (from critical-thinking)
- **Cash or equity?** Is `$12,480` (labelled "Portfolio balance" and "My portfolio") cash or equity? Spec 02 debits margin from it, so the label and the store's meaning need settling first.
- **Why does cash drift?** `LiveFeed.watch('portfolio', ...)` moves the shown value by up to ±$9 every 3 seconds. Tests disable the feed, so AC1 proves propagation only with drift off. Spec 02 needs agreement "to the cent".
- **Reset doesn't clear drift when cash already equals the seed:** `LiveFeed` re-bases only when the base changes. The doc comment at `live_feed.dart:26-28` claims reset starts a fresh value, so the toast can appear over a drifted balance.
- **Asset-detail follow filter:** is it in scope for "follows"? If not, record it as a known second source, the way `OrderTicket.available` is recorded.
- **Canonical follow source:** list membership or the `followed` set? Do `followers` and `following` need to be notifiers when nothing in `lib/` writes them? The counts (`'128'`, `'1,204'`) stay const.
- **Your market screen:** is it in AC1 scope? `'MAYA'` is seeded three times (`PortfolioMock.marketSymbol`, `YourMarketMock.symbol`, `MakeMarketMock.defaultTicker`).
- **Clock:** should the chart readers move to `Scenario.clock` now, or is "seeded, no readers" an accepted deferral? Is "where charts end" the same moment as "fixture start"?
- **Reset scope:** what does a presenter expect "Demo reset to fixture-v1" to cover? `SettingsState`, `DisplayPrefs` and screen-local state are untouched.
- **Duplicated seed:** what stops a new field from getting an initializer but no reset line? The test's safety net depends on the same memory that would miss it.
- **Writable notifiers:** the spec says "expose as `ValueListenable`s". Was writable exposure a deliberate reading of "match existing style"?
- **`HAS_MARKET=true` in tests:** was the unit ever run with the define on? If the define-on path is demo-only, say so.
- **Pager history:** `_balanceMoves` are fixed dollar amounts. At cash ≤ $3,920 the label gives "Infinity%" or a wrong sign, and `bridgeSeries` draws below zero. Should the history scale with cash, or is this left to spec 02 (written down either way)?
- **Display doubles:** is a display-only double an accepted exception to the money rule? Should there be an int-cents formatting helper now, so spec 02 doesn't rework both screens?
- **AC1 test name:** should it still say "read one position" when only Wallet shows a position?
- **`PositionDetail.price`:** keep it or drop it?
- **`_seedFollowed`:** why "last entry wins" for a conflict the data never produces?
- **Dead value at `portfolio_pager.dart:159`:** `value: formatUsd(_balance)` is ignored whenever `live != null`, which is always the case there. Drop it, or make `value` and `live` mutually exclusive.
- **Shared `'portfolio'` key:** does it have one owner? Should live values be keyed by meaning (cash vs. equity)?
- **Reset confirmation:** does Reset need a confirm step or Undo for live presentations?
- **Store types:** where do they live, `lib/scenario/` or the feature mock files? Decide before units 02 and 04–06 each pick on their own.

## Reviewer Disagreements
- **H2 severity:** security-reviewer says HIGH (a reproduced regression in a flag the spec keeps alive). architect and pen-tester say LOW (the gate doesn't use the define). *Resolution:* keep it as a should-fix in this unit. The fix is two lines and the spec says "as today". On its own it doesn't block merge unless CI runs with the define.
- **H3 severity:** pen-tester says HIGH (AC1 names listing). architect says MEDIUM (the bug predates the unit, and the screen is outside the 16 files). *Resolution:* fix it in this unit, since AC1 explicitly claims listing is covered and the fix is one builder.
- **Settings surviving Reset:** pen-tester says MEDIUM and calls it a breach of the truthful-toast rule. architect says LOW, a scope question since the spec's seed list omits settings. *Resolution:* calling the existing `SettingsState.reset()` from the handler settles both views cheaply.
- **Vacuous Arena check:** pen-tester says MEDIUM, architect says LOW, and critical-thinking notes the manager already accepted trivial holds. *Resolution:* remove or rename the check. Don't count it as AC1 evidence.
- **LiveFeed replacement:** architect and security say MEDIUM, pen-tester says LOW (safe today). *Resolution:* MEDIUM, because spec 02 introduces fill prices that make the hazard reachable.
- **Line-number citations:** these differ across reports. A read-only check of the files confirms:
  - `account_top_bar.dart:45` (label) and `:50` (`/ 100`);
  - `portfolio_mock.dart:74` (`cashCents`);
  - `scenario_test.dart` is 255 lines, with `state()` at `:24` and `mutateEverything` at `:41`.

  pen-tester's `account_top_bar.dart:160-172` and `portfolio_mock.dart:300`, critical-thinking's `account_top_bar.dart:136-141`, and security's `scenario_test.dart:759-787` look like diff offsets. This report uses the file line numbers.

## Recommended Changes (Prioritized)
1. Reset `PortfolioPager`'s page to 0 when `hasMarket` turns false (`didUpdateWidget` or `ValueKey`), and add the list → swipe → reset widget test.
2. Make the Your market title read `Scenario.ticker`, and seed the make-a-market field from `Scenario.ticker.value`.
3. Restore explicit no-market forcing in tests (`Scenario.reset(withMarket:)` or a `setUp` override), and make `mutateEverything` flip `hasMarket`.
4. Switch the asset-trade "Following" filter to `Scenario.followed` under a `ValueListenableBuilder`, and drop `CallerPost.following`.
5. Call `SettingsState.reset()` from the Reset handler, or narrow the toast to what was actually reset.
6. Remove or rename the vacuous Arena assertion in the AC1 test.
7. Guard `_change()` against `start == 0`.
8. Before unit 02, decide whether the headline figure is cash or equity, and relabel or add a derived equity value.
9. Make `LiveFeed.watch` idempotent with an explicit rebase that disposes the old notifier, and correct the doc comment about reset.
10. Collapse the seed into one definition or field registry that both `reset()` and the test iterate.
11. Expose store reads as `ValueListenable`s and move all mutators onto `Scenario` before spec 02 adds `placeOrder`.
12. Batch the LOW cleanups:
    - drop `PositionDetail.price`;
    - derive `marketId`;
    - add one cents formatter;
    - extract the reset action;
    - move store types out of the mock files;
    - make `MarketsMock.traders` unmodifiable;
    - fix import order;
    - share `_loadFonts`.

## Open Questions for the Author
- Are `your_market_screen.dart` and the asset-trade callers filter in AC1 scope, even though they are outside the 16 files?
- Is `$12,480` cash or equity, and what should the labels say?
- Should Reset demo cover `SettingsState`, `DisplayPrefs` and the LiveFeed drift, or should the toast say less?
- Is `Scenario.clock` a recorded deferral, or should the chart readers move to it in this unit?
- Is the `HAS_MARKET=true` path supported in tests or only in manual demos, and does any CI job run it?
- Which is the canonical follow source: list membership or the `followed` set?
- Where do store types live from here on?
- Does Reset need a confirmation or Undo?
- Is display-only `double` an accepted exception to the money rule?
- Does the position sheet's TP/SL toast belong to a queued unit, or should it be reworded now?

## Report Audit
1. **The Executive Summary claims more agreement than the reviewers gave (class 4).**
   - Report: "All five agree on the basics: … `reset()` covers all 13 fields; pubspec is frozen and the gate is clean; nothing out of scope was built."
   - Source:
     - critical-thinking says "I ran no Flutter tests" and records no pubspec or out-of-scope check.
     - architect says "I did not re-run `scripts/gate.sh`; I'm relying on the reported pass" and records no out-of-scope check.
     - silent-failure never confirms that reset covers all 13 fields. Its M2 says the round-trip test "depends on a comment."
   - The report's own Coverage section credits "Out of scope respected" to "(silent-failure, security, pen-tester)", "Reset completeness" to "(architect, security, pen-tester)" and "Pubspec unchanged" to four reviewers, not five.

2. **H3 disagreement: the report gives architect a reason architect argued against (class 6).**
   - Report: "architect says MEDIUM (the bug predates the unit, and the screen is outside the 16 files)."
   - Source, architect M2: "This predates the unit, but it falls inside its "listing" scope."
   - The "outside the 16 files" point comes from critical-thinking ("It is not among the 16 files"), not from architect.

3. **H3's only HIGH vote came with the reviewer's own doubt, and the report drops it (class 6).**
   - Report: "pen-tester says HIGH (AC1 names listing)". The resolution keeps H3 at HIGH.
   - Source, pen-tester's Confidence section: "Medium on where to put the HIGH/MEDIUM line for 1 and 2, because the spec doesn't say whether Wallet sub-screens and the callers filter are in AC1's scope."
   - No section of the report mentions this doubt.

4. **H2 disagreement: the reason given for the LOW votes doesn't appear in their reports (class 6).**
   - Report: "architect and pen-tester say LOW (the gate doesn't use the define)."
   - Source: architect L5 and pen-tester L5 give no reason for LOW.
   - The point about the gate comes from security-reviewer, made while arguing for HIGH: "This doesn't fail the documented gate (`scripts/gate.sh` invokes plain `flutter test`, no dart-define)".

5. **Coverage credits the removed-API check to reviewers who didn't fully run it (class 5/6).**
   - Report: "Removed APIs have no callers left: the four old `reset()` methods, `parseUsd` and `PortfolioMock.balance`. (silent-failure, security, pen-tester)"
   - Source:
     - silent-failure's grep covered only "AccountState.reset|LikesState.reset|WatchlistState.reset|OrdersState.reset".
     - pen-tester only says "The old `reset()` methods are removed."
     - Only security grepped `parseUsd` and `PortfolioMock.balance` ("zero remaining references").
     - architect grepped `PortfolioMock.balance` reads but isn't credited.

6. **Lost: pen-tester's note on the user's own market in Home and Explore (class 6).**
   - Source, pen-tester finding 1: "with the default `hasMarket=false`, Home still shows a call on maya.eth's market (`mock_trade_idea.dart:190`) and Explore still lists it (`markets_mock.dart:160-169`)". Its suggested fix: "Decide in the spec whether the user's own trader market in feed and Explore should follow `hasMarket`."
   - Report: neither the observation nor the spec decision appears in H3, Open Questions or Recommended Changes.

7. **Lost: part of architect's fix for H3 (class 6).**
   - Source, architect M2 fix: "Do the same for the owner and cap strings that already exist in `PortfolioMock`."
   - Report: the H3 fix covers only "the Your market title" and the make-a-market field.

8. **Lost: the AC1 test's missing listing check on Home (class 6).**
   - Source, architect L4: "Listing is not checked on Home."
   - Report: the AC1 row says "Arena never shows cash … and the position is checked only on Wallet." The missing listing check appears nowhere.

9. **Lost: a third time source (class 6).**
   - Source, critical-thinking: "new order ids use `DateTime.now()` (`order_ticket.dart:205`, `feed_order_ticket.dart:144`)".
   - Report, clock row: "Charts still read `TradeMock.chartEnd`, so there are two clocks." The order-id clock isn't mentioned anywhere.

I found no problems in classes 1, 2, 3 or 7. The report says no refutation pass ran, and the source material has no refuter output. The severity counts (3 HIGH, 8 MEDIUM, 13 LOW) match the sections. All five reviewers' numbered findings reached some section, and HIGH is well under the cap of 8.
