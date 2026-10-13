# Verification

How each milestone was checked, and against which build. Records use four outcomes only: `passed`, `failed`, `not run` and `deferred`.

## Current

| Record | What it shows |
|---|---|
| [Rehearsal 2, October 12 (web, scripted)](m6-rehearsal-2-web.md) | 24 of 41 steps passed on the hosted build of `ae7b7ff`, driven by a script; copy story and sliders not reached. No defect; M6 does not exit |
| [Rehearsal 1, October 12](m6-rehearsal-1.md) | All 41 protocol steps from reset passed on build `505217c`. M2 to M5 exit. Run as the Linux desktop build on WSL |
| [Rulings, October 12](2026-10-12-user-rulings.md) | The six decisions on the demo's money rules that closed the last open questions |
| [M1, October 5](2026-10-05-m1-shell-and-scenario.md) | Launch, navigation and reset in the iOS Simulator on a Mac. M1 exits |
| [Rehearsal protocol](rehearsal-protocol.md) | The 41 steps, the control inventory and the P0/P1 ID lists every rehearsal follows |
| [WSL presenter checklist](presenter-checklist-wsl.md) | How to run the protocol on Linux or WSL |

## Superseded

These records were accurate on their date and are kept as the audit trail. Each found failures that were fixed later; rehearsal 1 is the current result. Some cite internal build logs that are no longer in the tree but remain in git history.

| Record | Outcome then | Resolved by |
|---|---|---|
| [M2, October 5](2026-10-05-m2-home-and-listing.md) | Not exited | October 7 fixes (#32), #44, rehearsal 1 |
| [M3, October 5](2026-10-05-m3-market-and-wallet.md) | Not exited | #32, #41, rehearsal 1 |
| [M4, October 5](2026-10-05-m4-arena-discovery.md) | Not exited | #32, #41, #45, rehearsal 1 |
| [M2–M4 re-verification, October 7](2026-10-07-m2-m4-reverification.md) | Not exited | #41, #43, the October 12 rulings, rehearsal 1 |
| [M5, October 7](2026-10-07-m5-participation-and-copy.md) | Not exited | #43, the October 12 rulings, rehearsal 1 |

## Still to do

- **M6:** rehearsal 2 from reset on the same build, and the viewport checks at 390×844 and 375×667 with 1.3× text.
- **M7:** the final narrated recording and the submission package.

## Known limitations

- **Not exercised in rehearsal 1:** the AVAX order-failure recovery (VC-ORD-002), the zero-history and capital-independence examples (VC-MKT-003), the worked 40% fee example (VC-MKT-004), and the iOS-device clause of VC-DEM-001.
- **Deliberately not built:** the scenario-phase control (VC-DEM-004) and the P1 items VC-REC-002, VC-REC-003, VC-ARN-006 and VC-MKT-005.
- **Cosmetic residuals** still open from the October 7 records:
  - no missing-history state for a call replay (VC-FED-002);
  - Details opens the asset or trader market, not a view of the call, and the empty follow list routes only to Explore (VC-FED-003);
  - Maker "Trade this" opens the ticket at the live mark, not the suggestion's reference price (VC-ORD-001);
  - the copy-fee ledger row names the copier and asset but not one specific source call (VC-CPY-002);
  - Deposit is a not-built notice and there is no Withdraw (VC-MKT-003);
  - two tests named in spec 06 were never written, and the ledger has no per-kind footer (VC-MKT-004);
  - spec 12 residuals: the seeded market's 1M and All history predates its listing, and the taken-ticker list doesn't match Explore (VC-MKT-001);
  - the primary button exposes no accessibility tap action, and two listing steps overflow at text scale 1.15 or above on a 360×640 screen.
- **Economics:** the market cap, supply, 40% creator share and $5.00 copy fee are a demo narrative, not the product's real economics.
