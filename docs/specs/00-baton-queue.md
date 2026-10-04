# Baton-runner queue — decision-free P0 work (Oct 4)

Ordered. Each unit is one implement→review→fix pass in one worktree. None of these depends on the open decisions in PRD §8 (deadline O-01, runtime O-04, market-cap wording O-05, premium-feel branch). Gate per unit: `cd app && flutter analyze && flutter test` clean.

| # | Spec | Closes (PRD) | Depends on |
|---|---|---|---|
| 1 | `01-scenario-store.md` | VC-DEM-002, half of VC-DEM-004 | — |
| 2 | `02-truthful-order-confirm.md` | VC-ORD-001/002/003, VC-MKT-003, rest of VC-DEM-004 | 1 |
| 3 | `03-simulation-indicator.md` | VC-DEM-003 | 1 |
| 4 | `04-arena-sort-filter-join.md` | VC-ARN-002/003/004 | 2 |
| 5 | `05-maker-suggestion-card.md` | VC-FED-004 | 2 |
| 6 | `06-fee-ledger-and-receipts.md` | VC-MKT-004, VC-REC-001 | 1 |
| 7 | `07-trader-record-panel.md` | VC-MKT-002, VC-FED-003 (trader link) | 6 |
| 8 | `08-list-empty-failed-states.md` | VC-QA-002 | 1–7 |

Common rules for every unit: original lightweight code (CONTEXT.md), no new pub dependencies, money as `int` minor units or fixed-decimal strings (never new `double` money), every success message describes something that actually happened, keep the existing "— not in the demo yet" toast for anything you don't build. Run gate; add tests named in the spec.

Run: `/ClaudesMods:baton-runner docs/specs/01-scenario-store.md docs/specs/02-truthful-order-confirm.md docs/specs/03-simulation-indicator.md docs/specs/04-arena-sort-filter-join.md docs/specs/05-maker-suggestion-card.md docs/specs/06-fee-ledger-and-receipts.md docs/specs/07-trader-record-panel.md docs/specs/08-list-empty-failed-states.md`
