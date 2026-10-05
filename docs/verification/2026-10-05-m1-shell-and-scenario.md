# M1 verification record: running shell and scenario

Milestone M1 from `docs/prd/2026-10-01-vc-hackathon-roadmap.md`. Rows marked *recording* are read from `iphone-proof.mp4`. Rows marked *attested* were verified by the presenter on the Mac on 2026-10-05 and reported as passed; they are not in the footage.

| Field | Value |
|---|---|
| Build / revision | app code at `main` 7a153be (0c7402d adds docs only); recorded 2026-10-05 06:40 PDT, after the last app merge |
| Fixture version | `fixture-v1` (`app/lib/scenario/scenario.dart`) |
| Target | iOS Simulator on the presenter Mac, iPhone-class device with Dynamic Island frame, 680x1402 capture (attested) |
| Run date | 2026-10-05 |
| Evidence | `iphone-proof.mp4`, 49.7 s, 680x1402, recorded 06:40 (copy into `docs/verification/evidence/` or link its stored location) |

## PRD IDs exercised

| ID | Check | Outcome | Evidence |
|---|---|---|---|
| VC-DEM-001 | App launches on the presenter machine in a portrait iOS device; Home, Explore, Arena, Wallet reachable; market and profile drill-downs reachable | passed | Recording 0:00 to 0:48: Home feed, Explore assets and traders, maya.eth market with Record tab, Arena, vega's call detail, Wallet |
| VC-DEM-001 | Mouse click, scroll and keyboard text entry drive a core journey | passed | Recording 0:30 to 0:38: Make-a-market ticker typed, pitch typed, checkboxes clicked, "Your market is open" |
| VC-DEM-002 | Same entity shows the same value on feed, detail, Arena and Wallet | passed (spot check) | maya.eth $44.0M cap and 4.27% appear identically on Explore (0:08), market page (0:10) and Wallet (0:40) |
| VC-DEM-002 | Reset restores the fixture and clock; two runs after reset match | passed (attested) | Settings "Reset demo", not in the recording. Unit test `Scenario.reset()` twice-equal in spec 01 (PR #10) covers the state half |
| VC-DEM-003 | Persistent simulation indicator visible | passed (attested) | Not legible at capture resolution; spec 03 widget tests (PR #13) cover presence |
| VC-DEM-003 | Build runs without credentials, signing, RPC or VMBE, network unavailable | passed (attested) | No network calls exist in the app; the demo ran without any configured credentials |
| VC-DEM-004 | Presenter reset control works | same as the VC-DEM-002 reset row | |
| VC-DEM-004 | Persona switch and scenario-phase advance | not run | Deliberately unbuilt: persona switch is spec 09, phase advance is P1 (O-10) |

## Roadmap exit criteria

| Criterion | Outcome |
|---|---|
| Launches in the iOS Simulator on the actual presenter Mac | passed (attested; recording made on that machine) |
| Navigates Home, Explore, Arena, Wallet and the market route | passed |
| Displays simulation status | passed (attested) |
| Resets identities, clock and state | passed (attested) |
| Scenario-store contracts frozen | passed, spec 01 merged in PR #10 |
| Run and reset instructions exist and work on that machine | passed; see below |
| Sample recording works on that machine | passed, this recording |
| No VMBE or credentials required | passed |

## Defects observed

- The Wallet at ~0:40 shows the demo trader's $44.0M cap beside the portfolio after the user created `$MAYA` at $10,000 (0:38). Either the toggle shows the pre-seeded market rather than the newly listed one, or the two are the same market and the create flow did not change the cap. Needs a look before the copy story lands. Not blocking M1.

## Run and reset instructions

Run: `cd app && flutter run -d <simulator id>` (`flutter devices` lists it; add `--dart-define=HAS_MARKET=true` for the listed-market persona). Reset: Settings, bottom row "Reset demo", toast "Demo reset to fixture-v1".

## Verdict

**M1 exited 2026-10-05.** Navigation, drill-downs, input handling and cross-screen consistency are proven by the recording; reset, simulation indicator, offline run and the launch target are attested by the presenter on the Mac and backed by the merged unit tests. VC-DEM-004 persona switch and phase advance remain unbuilt by design.
