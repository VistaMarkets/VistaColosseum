# Multi-Agent Review: spec set: account_state.dart + account_top_bar.dart + likes_state.dart + live_feed.dart + make_market_flow.dart + market_mock.dart + your_market_screen.dart + follow_list_screen.dart + orders_state.dart + portfolio_mock.dart + portfolio_pager.dart + portfolio_screen.dart + private_profile_screen.dart + profile_screen.dart + settings_screen.dart + asset_trade_screen.dart + trade_mock.dart + watchlist_state.dart + scenario.dart + home_screen_test.dart + scenario_test.dart

## Executive Summary
Five reviewers checked iteration 2 of phase 1 (spec 01, scenario store and reset) at f55c061. Every iteration-1 fix marked **fixed** holds: three reviewers reverted each fix in a scratch copy, and every new test went RED. All three intent gaps (a) one listing source, (b) pager returns to "My portfolio" after reset, and (c) a real Arena assertion are closed. Gate claims were reproduced: analyze is clean, 180/180 pass with and without `HAS_MARKET=true`, and pubspec is unchanged. The tally is C0 / H0 / M2 / L14, with both MEDIUMs on the Reset path: Reset is split across two calls in a UI lambda, and on a device it leaves the live-feed balance drift on screen. Refutation was off, so these counts are raw and unchallenged. No HIGH was demoted. Recommended action: one more fix pass that adds a single `resetDemo()` entry point with a LiveFeed rebase, plus the cheap LOW cleanups.

## Critical Findings
None.

## High Findings
None. (Budget `high_cap = 8`; nothing to demote.)

## Medium and Low Findings

