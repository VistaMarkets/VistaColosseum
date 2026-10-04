---
source: baton-runner work unit, phase 3 of 8 (docs/specs/03-simulation-indicator.md)
scope: br-2026-10-04-p0-queue
parent_session: 2026-10-04T151112-phase3-simulation-indicator-checkpoint.md
status: COMPLETE: all 3 acceptance items green; GATE: PASS; nothing committed (the manager owns git)
---

# Phase 3 complete: persistent "Simulated · fixture-v1" pill

Branch `feat/br-2026-10-04-p0-queue/phase-3`, uncommitted. One pill wraps the navigator in `MaterialApp.builder`, so it shows on every tab, pushed route and sheet. Tapping it opens a note with the spec's sentence and a Reset demo button that runs the same action as Settings.

## Acceptance criteria

| AC | State | Test | RED evidence (before the code) |
|---|---|---|---|
| 1. Pill visible on Home, Explore, Arena, Wallet, inside the order ticket and the make-market flow | DONE | `app/test/home_screen_test.dart: 'simulation indicator the pill shows on every tab and inside both order tickets on iPhone SE 375x667'` and `'... on iPhone 14 390x844'` (all four tabs, Home's feed ticket, the pushed asset screen, its OrderTicket); `'simulation indicator the pill shows in the make-market flow on iPhone SE 375x667'` and `'... on iPhone 14 390x844'`. Each checks that the pill can be hit and does not overlap the nav, the CTA / Place button, the visible TextFields, or the Long/Short buttons | `Actual: _HitTestableWidgetFinder:<Found 0 widgets with a semantics label named "Simulated · fixture-v1"` / `Which: means none were found but one was expected` (all 4 tests) |
| 2. Widget test: pill present on each tab; no overflow at the smallest viewport in `home_screen_test.dart`'s device list | DONE | `app/test/home_screen_test.dart: 'simulation indicator the pill shows on every tab without overflow on the smallest phone at 1.0x text'` and `'... at 1.3x text'` (`phones['small Android 360x640']`, each tab: `takeException()` is null, pill hit-testable and clear of `VistaBottomNav`) | same message as AC1 (both tests) |
| 3. Review/confirmation sheet from unit 02 shows the simulated label (verify, don't duplicate) | VERIFIED, no code | `app/test/order_ticket_test.dart: 'double tap confirm places one position'` asserts `inSheet(find.text('Simulated — no real order'))` (`order_ticket.dart` `_ReviewPanel`, shared by both tickets). No RED is possible for existing behaviour. A mutation check stands in: blanking the label in a temporary copy failed it with `Actual: _DescendantWidgetFinder:<Found 0 widgets with text "Simulated — no real order" descending`. The file was restored (empty `git diff` on order_ticket.dart) and the test passed again | n/a (mutation check above) |

The pill's note and Reset button (spec Behavior; the phase-1 carried finding): `app/test/scenario_test.dart: 'the simulated pill explains itself; its Reset demo is the Settings reset'`. It mutates every store field plus Settings and DisplayPrefs, taps the pill, expects the sentence, taps Reset demo, then expects the note closed, the `Demo reset to fixture-v1` toast, `state()` deep-equal to the seed, and Settings/DisplayPrefs restored. RED: `The finder "Found 0 widgets with text "Simulated · fixture-v1": []" (used in a call to "tap()") could not find any matching widgets.` The existing `'Reset demo in Settings restores the fixture and says so'` still passes through the shared `resetDemo`.

## Verification (final)
- `scripts/gate.sh baton-runner/br-2026-10-04-p0-queue/gate-phase-3-work` → `PASS flutter-analyze`, `PASS flutter-test` (`+219: All tests passed!`), `PASS pubspec-frozen`, `GATE: PASS`.
- `flutter test --dart-define=HAS_MARKET=true` → `+219: All tests passed!`
- `flutter analyze` → `No issues found!`. pubspec.yaml and pubspec.lock are unchanged. No new dependencies.
- First gate run (before the test fix below) failed `Portfolio renders without overflow on small Android 360x640` and `position sheet renders without overflow on small Android 360x640` with `Bad state: No element`. The reserved 30px strip left the last Wallet rows outside the lazy list's cache extent, so `ensureVisible` found no element to scroll to. Both now use `scrollUntilVisible` on the PortfolioScreen's scrollable, which keeps the test's intent ("reachable by scrolling"). The layout itself did not overflow.

## Files touched (4 modified + 1 new)
`app/lib/main.dart` (navigatorKey + builder wraps the navigator in `SimulationIndicator`, inside the 1.3x text clamp), `app/lib/features/settings/settings_screen.dart` (Reset demo row → `resetDemo(context)`; unused scenario import dropped), new `app/lib/features/simulation/simulation_indicator.dart`, `app/test/home_screen_test.dart` (new `simulation indicator` group; two `ensureVisible` → `scrollUntilVisible`), `app/test/scenario_test.dart` (pill note/reset test).
Evidence dir (untracked, the manager decides whether to keep it): `baton-runner/br-2026-10-04-p0-queue/gate-phase-3-work/`.

## Public surface added (`app/lib/features/simulation/simulation_indicator.dart`)
- `void resetDemo(BuildContext context)`: `Scenario.reset(); SettingsState.reset();` then the snackbar `Demo reset to ${Scenario.fixtureVersion}`. This is the one Reset demo action. Settings and the pill's note both call it.
- `class SimulationIndicator({required GlobalKey<NavigatorState> navigator, required Widget child})` with `static const double slot = 30`. It adds `slot` to `MediaQuery.padding.bottom` and `viewPadding.bottom` for the whole navigator, then floats the pill in that strip at `padding.bottom + viewInsets.bottom`, which puts it above the keyboard when one is open. The pill is its own semantics node: `container: true`, a button labelled `Simulated · fixture-v1` with a tap action. A `_open` flag stops a second note opening.
- `VistaColosseumApp._navigator` (private static navigator key) passed as `MaterialApp.navigatorKey`.

## Decisions phases 04-08 must honour
- **Bottom safe area = pill clearance.** Every new screen or sheet must pad its bottom with `MediaQuery.paddingOf(context).bottom` (SafeArea, or the `30 + safe` pattern). That inset now includes the 30px pill strip. A widget that hard-codes a bottom offset will sit under the pill.
- `slot` is sized for the app's 1.3x text-scale cap (11pt label at 1.3x ≈ 25px). If the clamp in `main.dart` rises, raise `slot`.
- Tests that `ensureVisible` a row near the end of a lazy list on 360x640 may need `scrollUntilVisible`, because the screen is 30px shorter.
- The pill sits above the navigator, so `find.text('Simulated · fixture-v1')` / `find.bySemanticsLabel(...)` finds exactly one widget in any `VistaColosseumApp` test. Don't add a second Text with that exact string, such as a sheet title.
- New reset paths must call `resetDemo`. New store fields still need `reset()`, `state()` and `mutateEverything()` lines; the pill test checks deep equality through `state()`.
- AC3 label: the review panel keeps `Simulated — no real order`. Don't add a second simulated label to the review sheet; the global pill already shows above it.

## Deviations / reading of the spec
- "rendered once in AppShell above the floating nav ... (wrap MaterialApp.builder)": the pill is rendered once, in the builder, and is drawn above every route, including sheet scrims. It sits in a reserved strip *below* the nav capsule, not between the content and the nav. A single global widget cannot sit above the nav on tabs and also stay clear of bottom buttons on pushed routes and sheets. The reserved inset is what makes the "covers no nav, fields or buttons" rule hold everywhere, and the tests check it at 375x667, 390x844 and 360x640.
- The pill's tap area is 30px tall (the strip height), which is under the 44px tap-target token. A taller strip would cost every screen more height. Flag this for design if needed.

## Carried findings
- RESOLVED (phase-1 M, "split reset handler"): one `resetDemo()`, reused by Settings and the pill's note, tested for deep equality (test above).
- LEFT (phase-1 M, "LiveFeed drift after reset"): none of spec 03's acceptance items reads or resets LiveFeed. The pill shows only the const `Scenario.fixtureVersion`, and the Reset button keeps Settings' existing behaviour. Still open for a later phase: `resetDemo` is now the single place to add a LiveFeed rebase.

## Remaining
Nothing for spec 03. Next: manager review/gate for phase 3.
