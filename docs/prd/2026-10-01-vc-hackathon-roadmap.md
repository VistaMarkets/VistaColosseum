# VistaColosseum — 10-day product roadmap

**Planning date:** October 1, 2026, America/Los_Angeles. **Target deadline:** October 11, derived from the user's “in 10 days”; exact submission cutoff remains open. This is a proposed sequence, not a capacity-backed commitment.

**Updated October 2:** the user confirmed a PC with a simulated iOS device as the presentation target. The proposed runtime is a desktop browser with a portrait phone viewport/frame; exact host OS and simulation tool remain to be recorded. This clarification does not restart the original ten-day window: the planning target remains October 11, nine calendar days after this update. No implementation milestone is marked complete by this clarification.

The [master PRD](2026-10-01-vc-hackathon-master-prd.md) defines scope and acceptance. The [evidence register](2026-10-01-vc-hackathon-evidence.md) supplies source revisions and the video/Figma audit. Do not estimate Arena, TPX or creator listing as existing FMA implementations: matching source was not found on current main.

**Figma recheck, October 2:** the plugin is confirmed installed/enabled, but its design-reading tools are unavailable in this chat; browser access still fails at WebGL. E-D01/O-09 remain open. Once access is available, inspect node 1325-7814 and record its frame IDs, visible states, dimensions and differences from the video; map findings to existing PRD IDs and SP-01–SP-07 before finalizing affected visual specs. This is unfinished reference verification within M0, not a new implementation milestone or grounds to assume additional live backend work.

**VC baseline update, October 2:** fetched main `ddcfaa350890864b8726732837629bd237a0d603` now includes a Flutter app (E-C03). The milestone table remains the original delivery sequence, not an assertion that its screens still need to be built. M0/SP-00 must map existing VC behavior to the stable PRD IDs and schedule only the remaining work; source presence alone does not complete a milestone.

## Delivery strategy

Complete the connected demo in the existing VC app, using deterministic local data and simulated actions. FMA informs interaction patterns; VMBE informs domain/contract vocabulary. Neither repository's production integration work is a prerequisite. The current VC policy favors original lightweight implementation rather than transplanted source files.

Plan one sequential stream because team capacity is unspecified. If additional people are available, the shared contracts allow bounded screen work to proceed independently. The dates below are desired milestone windows; M0 must validate them against actual availability and target-platform setup.

**Time convention:** D0 is October 1, D10 is October 11. These are elapsed-day offsets, not eleven promised engineering days. Aim for a recordable build by D7 and a packaged submission by D9, leaving D10 as submission buffer. Check the official cutoff before treating any of D10 as available work time.

## Milestones and exit criteria

