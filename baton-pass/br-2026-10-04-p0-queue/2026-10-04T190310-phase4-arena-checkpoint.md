---
source: baton-runner work unit, phase 4 of 8 (docs/specs/04-arena-sort-filter-join.md)
scope: br-2026-10-04-p0-queue
parent_session: 2026-10-04T184857-phase3-close.md
status: IN PROGRESS: RED tests written for every acceptance item; no production code yet
---

# Phase 4 checkpoint: RED tests in place

Branch `feat/br-2026-10-04-p0-queue/phase-4`, uncommitted. Raw logs: `baton-runner/br-2026-10-04-p0-queue/phase-4-red/`.

## RED evidence
- `flutter test test/scenario_test.dart` (scenario-red-1.log): compile fails, the API is missing:
  `Error: Member not found: 'participation'.` / `'arena'` / `'Scenario.setArena'` / `'Scenario.joins'`.
- `flutter test test/home_screen_test.dart --name '^(arena|opinions) '` (home-red-1.log), 9 failing:
  - `arena Arena tab shows the battles with the crowd filter`: `Found 0 widgets with text "Crowd split 50/50 +"` (panel opens on Figma's constant 70/30 selection).
  - `arena sort chips order ...`: `Expected: ['BTC', 'ETH', 'SOL'] Actual: ['BTC', 'BTC']`.
  - `arena the crowd range filters the cards ...`: `Expected: [0, 0, 1, 0, 1, 0, 0, 1, 0, 0] Actual: [15.0, 19.0, 17.0, ...]` (constant buckets).
  - `arena an empty crowd split ...`: `Found 0 widgets with text "0 battles"`.
  - `arena Ask filters by asset ...`: `Expected: ['ETH'] Actual: ['BTC', 'BTC']`.
  - `arena joining: Cancel counts nothing ...`: `Found 2 widgets with text "and 14"` (duplicate fixture; no derived count).
  - `arena a battle's opinions trade ...`: `Found 0 widgets with text "+7 more opinions"`.
  - `opinions more opinions opens ...`: `Found 0 widgets with text "Crowd split · 23 opinions"`.
  - `opinions the crowd split is labelled ...`: `Found 0 widgets with text "Crowd split 63% bull"`.

## Plan (next step)
Battle numeric fixtures (3 battles BTC/ETH/SOL, ids btc-72k/eth-4k/sol-200), `ArenaView` record in `Scenario.arena` (sort, bucket range, query) + `Scenario.setArena`, `Scenario.participation` written by `placeOrder` on a clash fill, `Scenario.joins(clashId, side)` counted from receipts (unique by actionId). Ticket gains `clashId`; OpinionsScreen takes the Battle.
