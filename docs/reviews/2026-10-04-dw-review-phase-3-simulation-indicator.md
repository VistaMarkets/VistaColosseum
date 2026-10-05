# dw-review — `feat/br-2026-10-04-p0-queue/phase-3` (persistent simulation indicator, spec 03)

- **Target:** `feat/br-2026-10-04-p0-queue/phase-3`, phase 3 of baton-runner run `br-2026-10-04-p0-queue`: one persistent "Simulated · fixture-v1" pill drawn over every tab, pushed route and sheet, its note sheet, and a single `resetDemo()` path shared with Settings (`docs/specs/03-simulation-indicator.md`). Base is `main` (`d77fe5916d92125f30c67f36ca4ea013d32bade2`), because phases 1 and 2 merged as [VistaColosseum#10](https://github.com/VistaMarkets/VistaColosseum/pull/10) and [VistaColosseum#12](https://github.com/VistaMarkets/VistaColosseum/pull/12). Diff reviewed: `origin/main...feat/br-2026-10-04-p0-queue/phase-3`.
- **Commit reviewed:** the review ran at `42ae15b0f9f98b937f8fba803c5a6c5369461f0b`. The fixes landed at `ee8f52cf248dec44f9634f8830049ba902ca8e48`.
- **Date:** 2026-10-04. Skill `dw-review`, run by `baton-runner-managed`. Workflow runs `wf_3b40d5fa-7db` (review) and `wf_682e549c-b36` (finding-fixer).
- **Lanes:** tautology-hunt 2, layout-reachability 2, state-truthfulness 1 (raw 5), plus the fixed skeptic. Merges: 1 (tautology-hunt's Settings-reset finding and state-truthfulness's finding are the same gap, now F3). Confirmed: 4 (1 MEDIUM, 3 LOW; the skeptic demoted F2 from MEDIUM). None is marked before-merge.
- **Disposition:** 3 applied, 1 annotated, 0 skipped, 0 unreported. F2 and F3 are test-strength fixes, each mutation-proven. F4 adds two design-system tokens with identical values. F1 is annotated only: the adjudicator found that the manager's chosen fix would cover action buttons that spec 03 says must stay uncovered, so a comment next to `SimulationIndicator.slot` records the gap and the choice is left to the user.

## Verdict: APPROVE

"The scope is sound. feat/br-2026-10-04-p0-queue/phase-3 resolves to 42ae15b, which is also the worktree HEAD, and the three-dot diff lists 55 files. All five findings hold up against the tree, but none is CRITICAL or HIGH and nothing here freezes at merge. Findings 2 and 5 describe the same gap and are merged below. That leaves four survivors: one MEDIUM product issue (the pill's 30px tap target, an outlier in a codebase that wraps every 30px chip in a 44px hit area and still waiting on a design call) and three LOWs. Two LOWs are test gaps: the leverage tests never check that Set clears the pill, and no test runs the Settings reset inside the real app. The third LOW is the hardcoded scrim colour. I demoted the leverage test gap from MEDIUM to LOW: the product code is correct today, and the surviving mutant is worked out on paper rather than run. Every claimed-correct item I spot-checked held. All survivors can be fixed after merge."

## Confirmed findings

### F1 MEDIUM — The pill's tap target is 30px tall, below VistaSize.tapTarget (44), and the codebase's own pattern gives every 30px chip a 44px hit area

**Location:** `app/lib/features/simulation/simulation_indicator.dart:40, 81-97` at 42ae15b; now `simulation_indicator.dart:47` (`slot`, with the F1 comment at :39-46) and :88-105 (the Positioned strip and its GestureDetector) at ee8f52c.

On any route, at any viewport or text scale, the GestureDetector sits inside Positioned(height: SimulationIndicator.slot = 30). Its Align(widthFactor: 1) fills the 30px strip, so the hit region is the pill's width by 30px (93.5-266.5 x 610-640 at 360x640, per cta_probe.log). Outside Settings, the pill is the only way to reach the note and its Reset demo. This is the iter-1 M4, still open and waiting on a design call.

**Annotated (real-but-decided-elsewhere):** the adjudicator confirmed the defect and showed the decided fix cannot land as written. Its evidence, verbatim:

> The claim holds. simulation_indicator.dart:86 `height: SimulationIndicator.slot,` with :40 `static const double slot = 30;`. The Semantics/GestureDetector sit in that Positioned, and `Align(widthFactor: 1)` (:97-98) fills the 30 px height, so the hit and semantics rect is pill-width x 30. vista_metrics.dart:27 `static const double tapTarget = 44;`. The chips do pad to 44: order_ticket.dart `SizedBox(height: 44, child: Center(child: Container(height: 30` and `_chip` `SizedBox(height: 44 ... height: 28`, and open_order_card.dart `SizedBox(height: VistaSize.tapTarget, ... height: 30`.
>
> Rule 10's re-check FAILS, so the decided pad cannot land as written. Three action buttons end exactly on the strip's top edge, because each pads its bottom by the inset, which already includes the slot:
> - make_market_flow.dart:138 `bottomInset > 0 ? bottomInset : 30,` in `_footer`, which holds `VistaPrimaryButton` (:203, :213).
> - chart_sheet.dart:255 `bottomInset > 0 ? bottomInset : VistaSpace.gutter,` under the `Long`/`Short` VistaPillButtons (:261-270). asset_trade_screen.dart:68 `return ChartSheet(` is the 'Details' route.
> - your_market_screen.dart:137, same expression, under `VistaPillButton(label: 'Make a call'`.
>
> opinions_screen.dart:181 and position_sheet.dart:97 use the same flush pattern. A pad that reaches 14 px above the strip sits on the bottom 14 px of each of these buttons, across the pill's width (93.5-266.5 at 360). The overlay is the later Stack child, so with `HitTestBehavior.opaque` it wins the tap, and those taps open the note instead of the CTA. Spec 03 Behavior is binding: "Must not cover nav, form fields or action buttons at 375×667 and 390×844".
>
> The tests already encode this. home_screen_test.dart `expectPillClear(tester, find.byType(VistaPrimaryButton));` (make-market test) and `expectPillClear(tester, find.byType(VistaPillButton).hitTestable());` (Details route) compare `tester.getRect(find.bySemanticsLabel(pill))` with `rect.overlaps`. The semantics rect has to grow to 44 for iOSTapTargetGuideline to pass, so both assertions would fail.
>
> The nav also fails the rect check, though not functionally. AppShell pads the dock `VistaSpace.sm + bottomInset` (6), and VistaBottomNav has `padding: const EdgeInsets.all(VistaSpace.md)` (8). A 14 px pad reaches 8 px into the nav container, which is padding with no item in it, so `expectPillClear(tester, find.byType(VistaBottomNav))` would fail on rects only.
>
> Rule 10 forbids raising the slot, and spec 03 forbids covering action buttons. Within those two decisions the 30 px hit area is the consequence. Closing F1 needs the manager to pick one of two options: raise the slot (rejected under rule 10), or move the flush footers (make_market_flow, chart_sheet, your_market_screen, opinions_screen, position_sheet) 14 px clear of the strip. The second option is 5 files, above the scope-confirmation threshold and outside the indicator file. The edit below only records the decision and its cost next to `slot`.

The decision that owns it is two rules pulling against each other:

- **The run manager's rule 10** (run log `baton-runner/br-2026-10-04-p0-queue/log.md`, 2026-10-05T01:34:10Z): "F1 fix = keep the 30px visual strip, extend the pill's hit area upward to VistaSize.tapTarget with a transparent pad (the codebase's chip pattern), re-checked clear of bottom nav and sheet buttons; not raising the slot." The house rules also keep the reserved bottom strip as decided for spec 03.
- **Spec 03's no-cover rule** (Behavior): "Must not cover nav, form fields or action buttons at 375×667 and 390×844". The rule-10 re-check fails against it on five flush footers.

**What landed:** Comment-only (F1.1): records next to SimulationIndicator.slot that the pill's tap target is the 30 px strip, below VistaSize.tapTarget. A pad above the strip would cover footers that end flush on it, and raising the slot is rejected by rule 10, so the manager has to choose. No behaviour change. The comment says "Closing it is the manager's call"; the run log routes the call to the user, which is the owner this record names.

**Who decides next: the user.** Two options:

1. Raise `SimulationIndicator.slot` to `VistaSize.tapTarget` (44). Every screen loses 14px, and it overrides rule 10's "not raising the slot".
2. Give the five flush footers a 14px gap above the strip (`make_market_flow.dart`, `chart_sheet.dart`, `your_market_screen.dart`, `opinions_screen.dart`, `position_sheet.dart`), then add the transparent pad. Five files, above the scope-confirmation threshold.

Under option 2, `app/test/home_screen_test.dart: simulation indicator the pill shows in the make-market flow on iPhone SE 375x667` fails if the pad lands before the footer gap (adjudicator's testProof), so the order is guarded.

### F2 LOW — The 1.3x leverage tests check that Set can be tapped, not that Set clears the pill. A dropped-inset mutant leaves Set 6px under the pill at both phone sizes and passes all four tests.

**Location:** `app/test/home_screen_test.dart:1986-2004 and :2273-2292 (sheet padding: app/lib/features/trade/order_ticket.dart:1151)` at 42ae15b; now `home_screen_test.dart:2002-2024` and `:2295-2317` at ee8f52c; `order_ticket.dart:1151` unchanged.

The mutant changes `EdgeInsets.fromLTRB(16, 10, 16, 24 + safe)` to `... 24)` in the shared _LeverageSheet (feed_order_ticket.dart is `part of` order_ticket.dart). The phones map gives a bottom padding of 0, so safe is 30 (just the strip). The sheet is scroll-controlled and sized to its content (maxScroll=0 in h1_probe.log), so it shrinks by 30 and Set moves from 532-586 to 562-616 against the pill at 610-640 (360x640). At 375x667 it moves from 559-613 to 589-643 against the pill at 637-667. Set's centre stays outside the pill, so tap('Set 11x') / tap('Set 3x') still lands. The outcome text appears, nothing overflows, and all four tests pass. On a phone, the bottom 6px of the Set button sits under the pill, which breaks the spec's rule that the pill must not cover action buttons. The narrow N1 also holds: under the isScrollControlled revert, both 375x667 variants pass (mut log +2 -2, with the two 360x640 variants failing).

**Applied:** Moved pill and expectPillClear to file scope and dropped the group-local copies. The order-ticket and feed-ticket 1.3x leverage tests now call expectPillClear on find.widgetWithText(VistaPrimaryButton, 'Set 11x'/'Set 3x') before tapping. Mutation proof (order_ticket.dart `24 + safe` -> `24`): the old tests gave '00:02 +4: All tests passed!' under the mutant, the new tests fail all 4 under it, and all 4 pass again once the mutant is reverted.

Red output, verbatim from the writer:

```text
Under mutant, before edits: `00:00 +0: order ticket Set applies leverage at 1.3x text on small Android 360x640 / 00:00 +1: order ticket Set applies leverage at 1.3x text on iPhone SE 375x667 / 00:01 +2: feed order ticket custom leverage applies at 1.3x text on small Android 360x640 / 00:01 +3: feed order ticket custom leverage applies at 1.3x text on iPhone SE 375x667 / 00:02 +4: All tests passed!`
Under mutant, after edits:
The following TestFailure was thrown running a test:
Expected: false
  Actual: <true>
Rect.fromLTRB(93.5, 610.0, 266.5, 640.0) covers Rect.fromLTRB(16.0, 562.0, 344.0, 616.0)
...
The following TestFailure was thrown running a test:
Expected: false
  Actual: <true>
Rect.fromLTRB(101.0, 637.0, 274.0, 667.0) covers Rect.fromLTRB(16.0, 589.0, 359.0, 643.0)
...
00:03 +0 -4: Some tests failed.

Failing tests:
  .../app/test/home_screen_test.dart: feed order ticket custom leverage applies at 1.3x text on iPhone SE 375x667
  .../app/test/home_screen_test.dart: feed order ticket custom leverage applies at 1.3x text on small Android 360x640
  .../app/test/home_screen_test.dart: order ticket Set applies leverage at 1.3x text on iPhone SE 375x667
  .../app/test/home_screen_test.dart: order ticket Set applies leverage at 1.3x text on small Android 360x640
```

### F3 LOW — The Settings half of the single resetDemo() path is never tested inside the app, and the pill test's name claims an equivalence it does not check (merges N4 / state-truthfulness finding)

**Location:** `app/test/scenario_test.dart:117-137, :139-140 (code: app/lib/features/settings/settings_screen.dart:123)` at 42ae15b; now `scenario_test.dart:117` (rewritten test) and `:152` (pill test) at ee8f52c; `settings_screen.dart:123` unchanged.

Settings is pushed in the real app (account_top_bar.dart:72, SettingsScreen.route()). The only Settings reset test pumps MaterialApp(home: SettingsScreen()), which makes Settings the root route, so popUntil(isFirst) does nothing there. Suppose a later edit puts the old inline reset back at settings_screen.dart:123 (Scenario.reset(); SettingsState.reset(); _say(...), where _say still exists at :34). Settings then resets but stays open over a stack built on old state, which is the M2 regression. The root-mounted test still passes: the toast and state()==seed both hold. The pill test at :139 never opens Settings. The in-app check exists only as the out-of-suite baton-runner probe settings_reset_probe_test.dart, which passes today.

**Applied:** Rewrote the Settings reset test so it mounts VistaColosseumApp, pushes Settings from the Wallet gear, taps Reset demo, and then checks four things: Settings is gone, canPop() is false, the toast is hit-testable, and the state equals the seed. Mutation proof (inline Scenario.reset(); SettingsState.reset(); _say(...) in place of resetDemo(context)): the old test passed under the mutant and the new one fails at findsNothing. With the mutant reverted, all 18 scenario tests pass.

Red output, verbatim from the writer:

```text
Under mutant, before edit: `00:00 +0: Reset demo in Settings restores the fixture and says so / 00:00 +1: (tearDownAll) / 00:00 +1: All tests passed!`
Under mutant, after edit:
══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞════════════════════════════════════════════════════
The following TestFailure was thrown running a test:
Expected: no matching candidates
  Actual: _TypeWidgetFinder:<Found 1 widget with type "SettingsScreen": [
            SettingsScreen(dependencies: [_ScaffoldMessengerScope], state:
_SettingsScreenState#13577),
          ]>
   Which: means one was found but none were expected
...
This was caught by the test expectation on the following line:
  file:///home/alex/VistaColosseum/.worktrees/br-2026-10-04-p0-queue/app/test/scenario_test.dart line 141
00:02 +0 -1: Reset demo in Settings restores the fixture, closes Settings and says so [E]
00:02 +0 -1: Some tests failed.
```

### F4 LOW — The new feature file hardcodes the scrim colour (and the sheet radius) outside design_system

**Location:** `app/lib/features/simulation/simulation_indicator.dart:57, 134` at 42ae15b; now `simulation_indicator.dart:64` and `:141-143` at ee8f52c, using `vista_colors.dart:16` and `vista_metrics.dart:23`.

`barrierColor: const Color(0x73000000)` is a hardcoded colour in feature code, which the project rule forbids. design_system has no scrim token (grep finds only textFaint 0x73FFFFFF). This copies 6 existing call sites on main (people_in_sheet, share_call_sheet, feed_order_ticket x2, order_ticket x2), so a scrim change is now a 7-site hand edit. Radius.circular(24) likewise has no VistaRadius token, but the rule's explicit ban is on colours and font sizes.

**Applied:** Added VistaColors.scrim = Color(0x73000000) and VistaRadius.sheet = 24. simulation_indicator.dart now uses them for barrierColor and the note's top radius (the const BoxDecoration still holds). The six older scrim call sites are unchanged, per rule 11.

Red: n/a - token extraction with identical values; no widget test can distinguish before/after.

Rule 11 is the run manager's F4 decision (run log, 2026-10-05T01:34:10Z): "F4 fix = add a design-system scrim token and use it in the indicator; migrating the 6 pre-existing scrim sites is out of scope."

## What the fixes now reject

Adjudicator answers to "does this fix reject valid input":

- **F1:** The proposed edit is a comment and rejects no input. For the record, the decided pad would intercept valid taps on the bottom 14 px of the make-market primary button, the Details-route Long/Short buttons and your-market 'Make a call', inside the pill's width. Spec 03 Behavior is the document that says those buttons must stay uncovered.
- **F2:** none. These are test-only edits. The new assertion fails only when the pill's rect overlaps the Set button, and spec 03 Behavior forbids that ('Must not cover nav, form fields or action buttons'). No layout the spec allows is rejected, and no product input path changes.
- **F3:** none. This is a test-only edit. The new assertions (Settings closed, root route, visible toast, store at seed) describe what resetDemo already does on the pill path and what the probe shows on the Settings path today. No product input or layout that is correct today fails it.
- **F4:** none - checked. The values are byte-identical (0x73000000, radius 24), so the rendered barrier and corner do not change. Nothing reads the old literal, and the new names `VistaColors.scrim` and `VistaRadius.sheet` do not collide with any existing member (grep of app/lib/design_system for scrim/sheet tokens finds none).

F2, F3 and F4 answer none: two are test-only edits and one is a token extraction with byte-identical values. F1 is the only answer that is not none, and it describes the decided pad, which did **not** land. The applied F1 edit is a comment. If the pad lands without the footer gap, it rejects a valid tap on the bottom 14px of the make-market primary button, the Details-route Long/Short buttons and your-market "Make a call", inside the pill's width. The document that teaches a human to make that tap, and that says those buttons must stay uncovered, is `docs/specs/03-simulation-indicator.md` Behavior ("Must not cover nav, form fields or action buttons at 375×667 and 390×844").

Nothing in the fixer run executed a rejected input. These are claims the full gate has not contradicted, not test results.

## Refuted: 3

The skeptic numbers the lanes' raw findings in order: Finding 1 is F2 (tautology-hunt), Findings 2 and 5 are F3 (tautology-hunt and state-truthfulness), Finding 3 is F1 and Finding 4 is F4 (layout-reachability). Each refutation below rejects part of a finding, not a whole survivor.

- **Finding 1 at MEDIUM severity (the test-gap substance survives at LOW).** The product code is correct. The finding is a test that could miss a future regression, and its failure path is a hypothetical mutant whose survival was worked out from the probe's rects, never run. That fits LOW, not a MEDIUM maintainability concern.
- **Finding 4: `static const double slot = 30` violates the design-token rule.** The rule's explicit ban is on hardcoded colours and font sizes. `slot` is the widget's own public geometry constant, and the tests reference it by name (SimulationIndicator.slot). It is a single source of truth, not a scattered literal. Only the scrim colour part of Finding 4 is a real violation.
- **Finding 5 as a separate item.** It duplicates Finding 2: same test (scenario_test.dart:117), same root-mounted-Settings blind spot. I merged it into the Settings reset finding and kept Finding 2's concrete inline-revert mutant as the failure path. Its other path, capturing ScaffoldMessenger after the pop, is speculative: Settings' context is still mounted during the pop animation.

## Checked claims that were wrong: 0

The skeptic spot-checked the lanes' claimed-correct items and they held: "Every claimed-correct item I spot-checked held."

## Residual risk (verbatim)

- tautology-hunt: No mutant was run (the lane is read-only, and running one would mean writing files). The survival of the dropped-inset leverage-sheet mutant is derived from the probe's measured rects, not from a run.
- tautology-hunt: The ticket-CTA and TextField clearance assertions inside 'the pill shows on every tab and inside both order tickets' have never been shown to discriminate. In the no-padding-reserve mutant both ticket tests died at the earlier VistaBottomNav check (line 2369). A ticket-only inset mutant was not modelled, because OrderTicket's 30+safe fallback likely leaves the CTA touching, not overlapping, the pill.
- tautology-hunt: The hitTestable() pre-filter blind spot in expectPillClear for TextField/VistaPillButton targets is already carried as L1. It was not re-examined beyond confirming the shape is unchanged.
- tautology-hunt: The make-market AC1 test at 375x667 does not kill the no-padding-reserve mutant (the footer's `bottomInset > 0 ? bottomInset : 30` fallback places the button the same either way). The 390x844 variant kills it. This is a product coincidence, not a test defect, and was not pursued.
- tautology-hunt: Non-test lanes (product correctness, design tokens, the LiveFeed drift) are out of scope for this reviewer.
- layout-reachability: No new widget probe was run because the review is read-only. The following rely on reading the code plus the existing review probes, not on fresh runs: the position, share and people sheets at 1.3x on 360x640; the order ticket's _ReviewPanel Confirm button; CallerPlayScreen at 360x640 and 1.3x.
- layout-reachability: Floating snackbars shown while the keyboard is up. Scaffold zeroes minViewPadding then, so a toast's 10px bottom margin could fall under the pill. Whether any toast fires with the keyboard open was not traced.
- layout-reachability: Landscape, tablets and Android 3-button navigation insets were not considered.
- layout-reachability: Semantics traversal order with a modal open (the pill sits outside the Navigator, so screen readers can reach it past the barrier) was not tested with a screen reader.
- state-truthfulness: I did not run any tests. I relied on the stated gate pass at 42ae15b (225 tests, plus HAS_MARKET 225) and on reading the source.
- state-truthfulness: Layout, overlap and tap-target questions (pill below the nav instead of above it, 30px tap target, isScrollControlled leverage sheets, scrollUntilVisible test changes) belong to other lanes.
- state-truthfulness: Hardcoded scrim Color(0x73000000) and Radius.circular(24) in simulation_indicator.dart are a design-token issue for another lane. It copies 6 existing call sites on main.
- state-truthfulness: Timing edges that need taps under ~250ms (tapping a SnackBar action while it animates out after reset, or tapping during an open-order cancel fold) were reasoned through, not reproduced. None looked reachable at human speed.

## Verification after the fixes

finding-fixer verification (`scripts/gate.sh baton-runner/br-2026-10-04-p0-queue/gate-phase-3-fixer/`), verbatim:

```text
=== gate: flutter-analyze: flutter analyze ===
PASS flutter-analyze
=== gate: flutter-test: flutter test ===
PASS flutter-test
=== gate: pubspec-frozen: git diff --exit-code d77fe5916d92125f30c67f36ca4ea013d32bade2 -- pubspec.yaml pubspec.lock ===
PASS pubspec-frozen
----
GATE: PASS
exit=0
```

Full gate after commit (`baton-runner/br-2026-10-04-p0-queue/gate-phase-3-close/`):

GATE: PASS exit 0 at ee8f52c, 225 tests, HAS_MARKET=true 225