| Severity | Title | Location | Reviewer(s) | One-line description |
|---|---|---|---|---|
| MEDIUM | Reset demo leaves the drifted live-feed balance on screen | `live_feed.dart:25-34`; `settings_screen.dart:123-127`; `scenario.dart:82` | architect-reviewer, penetration-tester | `LiveFeed.watch` re-bases only when the base changes, and cash always equals the seed until spec 02. So after Reset the top bar still shows e.g. `$12,731` (store 1248000), and the doc comment claims otherwise (median drift $68 at 20 min). Fix: add `LiveFeed` rebase/reset (clear `_bases`/`_values`, dispose), call it from reset, correct the comment, add a widget test expecting `$12,480`. |
| MEDIUM | "Reset demo" split across two owners inside a UI lambda | `settings_screen.dart:120-128`; `scenario.dart:8-10, 79-95`; `scenario_test.dart:76, 88-95` | architect-reviewer (MEDIUM), penetration-tester (LOW) | `Scenario.reset()` + `SettingsState.reset()` live only in `onTap`. Spec 03's "same action as Settings" button will drop the Settings half, and the store tests never cover settings. Fix: add one `resetDemo()` entry used by both and tested for deep equality. |
| LOW | No-market cap page reachable via accessibility increase | `portfolio_pager.dart:94-99, 133-136` | architect-reviewer, penetration-tester | `onIncrease: () => _settle(1)` is ungated. Reproduced with `hasMarket=false`: cap opacity 1.0 and "$MAYA market cap $44.0M" shown (pre-existing on main). Fix: `onIncrease: widget.hasMarket ? … : null`. |
| LOW | `didUpdateWidget` zeroes page on every no-market rebuild | `portfolio_pager.dart:98` | architect-reviewer, penetration-tester | `_page.value = 0` calls stop+notify on every rebuild. Guard on the true→false transition or on `_page.value != 0`. |
| LOW | Refutation unsound: "Listing is three notifiers" | `scenario.dart:31-33, 59-60, 87`; `account_state.dart:16-20`; `scenario_test.dart:47-50` | architect-reviewer | Three writers keep `marketId == (hasMarket ? ticker : null)` by hand, the H2 fix added a second inline seed expression, and `mutateEverything` already builds an incoherent state. Fix: derive `marketId`, or share one seed helper. |
| LOW | `Scenario.reset({withMarket})` is a public test seam on production reset | `scenario.dart:79-81` | architect-reviewer | Can produce a non-seed state, contradicting "restores the seed exactly". Mark it `@visibleForTesting` or move the override into test `setUp`. |
| LOW | `MakeMarketMock.defaultTicker` now dead | `make_market_mock.dart:5` | architect-reviewer, silent-failure-hunter, security-reviewer, penetration-tester | No readers after the H3 fix; a stale `'MAYA'` that could be rewired. Delete it (the baton already plans to). |
| LOW | `PortfolioPager` defaults to a literal listing | `portfolio_pager.dart:25-30` | architect-reviewer, penetration-tester | `hasMarket = true, ticker = 'MAYA'` bypasses the store for any new caller (pre-existing). Make both `required`. |
| LOW | Market-cap figures have four copies and disagree after listing | `your_market_screen.dart:160,167`; `portfolio_mock.dart:80-81`; `portfolio_pager.dart:62`; `make_market_mock.dart:27` | architect-reviewer | Live step says "$10,000" while Wallet and Your market show "$44.0M", and `PortfolioMock.marketCapChange24h` is unread. Outside AC1 scope (price-like). Consolidate to one cap and one change constant. |
| LOW | Two access paths for the same listing notifier | `your_market_screen.dart:40` vs `make_market_flow.dart:29`, `portfolio_screen.dart:55-59` | architect-reviewer | `Scenario.ticker` vs `AccountState.ticker`/`hasMarket` in the same fix. Pick one read path per field. |
| LOW | Negative start in `_change` untested | `home_screen_test.dart:334-341`; `portfolio_pager.dart:76` | architect-reviewer | Only `start == 0` is covered, so narrowing the guard to `== 0` would restore "+$91 (−221.95%)" and still pass. Add a $50 case. |
| LOW | User can follow herself | `profile_screen.dart:186-196`; `scenario.dart:72-77`; `asset_trade_screen.dart:484` | penetration-tester | Reproduced: `maya.eth` lands in `Scenario.followed`, and her own call then appears under Callers › Following. Hide Follow on her own handle or ignore it in `toggleFollow`. |
| LOW | Callers Following filter can render empty with no message | `asset_trade_screen.dart:478-491`; `caller_thread.dart:35` | penetration-tester | Now reachable by unfollowing lunaq and mirin. Add an empty state or list this screen in spec 08. |
| LOW | Gate never runs `HAS_MARKET=true` | `scripts/gate.sh:43` | penetration-tester | Reverting either H2 piece passes the gate; only the manual extra log catches it. Add a `--dart-define=HAS_MARKET=true` run. |
| LOW | "Who notifies you" is a possible third follows source | `settings_state.dart:43-47` | penetration-tester | It lists kaito.eth/0xreal/kilo.sol, while `followed` is {lunaq, kilo.sol, mirin}, and unfollowing leaves the switch on. Pre-existing; intent is the author's call. |
| LOW | "Logged out (simulated)" toast describes nothing | `settings_screen.dart:118` | penetration-tester | Breaks the letter of the truthful-toast rule (pre-existing, row above Reset). Use "Log out — not in the demo yet". |

**Carried forward (deferred in the baton; no severity, not re-raised):**
- Seed declared twice plus the hand-kept test copy (the fix added a second `marketId` seed expression).
- `LiveFeed.watch` replaces notifiers without disposing them.
- Writable notifiers, with mutators split between `Scenario` and the forwarders.
- Cash vs equity labels.
- Two answers to "who the user follows".
- `PositionDetail.price` is dead.
- `clock`/`marketId` have no readers.
- `/ 100` is done in two places.
- The Reset action is inline (now the MEDIUM above).
- Store types live in the mock files.
- `_seedFollowed` lets the last entry win.
- `_loadFonts` is duplicated.
- The TP/SL toast touches no store.
- `MarketsMock.traders` is growable (verified not mutated in place).
- Import order.
- Order ids use `DateTime.now()`.
- maya.eth's market shows on Home/Explore while `hasMarket` is false. The seed's own `favoriteTraders` includes `'maya.eth'`.
- `_NumberPage` ignores `value:` when `live` is set.
- `OrderTicket.available = 1000` (double) is owned by spec 02.

## Coverage Report
Reviewers: 5/5 returned
Reviewed at: f55c061ccc33c08c64a2b5ddc4d40c7dad0d75cd
Any commit after this one is unreviewed.

