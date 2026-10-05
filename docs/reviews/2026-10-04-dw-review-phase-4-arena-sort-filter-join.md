# dw-review — `feat/br-2026-10-04-p0-queue/phase-4` (Arena sort, crowd filter and join, spec 04)

- **Target:** `feat/br-2026-10-04-p0-queue/phase-4`, phase 4 of baton-runner run `br-2026-10-04-p0-queue`: the Arena sort chips reorder the battles by Volume, Change and Funding; the crowd filter's histogram and range come from the battles' own crowd split, with an empty state and Show all; and the Bull/Bear buttons open the unit-02 ticket for the battle's asset, carrying a `clashId`, so a fill joins that side once per actionId (`docs/specs/04-arena-sort-filter-join.md`). Base is `main` (`c95349cc2a9a40be16d4bddee74c512129ac0114`), because phases 1-3 merged as [VistaColosseum#10](https://github.com/VistaMarkets/VistaColosseum/pull/10), [VistaColosseum#12](https://github.com/VistaMarkets/VistaColosseum/pull/12) and [VistaColosseum#13](https://github.com/VistaMarkets/VistaColosseum/pull/13). Diff reviewed: `origin/main...feat/br-2026-10-04-p0-queue/phase-4`.
- **Commit reviewed:** the review ran at `4fe2e7bf257050a47839d9271b515a51359dfbaf`. The fixes landed at `d63eb32444d98c4d358ffc4e25a564ffcc686667`.
- **Date:** 2026-10-04. Skill `dw-review`, run by `baton-runner-managed`. Workflow runs `wf_1cf11798-9fa` (review) and `wf_79eb73a7-c88` (finding-fixer).
- **Lanes:** tautology-hunt 4, state-participation 2, layout-filter-panel 2 (raw 8), plus the fixed skeptic. Merges: 0. Confirmed: 7 (2 MEDIUM, 5 LOW; the skeptic demoted F3 and F4 from MEDIUM to LOW). Refuted: 1. None is marked before-merge.
- **Disposition:** 7 applied, 0 annotated, 0 skipped, 0 unreported. Every adjudicator verdict was fix-here. F2, F3 and F7 change product code (`app_shell.dart`, `arena_mock.dart`, `arena_screen.dart`), each behind a test written first that ran red. F1, F4, F5 and F6 are test-strength fixes in `home_screen_test.dart`, each mutation-proven: the mutant survived the old tests and the new tests kill it.

## Verdict: APPROVE

"Scope checks out. The ref feat/br-2026-10-04-p0-queue/phase-4 resolves to 4fe2e7b, which is also the worktree HEAD. The three-dot diff has 53 files, 10 of them under app/. Of the 8 findings, 7 hold up against the tree and 1 is refuted. None is CRITICAL or HIGH, and none involves anything that freezes at merge (no migrations, schemas or wire formats). The two MEDIUMs are a missing Bear-side test (three mutants that record or show the wrong side get through the whole suite) and live Ask results hidden by the crowd panel while the keyboard is open. The rest are LOW: test-strength gaps, fixtures that disagree with the Markets tab, and a scroll offset that stays clamped after narrowing the filter. Nothing must be fixed before merge. The Bear-side test is the cheapest worthwhile fix and should go in first."

## Confirmed findings

### F1 MEDIUM — Bear-side join is never asserted; three wrong-side mutants survive

**Location:** app/test/home_screen_test.dart:1063-1080 (AC2 test), app/test/scenario_test.dart:342-360; production code at app/lib/scenario/scenario.dart placeOrder participation write, app/lib/features/arena/arena_screen.dart:137-138, app/lib/design_system/components/vista_battle.dart joined labels at 4fe2e7b; now tests `app/test/home_screen_test.dart:1143-1144` (joining test) and `:1171`, `:1178-1180` (AC2 test); `scenario_test.dart:342-360` unchanged; production unchanged at `scenario.dart:242-246`, `arena_screen.dart:146-147`, `vista_battle.dart:210, 217` at d63eb32. Raised by tautology-hunt.

