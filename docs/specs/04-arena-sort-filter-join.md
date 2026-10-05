# 04: Arena: real sort, real crowd filter, real participation

## Rules for this unit

Common rules for every unit: original lightweight code (CONTEXT.md), no new pub dependencies, money as `int` minor units or fixed-decimal strings (never new `double` money), every success message describes something that actually happened, keep the existing "— not in the demo yet" toast for anything you don't build. Run `scripts/gate.sh <log-dir>` before returning; it must print `GATE: PASS`. Every acceptance criterion names its test as `app/test/<file>.dart: <test name>` or is marked `manual, waived`; add the tests the spec names.

**PRD:** VC-ARN-002/003/004, VC-ARN-005 (crowd-split label). **Gap:** `arena_screen.dart:24,57` `_sort` only highlights a chip; `crowd_filter_panel.dart:70` range changes only the panel's own count; `arena_screen.dart:83` "joining a side places nothing"; `opinions_screen.dart:136` hardcodes `'BTC'`.

## Behavior
- Give `Battle` numeric fixture fields: `volume`, `changePct`, `fundingPct`, `bullPct` (0–100), `bullCount`, `bearCount`, a stable `id` and `asset`. Derive the display strings from them; every derived percentage is labelled "crowd split", never odds or probability, and sort or range changes touch no record, verdict or index (VC-ARN-005).
- Sort chips (Volume, Change, Funding) reorder the list by the field, descending, stable tiebreak by id.
- Crowd filter: histogram buckets are computed from the battles' `bullPct` (not a constant). Range selection filters the visible cards; panel count == visible card count. Full range restores all. Empty result shows "No battles in this crowd split" with a "Show all" action.
- Panel ↔ list share state through `Scenario` (or a small `ArenaFilterState` listenable); `AppShell` keeps drawing the panel.
- Bull/Bear side buttons and opinions-screen side buttons open the unit-02 ticket with the battle's own asset and direction, carrying `clashId`. A `filled` result increments that side's participant count once (keyed by actionId) and records `participation[clashId] = side`. `failed`/cancel leave counts unchanged.
- Chosen side shows on the card after joining; Wallet position for that fill references the clash.
- Ask field: filter battles by asset/ticker substring; no match → "Try BTC, ETH, SOL" (list derived from fixtures). Keep "Sort by new" as not-built.

## Acceptance
- [ ] Tests: sort order for each chip; range filter count equals cards; empty state; join once → +1, join again same actionId → +1 total; cancel → +0; derived percentages carry the "crowd split" label.
- [ ] Opinions screen passes the battle's asset, not `'BTC'`.