**Confirmed:**
- **H1 fixed.** Reverting `portfolio_pager.dart:98` fails the test with `Expected: <1> Actual: <0.0>` (architect-reviewer, critical-thinking, penetration-tester). Driving the real Settings flow (gear → Reset demo → Back) gives portfolio opacity 1.0 (critical-thinking, penetration-tester). silent-failure-hunter and security-reviewer traced the rebuild path to `didUpdateWidget`. Gap (b) is closed.
- **H2 fixed.** 180/180 pass with and without `--dart-define=HAS_MARKET=true` (all five). `mutateEverything` flips `hasMarket` relative to its start (`scenario_test.dart:47-50`).
- **H3 title fixed.** Reverting gives `Found 0 widgets with text "ZED"`. `YourMarketMock.symbol/owner/marketCap` have zero references (architect-reviewer, critical-thinking, penetration-tester, silent-failure-hunter, security-reviewer).
- **H3 prefill fixed.** Reverting gives `Found 0 … "Continue with $ZED"` (architect-reviewer, critical-thinking, penetration-tester). Gap (a) is closed for the two named sites.
- **Arena step is real.** Removing the Arena tap gives `Found 0 widgets with type "ArenaScreen"` (architect-reviewer, penetration-tester). Arena code has no coincidental matches for the asserted strings (security-reviewer). Gap (c) is closed.
- **Follow filter fixed.** Static-set and one-shot-read mutants both fail on "vega". `CallerPost.following` is fully removed (all five). All three `VistaFollowButton` sites read `Scenario.followed` (security-reviewer).
- **Settings toast fixed.** Reverting gives `Expected: true Actual: <false>`. `SettingsState.reset()` restores all six fields (architect-reviewer, critical-thinking, penetration-tester, security-reviewer, silent-failure-hunter).
- **Infinity guard fixed.** Reverting gives `Found 1 widget with text containing Infinity` (architect-reviewer, critical-thinking, penetration-tester, silent-failure-hunter, security-reviewer).
- **Run-wide checks** (all five):
  - `flutter analyze` reports no issues.
  - pubspec diff is empty.
  - AC4: `PortfolioMock.positions` appears only at `scenario.dart:23, 83`.
  - No persona, phase-advance or persistence code.
- **No new money doubles.** The only added doubles are display derivations (architect-reviewer, critical-thinking, security-reviewer, penetration-tester).
- **Single write path outside `scenario.dart`:** only `listMarket` in `account_state.dart` (silent-failure-hunter).
- **Removed APIs have zero references**, and mock fixture lists are read only by the seed and reset (security-reviewer).
- **Only three global mutable stores:** Scenario, SettingsState/DisplayPrefs, and LiveFeed (architect-reviewer, penetration-tester).
- **Follow seed** is {lunaq, kilo.sol, mirin} with no conflicting flags (silent-failure-hunter).
- **Reset row** is reachable and hit-testable at 360x640 with the font loaded (critical-thinking).
- **LiveFeed bases** agree across callers today (penetration-tester).
- **No try/catch/logging surface** in the 21 files (silent-failure-hunter).
- **Refutation "Reset has no confirmation" is sound** (all five).

**Examined, inconclusive:**
- **LiveFeed drift after Reset on a real device:** timers are disabled under `FLUTTER_TEST`, so it was reproduced by writing the watched notifier, not by a running `Timer` (architect-reviewer, penetration-tester). A device run after about 20 minutes would settle the magnitude.
- **Leak behaviour of replaced LiveFeed notifiers:** needs a `LeakTesting` or device run (silent-failure-hunter, security-reviewer, penetration-tester).
- **Intermediate-state visibility during `reset()`'s sequential notifier writes:** reasoned safe but not proven with an instrumented listener (silent-failure-hunter).
- **`didUpdateWidget` setting `_page.value` during reconciliation:** no setState-during-build hazard found, backed by suite runs; no release or device run (security-reviewer).
- **"Who notifies you" mirroring follows:** needs an author or design call (penetration-tester).

