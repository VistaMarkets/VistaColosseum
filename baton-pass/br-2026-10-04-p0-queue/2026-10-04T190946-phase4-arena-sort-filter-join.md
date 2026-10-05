---
source: baton-runner work unit, phase 4 of 8 (docs/specs/04-arena-sort-filter-join.md)
scope: br-2026-10-04-p0-queue
parent_session: 2026-10-04T190310-phase4-arena-checkpoint.md
status: COMPLETE: both acceptance items green; gate PASS (233), HAS_MARKET=true 233 pass; uncommitted on feat/br-2026-10-04-p0-queue/phase-4
---

# Phase 4: Arena real sort, crowd filter, participation

## Criteria (test, RED evidence, now)
Raw RED logs: `baton-runner/br-2026-10-04-p0-queue/phase-4-red/` (`scenario-red-1.log`, `home-red-1.log`); full RED list in the checkpoint note.

AC1 tests:
- Sort order per chip: `app/test/home_screen_test.dart: sort chips order the battles by volume, change and funding`. RED `Expected: ['BTC', 'ETH', 'SOL'] Actual: ['BTC', 'BTC']`. GREEN. Mutation: dropping the id tiebreak fails it (`Actual: ['SOL', 'ETH', 'BTC']`).
- Range filter count == cards: `app/test/home_screen_test.dart: the crowd range filters the cards and the panel counts them` (also asserts buckets come from bullPct and that a filter writes no receipt/participation). RED `Expected: [0, 0, 1, 0, 1, 0, 0, 1, 0, 0] Actual: [15.0, 19.0, 17.0, ...]`. GREEN. Mutations caught: panel counting all battles (`Found 0 widgets with text "2 battles"`); bucket ignoring bear majorities.
  Updated: `app/test/home_screen_test.dart: Arena tab shows the battles with the crowd filter` (RED `Found 0 widgets with text "Crowd split 50/50 +"`).
- Empty state: `app/test/home_screen_test.dart: an empty crowd split says so; Show all restores the cards` (+ `expectPillClear` on Show all). RED `Found 0 widgets with text "0 battles"`. GREEN.
- Join once → +1, same actionId → +1 total, failure → +0: `app/test/scenario_test.dart: a clash fill joins its side once per action; a failure joins none`. RED compile `Member not found: 'Scenario.joins'` / `'participation'`. GREEN. Mutation: no participation write fails it (`Expected: {'eth-4k': long} Actual: {}`).
- Cancel → +0, fill → +1 and chosen side on the card, position references the clash: `app/test/home_screen_test.dart: joining: Cancel counts nothing; a fill counts once, shows`. RED `Found 2 widgets with text "and 14"`. GREEN.
- "Crowd split" label: `app/test/home_screen_test.dart: the crowd split is labelled crowd split, never odds` (RED `Found 0 widgets with text "Crowd split 63% bull"`) and updated `more opinions opens the clash detail; filters and back` (RED `Found 0 widgets with text "Crowd split · 23 opinions"`). GREEN.
- Ask (spec behavior): `app/test/home_screen_test.dart: Ask filters by asset; no match names the assets there are` (incl. reset clears query and field). RED `Expected: ['ETH'] Actual: ['BTC', 'BTC']`. GREEN.

AC2 opinions passes the battle's asset: `app/test/home_screen_test.dart: a battle's opinions trade that battle's asset and clash` (ETH battle → Follow Bear → `OrderTicket` ETH short; fill's position `clashId == 'eth-4k'`). RED `Found 0 widgets with text "+7 more opinions"`. GREEN.

Verification (after final `dart format`): `scripts/gate.sh baton-runner/br-2026-10-04-p0-queue/gate-phase-4-work` → analyze `No issues found!`, test `+233: All tests passed!`, pubspec-frozen PASS, `GATE: PASS`. `flutter test --dart-define=HAS_MARKET=true` → `+233: All tests passed!` (`gate-phase-4-work/flutter-test-has-market.log`).

