# M4 verification record: Arena discovery

Milestone M4 from `docs/prd/2026-10-01-vc-hackathon-roadmap.md` (S05; VC-ARN-001, -002, -003, -005). VC-ARN-004 is a P0 row of S05, so it is recorded here too, though the roadmap places its exit in M5. VC-ARN-002 to -005 are built by unit 04. VC-ARN-001 pre-dates the plan and has no spec. Evidence is the widget and unit tests plus code reading at the revision below. No device run or rehearsal was made for this record.

Code paths are under `app/lib/`. Test names are as `flutter test` prints them (group, then test), in `app/test/<file>`. Each PRD ID is split into the checks its acceptance text names; one row per check.

| Field | Value |
|---|---|
| Build / revision | 7d39bffaa1e1e594dfccb6f39359b9d9038df4e7 (`main` 7d39bff; `app/` is identical to `main` 7a153be, `git diff 7a153be 7d39bff -- app` is empty) |
| Fixture version | `fixture-v1` (`scenario/scenario.dart:37`) |
| Target | `flutter test` headless widget tests, Flutter 3.47.5, Linux (WSL2) host. Not the iOS Simulator |
| Run date and start time | 2026-10-05, before 11:12-07:00 (PDT). The start time of the `flutter test` run (289 passed) was not recorded; 11:12 is the commit time of 137dae3, an upper bound |
| Flags | none |
| Test run | `cd app && flutter test`: **289 passed, 0 failed, 0 skipped** |
| Evidence | The tests named below; code citations as `file:line` |

## PRD IDs exercised

| ID | Check | Outcome | Evidence |
|---|---|---|---|
| VC-ARN-001 | Scrollable seeded Clash feed with more than one card | passed | Three battles (`features/arena/arena_mock.dart:238`) in `features/arena/arena_screen.dart`. `home_screen_test.dart` "arena Arena tab shows the battles with the crowd filter" ("3 battles"); "arena sort chips stay fixed while battles scroll" |
| VC-ARN-001 | Each card shows the event, asset and mark, deadline, and both sides' rationales | not run | Code: `question`, `price`, `timeLeft`, `thesis` in `arena_mock.dart:93-236`, drawn by `design_system/components/vista_battle.dart:271-305`. The deadline is a fixed string ("4h 12m left", `arena_mock.dart:103`), not a countdown on the demo clock. To prove: on the BTC card find its question, "$67,412", "4h 12m left" and both theses |
| VC-ARN-001 | Bull and bear identities, each with a sample-backed record | passed | `arena_screen.dart:146-162`, `accuracyLine` (`features/arena/opinions_screen.dart:13`) reads `Scenario.record`. `trader_record_test.dart` "Arena card trader link opens the record panel" (accuracy follows the receipts); `home_screen_test.dart` "arena tapping a caller opens their profile" |
| VC-ARN-001 | Participant counts and side actions | passed | `arena_screen.dart:134-139`. `home_screen_test.dart` "arena joining: Cancel counts nothing; a fill counts once, shows" ("and 14", "and 6"); "order ticket Arena Bull and Home Long open the ticket on that side" |
| VC-ARN-001 | Every displayed participant matches the same scenario entity | failed | Code inspection: the unlabelled price under each caller disagrees with that trader's market price. maya.eth $0.2610 vs $0.4400, 0xreal $0.2610 vs $0.3820, kilo.sol $0.1840 vs $0.1720, lunaq $0.3120 vs $0.3145 (`arena_mock.dart:107,116,141,148` vs `features/live/market_prices.dart:17-22`). See Defects |
| VC-ARN-002 | Volume, Change and Funding sorts give a predictable order | passed | `ArenaMock.visible` (`arena_mock.dart:264-277`). `home_screen_test.dart` "arena sort chips order the battles by volume, change and funding"; "arena sorts by the chip field, highest first, ties by id"; "arena each battle quotes its asset as the Markets tab does" |
| VC-ARN-002 | A range changes the card set and count; histogram and count derive from the same battles | passed | `ArenaMock.buckets` (`arena_mock.dart:254`), panel count `features/arena/crowd_filter_panel.dart:35,52`. `home_screen_test.dart` "arena the crowd range filters the cards and the panel counts them"; "arena Arena tab shows the battles with the crowd filter" |
| VC-ARN-002 | No-match state; Show all and reset restore every card | passed | `arena_screen.dart:168-180`. `home_screen_test.dart` "arena an empty crowd split says so; Show all restores the cards"; `scenario_test.dart` "seed → mutate everything → reset equals the fresh seed" (Arena view included) |
| VC-ARN-002 | Battle totals derive from fixture fields, not disconnected decoration | passed | Spec 04 line 10 derives every display string from `Battle` fields: side counts are `bullCount`/`bearCount` plus `Scenario.joins` (`arena_screen.dart:149,153`), the crowd split and histogram read `bullPct` (`opinions_screen.dart:46`, `arena_mock.dart:68`), `volume` is a sort key only. `home_screen_test.dart` "arena joining: Cancel counts nothing; a fill counts once, shows"; "arena the crowd range filters the cards and the panel counts them" |
| VC-ARN-003 | More opinions shows the named sides' seeded rationales and participants | passed | `opinions_screen.dart:21-170`. `home_screen_test.dart` "opinions more opinions opens the clash detail; filters and back"; "arena a battle's opinions trade that battle's asset and clash" (ETH's own split, count and callers) |
| VC-ARN-003 | Closing returns to the same card | passed | Same two tests: Back returns to the list, and the ETH card shows the join made from its opinions |
| VC-ARN-003 | Ask filters a small known set of assets | passed | `ArenaMock.asked` (`arena_mock.dart:245-251`), field at `arena_screen.dart:63`. `home_screen_test.dart` "arena Ask filters by asset; no match names the assets there are" |
| VC-ARN-003 | Unsupported input explains the available examples | passed | `ArenaMock.askHint` shown at `arena_screen.dart:172`. Same test ("Try BTC, ETH, SOL"); "arena with the keyboard up the panel folds and Ask results show" |
| VC-ARN-004 | Side selection passes clash ID, asset and direction into the ticket | passed | `arena_screen.dart:139`, `opinions_screen.dart:151-161`. `home_screen_test.dart` "arena a battle's opinions trade that battle's asset and clash"; "order ticket Arena Bull and Home Long open the ticket on that side" |
| VC-ARN-004 | Only a confirmed fill registers participation, once per action | passed | `scenario/scenario.dart:218-223,351-356`. `scenario_test.dart` "a clash fill joins its side once per action; a failure joins none"; `home_screen_test.dart` "arena joining: Cancel counts nothing; a fill counts once, shows" |
| VC-ARN-004 | Cancel, failure and insufficient funds leave counts unchanged | passed | Same two tests (Cancel; an order cash cannot cover fails and joins none) |
| VC-ARN-004 | Chosen side and resulting position agree across Arena and Wallet | passed | Same joining test: "Joined Bull" on the card and the new position's `clashId` is `btc-72k`. It checks the store Wallet reads, not the rendered Wallet row |
| VC-ARN-005 | Percentages are labelled crowd split, never odds or probability | passed | `opinions_screen.dart:85,218`. `home_screen_test.dart` "opinions the crowd split is labelled crowd split, never odds" |
| VC-ARN-005 | Changing the display filter cannot change a verdict, record or index | passed | `Scenario.setArena` writes only `Scenario.arena` (`scenario/scenario.dart:208-216`). `home_screen_test.dart` "arena the crowd range filters the cards and the panel counts them" (no receipt or participation written) |
| VC-ARN-005 | Crowd split, verdict and position P&L are shown apart | not run | Code: each side's `result` ("+4.2%", `arena_mock.dart:112,121`) sits beside the crowd line, unlabelled (`vista_battle.dart:313-325`). To prove: label the figure and assert the label and the crowd-split line are separate widgets |
| VC-ARN-005 | A scripted settled example shows a winning prediction with losing paper P&L | deferred | `docs/specs/00-baton-queue.md` unit 4: "the optional settled winning-call/losing-P&L example is not seeded"; settled clash states are VC-ARN-006 (P1) |