Every participation and Joined assertion uses the long side. The scenario test fills only ethLong and checks {'eth-4k': long}. The widget join test checks 'and 15' and finds exactly one 'Joined Bull'. The AC2 test fills an ETH short but checks only positions.first.clashId and side, never participation, 'Joined Bear' or the bear crowd line. Three mutants get through: (1) `clash: TradeSide.long` in placeOrder records a Bear fill as Bull; (2) `bear: b.bear.withCrowd(crowd(b.bearCount, TradeSide.long))` makes the BTC bear line read 'and 7' after a Bull fill, and no test checks 'and 6' or 'and 7'; (3) `joined != null ? 'Joined Bear'` makes both buttons say Joined after a Bull join, yet findsOneWidget('Joined Bull') still passes. grep finds 'Joined Bear' in no test at all.

**Adjudicated:** The adjudicator dropped the finding's extra `Scenario.joins('eth-4k', TradeSide.short)` check, because 'and 13' proves it through the UI, and added the mirror assertion ('Joined Bull' absent after a Bear join).

**Applied:** F1.1 adds 'Joined Bear' findsNothing and 'and 6' findsOneWidget to JOINW. F1.2 adds the participation == {'eth-4k': short} assertion to AC2, then Done and Back, then 'Joined Bear' present, 'Joined Bull' absent and 'and 13' present. All four mutants survived the old tests, and each is now killed by at least one test (output in red). Each mutant was applied in place, one at a time, and restored afterwards. md5 confirms lib/ is unchanged.

**Test:** `app/test/home_screen_test.dart: joining: Cancel counts nothing; a fill counts once, shows` and `app/test/home_screen_test.dart: a battle's opinions trade that battle's asset and clash`.

Red output, verbatim from the writer:

```text
BEFORE (old tests):
[f1-1-participation-long] SURVIVED :: joining: Cancel counts nothing; a fill counts once, shows
[f1-1-participation-long] SURVIVED :: a battle's opinions trade that battle's asset and clash
[f1-2-bear-crowd-long] SURVIVED :: joining: Cancel counts nothing; a fill counts once, shows
[f1-2-bear-crowd-long] SURVIVED :: a battle's opinions trade that battle's asset and clash
[f1-3-bear-label-any] SURVIVED :: joining: Cancel counts nothing; a fill counts once, shows
[f1-3-bear-label-any] SURVIVED :: a battle's opinions trade that battle's asset and clash
[f1-4-bull-label-any] SURVIVED :: joining: Cancel counts nothing; a fill counts once, shows
[f1-4-bull-label-any] SURVIVED :: a battle's opinions trade that battle's asset and clash
AFTER (new tests, same mutants):
[f1-1-participation-long] KILLED :: a battle's opinions trade that battle's asset and clash
    Expected: {'eth-4k': TradeSide:TradeSide.short}
      Actual: {'eth-4k': TradeSide:TradeSide.long}
[f1-2-bear-crowd-long] KILLED :: joining: Cancel counts nothing; a fill counts once, shows
    Expected: exactly one matching candidate
      Actual: _TextWidgetFinder:<Found 0 widgets with text "and 6": []>
[f1-2-bear-crowd-long] KILLED :: a battle's opinions trade that battle's asset and clash
      Actual: _TextWidgetFinder:<Found 0 widgets with text "and 13": []>
[f1-3-bear-label-any] KILLED :: joining: Cancel counts nothing; a fill counts once, shows
    Expected: no matching candidates
      Actual: _TextWidgetFinder:<Found 1 widget with text "Joined Bear": [
[f1-4-bull-label-any] KILLED :: a battle's opinions trade that battle's asset and clash
    Expected: no matching candidates
      Actual: _TextWidgetFinder:<Found 1 widget with text "Joined Bull": [
```

### F2 MEDIUM — Ask's live results and no-match hint are squeezed out while the keyboard is up

