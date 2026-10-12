# M6 rehearsal 1

The first full rehearsal of [the protocol](rehearsal-protocol.md), steps 1–41, run from reset by the presenter using [the WSL checklist](presenter-checklist-wsl.md). The presenter reported every step as passed. Rows are *attested*: the presenter checked them and reported them passed. The screen recording is the footage; it has not been reviewed beyond the presenter's attestation.

**Target deviation.** Spec 11 names the iOS Simulator on a Mac (FR-1, FR-13, FR-18). This run used the Linux desktop build under WSLg in a 402×874 window (PR #46), because the presenter ran on WSL. The macOS, Xcode, Simulator device and iOS runtime fields below are replaced with the WSL host's versions.

| Field | Value |
|---|---|
| Build SHA | `505217c97d825d6ddc003fc4e831d4190ab686c1` (`main`, PR #46) |
| Fixture version | `fixture-v1` (`app/lib/scenario/scenario.dart`) |
| Date and start time | 2026-10-12. The app window opened at 08:30:58 PDT, per the launch log; the presenter did not report the run's start time |
| Host | Ubuntu 24.04.5 LTS on WSL2 (kernel 6.18.33.2-microsoft-standard-WSL2), Flutter 3.47.5 stable |
| Target | Linux desktop (`flutter run -d linux --release`), no `--dart-define` flags, 402×874 window, text scale 1.0x. Not the iOS Simulator |
| Input | Mouse click, mouse drag (pagers, sliders, sheet handles, made to work in PR #46), scroll wheel, keyboard |
| Recording | Windows `Videos\Captures` folder (Xbox Game Bar). File name, duration and sha256 not recorded |
| Seeded-market cover (FR-9) | `flutter test --dart-define=HAS_MARKET=true` at the build SHA: 348 passed, exit 0. Log: `evidence/m6-rehearsal-1-has-market.log` |

## P0 IDs exercised

| ID | Check | Outcome | Evidence |
|---|---|---|---|
| VC-DEM-001 | Home, Explore, Arena and Wallet reachable; market and profile drill-downs; Back returns to the prior surface; state kept across tabs | passed | Attested, steps 3, 6–8, 18, 23–24, 31, 39–40 |
| VC-DEM-001 | Mouse click, drag, scroll wheel and keyboard drive every core journey, including swipes and the crowd-split range drag | passed | Attested, steps 5, 12, 16, 20–22, 26–27, 34 |
| VC-DEM-001 | Runs inside a portrait simulated iOS device | not run | Linux desktop window instead (see Target deviation) |
| VC-DEM-002 | Cash, positions, receipts and ledger agree across Wallet, Fee ledger and All receipts | passed | Attested, steps 28, 32, 35–37 |
| VC-DEM-002 | Reset restores the fixture | passed | Attested, step 1 ("Demo reset to fixture-v1") |
| VC-DEM-003 | "Simulated · fixture-v1" pill visible; simulated wording on review and toasts | passed | Attested, steps 4, 25, 27 |
| VC-DEM-004 | Reset | passed | Attested, step 1 |
| VC-DEM-004 | Persona switch | passed | Attested, steps 33, 36 |
| VC-FED-001 | For You and Following show different calls; card pager and replay | passed | Attested, steps 4–5 |
| VC-FED-002 | Card replay and Details | passed | Attested, steps 5, 7 |
| VC-FED-003 | Like, People in, Details, trader profile and Follow | passed | Attested, steps 6–8, 24 |
| VC-FED-004 | Maker cards attributed and advisory; the expired one can't trade; viewing creates no order | passed | Attested, step 9 |
| VC-LST-001 | Ticker validation: blank, taken, available; pitch kept | passed | Attested, steps 11–12 |
| VC-LST-002 | Consent rows gate Create; closing creates nothing | passed | Attested, steps 13–14 |
| VC-LST-003 | Listing completes once; success leads to the market; Wallet updates | passed | Attested, steps 14–16 |
| VC-LST-004 | First call explains it is outside the demo and offers a seeded call (PR #44) | passed | Attested, step 15 per the checklist |
| VC-MKT-001 | One cap ($10,000) on success, Wallet, Your market, Explore, Trader market and Profile; series switch | passed | Attested, steps 16–17 and the checklist's post-step-17 check (PR #41) |
| VC-MKT-002 | Record panel and call receipts agree on Profile and Trader market | passed | Attested, steps 17, 39–40 |
| VC-MKT-003 | Positions and cash after fills and cancel | passed | Attested, steps 25, 28, 32, 41 |
| VC-MKT-004 | Fee ledger separate from P&L; Total = market credits + copy fees; 40% creator share label | passed | Attested, steps 32, 37 |
| VC-ARN-001 | Three seeded battle cards with both sides | passed | Attested, step 18 |
| VC-ARN-002 | Sorts; crowd-split filter with derived counts; empty state and Show all (3, 0, 3) | passed | Attested, steps 19–21 |
| VC-ARN-003 | Ask filters and explains unknown input; more opinions | passed | Attested, steps 22–23 |
| VC-ARN-004 | Cancel joins nothing; a fill from a battle joins once; a fill from Explore joins nothing | passed | Attested, steps 25, 30–31 |
| VC-ARN-005 | Crowd split, verdict and P&L kept separate | passed | Attested, steps 20, 38, 41 |
| VC-ORD-001 | Ticket opens with the right instrument and side; review shows values and simulation status | passed | Attested, steps 25–26, 34 |
| VC-ORD-002 | Cancel changes nothing; a double-click on Confirm fills once | passed | Attested, steps 25, 27; `order_ticket_test.dart` 'double tap confirm places one position' (FR-11) |
| VC-ORD-003 | Instrument and direction agree from entry through review to receipt | passed | Attested, steps 26, 28–29 |
| VC-REC-001 | Paper receipts and call receipts are separate and match the review | passed | Attested, steps 29, 38 |
| VC-CPY-001 | Copier copies a call through review | passed | Attested, steps 33–35 |
| VC-CPY-002 | One $5.00 copy row naming copier and source call, in maya.eth's ledger (Oct 12 ruling 1) | passed | Attested, steps 35, 37 |
| VC-CPY-002 | Presenter states the fee is invented | passed | Attested, checklist section 4 |
| VC-QA-002 | Seeded load failure and Retry recover | passed | Attested, steps 2–3 |
| VC-QA-003 | One run from reset with cancel, error, duplicate confirm and filter reset | passed | Attested, steps 1–3, 21, 25, 27 |

## Not exercised

| ID | Clause | Outcome |
|---|---|---|
| VC-DEM-004 | Scenario-phase advance (never built, gated on PRD O-06/O-10) | deferred |
| VC-QA-001 | 390×844 and 375×667 viewports, 1.3x text, touch-target sizes (the M6 viewport matrix) | not run |
| VC-QA-003 | Second run from reset (rehearsal 2) | not run |
| VC-QA-004 | Final recording and submission package (M7) | not run |
| VC-ORD-002 | AVAX order-failure recovery | not run |
| VC-MKT-003 | Zero-history and capital-independence examples | not run |
| VC-MKT-004 | Worked 40% market-fee example | not run |
| VC-REC-002 (P1-A) | — | deferred |
| VC-REC-003 (P1-A) | — | deferred |
| VC-ARN-006 (P1-A) | — | deferred |
| VC-MKT-005 (P1-B) | — | deferred |

## Defects observed

None reported.

## Milestones

M2 to M5 exit on this run, on the Linux desktop target. J1 to J5 and the copy story ran from reset with every step passing. No exit criterion is failing: VC-LST-004 is fixed (#44), and M4's video-only labels were removed from its exit on Oct 12. No row of class "misrepresents a financial action" is open (rulings record, #41, #43). M6 does not exit yet: it needs rehearsal 2 and the viewport matrix.

**Verdict:** exit. No defect of class "prevents a core journey" or "misrepresents a financial action" was observed.