## Files touched (10, all under app/)
`lib/features/arena/arena_mock.dart`, `arena_screen.dart`, `crowd_filter_panel.dart`, `opinions_screen.dart`, `opinions_mock.dart`; `lib/design_system/components/vista_battle.dart`; `lib/features/trade/order_ticket.dart`; `lib/scenario/scenario.dart`; `test/home_screen_test.dart`, `test/scenario_test.dart`. pubspec unchanged.

## Public surface added
- `Battle{id, asset, price, volume (int cents), changePct, fundingPct (double %), bullPct (int 0–100), bullCount, bearCount, timeLeft, question, bull, bear, opinionCount, opinions}`; getters `change`, `moreOpinions`, `bucket` (0–9 by majority share). `ticker` renamed `asset`.
- `typedef ArenaView = ({int sort, int from, int to, String query})` (bucket range `[from, to)`); `ArenaMock.bucketCount = 10`, `allBattles`, `battles = [_btc, _sol, _eth]` (ids `btc-72k`, `sol-200`, `eth-4k`), `askHint` ("Try BTC, ETH, SOL"), `asked(query)`, `buckets(query)`, `visible(view)`. Removed `crowdBuckets`, `defaultStart`, and `OpinionsMock.title/asset/bullShare/opinionCount`.
- `Scenario.participation: ValueNotifier<Map<String, TradeSide>>` (written only by `placeOrder` on a fill with `clashId`), `Scenario.arena: ValueNotifier<ArenaView>`, `Scenario.setArena({sort, from, to, query})`, `Scenario.joins(clashId, side) → int`. Both fields are in `reset()`, `state()` and `mutateEverything()`.
- `showOrderTicket(..., String? clashId)`, `OrderTicket.clashId` (goes into `_intent`, so requote/Retry carries it). `OpinionsScreen({required Battle battle})`, `OpinionsScreen.route(Battle)`.
- `VistaBattleSide.crowd` now defaults to `''`; `VistaBattleSide.withCrowd(String)`; `VistaBattleCard.joined: TradeSide?` (button reads "Joined Bull"/"Joined Bear").

## Decisions phases 05–08 must honor
- Counts are derived, not stored: shown crowd = fixture `bullCount/bearCount` + `Scenario.joins` (receipts with that clashId and side). Receipts are unique by actionId, so a replay counts once and a failure/cancel counts nothing. Two different fills on one side count twice (literal "once per actionId").
- `participation[clashId]` = the side of the latest fill there (a later Bear fill overwrites Bull). Resting limit/stop orders do not join (no fill; `OpenOrder` has no clashId).
- The crowd panel now opens on the full range (50/50 +), not Figma's 70/30 selection: with real buckets the BTC battle (63/37) would start hidden. Panel count is always `ArenaMock.visible(view).length`, histogram is over Ask's matches, so panel count == cards even with a query.
- Ask filters live as you type (`onChanged`), by asset substring, any case; the old "Ask — not in the demo yet" toast is gone. "Sort by new" (markets_screen) untouched, still not built.
- "Wallet position references the clash" is data-level: `PortfolioPosition.clashId` (phase 2 field) is set; no Wallet UI shows it.
- Crowd percentages are worded "Crowd split …" (opinions header `Crowd split 63% bull`, dock `Crowd split · N opinions`, panel label). Never odds/probability.
- Empty states sit inside the Arena list, above the shell dock, so they clear the pill strip (asserted with `expectPillClear`). No new footer.

## Remaining / for review
- Not done (not required): a crowd-split readout on the battle card itself; Wallet UI for the clash link.
- Fixture content added for ETH and SOL (callers reuse existing handles kilo.sol, lunaq, mirin, renatafx; each seeds 2 opinions). Opinions header now shows the battle's full question and card price (was a shorter Figma title and `BTC $71,840`).
- Pre-existing, untouched: `showOrderTicket` keeps the literal scrim `Color(0x73000000)`; `VistaBattleCard` has `Color(0xFF262626)` (design system file). F1 pill target is unchanged.
- Nothing is committed (runner owns git).