**Location:** app/lib/app_shell.dart:75-150 (dock under Expanded tabs, heightFactor depends only on `arena`); app/lib/features/arena/arena_screen.dart:57 at 4fe2e7b; now `app/lib/app_shell.dart:74-76` (`panelOpen`) and `:126-136` (heightFactor, opacity, IgnorePointer, ExcludeSemantics); Ask still live at `arena_screen.dart:65`; test `home_screen_test.dart:1095` at d63eb32. Raised by layout-filter-panel.

The Scaffold body is Column[Expanded(tabs), dock], and resizeToAvoidBottomInset is left at its default. When the soft keyboard opens, the body shrinks but the dock keeps the full crowd panel plus the nav. With no keyboard the dock starts at about y=406 on 360x640, so it is about 234 px tall. With a 280 dp keyboard that leaves roughly 126 px for the tab. After SafeArea, the Ask bar and the sort-chip row, the battle list has only single-digit to low-tens of pixels. This diff makes Ask filter live through onChanged, replacing the old onSubmitted not-built toast, so the results (or 'Try BTC, ETH, SOL') can't be seen until the keyboard closes. The squeeze itself predates this diff. What's new is that a live feature now depends on that space.

**Applied:** F2.3 regression test added first (arena group, 'with the keyboard up the panel folds and Ask results show'), then F2.1 added `panelOpen = arena && MediaQuery.viewInsetsOf(context).bottom == 0` and F2.2 moved heightFactor, opacity and its curve, IgnorePointer and ExcludeSemantics onto panelOpen. The panel stays mounted. Decoration, shadow, padding and resizeToAvoidBottomInset are unchanged. dart format reports 0 changed and the test passes after the fix.

**Test:** `app/test/home_screen_test.dart: with the keyboard up the panel folds and Ask results show`.

Red output, verbatim from the writer:

```text
00:00 +0: arena with the keyboard up the panel folds and Ask results show
══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞════════════════════════════════════════════════════
The following TestFailure was thrown running a test:
Expected: no matching candidates
  Actual: _HitTestableWidgetFinder:<Found 1 widget with type "RangeSlider" (considering only
hit-testable widgets with a RenderBox): [
            RangeSlider(valueStart: 0.0, valueEnd: 1.0, min: 0.0, max: 1.0, divisions: 10,
labelStart: null, labelEnd: null, activeColor: null, inactiveColor: null, has
semanticFormatterCallback, dependencies: [InheritedCupertinoTheme, MediaQuery, SliderTheme,
_InheritedTheme, _LocalizationsScope-[GlobalKey#65781]], state: _RangeSliderState#554a4(tickers:
tracking 5 tickers)),
          ]>
   Which: means one was found but none were expected
...
00:01 +0 -1: arena with the keyboard up the panel folds and Ask results show [E]
  Test failed. See exception logs above.
00:01 +0 -1: Some tests failed.
```

### F3 LOW — New ETH/SOL battle fixtures contradict the Markets tab for the same assets; Funding sort ranks ETH opposite

**Location:** app/lib/features/arena/arena_mock.dart:133-134, 190-191 (and BTC fundingPct :97, volume :95) at 4fe2e7b; now `app/lib/features/arena/arena_mock.dart:98-99` (BTC), `:134-135` (ETH), `:191-192` (SOL), `asked`/`visible` pool parameter at `:251`, `:270`; tests `home_screen_test.dart:948` (re-pinned), `:965` (guard), `:976` (test-local tiebreak) at d63eb32. Raised by state-participation (lane MEDIUM; the skeptic demoted it to LOW).