**Not examined (residual risk):**
- `main.dart`, `app_shell.dart` and `home_screen.dart` were only grepped, not read in full.
- `position_sheet.dart`.
- `order_ticket.dart`/`feed_order_ticket.dart` in full (spec-02 territory).
- `home_screen_test.dart` assertion by assertion outside the changed groups.
- The `asset_trade_screen.dart` Market/Book panels (lines 200-430).
- Whether any `.github/workflows` CI runs `HAS_MARKET=true`.
- Accessibility beyond the pager semantics actions.
- iOS/Android folders, goldens, and real-device runs.

**Engagement check:** all five reviewers have substantive Confirmed lists. None is tagged `[DID NOT ENGAGE]`.

## Unstated Assumptions and Open Questions (from critical-thinking)
- **Reset lives in two places.** Is `SettingsState` demo state (then it belongs in the store or `reset()`) or device state (then why does Reset touch it)? Spec 03 and spec 08 will reach for `Scenario.reset()` alone. Name the single function every Reset button calls.
- **Reset now wipes `DisplayPrefs`,** which is documented as "device-only". A presenter loses chart mode on every Reset. The fix chose the wider reset over narrowing the toast without recording why.
- **`reset({withMarket})` adds a test knob** to the production API. That makes two possible seeds per build and two `marketId` seed expressions. The H1 test drives a state the product cannot reach under `HAS_MARKET=true`. Keep the knob and document it, or move the override into test `setUp`.
- **The accessibility increase reaches the cap page with no market.** Is H1 about "reset", or about "no market means no cap page"? Only two of the three inputs are guarded.
- **The follow-filter fix settled canonicality while the baton defers it.**
  - The filter uses `Scenario.followed` = {lunaq, kilo.sol, mirin}.
  - Wallet → Following lists vega, 0xreal, deltaone and orbit.eth, whose posts the filter hides.
  - The default Callers view went from 4 posts to 2, and the test was rewritten to match.
  - Home's Following tab filters nothing.
- **Your market shows the new ticker on top of the fixture market's history** ($44.0M cap, 142 holders, $42.80 fees), seconds after the flow said "$10,000". Spec 06's `FeeEntry` sum hits the same contradiction, and PRD O-05 (cap wording) is still open.
- **The `marketId` value contradicts its comment.** Every market surface keys trader markets by handle (`maya.eth`), not by symbol, and spec 06 joins `FeeEntry` on `marketId`.
- **Refutation unsound: "AC1 listing on Home".** Home renders deltaone's call on `maya.eth`'s trader market (`mock_trade_idea.dart:186-195`), ignoring `hasMarket`.
- **The make-a-market prefill fix changes nothing a user can reach,** since ticker is always MAYA before listing. Three `'MAYA'` literals remain, one of them dead.
- **The Arena step asserts absence.**
  - Unit 04 will trip the `findsNothing` checks.
  - `textContaining(r'$12,')` matches both the correct and the stale value.
  - VC-DEM-002's Arena price ($0.2610 vs $0.4400 elsewhere) has no owner.
- **The LiveFeed RNG (seed 7) keeps advancing across resets.** Does VC-DEM-002's "same balances after reset" mean the store or the screen?
- **`MarketsMock.traders` breaks spec 01's own Behavior line.** The fix is one line (`List.unmodifiable`). Fold it in, or record the exception.
- **Refutations:** "three notifiers" accepted; "no confirmation" accepted; "Home listing" unsound.

## Reviewer Disagreements
- **"Listing is three notifiers" refutation.**
  - architect-reviewer: unsound. The spec names fields, not independent notifiers.
  - critical-thinking, silent-failure-hunter, security-reviewer, penetration-tester: sound.
  - **Resolution:** the refutation is sound on the spec's letter. The architect's concrete cost (a hand-kept invariant and two seed expressions) stands as a LOW maintainability item, fixed with one shared helper.
- **"AC1 listing on Home" refutation.**
  - critical-thinking: unsound.
  - The other four: sound, because no Home code reads `hasMarket` or `ticker`.
  - I checked `mock_trade_idea.dart:186-195`: it does render a `traderMarket` call on `maya.eth`. Spec 01 line 7 says "calls stay const fixtures".
  - **Resolution:** the outcome stands, but the baton's stated reason ("Home shows no listing value") is false. Correct the reason, and record in spec 01 that Home's trader-market call is a const fixture.