| Milestone / proposed window | Priority and PRD links | Dependencies | Concrete exit criteria | Suggested spec |
|---|---|---|---|---|
| **M0 — baseline and demo contract** · D0, Oct 1; remaining decisions carry into Oct 2 | P0 · assumptions, journeys, S01/S09 | None | Record the confirmed PC/simulated-iOS target and select host runtime/tool and run/record path; identify available capacity and official deadline/rules; agree on J1–J5 and mock boundary; log unresolved economic wording and Figma gap. Define a small scenario with shared IDs. Every open item has an owner or remains explicitly unassigned. Missing demo source is not counted as delivered functionality. | SP-00 |
| **M1 — running shell and scenario** · D1, Oct 2 | P0 · S01, VC-DEM-001–004 | M0 runtime choice | Build launches on the presenter's PC in the portrait simulated device, navigates Home/Arena/Wallet placeholders and market route with mouse/keyboard, displays simulation status, resets identities/clock/state. Run/reset instructions and a sample recording work on that machine. No VMBE or credentials required. | SP-01 |
| **M2 — Home and creator-listing journeys** · D2–D3, Oct 3–4 | P0 · S02, S03 | M1 scenario contracts | J1 can browse/detail/replay; listing completes once and updates Wallet entry. Duplicate/blank ticker and unchecked acknowledgment paths are demonstrable. First-call control truthfully routes to a fixture or optional composer. Maker-style content is clearly attributed and advisory. | SP-02, SP-03 |
| **M3 — market and Wallet consistency** · D4, Oct 5 | P0 · S04, VC-REC-001 | M1 financial/receipt model; M2 listing | J2 ends in the listed creator's market; chart/portfolio switching works; sample-count/receipt explanation supports J5; fee total equals the demo ledger. Index, P&L and cash have distinct labels/units. Insufficient-history example is honest. | SP-04 |
| **M4 — Arena discovery** · D5, Oct 6 | P0 · S05, VC-ARN-001–003/005 | M1; shared calls/traders from M2 | J3 works: seeded opposing views, predictable sorts, crowd-range filtering with derived counts, more-opinions view, bounded ask/search behavior. Empty filter state recovers. Video-only/unverified behavior is still labeled in the spec. | SP-05 |
| **M5 — connected participation** · D6, Oct 7 | P0 · S06, VC-ARN-004, VC-MKT-003 | M2–M4 shared entity/financial contracts | J4 reaches one review flow from Home/Maker/Arena. Confirm adds one position and participation; cancel/error add none; duplicate confirm has one effect. Wallet/receipt values reconcile. J1–J5 run end to end from reset. | SP-06 |
| **M6 — harden and freeze scope** · D7–D8, Oct 8–9 | P0 · S09; all included sections | M5 core integration | Complete checks on the PC at primary and smaller phone viewports (proposed 390×844 and 375×667), including mouse/keyboard controls, text scaling and unobstructed actions; two reset rehearsals pass; failed/empty/cancel cases recover. Fix broken journeys and misleading state. Freeze new feature scope by end of D7, subject to a later official cutoff. Record included/deferred P1 IDs explicitly. | SP-07 |
| **M7 — recording and submission package** · D9, Oct 10 | P0 · VC-QA-004 | M6 | Produce the final PC screen recording of the simulated device, local fallback, setup/reset notes with tested host/runtime/viewport, known-limitations list and build/fixture IDs. Check submission length, asset/link accessibility and required materials. Recording narrates mocks and does not claim a live backend. | SP-07 |
| **M8 — submission buffer** · D10, Oct 11, cutoff TBD | P0 · delivery | M7 and confirmed official rules | Submit through the required channel in a subsequent authorized execution task; verify receipt/status and preserve the exact submitted build/video. If cutoff is earlier, shift M7/M8 earlier. This document does not submit anything. | Submission checklist |

The critical path is **M0 → M1 → M2 → M3/M4 → M5 → M6 → M7 → M8**. M3/M4 may overlap only if capacity supports it and they use the same M1 contracts. There is no dependency on live price feeds, VMBE servers, production auth or a TPX scoring service.

## Priority and cut policy

| Tier | Included behavior | Rule |
|---|---|---|
| P0 observed core | Feed; listing/acknowledgments/success; market/portfolio views; Arena opposing views/sort/crowd filter | Protect these because they carry the supplied video's story. |
| P0 integration/comprehension | Shared simulated review/position path, seeded receipts, fee explanation, deterministic reset, simulation disclosure | Protect these because they make the screens a coherent demonstrable system. They are proposed completions, not observed live backend behavior. |
| P1-A | Public first-call composer and scripted challenge/result progression: VC-REC-002/003, VC-ARN-006 | Consider only after M5 exits early enough to test and record before scope freeze. Prefer this over unrelated breadth. |
| P1-B | Trader-index Long/Short ticket: VC-MKT-005 | Reuse the shared simulator after instrument distinctions are specified; keep own-market restriction. |
| P1-C | Manual-copy story and creator credit: VC-CPY-001/002 | Requires its reward decision first. Do not confuse it with the existing market-fee display. Use persona switching in the same PC-hosted simulated device. |
| Deferred | Real funds/auth/execution, scoring calibration, production matching/settlement, AI forum, push, advanced orders and large catalog | No work during this window unless an explicit mandatory requirement replaces other scope. |

**Cut order:** omit P1-C, P1-B, then P1-A; simplify peripheral sharing/settings/notifications and decorative motion; reduce the fixture catalog to the proposed minimum. Preserve working controls and truthful state. An honest fixture walkthrough is preferable to disconnected success screens.

If core integration has not passed by D6, stop optional work and use D7–D8 for P0. If available capacity cannot cover P0, explicitly revise the target journeys and record the uncovered video behavior; do not silently call a reduced demo full reference coverage. Mandatory live integration introduced late requires an impact decision, fallback and corresponding scope reduction, not extra unbudgeted work.

## Boundaries for subsequent implementation specs

These are proposed spec packages, not instructions to build all of them at once. Each spec should carry: PRD IDs; exact source citations; proposed behavior versus observed behavior; input/output shapes; fixture/state transitions; relevant failure cases; dependencies; acceptance checklist; selected target and out-of-scope limits. No spec may silently promote a mock to live behavior.

