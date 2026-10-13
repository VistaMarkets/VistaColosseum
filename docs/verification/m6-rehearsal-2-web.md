# M6 rehearsal 2 — hosted web build, scripted

The second run of [the protocol](rehearsal-protocol.md), steps 1–41, from reset. This run was **not** performed by the presenter: a Playwright script drove the hosted web build through Flutter's web semantics tree and recorded the screen. Rows are *scripted*: an outcome is `passed` only where the script found the expected label on screen; `failed` means the script could not complete the step, which in every case below traces to the driver (a control not exposed to web semantics, or a count the script read wrong), not to an observed app defect. The video is the footage; nobody has narrated it.

**Target deviation.** Spec 11 named the iOS Simulator on a Mac. This run used the hosted web build in headless Chromium at 390×844 (the phone frame fills the viewport at that width). Rehearsal 1 used the Linux desktop build on WSL.

| Field | Value |
|---|---|
| Build SHA | `ae7b7ffd` (`main`, PR #52) — the commit the gh-pages build names (`gh-pages` commit `ff52cb4`, "web build ae7b7ff") |
| Fixture version | `fixture-v1` |
| Date and start time | 2026-10-12, 22:38 PDT |
| Host | Ubuntu 24.04.5 LTS on WSL2, Node 24.15.0, Playwright Chromium 1248 (headless) |
| Target | https://vistamarkets.github.io/VistaColosseum/ at 390×844, device scale 2, text scale 1.0 |
| Input | Mouse click, mouse drag (card pager, balance pager), scroll wheel, keyboard. Range-slider drags not attempted |
| Recording | `evidence/m6-rehearsal-2-web.webm`, 216.8 s, 390×844, sha256 `95b1c70e1f178a3f8e1d9cd8ef13793f95423cccf47847c1b83e97764fd9020a`. Second location: not uploaded |
| Driver and log | `evidence/m6-rehearsal-2-web-driver.js`, `evidence/m6-rehearsal-2-web.log` |
| Seeded-market cover (FR-9) | not re-run at this SHA; rehearsal 1's log covers `505217c`. `flutter test` (no flags) at `ae7b7ff`: 360 passed |

## Step outcomes

| Steps | Outcome | Note |
|---|---|---|
| 1–7 | passed | Reset toast, Creator persona, $12,480.00, 3 positions, 3 open orders; load-failure switch and Explore Retry; For You / Following distinct; card replay; Like, People in, Details |
| 8 | failed | Profile opened by a coordinate tap (`step8-profile.png`) but the Follow toggle label was not found; the handle is not a semantics node |
| 9 | failed | The driver's swipes did not reach a Maker card in 14 attempts |
| 10–17 | passed | Span chips, Deposit toast, Make a market: ticker blank/BTC disable Continue, $MAYA enables it, consents, Create, $10,000 cap, first-call sheet, sample call, Share toast, "Fees from your market" $0.00, Your market pill, Make a call toast |
| 18–19 | passed | 3 battles, Bull/Bear, sort chips |
| 20–21 | not run | Range-slider drag not scripted |
| 22 | not run | The Ask field accepts typed text ("SOL" → 1 battle) but the driver cannot clear it, so DOGE and Clear search were not exercised |
| 23–26 | passed | Opinions, 0xreal profile, cancel leaves $12,480.00 / 3 / 3 / no receipt; review "Bitcoin · BTC", Long 10x, Paper funds required $3,120.00 |
| 27 | failed | Double-click Confirm produced one fill (Positions · 4 at step 28); the toast text pattern the script expected was not matched |
| 28–30 | passed | Positions 4; BTC receipt under All receipts; Arena card reads "Joined Bull" |
| 31 | failed | The Explore ETH fill succeeded (an "Ethereum, LONG 10x" position appeared) but the script lost its place returning to Arena |
| 32 | failed | Driver counted only the position rows on screen (4 of 5) |
| 33–41 | failed | Cascade from step 32: the script never switched persona, so the copy story, ledger, call receipt, trader market and position sheet were not reached in this run |

Ticker availability text ("✓ Available", "× Taken", "2–8 letters") is not exposed to semantics; screenshots `step11-ticker-available.png`, `step12-blank.png`, `step12-btc.png` were taken but not kept in the tree.

## P0 IDs exercised

| ID | Check | Outcome | Evidence |
|---|---|---|---|
| VC-DEM-001 | Navigation and drill-downs with Back | passed | steps 3, 6–7, 23–24 |
| VC-DEM-001 | Mouse, drag, wheel, keyboard drive the journeys | passed | steps 5, 12, 16 |
| VC-DEM-001 | Portrait simulated iOS device | not run | web build |
| VC-DEM-002 | Reset restores the fixture | passed | step 1 |
| VC-DEM-002 | Figures agree across Wallet, ledger, receipts | not run | step 32 onward not reached |
| VC-DEM-003 | Pill visible; simulated wording on review | passed | steps 4, 25 |
| VC-DEM-004 | Reset | passed | step 1 |
| VC-DEM-004 | Persona switch | not run | step 33 not reached |
| VC-DEM-004 | Scenario-phase advance | deferred | never built |
| VC-FED-001 | Tabs differ; pager; replay | passed | steps 4–5 |
| VC-FED-002 | Replay markers; Details market | passed | steps 5, 7 |
| VC-FED-003 | Like, People in, profile | passed | steps 6, 24 |
| VC-FED-004 | Maker cards | not run | step 9 driver failure |
| VC-LST-001 | Ticker validation | passed | steps 11–12 (Continue enable state) |
| VC-LST-002 | Consents; nothing created on close | passed | steps 13–14 |
| VC-LST-003 | $10,000 cap on success, Wallet and Your market | passed | steps 15–17 |
| VC-LST-004 | First-call sheet and sample call | passed | step 15 |
| VC-MKT-001 | One market cap everywhere | passed | steps 16–17 |
| VC-MKT-002 | Trader record | not run | steps 39–40 not reached |
| VC-MKT-003 | Wallet balance, Deposit notice | passed | step 10 |
| VC-MKT-004 | Fee ledger | not run | step 37 not reached |
| VC-ARN-001 | Three battle cards | passed | step 18 |
| VC-ARN-002 | Sort chips | passed | step 19; crowd split not run |
| VC-ARN-003 | Opinions | passed | step 23; search not run |
| VC-ARN-004 | Joined Bull after fill | passed | step 30 |
| VC-ARN-005 | Crowd panel | passed | step 18 |
| VC-ORD-001 | Ticket and review | passed | steps 25–26 |
| VC-ORD-002 | Cancel; one fill on double-click | passed | steps 25, 28 (toast text not matched by script) |
| VC-ORD-003 | Receipt matches review | passed | step 29 |
| VC-REC-001 | Call receipts | not run | step 38 not reached |
| VC-CPY-001 | Copier switch and copy order | not run | steps 33–35 not reached |
| VC-CPY-002 | $5.00 credit on creator's ledger | not run | step 37 not reached |
| VC-QA-001 | Viewport matrix | not run | 390×844 only, text scale 1.0 |
| VC-QA-002 | Failed/empty states | passed | step 3 |
| VC-QA-003 | Second run from reset | passed for steps 1–7, 10–19, 23–26, 28–30 | this record |
| VC-QA-004 | Final recording and package | not run | — |
| VC-REC-002, VC-REC-003, VC-ARN-006 (P1-A); VC-MKT-005 (P1-B) | — | deferred | — |

## Defects observed

None. Every `failed` row above is a driver limitation; no row of class "prevents a core journey" or "misrepresents a financial action" was observed.

## Milestones

M6 does not exit on this run: the copy story (steps 33–37), the crowd-split drags, the search field, and the viewport matrix were not exercised. Rehearsal 1 remains the only full pass, on build `505217c`.

**Verdict:** no exit for M6. The 24 passed steps confirm the hosted web build of `ae7b7ff` runs the reset, listing, Arena and order journeys from reset with figures matching the protocol.
