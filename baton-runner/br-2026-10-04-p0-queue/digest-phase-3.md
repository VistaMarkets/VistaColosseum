# Phase 3 digest: persistent simulation indicator (spec 03) — APPROVE at ee8f52c (dw-review 4 confirmed: 3 applied, F1 open; gate PASS 225, HAS_MARKET 225)

## Public surface
- `features/simulation/simulation_indicator.dart`: `void resetDemo(BuildContext)` = grab root ScaffoldMessenger, `popUntil(isFirst)`, `Scenario.reset(); SettingsState.reset();`, toast `Demo reset to ${Scenario.fixtureVersion}`. The ONE reset path (Settings row `settings_screen.dart:123` and the pill's note).
- `SimulationIndicator({navigator, child})`, `static const double slot = 30`: adds `slot` to `MediaQuery.padding.bottom` and `viewPadding.bottom` for the whole navigator; pill floats at `padding.bottom + viewInsets.bottom` (above the keyboard). One semantics button `Simulated · fixture-v1`; `_open` guard = one note at a time.
- `main.dart`: builder = `withClampedTextScaling(1.3, SimulationIndicator(...))`; `VistaColosseumApp({home = const AppShell()})` so tests start deeper inside the real builder.
- Tokens: `VistaColors.scrim` (0x73000000, `vista_colors.dart:16`), `VistaRadius.sheet` (24, `vista_metrics.dart:23`). Six older sites keep the literal scrim; use the token in new code.
- Tests: file-scope `const pill` + `expectPillClear(tester, finder)` (`home_screen_test.dart:48-60`): pill hit-testable, targets found, no rect overlap. Pass the box finder (e.g. `find.widgetWithText(VistaPrimaryButton, ...)`), not `.hitTestable()` (pre-filter hides covered targets, carried L1).

## Conventions 04 arena, 05 maker card, 06 fee ledger, 07 trader record, 08 empty states must honour
- Reserved bottom strip: `MediaQuery.paddingOf(context).bottom` includes the 30px pill strip. Every new screen, sheet and footer pads its bottom by it (SafeArea or `x + safe`). Never hard-code a bottom offset. Do not shrink, move or hide the indicator to make room (manager decision).
- Footers vs the strip: today's footers end flush on it. A new flush footer joins F1's fix list, so leave a 14px gap above the strip (tapTarget 44 − slot 30) where the layout allows.
- Sheets with actions: `showModalBottomSheet(isScrollControlled: true, backgroundColor: Colors.transparent, barrierColor: VistaColors.scrim)`; content sized to fit, scrollable, padded `+ safe`, top radius `VistaRadius.sheet`. Sizing pattern: `_LeverageSheet` (`order_ticket.dart:1122-1151`), which predates the tokens and still uses the literals. Test at 1.3x on 360x640 and 375x667 with `expectPillClear` on the main action.
- Reset only through `resetDemo(context)`; it pops to root, so routes built on old state close. New store fields (participation, suggestions, fee entries/receipts) still need initializer + `reset()` line + `state()` + `mutateEverything()` in `scenario_test.dart`.
- Settings reset tests push Settings via the Wallet gear (`scenario_test.dart:117`); a root-mounted Settings makes `popUntil` a no-op and hides regressions.
- Layout tests pump `VistaColosseumApp(home: ...)`, never bare `MaterialApp`. On 360x640 screens are 30px shorter: use `scrollUntilVisible`, not `ensureVisible`, near the end of lazy lists.
- Exactly one `Simulated · fixture-v1` node app-wide; don't reuse the string. The review panel keeps `Simulated — no real order` (`order_ticket.dart:977`); add no second simulated label.

## Open / carried
- F1 MEDIUM, OPEN, user's design call: pill tap target is 30px < `VistaSize.tapTarget` 44. Manager rule 10 (pad the hit area to 44, never raise the slot) fails spec 03's no-cover rule on flush footers: `make_market_flow.dart:138`, `chart_sheet.dart:255`, `your_market_screen.dart:137`, `opinions_screen.dart:181`, `position_sheet.dart:97`. Options: raise `slot` to 44 (every screen loses 14px), or gap those 5 footers 14px, then pad. Recorded at `simulation_indicator.dart:39-46`. Do not "fix" it inside another phase.
- LiveFeed drift after reset (phase-1 M, still open): `resetDemo` does not rebase LiveFeed; the Wallet change line and chart drift (phase-2 L-5). `resetDemo` is the one place to add the rebase.
- L9: pill sits below the nav capsule, not "above the floating nav"; product sign-off pending.
- N2 pre-existing: make-market step 1 overflows 20px at 1.3x on 360x640/375x667 (`make_market_flow.dart:254`, same on main); AC1 make-market tests run at 1.0x, step 1 only.
- Deferred iter-1 LOWs L1-L8, L10-L12, L14-L16, L20 (`baton-pass/.../2026-10-04T162846-phase3-fix-iter1.md`).
- Residual risk: snackbars with the keyboard up may land under the pill; screen readers reach the pill past a modal barrier; landscape, tablets, 3-button nav unchecked.

Records: `docs/reviews/2026-10-04-dw-review-phase-3-simulation-indicator.md`, `fixer-phase-3.json`, `review-phase-3-iter-1.md`.