| Spec | Owns / PRD coverage | Contract with other specs | Explicit boundary |
|---|---|---|---|
| **SP-00 — delivery contract** | Assumptions/O-01–O-11; J1–J5; fixture inventory and evidence status | Target, capacity, deadline, final narrative and labels | Resolve required choices; retain optional unknowns. No architecture research project. |
| **SP-01 — shell and scenario store** | S01, VC-DEM-001–004 | IDs, persona, fixture version, reset, demo clock, navigation and serializable financial values | PC-hosted portrait simulated iOS device, mouse/keyboard equivalents and local state. Browser viewport/frame is the proposed runtime. No auth, distributed database or production service mesh. |
| **SP-02 — Home / Tradefeed** | S02, VC-FED-001–004 | Call versus suggestion view models; shared prices/history; detail/profile routes; order context | Curated discovery; no recommendation engine or public social backend. |
| **SP-03 — creator listing** | S03, VC-LST-001–004 | Local ticker registry; draft/acknowledged/listed states; own-market route | Demo acknowledgments and duplicate handling; no actual issuance, eligibility service or binding account setup. |
| **SP-04 — record, market and Wallet** | S04, VC-MKT-001–004; VC-REC-001 | Price/index series, cash/position projections, receipts, fee ledger, shared rounding | Fixture index; no production scoring/funding/liquidity engine. Seeded open-orders view suffices. |
| **SP-05 — Arena / Clash** | S05, VC-ARN-001–005 | Event identity, side/participant fields, sort/filter semantics, ticket context | Seeded live/settled cards and local opinions; no generalized matching or forum backend. Coordinate VC-ARN-004 with SP-06. |
| **SP-06 — simulated order intent and receipt** | S06, VC-ORD-001–003; VC-ARN-004 / VC-MKT-003 integration | Candidate→review→cancel/confirm/failure; stable action ID; position + participation update | One simple asset-order path; no Merchant executor wiring or wallet signing. |
| **SP-07 — demo verification and packaging** | S09, VC-QA-001–004 | Requirements checklist, PC host/runtime/viewport matrix, scripted fixtures, reproducible build and screen recording | Verify actual delivered paths and desktop input in the simulated phone; do not inherit old FMA test-pass claims or imply native iOS verification. Figma fidelity remains explicitly provisional if inaccessible. |
| **SP-08 — optional call lifecycle** | VC-REC-002/003, VC-ARN-006 | Public call creation; deterministic pairing/result events; receipt/index projections | Scripted event transitions only; separate position close from event verdict. |
| **SP-09 — optional trader-index ticket** | VC-MKT-005 | Separate index instrument kind and eligibility on SP-06 simulator | No collateral/liquidity protocol; own-market entry blocked everywhere. |
| **SP-10 — optional copy reward story** | VC-CPY-001/002 | Source-call attribution, manual second-person order, separately typed demo credit | Define reward first; no automated copy execution or real payment. |

**Recommended next step:** SP-00 reconciliation of the newly merged VC app against PRD acceptance criteria, followed by specs for the actual gaps in SP-01–SP-07. Carry the confirmed PC/simulated-iOS target forward and record runtime/tool and team choices. Preserve existing working screens; establish the shared scenario contract where needed. Do not reimplement the shell or mark a milestone complete without evidence.

## Milestone verification record template

For each exit, record the build/revision, fixture version, target, PRD IDs exercised, outcome, defects and evidence location. Use `passed`, `failed`, `not run` and `deferred` distinctly. A screenshot proves appearance; a recorded interaction or focused test proves a transition. Neither proves a production backend.

The minimum integration checks are cancellation without mutation; repeated confirmation without duplication; matching instrument/direction across entry/review/receipt; consistent cash/fees/positions; matching Arena membership; correct filter counts; stable reset; and two full rehearsal runs. Add targeted tests for these state invariants when implementing, plus manual visual checks. Do not spend the hackathon recreating VMBE's production test matrix.

## Completion definition

The roadmap is fulfilled when the selected P0 requirements pass on the chosen target, the final demo can be reset and repeated, the submission package accurately states the mock boundary, and the hackathon submission is verified before its confirmed cutoff. P1 completion is separate and never assumed. At this planning stage, no implementation milestone, build, rehearsal or submission is claimed complete.
