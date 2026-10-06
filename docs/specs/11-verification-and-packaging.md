# Spec — 11: Verification and packaging (SP-07)

## 1. Executive summary

This spec turns VC-DEM-001, VC-QA-001, VC-QA-003 and VC-QA-004 into a verification trail a judge or a later session can audit: a rehearsal protocol with a control inventory, a viewport-and-input matrix on two named Simulator devices, two rehearsals from reset, a README section that lets anyone run and reset the demo, the final demo recording with its script, and a submission package that names build, fixture, recording and mock boundary. Deliverables are Markdown records under `docs/verification/`, a README section, a one-line deadline correction in the PRD and the roadmap, and one screen recording; no file under `app/` changes. The five phases map onto roadmap milestones M6 and M7 (`docs/prd/2026-10-01-vc-hackathon-roadmap.md:33-34`).

## 2. Problem and goals

**Problem.** M1 is the only milestone with a verification record (`docs/verification/2026-10-05-m1-shell-and-scenario.md`). The roadmap's completion definition (`roadmap.md:84`) requires that the P0 requirements pass on the chosen target, the demo resets and repeats, and the package states the mock boundary. None of that is written down for M6 and M7, so neither can exit, and VC-QA-003's exit bar (`docs/prd/2026-10-01-vc-hackathon-master-prd.md:170`: no unresolved defect that prevents a core journey or misrepresents a financial action) has never been applied.

**Goals.**
- G1: both required viewports and the desktop input path are checked and recorded against one build SHA, with evidence for passed rows (DR-12).
- G2: J1 to J5 run twice from reset against that build SHA and `fixture-v1`, with cancel, one seeded error, duplicate confirm and filter reset exercised, and the VC-QA-003 defect bar applied.
- G3: a stranger with the repo and a Mac can run and reset the demo from the README.
- G4: the final recording exists, follows the script, and the package names build, fixture, recording, mock boundary, known limitations and deadline.

**Non-goals.** Submitting anything (M8, `roadmap.md:35`). Changing app code: no file under `app/` is created or modified; `app/lib/scenario/scenario.dart`, `feed_order_ticket.dart`, the fee ledger and `settings_screen.dart` are being rewritten by spec 09 (`docs/specs/09-copy-story.md:7,11`). Native iOS certification or Figma fidelity claims (`master-prd.md:168`). Fixing defects found: a defect is a row in a record and a follow-up issue; the VC-QA-003 bar then decides whether M6 exits (FR-14). Declaring the scope freeze (roadmap M6, `roadmap.md:33`): a process event the user calls, recorded in the roadmap, not here.

**Success metrics.** Every file in the §5 manifest exists on `main`; in every record this spec creates (`docs/verification/m6-*.md`, `docs/verification/m7-*.md`), every Outcome cell is exactly one of `passed`, `failed`, `not run`, `deferred` (`roadmap.md:78`) with no qualifier: `grep -n -E '\| *(passed|failed|not run|deferred) [^|]' docs/verification/m6-*.md docs/verification/m7-*.md` prints no line whose hit is an Outcome cell (the M1 record is outside this check); `grep -rn -E 'TODO|TBD' docs/verification/` prints no line; the two rehearsal records cite the same 40-hex build SHA; `git diff origin/main --stat -- app/` on the branch is empty; both rehearsal records end with a Verdict line that applies FR-14.

## 3. Users and context

- **Presenter** (the user) runs the checks on the presenter Mac in the iOS Simulator. Mouse and keyboard are the input path; the Simulator turns clicks into touches, so a control's touch-target size cannot be judged by clicking it (FR-5 names the measuring method).
- **Judge** opens the README, may clone and run the demo, reads the package.
- **Next session** (agent or human) reads the records to know what passed, on which build, and what was never tested.

Constraints: Dart SDK `^3.13.1` (`app/pubspec.yaml:7`); no web target (`app/web/` absent, `app/ios/` present); fixture version `fixture-v1` (`app/lib/scenario/scenario.dart:37`); text scale clamped at 1.3x (`app/lib/main.dart:30-31`); the gate is `scripts/gate.sh <log-dir>` printing `GATE: PASS`; no `integration_test/` target exists under `app/`. Line citations into `app/` are as of `7d39bff`; after spec 09 merges, find the quoted string with grep rather than trusting the line number.

## 4. Requirements

### Functional