## Roadmap exit criteria

| Criterion | Outcome | Evidence |
|---|---|---|
| J3: seeded opposing views | passed | VC-ARN-001 identity and count rows |
| Predictable sorts | passed | VC-ARN-002 sort row |
| Crowd-range filtering with derived counts | passed | VC-ARN-002 range row |
| More-opinions view | passed | VC-ARN-003 rows |
| Bounded ask/search behavior | passed | VC-ARN-003 Ask rows |
| Empty filter state recovers | passed | VC-ARN-002 no-match row |
| Video-only or unverified behavior is still labelled in the spec | failed | `docs/specs/04-arena-sort-filter-join.md` has no observed/proposed labels. The evidence register (V07) says side selection, opinions and ask outcomes are not shown in the video, and the PRD calls them proposed (VC-ARN-003); spec 04 does not carry that over |

## Defects observed

| row or step | class | fix commit or open | follow-up |
|---|---|---|---|
| VC-ARN-001 (same scenario entity): Arena caller prices disagree with the traders' market prices (`features/arena/arena_mock.dart:107,116,141,148` vs `features/live/market_prices.dart:17-22`); maya.eth shows $0.2610 on the BTC card and $0.4400 everywhere else; the figure has no label, and if it is not the caller's market price it needs one | cosmetic | open | none |
| VC-ARN-003 (more opinions, test weakness): two opinions overflow tests probably never open the opinions screen; in "opinions renders without overflow on small Android 360x640" and "... on iPhone SE 375x667", flutter_test warns that the tap on "+21 more opinions" "derived an Offset ... that would not hit test on the specified widget"; the tests only assert no exception, so they pass either way; why the tap misses was not investigated | cosmetic | open | none |
| VC-ARN-002 (sorts, test weakness): the sort widget test cannot tell Change from Funding; both give SOL, BTC, ETH, so swapping the two chip labels would still pass; the unit test pins sort indices to fields, not labels (carried from digest P4) | cosmetic | open | none |
| VC-ARN-001 (deadline): the deadline is a fixed string ("4h 12m left") and does not move with the demo clock | cosmetic | open | none |
| Exit criterion "Video-only or unverified behavior is still labelled in the spec": spec 04 carries no video-only or proposed labels | cosmetic | open | none |

## Verdict

**M4 not exited.** J3's behavior (opposing views, sorts, crowd filter with derived counts, empty-filter recovery, more opinions, Ask, and participation once per action) is proven by tests. The milestone stays open on two findings: caller prices that disagree with the traders' markets (VC-ARN-001), and spec 04 missing its video-only labels. Two checks have code but no test. The optional settled example is deferred. No rehearsal has been recorded.