Markets has ETH changePct -0.4 and Funding -0.004, SOL 3.8 and 0.012, BTC 0.009 (markets_mock.dart). TradeMock quotes also show ETH -0.4 and SOL 3.8. The Arena battles use ETH -0.8 and 0.031, SOL 3.4 and 0.031, BTC 0.010. So the ETH card shows '− 0.8%' while Markets shows −0.4%. Arena's Funding chip puts ETH first while Markets' Funding sort puts it last. Only mock data is affected: no state, money or records. (The ETH bear thesis text says funding is 'hot at 0.03%', which is the fixture's own rationale, but it still contradicts the Markets tab.)

**Adjudicated:** The adjudicator aligned the literals with MarketsMock and added a guard test rather than reading MarketsMock by asset, so a test-local fixture can still carry its own change and funding values. The manager's decision allowed this ("read by asset where simple"). Volume is unchanged: Markets has no volume column, and Arena volume already gives the same BTC > ETH > SOL order.

**Applied:** Test changes went in first and ran red: the arena_mock import (F3.9), the Funding re-pin to ['SOL','BTC','ETH'] (F3.10) and the guard test 'each battle quotes its asset as the Markets tab does' (F3.11). Then the optional pool parameter on asked() and visible() (F3.7 and F3.8, defaulting to `battles`, so callers are unchanged) and the test-local unit test 'sorts by the chip field, highest first, ties by id'. That test is mutation-proven: with `return c != 0 ? c : a.id.compareTo(b.id);` changed to `return c;` it failed with `Expected: ['c', 'a', 'b'] / Actual: ['c', 'b', 'a']`, and it passed again after the revert. Last came the literals and doc (F3.1 to F3.6): BTC funding 0.009, ETH -0.4/-0.004, SOL 3.8/0.012, and the ETH bear thesis rewritten in both places. Grep finds no remaining 'Funding is hot' or '0.03%'. Volume is left alone, as adjudicated. All 17 arena tests pass.

**Test:** `app/test/home_screen_test.dart: sort chips order the battles by volume, change and funding` (re-pinned), `app/test/home_screen_test.dart: each battle quotes its asset as the Markets tab does` (new guard) and `app/test/home_screen_test.dart: sorts by the chip field, highest first, ties by id` (new, test-local pool).

**Close-out note (this closing unit; reasoned from source, not run):** with the aligned fixtures, Change and Funding give the same live order (SOL, BTC, ETH), which the adjudicator flagged. The test-local unit test pins the index-to-field mapping in `visible()`, but not the chip-label order in `ArenaMock.sorts` (`arena_mock.dart:80`). A mutant that swaps it to `['Volume', 'Funding', 'Change']` makes the Change chip sort by funding and the Funding chip by change, and every test still passes: before F3, the widget test's Funding order (ETH, SOL, BTC) would have caught it. LOW, test strength only, product code correct. The cheapest guard is one assertion, for example `expect(Scenario.arena.value.sort, 2)` after tapping Funding. Not fixed here (this unit changes no tests).

Red output, verbatim from the writer:

```text
Expected: ['SOL', 'BTC', 'ETH']
  Actual: ['ETH', 'SOL', 'BTC']
   Which: at location [0] is 'ETH' instead of 'SOL'
  file:///home/alex/VistaColosseum/.worktrees/br-2026-10-04-p0-queue/app/test/home_screen_test.dart line 959
  sort chips order the battles by volume, change and funding
00:01 +0 -1: arena sort chips order the battles by volume, change and funding [E]
  Test failed. See exception logs above.
  The test description was: sort chips order the battles by volume, change and funding
00:01 +0 -2: arena each battle quotes its asset as the Markets tab does [E]
  Expected: (double, double):<(1.2, 0.009)>
    Actual: (double, double):<(1.2, 0.01)>
  BTC
  package:matcher                                     expect
  package:flutter_test/src/widget_tester.dart 473:18  expect
  test/home_screen_test.dart 968:9                    main.<fn>.<fn>
00:01 +0 -2: Some tests failed.
```

### F4 LOW — Opinions-screen derived strings are only asserted on BTC, whose values equal the deleted constants

**Location:** app/test/home_screen_test.dart:1116-1161 (openOpinions taps '+21 more opinions' = BTC); app/lib/features/arena/opinions_screen.dart:38,77,138 at 4fe2e7b; now `app/test/home_screen_test.dart:1157-1159` inside the AC2 test; `opinions_screen.dart:31, 38, 77, 138` unchanged at d63eb32. Raised by tautology-hunt (lane MEDIUM; the skeptic demoted it to LOW).

BTC's bullPct 63, opinionCount 23 and OpinionsMock.opinions equal the removed bullShare 0.63, '23 opinions' and OpinionsMock.opinions. The AC2 test opens ETH ('+7 more opinions') but asserts only the ticket and the position. So `final bull = 63;`, a literal '23 opinions' or `OpinionsMock.opinions.where(...)` all pass the suite. The production code is currently correct (b.bullPct, b.opinionCount, b.opinions); only the guard is missing.

**Applied:** F4.1 asserts ETH's own 'Crowd split 28% bull', 'Crowd split · 9 opinions' (U+00B7) and '@lunaq' on the ETH opinions screen in AC2. All three opinions_screen mutants survived the old AC2 and LABEL tests, and AC2 now kills each one. They were applied one at a time and reverted.

**Test:** `app/test/home_screen_test.dart: a battle's opinions trade that battle's asset and clash`.

Red output, verbatim from the writer:

```text
BEFORE (old tests):
[f4-a-bull-63] SURVIVED :: a battle's opinions trade that battle's asset and clash
[f4-a-bull-63] SURVIVED :: the crowd split is labelled crowd split, never odds
[f4-b-count-23] SURVIVED :: a battle's opinions trade that battle's asset and clash
[f4-b-count-23] SURVIVED :: the crowd split is labelled crowd split, never odds
[f4-c-btc-opinions] SURVIVED :: a battle's opinions trade that battle's asset and clash
[f4-c-btc-opinions] SURVIVED :: the crowd split is labelled crowd split, never odds
AFTER (new tests, same mutants):
[f4-a-bull-63] KILLED :: a battle's opinions trade that battle's asset and clash
      Actual: _TextWidgetFinder:<Found 0 widgets with text "Crowd split 28% bull": []>
[f4-b-count-23] KILLED :: a battle's opinions trade that battle's asset and clash
      Actual: _TextWidgetFinder:<Found 0 widgets with text "Crowd split · 9 opinions": []>
[f4-c-btc-opinions] KILLED :: a battle's opinions trade that battle's asset and clash
      Actual: _TextWidgetFinder:<Found 0 widgets with text "@lunaq": []>
```

### F5 LOW — Ask test uses whole tickers; an exact-match mutant passes

**Location:** app/test/home_screen_test.dart:1005-1027; app/lib/features/arena/arena_mock.dart asked() at 4fe2e7b; now `app/test/home_screen_test.dart:1077-1080`; `arena_mock.dart:251` `asked()` unchanged at d63eb32. Raised by tautology-hunt.

The test inputs 'eth' (uppercased to exactly 'ETH') and 'doge'. Replacing `b.asset.contains(q)` with `b.asset == q` passes both, which breaks the spec's substring behaviour for inputs like 'bt' or 'et'.

**Adjudicated:** The adjudicator found that the exact mutant the finding names (`b.asset == q`) is already killed, because an empty query then matches nothing. Two near mutants survived: whole-ticker match and prefix match. The finding's suggested input 'bt' is a prefix of BTC, so the fix uses 'th' instead, which kills both.

**Applied:** F5.1 adds an Ask of 'th' that expects ['ETH']. Both the whole-ticker and prefix mutants survived the old ASK test, and the new test kills both. Each was reverted.

**Test:** `app/test/home_screen_test.dart: Ask filters by asset; no match names the assets there are`.

Red output, verbatim from the writer:

```text
BEFORE (old test):
[f5-a-whole-ticker] SURVIVED :: Ask filters by asset; no match names the assets there are
[f5-b-prefix] SURVIVED :: Ask filters by asset; no match names the assets there are
AFTER (new test, same mutants):
[f5-a-whole-ticker] KILLED :: Ask filters by asset; no match names the assets there are
    Expected: ['ETH']
      Actual: []
       Which: at location [0] is [] which shorter than expected
[f5-b-prefix] KILLED :: Ask filters by asset; no match names the assets there are
    Expected: ['ETH']
      Actual: []
       Which: at location [0] is [] which shorter than expected
```

### F6 LOW — Empty-state test can't tell Show all from 'reset only the upper bound'

**Location:** app/test/home_screen_test.dart:988-1002; app/lib/features/arena/arena_screen.dart:174-175 at 4fe2e7b; now `app/test/home_screen_test.dart:1056-1062`; `arena_screen.dart:183-184` unchanged at d63eb32. Raised by tautology-hunt.

The test empties the list with dragThumb(tester, 1, 0.2), so from=0 and to=2. The mutant `Scenario.setArena(to: ArenaMock.bucketCount)` still produces 'Crowd split 50/50 +' and '3 battles'. In the app, an empty range reached from the lower thumb (from=9, to=10, which VistaRangeSlider allows as a one-bucket width) would stay empty after Show all.

**Adjudicated:** The lower-thumb empty state is reachable: VistaRangeSlider allows a one-bucket width, so dragging the lower thumb to 0.9 gives from=9, to=10, which holds no battle.

**Applied:** F6.1 empties the list from the lower thumb (dragThumb 0 to 0.9, giving '0 battles'), taps Show all, and expects '50/50 +' and '3 battles'. The `setArena(to: ...)`-only mutant survived the old test and is killed now. The first assertion to fail is the 'Crowd split 50/50 +' line, one line before the '3 battles' line the adjudicator predicted. It was reverted.

**Test:** `app/test/home_screen_test.dart: an empty crowd split says so; Show all restores the cards`.

Red output, verbatim from the writer:

```text
BEFORE (old test):
[f6-show-all-to-only] SURVIVED :: an empty crowd split says so; Show all restores the cards
AFTER (new test, same mutant):
[f6-show-all-to-only] KILLED :: an empty crowd split says so; Show all restores the cards
    Expected: exactly one matching candidate
      Actual: _TextWidgetFinder:<Found 0 widgets with text "Crowd split 50/50 +": []>
       Which: means none were found but one was expected
```

### F7 LOW — Narrowing the range while scrolled keeps a clamped offset; the remaining card opens partway down

**Location:** app/lib/features/arena/arena_screen.dart:105-116 at 4fe2e7b; now `app/lib/features/arena/arena_screen.dart:26-27` (`_list`, `_shown`), `:38-44` (`_followView`), `:49` (dispose), `:114` (controller on the ListView); test `home_screen_test.dart:1201` at d63eb32. Raised by layout-filter-panel.

The ListView has no controller and no key tied to the view. When the visible set shrinks, ScrollPosition keeps its pixels clamped to the new maxScrollExtent. If the one remaining card is taller than the viewport, it shows partway down with its header off-screen. Presentation only: count and cards agree.

**Applied:** F7.3 test 'a narrower range starts the list at the top' went in first and failed with an offset of 135.0. Then F7.1 added the _list ScrollController and the _shown count, renamed the listener _followQuery to _followView (it jumps to 0 only when the visible count shrinks) and disposes the controller. F7.2 attached the controller to the ListView. The test passes after the fix. Mutation check: deleting `if (shown < _shown && _list.hasClients) _list.jumpTo(0);` brings back `Expected: <0> / Actual: <135.0>`. The mutation was reverted.

**Test:** `app/test/home_screen_test.dart: a narrower range starts the list at the top`.

Red output, verbatim from the writer:

```text
══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞════════════════════════════════════════════════════
The following TestFailure was thrown running a test:
Expected: <0>
  Actual: <135.0>

When the exception was thrown, this was the stack:
#4      main.<anonymous closure>.<anonymous closure> (file:///home/alex/VistaColosseum/.worktrees/br-2026-10-04-p0-queue/app/test/home_screen_test.dart:1197:7)
...
00:01 +0 -1: arena a narrower range starts the list at the top [E]
00:01 +0 -1: Some tests failed.
```

## What the fixes now reject

Adjudicator answers to "does this fix reject valid input", where the answer is not none:

- **F2**, verbatim:

  > None. The only behaviour change: while a bottom view inset is non-zero on the Arena tab, the crowd panel folds and the range slider can't be used until the keyboard closes. A drag on the list closes it (`keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag`, arena_screen.dart:106).
  >
  > A hardware or floating keyboard reports an inset of 0, so the panel stays open there, as it does today. The range still comes from Scenario.arena and is restored when the panel unfolds; the test checks that '0 battles' persists.
  >
  > No document tells a human to adjust the crowd range with the soft keyboard open. Spec 04 line 16 describes only Ask filtering and the 'Try BTC, ETH, SOL' hint.

- **F3**, verbatim:

  > The optional `pool` parameter defaults to `battles`, so every existing call (arena_screen.dart, crowd_filter_panel.dart buckets via asked) behaves the same. No runtime input is rejected.
  >
  > The new guard test does reject two kinds of future fixture:
  > - a Battle whose changePct or fundingPct differs from Markets
  > - a Battle on an asset absent from MarketsMock.assets (firstWhere throws StateError)
  >
  > No document tells a human to add a battle on a non-Markets asset or with its own change or funding. Spec 04 only says to give Battle numeric fixture fields, and its Ask hint is derived from the fixtures. So no producing procedure is broken.

- **F7**, verbatim:

  > No input is rejected. Every setArena call is still accepted, and only the scroll offset changes, and only when the visible count drops.
  >
  > One side effect: giving the ListView an explicit controller means it no longer inherits the route's PrimaryScrollController on mobile. On iOS, a status-bar tap would therefore no longer scroll the Arena list to the top. No doc in the repo (spec 04, CONTEXT.md, ARCH.md) describes or relies on that gesture, and grep finds no PrimaryScrollController use in app/lib or app/test.

- **F5 (qualified):** "None that the spec allows. A prefix-only or exact-match Ask implementation would now fail, but spec 04 line 16 requires substring matching, so those are not correct inputs." What it rejects is an implementation, not a user input.

F1, F4 and F6 answer none: each adds test assertions only.

The documents that teach a human to produce each rejected input:

- **F2, the crowd range while the soft keyboard is up.** `docs/specs/04-arena-sort-filter-join.md` Behavior teaches each half on its own: line 12 ("Range selection filters the visible cards") and line 16 (the Ask field). No document teaches doing both at once, which is the adjudicator's finding. A hardware or floating keyboard reports an inset of 0, so the panel stays open there.
- **F3, a battle fixture whose change or funding differs from Markets, or on an asset Markets does not list.** Spec 04 line 10 ("Give `Battle` numeric fixture fields") is the only document about adding battle fixtures, and it does not ask for values that differ from Markets. The guard test now fails on such a fixture.
- **F7, the iOS status-bar tap that scrolls the Arena list to the top.** No document in the repo teaches it (spec 04, CONTEXT.md and ARCH.md are silent, and nothing in app/ uses PrimaryScrollController). It is an iOS platform convention, lost because the list now owns its ScrollController.

Nothing in the fixer run executed a rejected input. The F2 test checks that the slider is not hit-testable while the keyboard is up; it never drags it. These are claims the full gate has not contradicted, not test results.

## Refuted: 1

- **Ask matches only the ticker, so asking by asset name falsely reports no battle.** The spec says to filter by 'asset/ticker substring', and the same spec defines `asset` as a Battle field. Battle.asset is the ticker ('BTC'), and asked() does a substring match on it, exactly as written. The no-match state then shows 'Try BTC, ETH, SOL', which is the spec-mandated hint pointing users to tickers, so the user is not misled. Matching full names (TradeMock.quotes[...].name) would be a feature extension, not a defect in this diff.

## Checked claims that were wrong: 2

The skeptic's two entries, verbatim. The first is a wrong premise in two lanes. The second records the spot-checks that held.

> The layout lens says 'from == to (the slider thumbs coincide): VistaHistogram's (from, to-1) selection highlights nothing, the list is empty and Show all appears. Consistent.' Its premise is wrong. VistaRangeSlider.onChanged (vista_market.dart:693-695) refuses any range narrower than one division ('Keep at least one bucket selected'), so the thumbs cannot coincide and from == to is unreachable from the UI. The conclusion does no harm, but the state it checks never happens. The state lens's residual-risk note that the 'range slider can collapse to an empty [from,to) window' is wrong for the same reason.

> Spot-checks that held: the state lens's 'participation write sits after the receipt write and after problem()/stale-price failure; resting orders return before it' (scenario.dart:163-247 confirms it); the lane's 'battle card colours a −-prefixed change as negative' (vista_battle.dart checks both '-' and '−'); the layout lens's 'dock bottom padding includes SimulationIndicator.slot' (simulation_indicator.dart:80 sets padding.bottom + slot); _newActionId is a single library-level 'act-N' counter (order_ticket.dart:799) and no seed uses an 'act-' id.

## Residual risk (verbatim)

- Mutants were reasoned from source, not executed: the lane is read-only, so the four surviving mutants above were not run. (tautology-hunt)
- Order-ticket actionId generation on the widget path (whether a double-tap on Confirm reuses the same actionId) is outside this test-strength lane; dedupe is only proven at the Scenario level. (tautology-hunt)
- Histogram response to the Ask query (buckets(view.query)) is not asserted, but the spec does not require it, so it is not filed. (tautology-hunt)
- Did not review the non-test production diff for correctness beyond what each mutation needed, nor layout/pill clearance (the review's L5 probe). (tautology-hunt)
- Did not run flutter tests; relied on gate facts given (233 pass both configs) and source reading. (state-participation)
- Crowd filter panel geometry/semantics, histogram selected tuple when from==to, and the 30px pill strip are outside this lane (panel/layout reviewer). (state-participation)
- Prior iter-1 findings M1 (Wallet clash ref data-only, accepted by manager), L2 (joins count fills not participants; Bull-then-Bear shows Joined Bear while bull count includes the user) and L6 (caller price fixtures) were confirmed in passing but not re-filed. (state-participation)
- Static Battle.price strings vs MarketPrices live ticking price on the ticket were not compared for BTC drift (pre-existing BTC pattern). (state-participation)
- The fixture's bullPct vs bull/bear counts (e.g. BTC 63% vs 15:7 heads) are inconsistent but pre-existing seed values; not filed. (state-participation)
- Real-device IME behaviour: the keyboard finding uses a simulated 280 dp viewInsets, so actual keyboard heights vary by device and locale. (layout-filter-panel)
- Touch-target size of the range slider thumbs: VistaRangeSlider's 24 px SizedBox predates this diff and was not re-reviewed. (layout-filter-panel)
- Screen-reader announcements of the panel count after a range change (no live region); not in spec 04. (layout-filter-panel)
- Landscape orientation and text scales above 1.3; the app caps at 1.3 per simulation_indicator.dart. (layout-filter-panel)
- The order-ticket sheet's layout when it opens from the Arena or the opinions screen with a clashId: the ticket's layout is phase-2 context and outside this lane. (layout-filter-panel)

## Verification after the fixes

finding-fixer verification (`scripts/gate.sh baton-runner/br-2026-10-04-p0-queue/gate-phase-4-fixer/`), verbatim:

```text
=== gate: flutter-analyze: flutter analyze ===
PASS flutter-analyze
=== gate: flutter-test: flutter test ===
PASS flutter-test
=== gate: pubspec-frozen: git diff --exit-code c95349cc2a9a40be16d4bddee74c512129ac0114 -- pubspec.yaml pubspec.lock ===
PASS pubspec-frozen
----
GATE: PASS
exit=0
(flutter-test.log tail: 00:37 +237: All tests passed!; flutter-analyze.log tail: No issues found! (ran in 0.9s))
```

Full gate after commit (`baton-runner/br-2026-10-04-p0-queue/gate-phase-4-close/`):

GATE: PASS exit 0 at d63eb32, 237 tests, HAS_MARKET=true 237
