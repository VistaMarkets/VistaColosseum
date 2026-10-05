---
source: baton-runner work unit, phase 8 of 8 (docs/specs/08-list-empty-failed-states.md, PRD VC-QA-002)
scope: br-2026-10-04-p0-queue
parent_session: 2026-10-05T065006-phase7-close.md
status: COMPLETE: criteria 3/3 green; gate PASS (287), HAS_MARKET=true 287/287; 3/3 mutants killed; uncommitted
---

# Phase 8: core-list empty states and the seeded Explore load failure

Branch `feat/br-2026-10-04-p0-queue/phase-8` (HEAD 5152785), worktree `.worktrees/br-2026-10-04-p0-queue`, all changes
uncommitted. Logs: `baton-runner/br-2026-10-04-p0-queue/phase-8-red/` (`red-1-compile.log`, `red-2-runtime.log`,
`mutations.log`) and `baton-runner/br-2026-10-04-p0-queue/gate-phase-8-work/` (gate logs + `flutter-test-has-market.log`).

## Criteria (all three done)

1. **Widget test: every listed screen renders with an empty scenario without overflow or exception.**
   `app/test/empty_states_test.dart: every core list renders an emptied scenario without overflow or exception on
   small Android 360x640 at 1.3x` and `... on iPhone SE 375x667 at 1.3x`. `emptyScenario()` empties positions, open
   orders, paper and call receipts, followers/following/followed, favourites, fee entries, and sets an Ask no battle
   matches. Per screen it scrolls to the list end, asserts no exception, the line inside a `VistaEmptyState`, its one
   action hit-testable, and `expectPillClear` on that action.
   Supporting: `Explore markets leads to Explore, from a tab or a pushed list`, `Clear search brings back an emptied
   Ask or follow search`.
   - RED 1 (compile, new API absent; `red-1-compile.log`): `test/scenario_test.dart:48:12: Error: Member not found:
     'marketsLoadFails'.` and the same for `empty_states_test.dart` (`feed`, `VistaEmptyState`).
   - RED 2 (runtime, after adding only the widget class, the store field and the `feed` param; `red-2-runtime.log`):
     both phone tests `Expected: exactly one matching candidate / Actual: ... Found 0 widgets with text "No calls to
     show"` (empty_states_test.dart:81); `Explore markets leads to Explore` StateError at :204 (no `Explore markets`);
     `Clear search` StateError at :232. Result `+2 -5`; scenario_test still 19/19.
2. **Failure toggle → failed state → Retry → loaded.**
   `app/test/empty_states_test.dart: Simulate load failure: only the Explore list fails; Retry clears the toggle and
   loads it` (Settings switch beside Reset demo → Home/Arena/Wallet unaffected → Explore shows "Couldn't load markets",
   no rows → Retry → rows and ALL MARKETS back → Settings shows the switch off). Reset clears it:
   `app/test/scenario_test.dart: seed → mutate everything → reset equals the fresh seed` (field added to `state()` and
   `mutateEverything()`), plus the Settings and pill Reset demo tests that compare `state()` to the seed.
   - RED (`red-2-runtime.log`): StateError in `openSettings` at :258 (no `Simulate load failure` switch).