- FR-1: the matrix MUST record every control in the inventory at 390x844 (Simulator device iPhone 14) and 375x667 (iPhone SE, 3rd generation), each at text scale 1.0x (Dynamic Type "Large") and 1.3x (any Dynamic Type step at or above xxxLarge; the app clamps at 1.3x, `main.dart:30-31`) (VC-QA-001, `master-prd.md:168`).
- FR-2: the matrix MUST record, per inventory control, that it is operable by mouse click, scroll or drag, or keyboard text entry, including the Arena crowd-split range filter by drag and every paging or swipe control by a mouse equivalent (VC-DEM-001 `master-prd.md:81`, VC-QA-001).
- FR-3: the matrix MUST record that Back returns to the prior surface from each drill-down, and that switching sections preserves the selected call and the Arena filter state (VC-DEM-001).
- FR-4: the matrix MUST record that the four navigation items (`app/lib/app_shell.dart:37-40`: Home, Explore, Arena, Wallet) and the market and profile drill-downs from Home, Explore and Arena each reach a destination (VC-DEM-001).
- FR-5: the matrix MUST record, for each control on the J1 to J5 action path, its touch-target size measured with Flutter DevTools "Select widget mode" (or Xcode Accessibility Inspector, named per row); a control under 44 logical pixels goes in the Exceptions list with its measured size, and the FR-5 summary row is `passed` only when the Exceptions section carries the presenter's sign-off line (DR-13).
- FR-6: the matrix MUST record that the Simulator's device chrome and the app's simulation strip cover no navigation item, form field or action button, and that resizing the Simulator window keeps the device viewport portrait at its logical size (VC-QA-001).
- FR-7: the matrix MUST record that bull/bear and long/short labels are readable without colour, each carrying text or a glyph, and that every J1 to J5 screen renders the dark mobile layout with Vista styling, both checked at both viewports and scales (VC-QA-001 `master-prd.md:168`; the DR-12 journey screenshots are the evidence for the layout rows).
- FR-8: the protocol MUST define one ordered step table covering J1 to J5 from reset, every step with a Persona cell (DR-10), with one cancel, one seeded error, one duplicate confirm, one filter reset, one entry-to-review-to-receipt instrument and direction check, one Arena membership check after a confirm opened from an Arena battle's Bull or Bear button (`arena_screen.dart:138-139`; participation is written only when the intent carries a `clashId`, `scenario.dart:351-356`, so a confirm from a call or from Explore joins nothing and MAY be recorded as a second, negative check), and one reconcile check after the J4 confirm in which Wallet cash, position count, fee ledger total and receipt count agree across Wallet, Ledger and Receipts (VC-QA-003 `master-prd.md:170`; roadmap minimum checks `roadmap.md:80`), and the copy-story steps of spec 09 (persona switch, copied order, `copy` ledger credit; `docs/specs/09-copy-story.md:11`) (DR-11).
- FR-9: a rehearsal MUST start with the Settings "Reset demo" row (`settings_screen.dart:123`) and record the toast "Demo reset to fixture-v1" (`app/lib/features/simulation/simulation_indicator.dart:19`), MUST run without `--dart-define=HAS_MARKET=true` so J2 creates the market (DR-9), and the record MUST cite a `flutter test --dart-define=HAS_MARKET=true` run on the build SHA with its log path as the cover for the seeded-market presentation.
- FR-10: the seeded error MUST be the Settings "Simulate load failure" switch (`settings_screen.dart:129-134`, `scenario.dart:109`) followed by Retry on Explore, which clears it (`app/lib/features/markets/markets_screen.dart:122-123`).
- FR-11: the duplicate confirm MUST be a fast double-click on Confirm in the shared order ticket (`app/lib/features/trade/order_ticket.dart:855-866`, the only `Scenario.placeOrder` caller, `order_ticket.dart:823,861`); the record MUST show one position and one receipt and MUST cite the widget test `app/test/order_ticket_test.dart:109` 'double tap confirm places one position' as the proof that the store guard (`scenario.dart:273-279`) holds (DR-8).
- FR-12: the filter reset MUST be Arena's "Show all" or "Clear search" (`app/lib/features/arena/arena_screen.dart:173-179`), which exist only in the empty state (`arena_screen.dart:168-181`; the range slider has no reset affordance, `crowd_filter_panel.dart:56-64`): the step first drags the crowd-split range, or Asks a query, until no battle matches and the "No battles in this crowd split" or "No battles on ..." message shows, then taps the button; the record MUST show the card count before narrowing, at empty (0) and after reset, the last equal to the unfiltered count.
- FR-13: each rehearsal record MUST state a 40-hex build SHA, fixture version, ISO date and start time, macOS version, Xcode version, Simulator device and iOS runtime version, and MUST give every P0 ID in the protocol's enumerated list at least one row with an outcome (an ID with several clauses, such as VC-DEM-004's reset, persona switch and scenario-phase advance, gets one row per clause, as the M1 record does at `2026-10-05-m1-shell-and-scenario.md:23-24`), the unexercised IDs or clauses under a "Not exercised" heading as `not run` or `deferred`, and MUST list every roadmap P1 ID (`roadmap.md:46-47`: VC-REC-002, VC-REC-003, VC-ARN-006, VC-MKT-005) with an outcome, `deferred` unless built and exercised at the build SHA.
- FR-14: a rehearsal record MUST end with a Verdict line applying VC-QA-003: `exit` only if no `## Defects observed` row carries the class `prevents a core journey` or `misrepresents a financial action`; otherwise `no exit` with those rows listed.
- FR-15: rehearsal 2 MUST run after rehearsal 1 on the same build SHA with its own start time and its own evidence files; the two records MUST agree, for the persona the step names, on cash at every step up to and including the cancel step (no fill yet) and on position count, receipt count and ledger fee total at every step; and after every market fill each record MUST show cash equal to its own previous step's cash minus the paper funds that step's receipt shows taken (`totalCents`, plus the $5.00 copy fee on a copied order) (DR-10). Cash is not compared across runs after a fill: a market order fills at `MarketPrices.now()` frozen when review opens (`order_ticket.dart:104,125-126,852`), the feed random-walks every 3 s (`live_feed.dart:37,46-48`), is off only under `FLUTTER_TEST` (`live_feed.dart:23`), and `Scenario.reset()` (`scenario.dart:362-384`) does not rebase it.
- FR-16: the README MUST gain a "## Running the demo" section naming the tested macOS version, Xcode version, both DR-1 Simulator devices with their iOS runtime versions and viewports (`390x844`, `375x667`), the exact `flutter run -d <simulator id>` command used, the Dynamic Type setting, and the reset step (VC-QA-004 `master-prd.md:171`).
- FR-17: the demo script MUST have one block per protocol screen, each naming the simulated component shown from the list: cash, positions, open orders, listing, fees, receipts, calls, prices, identities; it MUST NOT claim a live backend; it MUST state that the economics shown are a demo narrative (PRD A-05, `master-prd.md:48`); it MUST state that the copy fee is an invented demo number (VC-CPY-002, `master-prd.md:160`).
- FR-18: the presenter MUST produce the final recording in the Simulator at 390x844 on the build SHA, narrated from the script, and the recording record MUST name file, duration, resolution, sha256, two storage locations, build SHA, viewport and the script commit it followed; one of the two storage locations MUST be a URL that opens without sign-in, and uploading there is Phase 4 work (VC-QA-004; roadmap M7 `roadmap.md:34`).
- FR-19: the package MUST state the mock boundary: identities, prices and calls are constant fixtures (`scenario.dart:31`); cash, positions, open orders, listing status, fees and receipts are simulated in `Scenario`; no network call is made at runtime.
- FR-20: the package MUST list known limitations: every ID under "Not exercised" in the rehearsal records, every item still deliberately unbuilt at package time (`baton-runner/br-2026-10-04-p0-queue/digest-phase-8.md:28`), every `## Defects observed` row in any `docs/verification/` record whose third cell is `open` or a commit that is not an ancestor of the build SHA (§5 Defects observed rows), the deferred P1 IDs, and the demo-narrative economics statement.
- FR-21: the package MUST carry a links-and-length checklist: the recording link (FR-18's URL) opens in a private browser window, the repo link opens, the recording length against the allowed length from Q-1 (`allowed length unknown` while Q-1 is waived), the required materials as Q-1 names them (`unknown until Q-1` while waived), and the deadline `2026-10-12 23:59 America/Los_Angeles` (VC-QA-004; roadmap M7 `roadmap.md:34`).
- FR-22: the package MUST NOT claim a submission happened or that any backend is live.
- FR-23: the package MUST name a fallback local artifact with its sha256: a zip of the repo at the build SHA by default, or the format Q-1 names.
- FR-24: every `failed` matrix row MUST have a `## Defects observed` row and an evidence file named for its row id (DR-12).

### Interdependencies

- FR-15 depends on FR-9: a rehearsal that did not start from reset cannot be compared.
- FR-23's format depends on Q-1; the default zip applies until Q-1 answers.
- FR-21's allowed length and required materials depend on Q-1; the cells read `allowed length unknown` and `unknown until Q-1` until it answers.
- FR-18's viewport is FR-1's primary one, 390x844.
- FR-8's copy-story steps require spec 09 on `main` (DR-11).

### Non-functional

- Every record and the protocol are Markdown under 250 lines (`wc -l`); every record opens with the §5 field table.
- Evidence screenshots are PNG under `docs/verification/evidence/`, each under 500 KB (`ls -l`), named `<record>-<step>.png` where `<record>` is the record's basename without `.md` and `<step>` is the protocol step number, the matrix row id, `clock` for a rehearsal's Settings clock screenshot, or `<device>-<scale>-J<n>` for a DR-12 journey screenshot with device token `iphone14` or `iphonese` and scale token `1.0x` or `1.3x` (for example `m6-viewport-input-matrix-iphonese-1.3x-J4.png`).
- Recordings are not committed; they are referenced by name, size, sha256 and two storage locations.

### Terminology

- **record**: one Markdown file under `docs/verification/` produced by Phases 2 to 5, opening with the §5 field table. The protocol is not a record: it has no field table and no build SHA, so Phase 1 can be written before the build exists.
- **protocol**: `rehearsal-protocol.md`, the ordered step table plus the control inventory and the P0 and P1 ID lists.
- **control inventory**: the protocol's list of every tappable, scrollable, draggable or typable control on the J1 to J5 path, one row id each.
- **rehearsal**: one full run of the protocol from reset.
- **matrix**: the viewport-and-input record of Phase 2.
- **package**: `m7-submission-package.md` plus the artifacts it names.
- **mock boundary**: the FR-19 statement.
- **build SHA**: the full 40-hex `main` commit the Simulator build was made from (the M1 record used a short SHA; new records use 40 hex).
- **persona**: once spec 09 lands, `Scenario.activePersona` (creator or copier, `09-copy-story.md:11`); every protocol step names the active persona.

### Global constraints

- No file under `app/` is created or modified by any phase; checked by `git diff origin/main --stat -- app/` being empty on the branch.
- Outcome vocabulary is exactly `passed`, `failed`, `not run`, `deferred`.
- Viewports are written in ASCII as `390x844` and `375x667`; text scales as `1.0x` and `1.3x`, matching the test names (viewports at `app/test/home_screen_test.dart:2681-2682`, scales from `'${scale}x'` at `:2707-2709`).
- Fixture version string is `fixture-v1`.
- Deadline is 2026-10-12 23:59 America/Los_Angeles (DR-2). `master-prd.md:5` and `roadmap.md:35` say October 11, 23:00 and are stale.
- Target is the iOS Simulator on the presenter Mac, devices iPhone 14 and iPhone SE (3rd generation) (DR-1).
- Every record produced by Phases 2 to 5 names one build SHA and every such record names the same one: the first `main` commit at or after the spec 09 merge that the presenter builds (DR-11).

## 5. Architecture and design

No components; the design is a set of files with fixed shapes.

**Record field table** (every record starts with it; the M1 record's version is at `docs/verification/2026-10-05-m1-shell-and-scenario.md:5-11`):

| Field | Type | Constraint |
|---|---|---|
| Build / revision | 40-hex SHA | must be an ancestor of `main` |
| Fixture version | string | `fixture-v1` |
| Target | string | macOS version, Xcode version, iOS runtime version, Simulator device |
| Run date and start time | ISO 8601 with timezone | distinct per rehearsal |
| Flags | string | `none` or the `--dart-define` values used |
| Evidence | list | file names under `docs/verification/evidence/` or recording references |

**Check table rows**: `| <row id or step> | <check> | <outcome> | <evidence> |`, outcome always the third column and one of the four words with no qualifier; the evidence cell names a file, a test, or `attested` for a row the DR-12 journey screenshots back only by appearance (the qualifier never goes in the outcome cell). Matrix control rows carry a fifth column: `| <row id> | <check> | <outcome> | <evidence> | <size px / method> |`, the size measured per FR-5 and the method `DevTools` or `Accessibility Inspector`.

**Exceptions section** (matrix only): `## Exceptions` opens with the FR-5 summary row `| FR-5 | every J1 to J5 control at or above 44 px | <outcome> | <evidence> |`, continues with one line per control under 44 px as `<row id>: <size> px, <method>`, and ends with the sign-off line `Exceptions accepted by <presenter>, <ISO date>` (DR-13); the summary row appears nowhere else.

**Defects observed rows** (every record): `| <row id or step> | <class> | <fix commit or open> | <follow-up> |`, class one of `prevents a core journey`, `misrepresents a financial action`, `cosmetic`; the third cell is a 40-hex commit or the word `open`; the fourth names the follow-up issue or `none`.

**Protocol step table**: columns Step, Screen, Persona, Action, Expected state, PRD IDs (the journey tag `J<n>` beside the IDs). Step 1 is Reset demo. The control inventory follows as a table with columns Row id, Journey, Screen, Control, Input kind.

**Matrix layout**: four sections headed exactly `## iPhone 14 390x844 @1.0x`, `## iPhone 14 390x844 @1.3x`, `## iPhone SE 375x667 @1.0x`, `## iPhone SE 375x667 @1.3x`; each contains one row per control-inventory row id plus the FR-3, FR-4, FR-6 and FR-7 rows, each FR row with a row id of the form `FR<n>-<slug>` (for example `FR3-back-market`, `FR7-dark-layout`); then `## Exceptions` (FR-5) and `## Defects observed`, shaped as above.

### File manifest

| File | Create / Modify | Responsibility |
|---|---|---|
| `docs/verification/rehearsal-protocol.md` | Create | FR-8 to FR-12 step table; control inventory; enumerated P0 (31 rows, `grep -c '| P0 |' master-prd.md`) and P1 (2 items, 4 IDs) ID lists |
| `docs/verification/m6-viewport-input-matrix.md` | Create | FR-1 to FR-7 per viewport and scale |
| `docs/verification/m6-rehearsal-1.md` | Create | FR-13, FR-14 for run 1 |
| `docs/verification/m6-rehearsal-2.md` | Create | FR-13 to FR-15 for run 2 |
| `docs/verification/evidence/` | Create | PNG screenshots |
| `README.md` (new section before `## Hackathon planning`, `README.md:51`) | Modify | FR-16 |
| `docs/verification/demo-script.md` | Create | FR-17 |
| `docs/verification/m7-recording.md` | Create | FR-18 |
| `docs/verification/m7-submission-package.md` | Create | FR-19 to FR-23 |
| `docs/prd/2026-10-01-vc-hackathon-master-prd.md:5` | Modify | deadline line reads `2026-10-12 23:59 America/Los_Angeles` (DR-2, R-1) |
| `docs/prd/2026-10-01-vc-hackathon-roadmap.md:35` | Modify | M8 cutoff reads `2026-10-12 23:59 America/Los_Angeles` (DR-2, R-1) |

Seven Markdown records, one README section, two one-line deadline corrections, one recording outside the repo.

## 6. Decision records

### DR-1: Simulator devices iPhone 14 and iPhone SE (3rd generation) on the presenter Mac
- Decision: the matrix runs on both devices; rehearsals and the recording run on iPhone 14 (390x844).
- Context: runtime was decided on October 4 as the Simulator (`docs/prd/2026-10-04-open-decisions-recommendations.md:20`, Decision column); M1 proved launch on a Dynamic Island device (M1 record, Target row), which is 393x852 or larger and neither required viewport; the suite names iPhone SE 375x667 and iPhone 14 390x844 (`home_screen_test.dart:2681-2682`).
- Rationale: the two required viewports map one-to-one onto those two devices, and both runtimes ship with current Xcode.
- Alternatives considered:
  - M1's Dynamic Island device only — rejected because it provides neither 390x844 nor 375x667, so VC-QA-001 could not be recorded as checked.
  - One device with the Simulator window resized — rejected because resizing scales the device and does not change its logical viewport (checked by the FR-6 row, not assumed).
- Consequences: FR-16 names both devices and their iOS runtime versions.

### DR-2: deadline pinned to 2026-10-12 23:59 America/Los_Angeles
- Decision: the package measures itself against that cutoff; M7 should complete by end of October 11.
- Context: `master-prd.md:5` and `roadmap.md:35` record October 11, 23:00 with timezone assumed; the open-decisions doc hedged to 09:00; the user stated October 12, 23:59 PDT at this spec's Phase 2 gate on October 5.
- Rationale: the user's statement is the most recent and most specific, and M8 already reserves the final day as buffer.
- Alternatives considered:
  - Plan to the earlier written date, October 11, 23:00, as a safety margin — rejected because the margin already exists as the M8 buffer day and a wrong date in the package misinforms the judge.
  - Keep the 09:00 hedge — rejected because it hedged an unknown timezone, now known.
- Consequences: PRD and roadmap are stale (R-1); Phase 5 corrects `master-prd.md:5` and `roadmap.md:35` in its own Files and AC-5.3 greps for the new string.

### DR-3: one record per milestone exit and one per rehearsal
- Decision: M6 gets a matrix and two rehearsal records; M7 gets a recording record and a package.
- Context: the roadmap exits milestones individually and M1 set the format.
- Rationale: two runs on their own dates with their own evidence prove two runs happened; one file with two outcome columns cannot carry two field tables or two evidence sets, which is what FR-15 needs.
- Alternatives considered:
  - One rehearsal record with two outcome columns — rejected because it has one field table and one evidence set, so a single run copied into both columns is indistinguishable from two runs.
- Consequences: seven records; the roadmap rows for M6 and M7 point at files.

### DR-4: recordings referenced, screenshots committed
- Decision: `docs/verification/evidence/` holds PNGs only; each recording is referenced by name, size, sha256 and two storage locations.
- Context: the M1 recording measures 22,944,372 bytes (`ls -l` on the presenter's copy, October 5); judges may clone the repo (§3).
- Rationale: a clone should not pull tens of megabytes of video, and the hash is what proves the submitted file is the recorded one.
- Alternatives considered:
  - Commit the mp4 under `docs/verification/evidence/` — rejected because of clone size and because a later re-encode would silently change the hash.
  - Git LFS — rejected because it adds a hosting-side dependency for one file.
- Consequences: the recording lives outside the repo; R-3 covers loss.

### DR-5: run and reset notes in the README; the package manifest under docs/verification
- Decision: FR-16 is a README section; everything else is a record.
- Context: judges open the README first; the user's task brief for this spec (October 5) asked for a README section.
- Rationale: a runbook nobody finds is not a runbook.
- Alternatives considered:
  - A standalone `docs/RUNNING.md` — rejected because it adds a hop before the first command.
- Consequences: README grows by about 25 lines.

### DR-6: viewport checks are manual on the Simulator; existing widget tests are corroboration
- Decision: the matrix cites `home_screen_test.dart:2707-2731` (the 360x640 Android phone at 1.0x and 1.3x) and `:2733-2781` (iPhone SE 375x667 and iPhone 14 390x844 at default scale) as viewport corroboration, `receipts_test.dart:260-262`, `empty_states_test.dart:105` and `trader_record_test.dart:318` as the 1.3x corroboration, and performs every row on the real Simulator.
- Context: widget tests prove layout at a size, not that the Simulator's chrome leaves the buttons reachable or that mouse input works; no `integration_test/` target exists.
- Rationale: VC-QA-001 asks for the simulated phone on the host, which only the Simulator shows.
- Alternatives considered:
  - A scripted Simulator run (`xcrun simctl` plus an `integration_test` target) producing evidence automatically — rejected because adding the target is app code, forbidden here while spec 09 edits adjacent files; a fair follow-up after spec 09 merges.
- Consequences: the matrix is manual labour on the Mac; R-6.

### DR-7: withdrawn
- Withdrawn at the adversarial read of 2026-10-05; the number is kept so DR-8 to DR-13 keep the ids the Phase 4 gate record uses.

### DR-8: duplicate confirm is a fast double-click, proven by the existing widget test
- Decision: FR-11.
- Context: the ticket's `_busy` flag (`order_ticket.dart:855-866`) stops a second tap in the UI once a fill is in flight, so a manual second tap may never reach the store guard at `scenario.dart:273-279`; the widget test at `order_ticket_test.dart:109` drives the double tap deterministically.
- Rationale: the manual step shows the presenter what a judge would see; the test is the proof the guard holds.
- Alternatives considered:
  - Confirm the same order from a second ticket — rejected because that mints a second action ID by design and tests nothing.
- Consequences: the rehearsal row for the duplicate confirm cites a test, not a screenshot, for the store half.

### DR-9: rehearsals run without `--dart-define=HAS_MARKET=true`
- Decision: FR-9.
- Context: the flag changes the seed (`scenario.dart:39-40,362`); J2 is "become a listed creator" (`master-prd.md:63`).
- Rationale: with the flag, J2 cannot be exercised from reset.
- Alternatives considered:
  - Run with the flag — rejected because J2 would be `not run` in every rehearsal.
- Consequences: the seeded-market presentation is covered by a `flutter test --dart-define=HAS_MARKET=true` run on the build SHA, cited in the record by command and log path, not by the rehearsals; the gate (`scripts/gate.sh:40-42`) does not pass the flag, so the presenter runs it by hand.

### DR-10: figures are the named persona's
- Decision: every protocol step names the active persona; FR-15 compares that persona's cash through the cancel step and its position count, receipt count and ledger fee total at every step, and checks each record's post-fill cash against its own previous cash minus the receipt `totalCents`.
- Context: spec 09 keys cash, positions, orders and receipts by persona (`09-copy-story.md:11`).
- Rationale: an unnamed persona makes the FR-15 comparison ambiguous the moment spec 09 lands.
- Alternatives considered:
  - Compare the creator's figures only — rejected because the copy-story steps act as the copier.
- Consequences: the protocol gains a Persona column; before spec 09 lands every step reads `creator`.

### DR-11: all records run on one post-spec-09 build
- Decision: Phases 2 to 5 wait for spec 09 to merge; the build SHA is the first `main` commit at or after that merge which the presenter builds, and the protocol includes the copy-story steps.
- Context: roadmap M5 and M6 require J1 to J5 plus the copy story from reset (`roadmap.md:32-33`); spec 09 is in build on `feat/br-2026-10-05-copy-story/phase-1`; the user chose this at the Phase 4 gate on October 5.
- Rationale: one SHA across every record is what FR-15 and AC-3.2 need, and a rehearsal without S08 cannot exit M5 or M6.
- Alternatives considered:
  - Run now on 7d39bff with the copy story `not run` — rejected because it needs a third rehearsal later and leaves M5 unverified in the meantime.
- Consequences: Phase 1 can be written now; nothing else starts until spec 09 is on `main`.

### DR-12: evidence for passed matrix rows is one screenshot per section per journey
- Decision: FR-1's four sections each carry five screenshots (J1 to J5), plus a screenshot for every failed or exceptional row.
- Context: M1's record was attested for the rows its recording could not show; a `passed` row with no file proves nothing about the viewport or scale actually set; the user chose this at the Phase 4 gate on October 5.
- Rationale: twenty files prove the device and text size were really in place for every journey without a screenshot per control.
- Alternatives considered:
  - Attestation only, as M1 — rejected because the matrix is the M6 exit evidence and M1 already spent the attestation precedent.
  - One screenshot per row — rejected because hundreds of files bury the failed ones.
- Consequences: AC-2.4 is a file count and a name check.

### DR-13: under-44 px controls are recorded exceptions with the presenter's sign-off
- Decision: the FR-5 summary row is `passed` only when the Exceptions section lists every control under 44 logical pixels with its measured size and ends with a sign-off line naming the presenter and the date; fixes are follow-ups.
- Context: the 30 px pill tap target and the 14 px "All receipts" link are known (`digest-phase-8.md:11,23`); the PRD states 44 px as a target (`master-prd.md:168`); the user chose this at the Phase 4 gate on October 5.
- Rationale: neither control sits on a financial action, and fixing them is app code that must wait for spec 09.
- Alternatives considered:
  - Block M6 until both are fixed — rejected because M6 would wait on app changes that cannot start before spec 09 merges.
- Consequences: the outcome vocabulary stays at four words; the sign-off line is the fifth state.

## 7. Implementation plan

### Phase 1 — Rehearsal protocol and control inventory
- Outcome: `docs/verification/rehearsal-protocol.md` defines the step table, the control inventory and the enumerated P0 and P1 ID lists that every later record copies.
- Files:
  - Create: `docs/verification/rehearsal-protocol.md`
- Interfaces:
  - Consumes: journeys J1 to J5 (`master-prd.md:62-66`); Settings rows (`settings_screen.dart:123,129-134`); Arena actions (`arena_screen.dart:173-179`); the shared ticket (`order_ticket.dart:855-866`); roadmap minimum checks (`roadmap.md:80`); P0 rows (`grep -n '| P0 |' master-prd.md`, 31 rows) and P1 rows (`roadmap.md:46-47`).
  - Produces: a step table (Step, Screen, Persona, Action, Expected state, PRD IDs) with step 1 = Reset demo and the copy-story steps (persona switch in Settings, a copied order as copier, the `copy` ledger row as creator) after J4; a control inventory (Row id, Journey, Screen, Control, Input kind); a "P0 IDs" list of 31 and a "P1 IDs" list.
- Gotchas: the seeded-error switch is cleared by Retry (`markets_screen.dart:122-123`) as well as by reset (`scenario.dart:383`), so the error step must observe Explore before Retry. The crowd-split filter is a drag control; list it with input kind `drag`. "Show all" and "Clear search" are built only by Arena's empty state (`arena_screen.dart:168-181`) and the range slider has no reset affordance (`crowd_filter_panel.dart:56-64`), so the filter-reset step's Action must first drive the filter to zero matches.
- Complexity: mechanical
- Non-goals: running anything; the matrix.
- Depends on: none; the copy-story steps cite `docs/specs/09-copy-story.md:11` (spec text, not code lines), so the file needs no edit after spec 09 merges
- Acceptance criteria:
  - AC-1.1: given the file, the step table's first row is Reset demo with expected state "toast Demo reset to fixture-v1", and rows exist whose Action column names, respectively, a cancel on the ticket, the "Simulate load failure" switch then Retry, a fast double-click on Confirm, and "Show all" or "Clear search" preceded in the same Action cell by narrowing the filter to zero matches; each with a non-empty Expected state and PRD IDs cell.
  - AC-1.2: given the file, rows exist for the instrument-and-direction match from entry through review to receipt; for Arena membership after a confirm opened from an Arena battle's Bull or Bear button (not from a call or Explore ticket, which carry no `clashId`); for the reconcile of cash, position count, fee ledger total and receipt count across Wallet, Ledger and Receipts after the J4 confirm; and, after the J4 rows, for the Settings persona switch (Expected state names the toast `Now acting as <name>`, `09-copy-story.md:11`), a copied order with Persona `copier`, and a `copy` ledger row with Persona `creator`; and each of J1 to J5 is tagged in at least one step's PRD IDs cell.
  - AC-1.3: given the file, the "P0 IDs" list has 31 entries matching `grep -c '| P0 |' docs/prd/2026-10-01-vc-hackathon-master-prd.md`, and the "P1 IDs" list names P1-A (VC-REC-002, VC-REC-003, VC-ARN-006) and P1-B (VC-MKT-005), four IDs.
  - AC-1.4: given the control inventory, every J1 to J5 screen named in the step table has at least one control row, every row has an input kind from {tap, scroll, drag, type, swipe-with-mouse-equivalent}, and every row id is unique.
  - AC-1.5 (negative): `grep -n -E 'TODO|TBD'` on the file prints nothing, no step has an empty Persona cell, and `git diff origin/main --stat -- app/` on the phase branch prints nothing.

### Phase 2 — Viewport and input matrix
- Outcome: `m6-viewport-input-matrix.md` records every inventory control and the FR-3 to FR-7 rows on both devices at both scales against one build SHA.
- Files:
  - Create: `docs/verification/m6-viewport-input-matrix.md`
  - Create: `docs/verification/evidence/m6-viewport-input-matrix-<device>-<scale>-J<n>.png` with `<device>` in {`iphone14`, `iphonese`} and `<scale>` in {`1.0x`, `1.3x`}, one per section per journey (20 files), plus `m6-viewport-input-matrix-<row id>.png` for every failed or exceptional row (DR-12)
- Interfaces:
  - Consumes: Phase 1's control inventory and row ids; the §5 field table; the four section headings in §5.
  - Produces: the "Build / revision" cell later phases copy; `## Exceptions` opening with the FR-5 summary row, listing every control under 44 px with method and size, ending with the sign-off line; `## Defects observed` rows with the §5 class column.
- Gotchas: 1.3x is any Dynamic Type step at or above xxxLarge because the app clamps (`main.dart:30-31`); record the step chosen in the Flags row. Measure targets with DevTools "Select widget mode", not by clicking.
- Complexity: mechanical; six criteria on one file filled in one sitting, do not split the phase
- Non-goals: fixing a failed row; Figma comparison.
- Depends on: Phase 1; spec 09 on `main` (DR-11)
- Acceptance criteria:
  - AC-2.1: given the file, the four section headings from §5 appear exactly once each, and under each heading every row id from the Phase 1 inventory appears once with an outcome.
  - AC-2.2: given each section, rows exist for Back from each drill-down, section-switch state preservation, the four nav items, the market and profile drill-downs, chrome and strip occlusion, window resize, bull/bear label legibility, and dark layout and Vista styling, each with a `FR<n>-<slug>` row id and an outcome.
  - AC-2.3: given a row with outcome `failed`, a `## Defects observed` row names it with a class from the §5 list, and an evidence file named for its row id exists under `docs/verification/evidence/`.
  - AC-2.4: given each of the four sections, five evidence files named for that device, scale and J1 to J5 exist under `docs/verification/evidence/`, each showing the simulation strip and the journey's screen; a section with fewer than five fails this criterion.
  - AC-2.5 (negative): given a control measured under 44 px, its control row's fifth cell carries the size and method, it appears in `## Exceptions` with method and size, and the FR-5 summary row (the first row of `## Exceptions`) is `passed` only if `## Exceptions` ends with a line beginning `Exceptions accepted by` naming the presenter and an ISO date; absent that line the summary row is `failed`.
  - AC-2.6 (negative): every Outcome cell is exactly one of the four words with no qualifier (`grep -n -E '\| *(passed|failed|not run|deferred) [^|]' <file>` prints no line whose hit is an Outcome cell); `grep -n -E 'TODO|TBD'` on the file prints nothing; `git diff origin/main --stat -- app/` on the phase branch prints nothing.

### Phase 3 — Two rehearsals from reset
- Outcome: `m6-rehearsal-1.md` and `m6-rehearsal-2.md` record two runs of the protocol on the matrix's build SHA, each with its own start time and evidence, agreeing on every FR-15 figure, each ending with an FR-14 Verdict.
- Files:
  - Create: `docs/verification/m6-rehearsal-1.md`, `docs/verification/m6-rehearsal-2.md`
  - Create: `docs/verification/evidence/m6-rehearsal-<n>-<step>.png`: at least the reset toast, the cancel step before and after, the error state and after Retry, the duplicate-confirm result, the filter reset at empty and after reset, the reconcile step, and `m6-rehearsal-<n>-clock.png`, a Settings screenshot showing the device clock for each run
- Interfaces:
  - Consumes: Phase 1's step table and ID lists; Phase 2's build SHA; the widget test `order_ticket_test.dart:109`.
  - Produces: per-step observed figures (cash as displayed, position count, receipt count, ledger fee total, persona, and the receipt `totalCents` on every fill step); a "P0 IDs exercised" table; a "Not exercised" section; a "P1 IDs" section with an outcome per ID; `## Defects observed` rows with the §5 class column; the Verdict line `exit` or `no exit`.
- Gotchas: run both rehearsals in one sitting on one build; if `main` moves between them, the second record fails AC-3.2 and both must be redone. Cash after a market fill differs between runs on a correct build: the fill price is `MarketPrices.now()` frozen when review opens (`order_ticket.dart:104,125-126,852`), the feed moves by up to 0.04% of base every 3 s (`live_feed.dart:37,46-48`), is off only under `FLUTTER_TEST` (`live_feed.dart:23`), and `Scenario.reset()` never rebases it; so compare cash across runs only through the cancel step, and after a fill check each record's cash against its own previous cash minus the receipt `totalCents`. Position count, receipt count and the ledger fee total do not drift (`placeOrder` writes no fee-ledger row).
- Complexity: mechanical; six criteria on two files filled in one sitting, do not split the phase
- Non-goals: building P1 behaviour; fixing defects.
- Depends on: Phase 2; spec 09 on `main` (DR-11)
- Acceptance criteria:
  - AC-3.1: given both records, each has a distinct "Run date and start time" and its own evidence files, including `m6-rehearsal-<n>-clock.png`.
  - AC-3.2: given both records, their "Build / revision" cells are identical 40-hex strings equal to the matrix's; in each, the Flags cell reads `none`, the Fixture version cell reads `fixture-v1`, the Target cell names a macOS version, an Xcode version, an iOS runtime version and a Simulator device, and a `flutter test --dart-define=HAS_MARKET=true` run on that SHA is cited with its log path.
  - AC-3.3: given both records, every protocol step appears with an outcome; for every step up to and including the cancel step, cash for the named persona is equal between the two records; for every step, position count, receipt count and ledger fee total for the named persona are equal between the two records; and in each record, at every step after the first market fill, cash equals the previous step's cash minus the paper funds that step's receipt shows taken (`totalCents`, plus the $5.00 copy fee on a copied order; zero when the step fills nothing); a record whose post-fill cash matches the other run's cash but not its own previous cash minus the receipt fails this criterion.
  - AC-3.4: given the cancel step, cash and position count equal the previous step's; given the duplicate-confirm step, position count and receipt count each rose by exactly one and the row cites `order_ticket_test.dart:109`; given the error step, Explore shows the failed state then recovers on Retry; given the filter-reset step, the row records the count before narrowing, 0 at empty, and after reset a count equal to the unfiltered count; given the reconcile step, cash, position count, fee ledger total and receipt count read from Wallet, Ledger and Receipts agree; given step 1, the row's evidence names the reset-toast screenshot.
  - AC-3.5: given each record, every one of the 31 P0 IDs appears at least once across the "P0 IDs exercised" table and the "Not exercised" section, each row with an outcome, and an ID may have several rows (VC-DEM-004: its reset and persona-switch rows may be `passed`; its scenario-phase advance row is `deferred` (P1 by O-10), never `passed`); the "P1 IDs" section lists VC-REC-002, VC-REC-003, VC-ARN-006 and VC-MKT-005 each with an outcome, `deferred` unless built and exercised at the build SHA.
  - AC-3.6 (negative): given any `## Defects observed` row whose class cell is `prevents a core journey` or `misrepresents a financial action`, the Verdict line reads `no exit` and names it; a record whose Verdict reads `exit` while such a row exists fails this criterion; `git diff origin/main --stat -- app/` on the phase branch prints nothing.

### Phase 4 — README run notes, demo script, final recording
- Outcome: a stranger can run and reset the demo from the README; the final recording exists, follows the script, and is described in its record.
- Files:
  - Modify: `README.md` — insert `## Running the demo` immediately before `## Hackathon planning` (`README.md:51`)
  - Create: `docs/verification/demo-script.md`
  - Create: `docs/verification/m7-recording.md`
  - Outside the repo: the recording file, at two named locations
- Interfaces:
  - Consumes: the M1 record's "Run and reset instructions" section; Phase 1's step table (screens); Phase 3's build SHA.
  - Produces: README sub-items "Tested on", "Run", "Reset", "Viewport", "Text size"; `demo-script.md` with one block per protocol screen; `m7-recording.md` fields file, duration, resolution, sha256, location 1 (a URL that opens without sign-in), location 2, build SHA, viewport `390x844`, script commit, "narrates mocks: yes".
- Gotchas: get the Simulator id from `flutter devices` and paste the exact string. Compute sha256 on the stored file before any upload. Record with the Simulator at point-accurate scale so the resolution matches the viewport times the device scale factor.
- Complexity: mechanical
- Non-goals: the package.
- Depends on: Phase 3
- Acceptance criteria:
  - AC-4.1: given `README.md`, `grep -n '## Running the demo'` returns exactly one line, and the section contains the five sub-items with a macOS version, an Xcode version, both Simulator devices (iPhone 14, iPhone SE (3rd generation)) each with its iOS runtime version, both `390x844` and `375x667`, a `flutter run -d` command with a device id, a Dynamic Type setting, and the reset step.
  - AC-4.2: given `demo-script.md`, every screen in the protocol's step table has a block, every block names at least one component from the FR-17 list, the demo-narrative economics sentence is present, `grep -n -i 'copy fee'` matches a sentence stating the fee is an invented demo number, and `grep -n -i 'live backend'` matches only a sentence stating none exists.
  - AC-4.3: given `m7-recording.md`, `sha256sum` of the file at each of the two named locations equals the recorded hash, one of the two locations is a URL that opens in a private browser window without sign-in, the build SHA equals Phase 3's, the viewport is `390x844`, and the script commit is reachable from the branch head that carries `m7-recording.md` (`git merge-base --is-ancestor <commit> HEAD`); it becomes an ancestor of `main` when the Phase 4 PR merges.
  - AC-4.4 (negative): given the README section followed on a Mac with the pub cache warm, no credentials and networking disabled after the build, the app reaches Home and Reset demo shows the toast; a step that needs a credential or a network call at runtime fails this criterion; `git diff origin/main --stat -- app/` on the phase branch prints nothing.

### Phase 5 — Submission package
- Outcome: `m7-submission-package.md` states build, fixture, recording, mock boundary, known limitations, links-and-length checklist, deadline and fallback artifact.
- Files:
  - Create: `docs/verification/m7-submission-package.md`
  - Modify: `docs/prd/2026-10-01-vc-hackathon-master-prd.md:5` — the deadline reads `2026-10-12 23:59 America/Los_Angeles` (DR-2)
  - Modify: `docs/prd/2026-10-01-vc-hackathon-roadmap.md:35` — the M8 cutoff reads `2026-10-12 23:59 America/Los_Angeles` (DR-2)
  - Outside the repo: the fallback artifact (FR-23)
- Interfaces:
  - Consumes: Phase 4's `m7-recording.md`; Phase 3's "Not exercised" and "P1 IDs" sections and `## Defects observed` rows from every record; `digest-phase-8.md:28`.
  - Produces: sections Build, Fixture, Recording, Mock boundary, Known limitations, Links and length (with a Required materials cell), Deadline, Fallback artifact.
- Gotchas: the package must not say "submitted"; M8 is a separate task (`roadmap.md:35`).
- Complexity: mechanical
- Non-goals: uploading to the submission channel; writing the submission form text.
- Depends on: Phase 4
- Gated on: Q-1 for AC-5.4 only (fallback format, allowed length, required materials; waived: the zip default applies, the length cell reads `allowed length unknown` and the materials cell `unknown until Q-1`)
- Acceptance criteria:
  - AC-5.1: given the file, Mock boundary names identities, prices and calls as constant fixtures, cash, positions, open orders, listing status, fees and receipts as simulated in `Scenario`, and states no network call is made at runtime.
  - AC-5.2: given the file, Known limitations contains every "Not exercised" ID from both rehearsal records, every P1 ID as deferred, every item still unbuilt from `digest-phase-8.md:28`, every `## Defects observed` row from `docs/verification/*.md` whose third cell is `open` or a commit that is not an ancestor of the build SHA (the M1 record's Wallet-cap bullet is the first: `portfolio_pager.dart:183` reads a constant and no cap is stored on listing), and the demo-narrative economics sentence.
  - AC-5.3: given the file, Deadline reads `2026-10-12 23:59 America/Los_Angeles`, Build equals Phase 4's build SHA, Links and length records that the recording link (FR-18's URL) opened in a private window and the repo link opened, and `grep -n '2026-10-12 23:59 America/Los_Angeles' docs/prd/2026-10-01-vc-hackathon-master-prd.md docs/prd/2026-10-01-vc-hackathon-roadmap.md` hits line 5 and line 35 respectively, and `sed -n 5p docs/prd/2026-10-01-vc-hackathon-master-prd.md` no longer contains `October 11`.
  - [gated: Q-1] AC-5.4: given the file, Fallback artifact names a file in the Q-1 format with its sha256, or the default zip of the repo at the build SHA with its sha256 when Q-1 is unanswered; Links and length records the recording length with the allowed length beside it, or `allowed length unknown` while Q-1 is waived; and the Required materials cell lists what Q-1 names, or `unknown until Q-1` while waived; the waiver values satisfy this criterion.
  - AC-5.5 (negative): `grep -n -i -E 'submitted|live backend|production'` on the file returns no line asserting any of them happened or exists; `git diff origin/main --stat -- app/` on the phase branch prints nothing.

## 8. Risks and mitigations

| Risk | Likelihood / Impact | Mitigation or contingency |
|---|---|---|
| R-1: PRD and roadmap still say October 11; someone plans to the wrong day | medium / high | DR-2 pins the date; Phase 5 modifies `master-prd.md:5` and `roadmap.md:35` (manifest) and AC-5.3 greps for the new string |
| R-2: `main` moves between phases, so one build SHA cannot hold across Phases 2 to 5 | high / high | DR-11 fixes the SHA after spec 09 merges; Phases 2 and 3 run in one sitting; Phases 4 and 5 reuse that SHA even if `main` moved, and the package says so |
| R-3: the recording is lost or re-encoded | low / high | FR-18 hash plus two named locations |
| R-4: the matrix is self-attested and M6 exits on paper | medium / high | DR-12 evidence policy; FR-15's distinct start times and clock screenshots; FR-14's defect bar |
| R-5: Q-1 stays unanswered | medium / medium | only AC-5.4 is gated; the zip default stands in and the length and materials cells name the gap |
| R-6: every phase is manual on the Mac, so an agent session cannot progress it | high / low | an agent prepares each record skeleton with `not run` cells (never TODO) and the presenter fills outcomes |
| R-7: no recording at 390x844 exists; the M1 recording is at a Dynamic Island viewport with no narration | high / high | Phase 4 produces the recording; the M1 recording stays M1 evidence only |
| R-8: known under-44 px controls (30 px pill, 14 px receipts link, digest-phase-8 lines 11 and 23) make FR-5 unpassable | high / medium | DR-13: recorded exceptions with the presenter's sign-off; fixes are follow-ups |

## 9. Testing and validation

There is no test suite for records. Validation is the acceptance criteria, each a grep, a hash, or a comparison a reviewer runs on the files; `git diff origin/main --stat -- app/` empty on the branch proves no app code moved, restated in AC-1.5, AC-2.6, AC-3.6, AC-4.4 and AC-5.5 so it travels with the criteria block; `scripts/gate.sh` still runs on the branch so the suite is green at the build SHA.

| FR | Criterion | Check | Test |
|---|---|---|---|
| FR-1 | AC-2.1 | four section headings once each; every inventory row id under each with an outcome | grep, read |
| FR-1 | AC-2.4 | five journey evidence files per section, named with the device and scale tokens | ls |
| FR-1 | AC-2.6 | every Outcome cell exactly one of the four words, no qualifier | grep, read |
| FR-2 | AC-1.4, AC-2.1 | inventory input kinds; per-row operability outcome | read |
| FR-3 | AC-2.2 | Back and state-preservation rows per section | read |
| FR-4 | AC-2.2 | nav items and drill-down rows per section | read |
| FR-5 | AC-2.5 | per-control size and method; exceptions listed; summary row `passed` only with the sign-off line | read |
| FR-6 | AC-2.2 | occlusion and window-resize rows | read |
| FR-7 | AC-2.2 | bull/bear legibility and dark-layout rows | read |
| FR-8 | AC-1.1, AC-1.2 | required steps with expected state and IDs; Arena-button confirm, reconcile and copy-story rows; J1 to J5 tagged | grep, read |
| FR-8 | AC-1.5 | no empty Persona cell | grep |
| FR-9 | AC-1.1 | step 1 Reset demo with the toast | grep |
| FR-9 | AC-3.2, AC-3.4 | Flags `none`; `HAS_MARKET=true` test run cited; reset-toast evidence | read |
| FR-10 | AC-1.1, AC-3.4 | error step then Retry; recovery recorded | read |
| FR-11 | AC-1.1, AC-3.4 | one new position and receipt; test cited | read |
| FR-12 | AC-1.1, AC-3.4 | narrowing precondition; counts before, at empty and after reset | read |
| FR-13 | AC-1.3 | protocol enumerates 31 P0 IDs and the four P1 IDs | count |
| FR-13 | AC-3.2, AC-3.5 | 40-hex SHA; Target, Fixture and Flags cells; 31 P0 IDs each at least once; P1 IDs each with an outcome | grep, count |
| FR-14 | AC-3.6 | Verdict applies the defect bar through the Defects observed class column | read |
| FR-15 | AC-3.1, AC-3.3 | distinct times and evidence; cash equal through cancel; counts and ledger total equal; post-fill cash equals previous cash minus the receipt | diff, arithmetic |
| FR-16 | AC-4.1 | README section with the named items, both devices | grep |
| FR-16 | AC-4.4 | stranger reaches Home offline at runtime | manual on Mac |
| FR-17 | AC-4.2 | block per screen naming a component; narrative and copy-fee sentences | grep |
| FR-18 | AC-4.3 | hashes at two locations, one a URL; viewport; script commit reachable from the branch head | sha256sum, git |
| FR-19 | AC-5.1 | mock boundary complete | read |
| FR-20 | AC-5.2 | limitations cover all five sources | compare |
| FR-21 | AC-5.3 | links opened; deadline exact in the package, `master-prd.md:5` and `roadmap.md:35` | read, grep |
| FR-21 | AC-5.4 | length and required-materials cells, gap named under the waiver | read |
| FR-22 | AC-5.5 | no submission or live claim | grep |
| FR-23 | AC-5.4 | artifact named with hash | sha256sum |
| FR-24 | AC-2.3 | failed rows have a Defects observed row with a class and an evidence file named for the row id | ls, read |
| global | AC-1.5, AC-2.6, AC-3.6, AC-4.4, AC-5.5 | `git diff origin/main --stat -- app/` prints nothing on every phase branch; no TODO/TBD | git, grep |
| global | success metrics | manifest files on `main`; vocabulary; one SHA; Verdict lines | ls, grep, git |

## 10. Open questions

- Q-1: what is the submission channel, required format, allowed recording length and required materials? — blocks: AC-5.4 (fallback format, allowed length, required materials).
  WAIVED 2026-10-05 by user: the brief has not stated them; the zip default stands until it does. Closed by the user pasting the submission instructions.
  Options considered: A, repo link plus video link, no artifact to build but judges need a Mac; B, zip of the repo at the build SHA plus the video file, self-contained but large; C, Simulator `.app` bundle, runnable without building but Mac-only and unsigned.
  Recommendation: A, with B as the fallback artifact; the zip is one command.
  Impact of waiting: Phases 1 to 4 proceed; Phase 5 ships with the zip default, the length cell reads `allowed length unknown` and the materials cell `unknown until Q-1`.
