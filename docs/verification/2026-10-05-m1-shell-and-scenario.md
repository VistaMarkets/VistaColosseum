# M1 verification record: running shell and scenario

Milestone M1 from `docs/prd/2026-10-01-vc-hackathon-roadmap.md`. Fields marked TODO are the presenter's to fill; the rest is read from the recording.

| Field | Value |
|---|---|
| Build / revision | TODO (expected `main` @ 0c7402d or later; state the SHA that was launched) |
| Fixture version | `fixture-v1` (`app/lib/scenario/scenario.dart`) |
| Target | TODO (iOS Simulator on the presenter Mac, or physical iPhone; name the device and iOS version) |
| Run date | 2026-10-05 |
| Evidence | `iphone-proof.mp4`, 49.7 s, 680x1402, recorded 06:40 (copy into `docs/verification/evidence/` or link its stored location) |

## PRD IDs exercised

| ID | Check | Outcome | Evidence |
|---|---|---|---|
| VC-DEM-001 | App launches on the presenter machine in a portrait iOS device; Home, Explore, Arena, Wallet reachable; market and profile drill-downs reachable | passed | Recording 0:00 to 0:48: Home feed, Explore assets and traders, maya.eth market with Record tab, Arena, vega's call detail, Wallet |
| VC-DEM-001 | Mouse click, scroll and keyboard text entry drive a core journey | passed | Recording 0:30 to 0:38: Make-a-market ticker typed, pitch typed, checkboxes clicked, "Your market is open" |
| VC-DEM-002 | Same entity shows the same value on feed, detail, Arena and Wallet | passed (spot check) | maya.eth $44.0M cap and 4.27% appear identically on Explore (0:08), market page (0:10) and Wallet (0:40) |
| VC-DEM-002 | Reset restores the fixture and clock; two runs after reset match | TODO: passed / not run | Not in the recording. Record the Settings "Reset demo" tap and the toast "Demo reset to fixture-v1", then one journey repeated |
| VC-DEM-003 | Persistent simulation indicator visible | TODO: passed / failed | Not legible at the recording's resolution; confirm on device |
| VC-DEM-003 | Build runs without credentials, signing, RPC or VMBE, network unavailable | TODO: passed / not run | Run once with networking off |
| VC-DEM-004 | Presenter reset control works | same as the VC-DEM-002 reset row | |
| VC-DEM-004 | Persona switch and scenario-phase advance | not run | Deliberately unbuilt: persona switch is spec 09, phase advance is P1 (O-10) |

## Roadmap exit criteria

| Criterion | Outcome |
|---|---|
| Launches in the iOS Simulator on the actual presenter Mac | TODO (depends on Target above) |
| Navigates Home, Explore, Arena, Wallet and the market route | passed |
| Displays simulation status | TODO |
| Resets identities, clock and state | TODO |
| Scenario-store contracts frozen | passed, spec 01 merged in PR #10 |
| Run and reset instructions exist and work on that machine | TODO: add them below or link them |
| Sample recording works on that machine | passed, this recording |
| No VMBE or credentials required | TODO |

## Defects observed

- The Wallet at ~0:40 shows the demo trader's $44.0M cap beside the portfolio after the user created `$MAYA` at $10,000 (0:38). Either the toggle shows the pre-seeded market rather than the newly listed one, or the two are the same market and the create flow did not change the cap. Needs a look before the copy story lands. Not blocking M1.

## Run and reset instructions

TODO: the exact commands or steps used on the presenter Mac to build, launch and reset.

## Verdict

Not exited until the TODO rows above are filled. Navigation, drill-downs and input handling are proven by the recording; reset, simulation indicator, offline run and the launch target are the open checks.
