---
source: baton-runner work unit, phase 1 of 8 (docs/specs/01-scenario-store.md)
scope: br-2026-10-04-p0-queue
parent_session: -
status: checkpoint (in progress)
---

# Phase 1 checkpoint: Scenario store, seed, reset

## Done
- AC3 (seed → mutate → reset equals seed; reset twice equal): GREEN.
  - RED: `flutter test test/scenario_test.dart` → `Error: Undefined name 'Scenario'` (loading failed, store absent).
  - GREEN: `+2: All tests passed!`; full suite `+172: All tests passed!`; `flutter analyze` → No issues found.
- `app/lib/scenario/scenario.dart` created; the four statics are thin forwarders.

## Next
- Settings "Reset demo" row (AC2), Wallet positions from Scenario (AC4), then cash/follows callers (AC1).
