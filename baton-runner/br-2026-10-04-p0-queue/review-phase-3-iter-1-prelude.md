# Project prelude: phase 3 review, iteration 1 (VistaColosseum, Flutter app in app/)

## Where things are (use absolute paths; read-only)
- Worktree root <root> = /home/alex/VistaColosseum/.worktrees/br-2026-10-04-p0-queue (branch feat/br-2026-10-04-p0-queue/phase-3, HEAD 21092df). Do NOT read the other checkout your shell may start in; run git as `git -C <root> ...`. Read-only: no edits, no mutating git, no gh.
- Whole phase diff: `git -C <root> diff feat/br-2026-10-04-p0-queue/phase-2...HEAD -- app/` (product: app/lib/main.dart, app/lib/features/simulation/simulation_indicator.dart (new), app/lib/features/settings/settings_screen.dart; tests: app/test/home_screen_test.dart, app/test/scenario_test.dart).
- Spec (the intent; read Rules, Behavior, Acceptance in full): <root>/docs/specs/03-simulation-indicator.md
- Phase-1 digest and phase-2 digest (conventions this phase must honour; carried items): <root>/baton-runner/br-2026-10-04-p0-queue/digest-phase-1.md, digest-phase-2.md
- Work baton (what the author claimed, RED evidence, deviations): <root>/baton-pass/br-2026-10-04-p0-queue/2026-10-04T151800-phase3-simulation-indicator.md
- Later specs (to judge scope): <root>/docs/specs/04-*.md ... 08-*.md

## Run-wide rules from the user (judge every finding against these)
1. No new pub dependencies: app/pubspec.yaml and app/pubspec.lock unchanged.
2. Money in int minor units (cents), never double.
3. Every success message describes something that actually happened in state.
4. VC-DEM-004 persona switch and phase advance are deliberately excluded and must NOT have been built.

## Facts already established by the caller
- Gate `scripts/gate.sh` (log dir <root>/baton-runner/br-2026-10-04-p0-queue/gate-phase-3-iter-1/): flutter analyze clean, flutter test +219 all passed, pubspec frozen, GATE: PASS. `flutter test --dart-define=HAS_MARKET=true` also +219 all passed (gate-phase-3-iter-1/flutter-test-has-market.log).
- The design: `MaterialApp.builder` wraps the navigator in `SimulationIndicator`, which adds a 30px `slot` to `MediaQuery.padding.bottom` and `viewPadding.bottom` for everything under it, and floats the pill in that strip at `padding.bottom + viewInsets.bottom` (above the keyboard). The pill is drawn above every route, sheet scrim and dialog.

## What this review must decide (beyond the default lenses)
1. COVERAGE: the pill must cover no interactive control (nav, form field, action button, slider stop, snackbar action, drag handle, list row with a tap action that cannot be scrolled clear) on ANY screen at the app's tested sizes: the `phones` list in home_screen_test.dart (360x640, 375x667 top-20 no bottom inset, 393x852, 412x915, 430x932) plus the spec's 375x667 and 390x844. Walk every tab, every pushed route (asset trade screen, trader market page, your-market screen, settings, follow lists, profiles, leaderboard, etc.), every bottom sheet (feed ticket, OrderTicket, review panel, position sheet, make-market flow steps, settings sheets, the pill's own note) and dialog. Look for anything that does not honour MediaQuery bottom padding: `SafeArea(bottom: false)`, `MediaQuery.removePadding(removeBottom: true)`, Scaffold internals that consume padding (bottomNavigationBar, floating action buttons, persistent footers), hard-coded bottom offsets, sheets that pad only by `viewInsets`. Keyboard-open state: the pill rises to `viewInsets.bottom`; does any sheet put a field or button directly on the keyboard without the padding inset? Only static non-interactive content or scrollable content that can be scrolled clear is acceptable under the pill.
2. TRUTHFULNESS of the pill's own text: "Simulated · fixture-v1" (read from `Scenario.fixtureVersion`?), the note "All prices, fills, balances and results are simulated. Nothing leaves this device." (does the app perform any network I/O: fonts, images, analytics, url launches?), and the "Demo reset to fixture-v1" toast (rule 3).
3. RESET FROM ANYWHERE: Reset demo used to be reachable only from Settings; now it is reachable over any open ticket, position sheet, make-market step or pushed route. After a reset under an open route, can stale UI then make a false claim or a wrong store write (e.g. a position sheet acting on a position the reset removed, a ticket showing pre-reset cash, the make-market flow listing a market after reset)? Trace it concretely; say whether it is reachable and what the user sees.
4. TESTS ARE REAL: would each new test fail if the implementation were reverted or mutated (e.g. slot = 0, pill moved to bottom 0, pill removed on pushed routes, note sentence changed, resetDemo dropping SettingsState.reset)? AC3 has no RED (pre-existing behaviour) and a mutation check stands in; judge it.
5. The work changed two existing 360x640 tests from `ensureVisible` to `scrollUntilVisible` (home_screen_test.dart around lines 118 and 1264). Judge whether that weakened them or merely accommodated the 30px-shorter viewport. The author says the layout did not overflow and the last Wallet rows fell outside the lazy list's cache extent.
6. Accessibility: the pill's tap area is 30px tall (under the 44px tap-target token); the pill lives outside the navigator, so it stays focusable/tappable above modal barriers. Judge severity honestly.

## Out of scope (do not raise as defects of this phase)
- Phase-1 carried MEDIUM "LiveFeed drift after reset" (no AC of spec 03 touches it; carried forward). You may note if the new pill's wording makes it worse.
- Everything owned by specs 04-08 and VC-DEM-004. Pre-existing findings listed in the two digests unless this phase made them worse.