- **LiveFeed drift after reset.**
  - architect-reviewer and penetration-tester: MEDIUM, reproduced.
  - security-reviewer: called the equal-base case "theoretical" and unreachable.
  - silent-failure-hunter: covered LiveFeed only under the deferred disposal item.
  - **Resolution:** architect-reviewer and penetration-tester are right. Nothing writes cash before spec 02, so the base is always equal at reset and the drift always survives on a device. It is distinct from the disposal deferral.
- **Severity of the Reset split.**
  - architect-reviewer: MEDIUM.
  - penetration-tester: LOW.
  - silent-failure-hunter and security-reviewer: carried forward as "inline reset".
  - **Resolution:** MEDIUM. The fix created the split, spec 03 explicitly reuses the action, and the fix lands together with the LiveFeed MEDIUM.
- **Arena assertion strength.**
  - security-reviewer: a real, non-vacuous leak check.
  - critical-thinking: AC1's Arena clause is satisfied only by absence.
  - **Resolution:** both are right on different questions. Gap (c) is closed (Arena is reached). The spec should state that the clause is satisfied by absence, and unit 04 owns the rewrite.

## Recommended Changes (Prioritized)
1. Add one `resetDemo()` entry point (`Scenario.reset()` then `SettingsState.reset()`), call it from the Settings row and spec 03's button, and point the deep-equality and toast tests at it.
2. Add a `LiveFeed` rebase/reset that clears `_bases`/`_values` (disposing old notifiers), call it from `resetDemo()`, correct the `watch` doc comment, and add a widget test expecting `$12,480` after Reset.
3. Gate the pager's `onIncrease` on `widget.hasMarket`, and limit `didUpdateWidget`'s zeroing to the true→false transition.
4. Mark `Scenario.reset({withMarket})` `@visibleForTesting` (or drop the parameter), and have the initializer and `reset()` share one `marketId` seed helper.
5. Add a `flutter test --dart-define=HAS_MARKET=true` run to `scripts/gate.sh`.
6. Delete `MakeMarketMock.defaultTicker` and make `PortfolioPager.hasMarket`/`ticker` required.
7. Add a $50 negative-start test for `_change`.
8. Stop self-follow by hiding Follow on the user's own handle or ignoring it in `toggleFollow`.
9. Add an empty state to the callers Following filter, or list it in spec 08.
10. Change "Logged out (simulated)" to "Log out — not in the demo yet".
11. Pick one read path (`Scenario` or the forwarder) per listing field.
12. Consolidate the market-cap constants and delete `PortfolioMock.marketCapChange24h`, or hand them to the unit that owns the cap.
13. Correct the baton's "AC1 listing on Home" refutation reason and record the const-fixture scope in spec 01.

## Open Questions for the Author
- **Settings and Reset:** is `SettingsState` (including `DisplayPrefs`) demo state that Reset should wipe, or presenter/device state it should leave alone?
- **Follows:** which follow source is canonical (list membership or the `followed` set)?
  - Is the 2-post Callers default approved?
  - Should Home's Following tab read the store?
  - Does "Who notifies you" imply following?
- **`marketId`:** what should it hold (`MAYA` or `maya.eth`), and does listing under a new ticker change it?
- **Listing semantics:** is listing a rename of MAYA or a new market? What should a freshly listed Your market show (cap, holders, fees), and which unit owns the cap given PRD O-05?
- **Home's maya.eth call:** record it as an out-of-scope const fixture, or make it read `hasMarket`?
- **Arena:** accept AC1's Arena clause as satisfied by absence? Confirm that unit 04 owns rewriting that step, and name an owner for Arena price consistency.
- **VC-DEM-002:** does "same balances after reset" mean the store or the screen? That decides whether LiveFeed's RNG must reseed on reset.
- **`MarketsMock.traders`:** fix it in the next pass, or record the exception in spec 01?
- **Before unit 02:** are "Portfolio balance" and "My portfolio" cash or equity?

## Notes
- All five rostered agents are parked (`~/.claude/agents-parked/`), not registered in this session, so each ran by the paste method as a `general-purpose` subagent with its agent body as the role and an explicit read-only prohibition. Per their frontmatter, silent-failure-hunter and security-reviewer ran on sonnet; the other three inherited the orchestrator's model. The roster is the same five as iteration 1.
- The per-reviewer recovery checkpoints under `.claude/reviews/<slug>/` were not written: the caller's containment allowed writing only this report file.
- Refutation (`--adversarial`) was off, so the counts below are raw and unchallenged.

