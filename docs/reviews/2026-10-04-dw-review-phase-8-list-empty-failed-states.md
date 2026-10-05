# dw-review — `feat/br-2026-10-04-p0-queue/phase-8` (loading, empty and failed states, spec 08)

- **Target:** `feat/br-2026-10-04-p0-queue/phase-8`, phase 8 of 8 of baton-runner run `br-2026-10-04-p0-queue`: loading, empty and failed states on the core lists (`docs/specs/08-list-empty-failed-states.md`; PRD VC-QA-002). It adds one shared `VistaEmptyState` (short line, optional hint, one action) and uses it on Home feed, Arena (unknown Ask and empty crowd split), Positions, Open orders, Receipts (calls and paper), Ledger, Followers and Following, plus Profile CALLS. It adds a presenter-only Settings switch, "Simulate load failure", directly after Reset demo. The switch fails only the Explore markets list, which shows "Couldn't load markets" with Retry; Retry turns the switch off and the list loads. No spinner was added. The branch is stacked on `feat/br-2026-10-04-p0-queue/phase-7` (`ea4fceac52039d080e25f20b54127269d2ead5e0`), which is draft [VistaColosseum#19](https://github.com/VistaMarkets/VistaColosseum/pull/19), itself on [VistaColosseum#17](https://github.com/VistaMarkets/VistaColosseum/pull/17), [VistaColosseum#16](https://github.com/VistaMarkets/VistaColosseum/pull/16) and [VistaColosseum#15](https://github.com/VistaMarkets/VistaColosseum/pull/15). Phases 1-3 are on main as [VistaColosseum#10](https://github.com/VistaMarkets/VistaColosseum/pull/10), [VistaColosseum#12](https://github.com/VistaMarkets/VistaColosseum/pull/12) and [VistaColosseum#13](https://github.com/VistaMarkets/VistaColosseum/pull/13). Diff reviewed: `feat/br-2026-10-04-p0-queue/phase-7...feat/br-2026-10-04-p0-queue/phase-8`, 49 files, 14 under `app/` at review time (the skeptic's summary says 15; `git diff --name-only ... -- app` at e36eac8 gives 14). The fix commit changed 4 app files (`markets_screen.dart`, `profile_screen.dart`, `empty_states_test.dart`, `home_screen_test.dart`), the last of them new to the diff, so the diff is now 15 files under `app/` (12 in `lib`, 3 in `test`).
- **Commit reviewed:** the review ran at `e36eac83fd731fbff898a36867c07f7ed8c81d06`. The fixes landed at `289ec88f5fabadcb12eded809411970925a3bce9`.
- **Date:** 2026-10-05 UTC (run log 2026-10-05T08:25:59Z review launch to 08:49:16Z close gate, then this closing unit). Skill `dw-review`, run by `baton-runner-managed`. Workflow runs `wf_79d8428d-3e5` (review) and `wf_ef428cfc-2b6` (finding-fixer).
- **Lanes:** tautology-hunt 5, state-truthfulness 2, layout-empty-states 2 (raw 9), plus the fixed skeptic. Merges: the state-truthfulness HIGH and the layout-empty-states HIGH are the same defect, folded into F1, so 9 raw = 7 confirmed + 1 refuted + 1 merged. Confirmed: 7 (1 HIGH, 6 LOW; the skeptic demoted tautology-hunt's MEDIUM "seven of nine actions never tapped" to LOW as F2). Refuted: 1. Checked claims that were wrong: 0. F1 is marked before-merge; F2-F7 are not.
- **Disposition:** 7 of 7 dispositioned: 7 applied, 0 annotated, 0 skipped, 0 unreported (fixer coverage: failedGroups [], unreported []). Every adjudicator verdict was fix-here. The before-merge HIGH (F1) was applied in this phase. F1 and F7 change product code, each behind a test that ran red first. F2-F6 are test-strength fixes, each mutation-proven: the named mutant survived the old suite and the new test kills it. F6's own edit is a comment; its executable coverage is F5's new test, which kills F6's mutant.
  - Manager's decisions (run log 2026-10-05T08:26:34Z), verbatim: "F1 fix = scope the copy to the collection read, "No call receipts for <handle> in fixture-v1" (the ReceiptsScreen wording); keep the Profile CALLS empty state. F7 fix = preserve the Explore list's scroll offset across the failed state and Retry (keep the controller/list identity). F2-F6 test-strength: mutation-proven. F1 is before-merge: CLEAN requires it applied."
  - F7 as built: the failed state and the markets list sit in one `IndexedStack`, so the list's element and `ScrollPosition` stay mounted. No `ScrollController` was added; the file never had one, and the offset lives in the kept-mounted list. The adjudicator also corrected the reviewer's mechanism: the list was not rebuilt fresh; the shared Scrollable was clamped to offset 0 when its content shrank to the failed state.
  - Two author calls, ruled outside this phase by the iter-1 review and accepted by the manager (run log 2026-10-05T07:28:05Z, verbatim: "accept both rulings; "should the Following tab filter the feed" goes to the user in the final note."):
    - **Home feed cannot be emptied in the app.** Its Following and For You tabs do not filter; both show `homeFeed` (pre-existing). The empty state is real code, reached only through `HomeScreen(feed: [])`. Making Following filter by `Scenario.followed` would change the default Home view, so it is a user question, not a phase-8 gap.
    - **The record-panel note and Explore's "No matches" were left as they were.** `TraderRecordPanel.unavailableNote` is the record panel's no-record line, not one of spec 08's lists, and has no honest single action. Explore is on the spec only for its failure; its search "No matches" stays a plain line.

## Verdict: MERGE-WITH-FIXES

> "Scope checked before review. phase-8 resolves to e36eac83 and phase-7 to ea4fceac. The worktree HEAD is e36eac8 on feat/br-2026-10-04-p0-queue/phase-8, and the three-dot diff lists 49 files, 15 of them under app/. The newest code commit is 0621d10; e36eac8 and b085d7f touch only bookkeeping.
>
> Of the 9 findings, 8 survive and 1 is refuted. The two HIGH findings are the same defect seen from two lenses, so they merge into one:
> - **The defect:** the new Profile CALLS empty state says 'No calls from <handle> yet', but it only checks for seeded call receipts.
> - **How to hit it from the seed:** the first Home card is kaito.eth's call. The Followers and Following rows also say 'kaito.eth · 184 calls · 1 open'. Tap either one and the profile says kaito.eth has no calls.
> - **The fix:** change one string.
>
> The rest are LOW test-strength gaps and one note on scroll position. I checked those against the source and the probe logs. The semantics-tap finding is real, but its cause is in VistaPillButton, which this diff does not change, so it is refuted as out of scope.
>
> Nothing freezes at merge. I still recommend fixing the HIGH copy before merge because it is one string, so the verdict is MERGE-WITH-FIXES."

Every confirmed finding, F1 through F7, including the before-merge HIGH (F1), was applied at 289ec88 and the full gate passed there, so the merge-with-fixes condition is met.

## Confirmed findings

### F1 HIGH — Profile CALLS empty state says a trader has no calls when the app shows their calls one tap earlier (merges the state-truthfulness and layout-empty-states HIGHs)

**Before merge:** yes.

**Location:** `app/lib/features/profile/profile_screen.dart:360` (`_calls`, `'No calls from ${widget.handle} yet'`) at e36eac8. Now: `profile_screen.dart:359-365`, message at `:361-362`.

Start from the seeded app with no changes. `homeFeed` starts with `mockFeed[0] = mockTradeIdea`, whose `callerHandle` is 'kaito.eth' (`mock_trade_idea.dart:76,97-98`). Tapping the caller runs `home_screen.dart:131-133`, which pushes `ProfileScreen.route('kaito.eth')`. That profile is not private, because `privateProfiles` holds only 'nara'. kaito.eth has no `seedCalls` entry: the authors are `PortfolioMock.handle`, kilo.sol, lunaq, kestrel and nara. So `_calls()` rendered 'No calls from kaito.eth yet' with an 'Explore markets' button. The Followers and Following lists give a sharper path. `FollowMock` lists kaito.eth as '184 calls · 1 open', deltaone as '402 calls · 2 open' and mirin as '92 calls · 2 open'. Tapping any of those rows pushes `ProfileScreen` (`follow_list_screen.dart:142`), and the profile then denied the calls the row had just counted. The app uses 'No calls yet' to mean zero calls (`FollowMock` sam.sol), so the new line made an unqualified claim that other screens contradict. The record panel above it says 'No settled calls yet — record unavailable', and `ReceiptsScreen` says 'No call receipts for kaito.eth in fixture-v1'. The new line was the only one that did not name the collection it reads, which puts it in the "empty state that denies data which exists" class.

**Fix asked for:** scope the copy to the collection actually read and reuse the `ReceiptsScreen` wording, `'No call receipts for ${widget.handle} in ${Scenario.fixtureVersion}'`, then update the expectation at `empty_states_test.dart:187`.

**Applied:** The Profile CALLS empty state now reads 'No call receipts for ${widget.handle} in ${Scenario.fixtureVersion}'. It still uses VistaEmptyState with the 'Explore markets' action. The expectation in `app/test/empty_states_test.dart` changed to 'No call receipts for kilo.sol in fixture-v1'. The test was edited first and failed; after the code edit it passes on both small phones.

**Test:** `app/test/empty_states_test.dart: every core list renders an emptied scenario without overflow or exception on small Android 360x640 at 1.3x` and `... on iPhone SE 375x667 at 1.3x` (Profile leg at `:192-198`).

Red output, verbatim from the writer:

```text
00:00 +0: every core list renders an emptied scenario without overflow or exception on small Android 360x640 at 1.3x
══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞════════════════════════════════════════════════════
The following TestFailure was thrown running a test:
Expected: exactly one matching candidate
  Actual: _DescendantWidgetFinder:<Found 0 widgets with text "No call receipts for kilo.sol in
fixture-v1" descending from widgets with type "VistaEmptyState": []>
   Which: means none were found but one was expected
small Android 360x640 Profile calls
When the exception was thrown, this was the stack:
#4      expectEmpty (file:///home/alex/VistaColosseum/.worktrees/br-2026-10-04-p0-queue/app/test/empty_states_test.dart:81:3)
<asynchronous suspension>
#5      main.<anonymous closure> (file:///home/alex/VistaColosseum/.worktrees/br-2026-10-04-p0-queue/app/test/empty_states_test.dart:185:7)
...
00:01 +0 -1: every core list renders an emptied scenario without overflow or exception on small Android 360x640 at 1.3x [E]
(same failure for iPhone SE 375x667 Profile calls)
```

### F2 LOW — Seven of nine 'Explore markets' actions are never tapped

**Location:** `app/test/empty_states_test.dart:69-92` (`expectEmpty`), `199-224` at e36eac8. Now: `:233-276` in the test at `:207`.

Replace `onAction` with `() {}` on the Home feed, Open orders, Receipts calls, Receipts paper, Ledger, Following or Profile CALLS, and the old suite stays green. `expectEmpty` checks only that the button is present, hit-testable and clear of the pill. The only taps were the first 'Explore markets' match on Wallet (Positions) and the Followers one, so a no-op on any of the other seven survived. Every call site is the same one-line lambda, `() => AppShell.showExplore(context)`, so the skeptic rated the real risk low and demoted it from MEDIUM.

**Fix asked for:** tap each action and assert `AppShell.tab.value == AppShell.explore`.

**Applied:** The 'Explore markets leads to Explore' test now taps Open orders' own action, then the action on Home, Receipts (calls and paper), Ledger, Followers, Following and Profile, each pumped as the first route. Each tap must switch the tab to Explore. Mutation proof: the Ledger no-op mutant (`receipt_screens.dart:99` `onAction: () {},`) survived the full old suite (+288 all passed). The new test kills it. The writer also made the same no-op mutant at every other site: `receipt_screens:300` (ReceiptsScreen #0), `:310` (ReceiptsScreen #1), `portfolio_screen:317` (Open orders, actual tab 3), `home_screen:93` (Scaffold #0), `profile_screen:364` (ProfileScreen #0). The new test killed each one. `follow_list_screen:116` was killed by the existing Followers assertion. Every mutant was reverted afterwards.

**Test:** `app/test/empty_states_test.dart: Explore markets leads to Explore, from a tab or a pushed list`.

Red output, verbatim from the writer:

```text
Mutant receipt_screens.dart:99 -> `onAction: () {},`, old full suite:
00:42 +288: /home/alex/VistaColosseum/.worktrees/br-2026-10-04-p0-queue/app/test/home_screen_test.dart: (tearDownAll)
00:42 +288: All tests passed!

Same mutant, new test:
══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞════════════════════════════════════════════════════
The following TestFailure was thrown running a test:
Expected: <1>
  Actual: <0>
LedgerScreen #0

When the exception was thrown, this was the stack:
#4      main.<anonymous closure>.tapEach (file:///home/alex/VistaColosseum/.worktrees/br-2026-10-04-p0-queue/app/test/empty_states_test.dart:259:9)
...
00:01 +0 -1: Explore markets leads to Explore, from a tab or a pushed list [E]
```

### F3 LOW — The 'beside Reset demo' check passes when the switch is moved

**Location:** `app/test/empty_states_test.dart:259-262` at e36eac8. Now: `:312-321`.

Move the Simulate load failure row to the top of the Settings ListView and the old test still passed: it scrolled to the switch and then asserted only that `find.text('Reset demo')` appears somewhere in the tree. The review probe's `mutate-run-3.txt` shows `switch-not-beside-reset: SURVIVED (exit 0) ... +313`. The iter-1 review baton already listed this as L1.

**Fix asked for:** assert adjacency: the gap between the switch's `VistaSettingRow` and the Reset demo row is about 0, or the switch row is the next sibling.

**Applied:** In the 'Simulate load failure' test, `openSettings()` now checks that the switch's `VistaSettingRow` rect (inflated 0.5) overlaps the Reset demo `VistaSettingRow` rect. Before, it only checked that Reset demo was present. Mutation proof: `switch-not-beside-reset` (ROW moved before `_account(),`). The old `empty_states_test` passes on it (+6 all passed). The new assertion fails. The mutant was reverted and the test passes.

**Test:** `app/test/empty_states_test.dart: Simulate load failure: only the Explore list fails; Retry clears the toggle and loads it`.

Red output, verbatim from the writer:

```text
Mutant switch-not-beside-reset, old tests:
00:04 +6: All tests passed!

Same mutant, new assertion:
══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞════════════════════════════════════════════════════
The following TestFailure was thrown running a test:
Expected: true
  Actual: <false>

When the exception was thrown, this was the stack:
#4      main.<anonymous closure>.openSettings (file:///home/alex/VistaColosseum/.worktrees/br-2026-10-04-p0-queue/app/test/empty_states_test.dart:310:7)
...
00:01 +0 -1: Simulate load failure: only the Explore list fails; Retry clears the toggle and loads it [E]
```

### F4 LOW — Paper-receipts and Arena crowd-split empty states are not required to be VistaEmptyState

**Location:** `app/test/empty_states_test.dart:158`; `app/test/home_screen_test.dart:1055-1077` at e36eac8. Now: `empty_states_test.dart:159-166`; `home_screen_test.dart:1062-1076`.

(a) Revert PAPER ORDER RECEIPTS to a plain `Text`. The old check at line 158 looked only for the text, and the call-receipts `VistaEmptyState` on the same screen satisfied `expectEmpty`, so the mutant survived the full suite (+313). (b) Revert `arena_screen.dart` `_empty`'s crowd-split branch to a bare `VistaPillButton('Show all')`. The crowd-split test used unscoped finders (text and `widgetWithText(VistaPillButton, 'Show all')`) with no `VistaEmptyState` ancestor, and the emptied-scenario test reaches only the Ask branch ('doge'). The iter-1 review baton listed (a) as L2.

**Fix asked for:** scope both checks with `find.descendant(of: find.byType(VistaEmptyState), ...)` for the line and its action.

**Applied:** Two checks are now scoped to VistaEmptyState: (a) the paper receipts 'No paper orders yet' check in `empty_states_test.dart`, and (b) the crowd-split line and its Show all pill in `home_screen_test.dart`. Mutation proof: (a) `receipts-paper-plain-text` survives the old 'every core list' test (+2 passed) and the scoped check kills it. (b) The pre-phase-8 hand-built Padding/Column/Text/VistaPillButton mutant survives the old 'an empty crowd split' test (+1 passed) and the scoped check kills it. Both mutants were reverted and both tests pass.

**Test:** `app/test/empty_states_test.dart: every core list renders an emptied scenario without overflow or exception on <phone> at 1.3x`; `app/test/home_screen_test.dart: arena an empty crowd split says so; Show all restores the cards`.

Red output, verbatim from the writer:

```text
(a) Paper plain-text mutant, old test: 00:05 +2: All tests passed!
New test:
The following TestFailure was thrown running a test:
Expected: exactly one matching candidate
  Actual: _DescendantWidgetFinder:<Found 0 widgets with text "No paper orders yet" descending from
widgets with type "VistaEmptyState": []>
   Which: means none were found but one was expected
small Android 360x640
... empty_states_test.dart line 158

(b) Arena hand-built mutant, old test: 00:01 +1: All tests passed!
New test:
The following TestFailure was thrown running a test:
Expected: exactly one matching candidate
  Actual: _DescendantWidgetFinder:<Found 0 widgets with text "No battles in this crowd split"
descending from widgets with type "VistaEmptyState": []>
   Which: means none were found but one was expected
... home_screen_test.dart:1063:7
00:01 +0 -1: arena an empty crowd split says so; Show all restores the cards [E]
```

### F5 LOW — No test asserts that empty states are absent beside a populated list

**Location:** `portfolio_screen.dart:267`, `:313`; `receipt_screens.dart:95`, `:295`, `:305`. Now: the new test at `app/test/empty_states_test.dart:392-417` (import of `ethLong` at `:18`).

These guards are `if (x.isEmpty) VistaEmptyState(...)` placed next to `for (final e in x)`, not in place of the rows. Flip a guard to true and the seeded Wallet would show 'No positions yet' above real positions. No test had a `findsNothing` on these strings or on `VistaEmptyState`; the only matches outside `empty_states_test.dart` were two positive checks in `receipts_test.dart`. The guards were correct; this was a gap in test strength only.

**Fix asked for:** in one seeded-state test, assert `find.byType(VistaEmptyState), findsNothing` on Wallet (both segments), Ledger, and the Receipts screen of an author with calls and paper fills.

**Applied:** Added the import `import 'scenario_test.dart' show ethLong;` and a new test, 'seeded lists show no empty state, with the load failure on'. The test uses `reset(withMarket: true)`, places one paper fill and sets the flag on. On a 402x3000 surface it requires no VistaEmptyState on Positions, Open orders, Receipts, Ledger or FollowList. The anchor had moved because of F7's new test, so the writer appended it after that test. Mutation proof: the positions guard (`portfolio_screen:267` `length >= 0`) and the paper guard (`receipt_screens:306`) each survived the full old suite (+288 all passed). The new test kills both, plus the guard mutants at `portfolio:313` (Open orders), `receipt_screens:95` (LedgerScreen) and `:295` (ReceiptsScreen). Every mutant was reverted.

**Test:** `app/test/empty_states_test.dart: seeded lists show no empty state, with the load failure on`.

Red output, verbatim from the writer:

```text
Mutant portfolio_screen.dart:267 `if (positions.length >= 0)`, old full suite: 00:49 +288: All tests passed!
Mutant receipt_screens.dart:306 `if (Scenario.receipts.value.length >= 0)`, old full suite: 00:47 +288: All tests passed!

New test vs mutation 1:
The following TestFailure was thrown running a test:
Expected: no matching candidates
  Actual: _TypeWidgetFinder:<Found 1 widget with type "VistaEmptyState": [
            VistaEmptyState,
          ]>
   Which: means one was found but none were expected
Positions
... empty_states_test.dart line 403
00:01 +0 -1: seeded lists show no empty state, with the load failure on [E]

New test vs mutation 2: Actual: _TypeWidgetFinder:<Found 1 widget with type "VistaEmptyState": [ ReceiptsScreen
(orders:313 -> reason Open orders; ledger:95 -> LedgerScreen; calls:295 -> ReceiptsScreen)
```

### F6 LOW — Test of 'only Explore fails' covers tabs 0, 2 and 3 only

**Location:** `app/test/empty_states_test.dart:273-283` at e36eac8. Now: the comment at `:332-333`; the executable coverage is F5's test (`:398`, `:409-416`).

Make a pushed screen such as Receipts, Ledger, Follow or AssetTrade read `marketsLoadFails`, and the old loop never visited it, so the mutant would pass. `command grep -rn marketsLoadFails app/lib` finds only `scenario.dart`, `settings_screen.dart` and `markets_screen.dart`, so the code was correct and only the test was narrow.

**Fix asked for:** with the flag on, pump one or two pushed lists and assert the failed state is absent, or say in a test comment that the grep is the control.

**Applied:** Replaced the comment above the tab loop with: 'No other tab depends on it. The pushed lists (Receipts, Ledger, Follow) are checked with it on in 'seeded lists show no empty state'.' F5 landed, so the comment is accurate. Mutation proof: the Ledger flag mutant (`final entries = Scenario.marketsLoadFails.value ? Scenario.marketFees.take(0).toList() : Scenario.marketFees;`) survived the HEAD test suite. To isolate it, the writer patched only the F1 expectation line in a scratch copy of HEAD's `test/` and swapped it in (+287 all passed). F5's new test kills it with reason LedgerScreen. The mutant was reverted and the test dir restored; `git diff` confirmed the test files match the applied edits.

**Test:** `app/test/empty_states_test.dart: seeded lists show no empty state, with the load failure on` (F5's test; F6's own edit is a comment).

Red output, verbatim from the writer:

```text
Ledger flag mutant, HEAD test suite (F1 line patched only):
00:44 +287: All tests passed!

Same mutant, with F5 test:
The following TestFailure was thrown running a test:
Expected: no matching candidates
  Actual: _TypeWidgetFinder:<Found 1 widget with type "VistaEmptyState": [
            VistaEmptyState,
          ]>
   Which: means one was found but none were expected
LedgerScreen
```

### F7 LOW — Explore scroll offset resets after a simulated failure and Retry

**Location:** `app/lib/features/markets/markets_screen.dart:113-124` at e36eac8. Now: `markets_screen.dart:110-126` (the `IndexedStack` at `:114`, index at `:115`, the failed state at `:117-126`, the markets list from `:127`).

Scroll ALL MARKETS, turn on the failure, then Retry, and the list came back at offset 0. The two branches were bare, unkeyed `ListView`s under one ternary, and there is no `PageStorageKey` anywhere in `lib/`, so nothing restored the offset. Query, tab and sort survived because they live in `State`. The adjudicator reproduced it and corrected the mechanism: Flutter reused the same Scrollable, the content shrank to the single failed state, the position was clamped to 0, and it stayed there after Retry. The test needs a 360x640 phone; at the default 402x874 the Explore list cannot scroll.

**Fix asked for:** optional: give the loaded `ListView` a `PageStorageKey('explore-list')`, or accept the reset. The manager chose to keep the list's identity (decision above).

**Applied:** The failed/loaded ternary is now an IndexedStack (index 0 = failed state, 1 = markets list), so the markets ListView and its ScrollPosition stay mounted through the failure and Retry. The writer used the adjudicator's dart-format reference copy. Ignoring whitespace, it differs from the original only in the intended change, and `dart format --set-exit-if-changed` reports 0 changed. Added the test 'Explore keeps its scroll offset across a failure and Retry' at 360x640 with a `greaterThan(0)` guard. It failed first and passes after the edit.

**Test:** `app/test/empty_states_test.dart: Explore keeps its scroll offset across a failure and Retry`.

Red output, verbatim from the writer:

```text
══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞════════════════════════════════════════════════════
The following TestFailure was thrown running a test:
Expected: <130.0>
  Actual: <0.0>

When the exception was thrown, this was the stack:
#4      main.<anonymous closure> (file:///home/alex/VistaColosseum/.worktrees/br-2026-10-04-p0-queue/app/test/empty_states_test.dart:329:5)
...
The test description was:
  Explore keeps its scroll offset across a failure and Retry
════════════════════════════════════════════════════════════════════════════════════════════════════
00:01 +0 -1: Explore keeps its scroll offset across a failure and Retry [E]
```

## What the fixes now reject

Three adjudicator `rejectsValidInput` answers are not none: F2, F3 and F5. F1, F4, F6 and F7 answered none (F7: "None. Checked: ..."; the failed state, its text, Retry, the Settings toggle and Reset are unchanged).

**F2**, verbatim:

> It rejects an emptied list whose one action is no longer 'Explore markets', for example a Ledger that offers 'Make a market', and an own-receipts screen with other than two such actions. Spec 08 asks only for 'short line + one action' and does not name the action, so such a redesign meets the spec but must update this test. No document tells a human to produce that input today. The current copy on all nine lists is 'Explore markets'.

Document check: spec 08 says "short line + one action" and names no action. No doc asks for a different action on these lists.

**F3**, verbatim:

> It rejects a layout that puts a divider, a spacer or another row between Reset demo and the switch. The spec's 'next to Reset demo' could be read to allow that. A switch directly above Reset demo still passes, because the inflated rects overlap on either side. No document tells a human to separate the two rows. Spec 08 is the only placement source and says 'next to'.

Document check: spec 08 ("a presenter-only "Simulate load failure" toggle in Settings (next to Reset demo)") is the only placement source. At 289ec88 the Reset demo row (`settings_screen.dart:122-126`) is directly followed by the switch row (`:128-136`), with no spacer.

**F5**, verbatim:

> It rejects a fixture seed in which Positions, Open orders, the user's call receipts, the market's fee credits or followers are empty. Such a seed would turn the test red. The seed is defined in Scenario.reset (scenario.dart:362-384) and the *Mock files. No document tells a human to empty them; the PRD's demo depends on them being populated. Showing an empty state beside populated rows is not valid per spec 08 ('when the list is empty').

Document check: the seed is defined in `Scenario.reset` and the mock files. No doc tells anyone to ship an empty seed.

Nothing in the fixer run executed a rejected input. Every list `tapEach` pumps still offers 'Explore markets'. The Settings rows still touch. The only test that empties the seed (`emptyScenario()`) is not the F5 test, which reseeds with `reset(withMarket: true)`. The full suite (289) passes at 289ec88, and the closing unit's re-run of `empty_states_test.dart` passes 7/7.

## Refuted: 1

- **The empty-state action (including Markets Retry) exposes a button role and label but no semantics tap action.** Skeptic: "The claim is about code outside this diff. The Semantics(button, label, excludeSemantics: true) wrapper with no onTap is in vista_buttons.dart, last changed in 0fe0f52, and this diff does not touch it. The defect is real: excludeSemantics drops the GestureDetector's tap action, and SimulationIndicator passes onTap explicitly to avoid that. But it affects every VistaPillButton in the app, not something phase 8 added. The diff only adds more callers. File it separately as a design-system accessibility fix: add onTap: onPressed to the Semantics in VistaPillButton and check VistaSwitch for the same pattern."

## Checked claims that were wrong: 0

The skeptic spot-checked the lanes' "verified as correct" claims against the tree, and they held. Its `checkedClaimsThatAreWrong` list is empty.

## Residual risk (verbatim)

- tautology-hunt: I did not run any of my own mutants, because the run is read-only and creating files was forbidden. The no-op action and always-on guard survivors are inferred from the finders and from grep, not executed. The paper-receipts and switch-position survivors rely on the review probe's logs.
- tautology-hunt: I did not re-run flutter test. I relied on the stated gate pass at e36eac8 (287 tests).
- tautology-hunt: I did not check that a single tester.drag of -2000 builds every middle item of longer lists. In the emptied scenario the lists are short, so this is not a practical gap.
- tautology-hunt: Product-code correctness outside test strength (for example, the Home and Markets failed-state ListViews have no bottom padding for the pill strip) belongs to other lanes. I only noted it, and it passes expectPillClear at the small phones.
- state-truthfulness: Did not run any flutter test; all conclusions come from reading the source. The gate results (287 tests) were taken as given.
- state-truthfulness: Did not check that every review-baton L item (the duplicate Explore markets buttons, the text-only paper-receipts check, the surviving mutants) still reproduces.
- state-truthfulness: Follow-list empty copy ('No followers yet') sits beside static tab counts (FollowMock.followerCount '1,204'). This was not filed: the follow lists cannot be emptied by a user, only by the test's emptied scenario.
- state-truthfulness: The Ledger and Positions empty states are reachable only if a user can empty those collections in the app. Did not trace the close-position or market-unlisting paths.
- layout-empty-states: No device or emulator run. Layout checks rest on code reading plus the phase-8 gate logs and test assertions, not on screenshots at 360x640 or 375x667.
- layout-empty-states: Whether TalkBack or VoiceOver falls back to a simulated touch when no semantics tap action is present. This decides how serious the LOW finding is in practice.
- layout-empty-states: Ledger empty state after making a market under a new ticker: whether the footer total and the 'No fee credits yet' line agree. The money path is outside this lane.
- layout-empty-states: The 393, 412 and 430 px widths, and keyboard-up layout on Arena while the Ask empty state shows. The CrowdFilterPanel folds while the keyboard is up; behaviour was read, not rendered.
- state-truthfulness and layout-empty-states (merged): pill-strip clearance of the failed-state ListView at 1.3x was checked only by the test and code reading, not rendered; the failed ListView has no bottom padding of its own.

Closing-unit note (mine, not the lanes'): at 289ec88 the failed-state `ListView` inside the new `IndexedStack` (`markets_screen.dart:117`) still has no bottom padding of its own, and Retry still passes `expectPillClear` on both small phones at 1.3x.

## Verification after the fixes

finding-fixer verification (`scripts/gate.sh baton-runner/br-2026-10-04-p0-queue/gate-phase-8-fixer/`), verbatim:

```text
=== gate: flutter-analyze: flutter analyze ===
PASS flutter-analyze
=== gate: flutter-test: flutter test ===
PASS flutter-test
=== gate: pubspec-frozen: git diff --exit-code c95349cc2a9a40be16d4bddee74c512129ac0114 -- pubspec.yaml pubspec.lock ===
PASS pubspec-frozen
----
GATE: PASS
(flutter-test.log tail: 00:43 +289: All tests passed!)
```

Full gate after commit (`baton-runner/br-2026-10-04-p0-queue/gate-phase-8-close/`): `gate-stdout.log` `GATE: PASS` / `exit=0`, `flutter-test.log` `00:48 +289: All tests passed!`, `flutter-analyze.log` `No issues found!`, `has-market-tail.log` `00:56 +289: All tests passed!`. The closing unit re-ran one file at 289ec88: `cd app && flutter test test/empty_states_test.dart --reporter expanded` → `00:06 +7: All tests passed!`, exit 0 (`baton-runner/br-2026-10-04-p0-queue/close-phase-8/empty-states-test-expanded.log`).

GATE: PASS exit 0 at 289ec88, 289 tests, HAS_MARKET=true 289
