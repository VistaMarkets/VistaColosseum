---
source: baton-runner work unit, phase 3 of 8 (docs/specs/03-simulation-indicator.md)
scope: br-2026-10-04-p0-queue
parent_session: 2026-10-04T150315-phase2-review-iter3.md
status: IN PROGRESS: RED tests written for AC1, AC2 and the pill's Reset demo; no production code yet
---

# Phase 3 checkpoint: RED tests in place

Branch `feat/br-2026-10-04-p0-queue/phase-3`, uncommitted.

## RED evidence so far
- `app/test/home_screen_test.dart` group `simulation indicator` (6 tests: smallest phone 360x640 at 1.0x/1.3x walking all four tabs; 375x667 and 390x844 walking tabs + both order tickets + make-market). All fail with:
  `Actual: _HitTestableWidgetFinder:<Found 0 widgets with a semantics label named "Simulated · fixture-v1"` / `Which: means none were found but one was expected`.
- `app/test/scenario_test.dart: 'the simulated pill explains itself; its Reset demo is the Settings reset'` fails with:
  `The finder "Found 0 widgets with text "Simulated · fixture-v1": []" (used in a call to "tap()") could not find any matching widgets.`
- AC3 (review sheet label) already exists from phase 2 (`order_ticket.dart` `'Simulated — no real order'`, asserted in `order_ticket_test.dart: 'double tap confirm places one position'`).

## Plan (next step)
New `app/lib/features/simulation/simulation_indicator.dart`: `SimulationIndicator` wraps the Navigator in `MaterialApp.builder` (main.dart, inside the 1.3x text clamp). It reserves a fixed bottom slot by adding it to `MediaQuery.padding/viewPadding.bottom`, so every screen and sheet that respects the bottom safe area stays clear of the pill; the pill floats in that slot. Tap opens a sheet via a navigator key. `resetDemo(context)` is the one reset action; Settings reuses it (resolves phase-1 carried M "split reset handler"). LiveFeed drift (phase-1 carried M) is not touched by these criteria.