## Report Audit

Seven discrepancies between the report and its source material. One is Executive Summary drift and six are attribution errors. None of them changes a severity, a count, or the recommended action. Every MEDIUM and LOW raised in the source reaches a section of the report, and the C0/H0/M2/L14 tally reconciles with the table.

1. **The Executive Summary overstates who reverted which fix (class 4).**
   - **Report, Executive Summary:** "three reviewers reverted each fix in a scratch copy, and every new test went RED."
   - **Report, its own Coverage section:** credits the Arena revert to only two reviewers, "(architect-reviewer, penetration-tester)". It cites no revert at all for H2, which is confirmed only by "180/180 pass with and without --dart-define=HAS_MARKET=true".
   - **Source, critical-thinking:** its revert table lists six fixes (H1, H3 title, H3 prefill, Settings reset, Infinity guard, Follow filter) and no Arena revert. For Arena it says only "It fails if Arena isn't reached", with nothing measured.
   - **Source, penetration-tester L5:** reverting either H2 piece "still passes" the plain gate. No reviewer reverted H2 and ran the suite with the define.

2. **The H2 coverage line credits critical-thinking with a full run it did not do (class 6).**
   - **Report:** "H2 fixed. 180/180 pass with and without `--dart-define=HAS_MARKET=true` (all five)."
   - **Source, critical-thinking:** "with `--dart-define=HAS_MARKET=true`, I ran `scenario_test` (+6), the "make a market" group (+9) and the "portfolio pager" group (+4); all passed. The gate log shows 180 passing with the define." It reports no full 180-test run of its own, with or without the define.

3. **"Run-wide checks (all five)" credits checks that two reviewers did not report (class 6).**
   - **Report:** "Run-wide checks (all five): `flutter analyze` reports no issues. … No persona, phase-advance or persistence code."
   - **Source, critical-thinking:** its Validated list has no `flutter analyze` run.
   - **Source, security-reviewer:** "grepped `lib/` for "persona"/"phaseAdvance"/"advancePhase" — zero hits." That search does not cover persistence. The other three reviewers grepped for persist or `File(`.

4. **The `CallerPost.following` removal is credited to penetration-tester, which did not check it (class 6).**
   - **Report:** "`CallerPost.following` is fully removed (all five)."
   - **Source, penetration-tester:** its follow-filter entry is only the revert result, "Follow filter: `Found 0 widgets with text "vega"`". Nowhere does it check whether `CallerPost.following` was removed.

5. **The Infinity-guard revert is credited to two reviewers that did not revert it (class 6).**
   - **Report:** "Infinity guard fixed. Reverting gives `Found 1 widget with text containing Infinity` (architect-reviewer, critical-thinking, penetration-tester, silent-failure-hunter, security-reviewer)."
   - **Source, silent-failure-hunter:** says the tests "would fail if the fix were reverted". That is an inference, not a revert it ran.
   - **Source, security-reviewer:** "I ran the full suite myself and this passes". No revert.

6. **security-reviewer is said to have carried forward an item it never mentions (class 6).**
   - **Report, Reviewer Disagreements, "Severity of the Reset split":** "silent-failure-hunter and security-reviewer: carried forward as 'inline reset'."
   - **Source, security-reviewer:** it has no carried-forward section. Its only finding is the `MakeMarketMock.defaultTicker` LOW, and it never mentions the inline Reset action. Only silent-failure-hunter carried it forward: "Reset action inline in `onTap`".

7. **security-reviewer's position on the LiveFeed drift loses its qualifier (class 6).**
   - **Report, Reviewer Disagreements, "LiveFeed drift after reset":** "security-reviewer: called the equal-base case 'theoretical' and unreachable."
   - **Source, security-reviewer, under "Examined, inconclusive":** "The theoretical case … : unreachable under `flutter test` since `LiveFeed.enabled` is false there". The report drops "under `flutter test`". That turns an inconclusive finding, limited to the test environment, into a flat claim that the drift cannot happen, and makes security-reviewer look more opposed to the reproduced MEDIUM than it was.
