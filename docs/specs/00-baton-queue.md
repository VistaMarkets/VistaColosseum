# Baton-runner queue: decision-free P0 work (Oct 4)

Ordered. Each unit is one implement→review→fix pass in one worktree. Units 1–8 were chosen as decision-free; the user resolved PRD §8 O-01 to O-10 on October 4 ([decision record](../prd/2026-10-04-open-decisions-recommendations.md)), which promoted the copy story to P0 (O-06) and added unit 9, and changed unit 6's labels (O-05: economic copy follows the video, no demo-assumption label). Precondition for unit 02, the user's call (drift report item 6): merge or park `origin/feat/premium-feel` first. Measured on Oct 4 it is 26 commits and 129 files ahead of `main`, rewrites `order_ticket.dart`, `feed_order_ticket.dart`, `arena_screen.dart` and `app_shell.dart`, and deletes `crowd_filter_panel.dart` and `ArenaMock.crowdBuckets`; if it merges first, re-cite the file and line references in units 02, 03 and 04 before they run. Gate per unit: `scripts/gate.sh <log-dir>`, which runs `flutter analyze` and `flutter test` in `app/`, prints `GATE: PASS` or `GATE: FAIL` and exits non-zero on failure; the review unit runs it exactly as the baton-runner skill prescribes.

| # | Spec | Closes (PRD) | Depends on |
|---|---|---|---|
| 1 | `01-scenario-store.md` | VC-DEM-002 (financial state; identities, prices and calls stay const fixtures), VC-DEM-004 (reset only; persona and phase excluded, see below) | — |
| 2 | `02-truthful-order-confirm.md` | VC-ORD-001 (ticket and review; Maker entry closes in unit 05, Arena asset in unit 04), VC-ORD-002/003, VC-MKT-003, VC-DEM-004 (truthful notifications; persona and phase remain open) | 1 |
| 3 | `03-simulation-indicator.md` | VC-DEM-003 | 1, 2 |
| 4 | `04-arena-sort-filter-join.md` | VC-ARN-002/003/004, VC-ARN-005 (crowd-split label; the optional settled winning-call/losing-P&L example is not seeded) | 2 |
| 5 | `05-maker-suggestion-card.md` | VC-FED-004 | 2 |
| 6 | `06-fee-ledger-and-receipts.md` | VC-MKT-004 (market fees plus the separately typed copy row, O-05/O-06), VC-REC-001 | 1, 2 |
| 7 | `07-trader-record-panel.md` | VC-MKT-002, VC-FED-003 (trader link; likes and follows persist via unit 01, Call details via unit 06, empty Following via unit 08; residual: unavailable-call state and share preview) | 6 |
| 8 | `08-list-empty-failed-states.md` | VC-QA-002 | 1–7 |
| 9 | `09-copy-story.md` | VC-CPY-001, VC-CPY-002, VC-DEM-004 (persona switch; promoted to P0 by O-06) | 1, 2, 6 |

Deliberately excluded (no unit; the next drift pass must not mark these Built): the VC-DEM-004 scenario-phase advance (O-10 resolved it as P1: VC-REC-003 and VC-ARN-006 stay seeded-only). VC-DEM-001, VC-QA-001, VC-QA-003 and VC-QA-004 are unblocked by O-04 (iOS Simulator on a Mac) and O-01 (Oct 11, 23:00) but are verification and packaging work, not code units; they belong to M1 and SP-07. VC-MKT-001 is unblocked by O-05 (video labels permitted) and is a candidate for a later queue, not this one. VC-FED-001, VC-FED-002, VC-LST-001, VC-LST-003, VC-LST-004 and VC-ARN-001 are built or partial per the drift report with no decision-free gap this queue takes on.

Common rules for every unit: original lightweight code (CONTEXT.md), no new pub dependencies, money as `int` minor units or fixed-decimal strings (never new `double` money), every success message describes something that actually happened, keep the existing "— not in the demo yet" toast for anything you don't build. Run `scripts/gate.sh <log-dir>` before returning; it must print `GATE: PASS`. Every acceptance criterion names its test as `app/test/<file>.dart: <test name>` or is marked `manual, waived`; add the tests the spec names.

Precondition: merge this branch (these specs and `scripts/gate.sh`) to `main` and push before invoking. The runner branches its worktree from `origin/main`, and its pre-flight halts if `scripts/gate.sh` is absent there.

Run: `/ClaudesMods:baton-runner docs/specs/01-scenario-store.md docs/specs/02-truthful-order-confirm.md docs/specs/03-simulation-indicator.md docs/specs/04-arena-sort-filter-join.md docs/specs/05-maker-suggestion-card.md docs/specs/06-fee-ledger-and-receipts.md docs/specs/07-trader-record-panel.md docs/specs/08-list-empty-failed-states.md docs/specs/09-copy-story.md`