3. **All existing tests still pass; `flutter analyze` clean.** `scripts/gate.sh` → `GATE: PASS` (analyze "No issues
   found!", `00:42 +287: All tests passed!`, pubspec-frozen PASS). `flutter test --dart-define=HAS_MARKET=true` →
   `+287: All tests passed!`. Was 282; +5 new tests.

Mutants (`mutations.log`), all killed: M1 reset no longer clears the toggle → scenario_test fails 4 tests; M2 Retry a
no-op → `Expected: no matching candidates / Actual: Found 1 widget with text "Couldn't load markets"`; M3 Positions
empty state disabled → both phone tests fail on "No positions yet".

## Public surface added
- `VistaEmptyState({message, detail?, actionLabel, onAction})`
  (`app/lib/design_system/components/vista_empty_state.dart`, exported from `design_system.dart`): short line
  (`VistaType.subhead`), optional muted hint, one `VistaPillButton`. Tokens only; sits inside the list so it scrolls
  and the list's own bottom padding keeps it off the 30 px strip.
- `Scenario.marketsLoadFails` (`ValueNotifier<bool>`, seed false, `reset()` sets false) in `app/lib/scenario/scenario.dart`.
  Written by the Settings switch and the Explore Retry only; read only by `MarketsScreen` and Settings.
- Settings row "Simulate load failure" (subtitle "Explore markets list", `VistaSwitch` semanticLabel
  `Simulate load failure`) directly after Reset demo (`settings_screen.dart`). No toast.
- `AppShell.explore = 1` and `AppShell.showExplore(context)` (pop to root, select Explore) in `app/lib/app_shell.dart`.
- `HomeScreen.feed` (`List<Object>?`, defaults to `homeFeed`).

## Screens the empty-scenario test covers (line → action)
Home feed "No calls to show" → Explore markets; Arena "No battles on “doge”" (+ hint "Try BTC, ETH, SOL") → Clear
search; Positions "No positions yet" → Explore markets; Open orders "No open orders" → Explore markets; Receipts
(maya.eth) "No call receipts for maya.eth in fixture-v1" and "No paper orders yet" → Explore markets each; Ledger "No
fee credits yet" → Explore markets; Followers "No followers yet" / Following "Not following anyone yet" → Explore
markets (a search with no hit: "No matches" → Clear search); Profile CALLS (kilo.sol) "No calls from kilo.sol yet" →
Explore markets; Explore failed state "Couldn't load markets" (hint "Set by Simulate load failure in Settings") → Retry.
The Arena crowd-split empty state ("No battles in this crowd split" → Show all) is the same widget, still pinned by
`home_screen_test.dart: an empty crowd split says so; Show all restores the cards`.

## Files touched (14 app files + logs + this note)
Modified: `app/lib/app_shell.dart`, `app/lib/design_system/design_system.dart`, `app/lib/scenario/scenario.dart`,
`app/lib/features/settings/settings_screen.dart`, `app/lib/features/markets/markets_screen.dart`,
`app/lib/features/home/home_screen.dart`, `app/lib/features/arena/arena_screen.dart`,
`app/lib/features/portfolio/portfolio_screen.dart`, `app/lib/features/market/receipt_screens.dart`,
`app/lib/features/people/follow_list_screen.dart`, `app/lib/features/profile/profile_screen.dart`,
`app/test/scenario_test.dart`. New: `app/lib/design_system/components/vista_empty_state.dart`,
`app/test/empty_states_test.dart`. Two over the ~12 guide; the spec's seven surfaces span seven files. `home_screen.dart`
and `markets_screen.dart` diffs look big only from re-indent under the new conditional (`git diff -w` is small).

## Decisions made here (author calls; flag if wrong)
- **Home feed** cannot empty in the app: its Following / For You tabs do not filter (pre-existing, both show
  `homeFeed`). The empty state is real code, reached through `HomeScreen(feed: [])` only. Making Following filter by
  `Scenario.followed` would change the default Home view (it opens on Following), so not done. User call.
- One action everywhere is "Explore markets" except in-place filters (Arena: Clear search / Show all; follow search:
  Clear search) and the failure (Retry). The Arena unknown-Ask state gained Clear search (was hint only).
- Profile CALLS keeps its heading hidden when empty (phase 7 F8, test `a trader with no call receipts gets no CALLS
  heading` untouched); `VistaEmptyState` replaces the `SizedBox.shrink`.
- Not restyled, on purpose: `TraderRecordPanel.unavailableNote` (digest 7 suggested it, but it is the record panel's
  no-record line, not one of spec 08's lists, and has no honest single action; its tests are unchanged) and Explore's
  search "No matches" (Explore is not on the spec's empty list; only its failure is).
- The failure covers the whole Explore list (tabs, favourites, chips, rows) below the search bar.
- Features now import `app_shell.dart` (home, portfolio, receipt_screens, follow_list, profile): the same import
  cycle `order_ticket.dart` already has (phase 2 M6). New imports sit after the existing ones (import order is a
  carried phase-1 L; analyze is clean).

## Remaining / noticed in phase 8
- Own Receipts with both sections empty shows two "Explore markets" buttons (only in an emptied scenario; maya.eth
  always has 3 seeded calls).
- Follow list tab counts are `FollowMock` constants, so an emptied scenario still shows the seeded counts (pre-existing).
- No new dependency. Nothing blocks.

## Carried across phases 1-7 (the user should know)
- Phase 3 F1 MEDIUM, OPEN, design call: pill tap target 30 px < 44; 5 flush footers (`make_market_flow.dart:138`,
  `chart_sheet.dart:255`, `your_market_screen.dart:137`, `opinions_screen.dart:181`, `position_sheet.dart:97`).
- LiveFeed drift after reset (phase 1 M, phase 2 L-5), OPEN: `resetDemo` does not rebase LiveFeed; Wallet change line
  and chart drift under the exact cash headline.
- Phase 2 M-1 MEDIUM: feed `_parseCents` wraps int64 for 17-18 digit amounts. User questions still open: invented
  TP/SL on fills with exits off (M-3), a rule-2 waiver for double-dollar sizing, a store-owned leverage cap, the
  "Portfolio balance" label on a cash-only figure.
- Phase 4: Change↔Funding chip order unpinned; joins count fills, not people.
- Phase 5: Maker "Trade this" prices at the live mark, not the suggestion's reference price.
- Phase 6: trader-market "All receipts ›" 14 px tap target; receipt id not shown; SOL $300 "Right" while SOL marks
  $214.90; fixture dates.
- Phase 7: share card synthesises a record per handle; Markets Traders rows hard-code call/open counts; nara is a
  private profile yet has a trader-market card; record panel below the fold on 360x640/375x667; Figma 303:102's arena
  section is gone.
- Phase 1 L: "Logged out (simulated)" toast mutates nothing; the user can follow herself.

## Next step
Manager: review phase 8 (dw-review), then commit. This is the queue's last phase.
