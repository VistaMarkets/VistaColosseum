# Specs

One spec per built unit. Each states its rules, the PRD requirements it covers, and its acceptance checks. The roadmap's SP-numbers group requirements differently from these files (see the [roadmap's spec status](../prd/2026-10-01-vc-hackathon-roadmap.md#boundaries-for-subsequent-implementation-specs)).

| Spec | What it covers | PRD IDs | Status |
|---|---|---|---|
| [01 Scenario store](01-scenario-store.md) | One store for all demo state; deterministic reset | VC-DEM-002, VC-DEM-004 | Built, PR #10 |
| [02 Truthful order confirm](02-truthful-order-confirm.md) | Review, confirm, cancel, failure and receipt for simulated orders | VC-ORD-001, VC-ORD-003, VC-MKT-003 | Built, PR #12 |
| [03 Simulation indicator](03-simulation-indicator.md) | The persistent "Simulated · fixture-v1" pill and its note | VC-DEM-003 | Built, PR #13 |
| [04 Arena](04-arena-sort-filter-join.md) | Sort, crowd-split filter, participation | VC-ARN-002, VC-ARN-005 | Built, PR #15 |
| [05 Maker suggestion card](05-maker-suggestion-card.md) | Attributed, advisory Maker cards in the feed | VC-FED-004 | Built, PR #16 |
| [06 Fee ledger and receipts](06-fee-ledger-and-receipts.md) | Fee ledger, paper and call receipts | VC-MKT-004, VC-REC-001, VC-FED-003 | Built, PR #17 |
| [07 Trader record panel](07-trader-record-panel.md) | Records computed from call receipts | VC-MKT-002, VC-FED-003 | Built, PR #19 |
| [08 Loading, empty, failed states](08-list-empty-failed-states.md) | Honest states on the core lists | VC-QA-002 (lists) | Built, PR #20 |
| [09 Copy story](09-copy-story.md) | Persona switch, copied order, $5.00 copy fee | VC-CPY-001/002, VC-DEM-004 | Built, PR #27; Wallet label PR #43 |
| [11 Verification and packaging](11-verification-and-packaging.md) | Rehearsals, viewport checks, recording, package | VC-QA-001, VC-QA-003, VC-QA-004 | In progress: rehearsal 1 done (PR #47) |
| [12 Own market cap](12-own-market-cap.md) | One market cap that every screen reads | VC-MKT-001, VC-LST-003 | Built, PRs #32 and #41 |

**Not spec'd:** there is no spec 10 file. The copy story, which the roadmap calls SP-10, was written as spec 09. Later fixes that needed no spec of their own: the Following tab and the listing's link to the market (#32), the first-call sample (#44, VC-LST-004), and the Linux desktop build (#46).
