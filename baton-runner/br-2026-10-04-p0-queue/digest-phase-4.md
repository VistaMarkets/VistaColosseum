# Phase 4 digest: Arena sort, crowd filter and join (spec 04) — APPROVE at d63eb32 (dw-review 7 confirmed, 7 applied; gate PASS 237, HAS_MARKET 237)

## Public surface
- `Battle` (`features/arena/arena_mock.dart`): `id` (stable clash id `btc-72k`/`eth-4k`/`sol-200`), `asset` (ticker; was `ticker`), `price` (String), `volume` (int cents), `changePct`/`fundingPct` (double %, = MarketsMock for the asset), `bullPct` (int 0–100), `bullCount`/`bearCount` (seeded others), `opinionCount`, `opinions`; getters `change`, `moreOpinions`, `bucket` (0–9 by majority share).
- `typedef ArenaView = ({int sort, int from, int to, String query})`, bucket range `[from, to)`. `ArenaMock.sorts` (label order = sort index), `bucketCount = 10`, `allBattles` (an ArenaView seed, not a list), `battles`, `askHint` (derived "Try BTC, ETH, SOL"), `asked(query, [pool])`, `buckets(query)`, `visible(view, [pool])`.
- `Scenario.arena` (`ValueNotifier<ArenaView>`) + `Scenario.setArena({sort, from, to, query})` (null keeps the old part). `Scenario.participation` (`Map<clashId, TradeSide>`, written only by `placeOrder` on a fill with a clashId; latest side wins). `Scenario.joins(clashId, side)` = receipts with that clash and side.
- clashId plumbing: `showOrderTicket(..., clashId)` → `OrderTicket.clashId` → `OrderIntent` → `OrderReceipt.clashId` + `PortfolioPosition.clashId`; requote/Retry carry it. `OpinionsScreen({required Battle battle})`, `OpinionsScreen.route(Battle)`; both side buttons pass `b.asset`, `b.id`.
- `VistaBattleSide.withCrowd(String)`; `VistaBattleCard.joined: TradeSide?` ("Joined Bull"/"Joined Bear"). Crowd line = `and ${seed + Scenario.joins(...)}`.
- `AppShell`: `panelOpen = arena && MediaQuery.viewInsetsOf(context).bottom == 0` folds the crowd panel while a soft keyboard is up; panel stays mounted, state survives.
- `ArenaScreen` owns `_list` (ScrollController); `_followView` syncs the Ask field and jumps to 0 when the visible count shrinks.

## Conventions 05 maker card, 06 fee ledger, 07 trader record, 08 empty states must honour
- Crowd split labelling: every derived crowd percentage reads "Crowd split …", never odds or probability (test `the crowd split is labelled crowd split, never odds` greps `odds|probab`). Sort/range changes write only `Scenario.arena` (VC-ARN-005).
- Participation is keyed by actionId: counts derive from receipts (unique by actionId), so a replay adds 0, failure/cancel add 0, resting orders never join. Don't add a stored counter.
- Fixtures align with MarketsMock: a battle's change/funding must equal Markets for its asset; a battle on an asset Markets lacks fails `each battle quotes its asset as the Markets tab does`. New fixtures reuse Markets values, never fork them.
- List-to-top rule: when a filtered list shrinks, start it at offset 0 (own the controller, jump in the listener, not in build). Cost: no iOS status-bar scroll-to-top on that list.
- A live filter stays visible with the keyboard up: fold docked panels on `viewInsets.bottom > 0`; never change `resizeToAvoidBottomInset`.
- Wallet clash reference is a data field only (`PortfolioPosition.clashId`, manager decision 2026-10-05T02:25:49Z); no Wallet UI reads it. Build none unless a spec asks.
- `arena` and `participation` have initializer + `reset()` + `state()` + `mutateEverything()`; `resetDemo()` clears both (scenario_test Settings and pill reset tests).
- Ask filters live by asset substring (`onChanged`); "Sort by new" stays `_notBuilt`. The crowd panel opens on the full range (50/50 +), not Figma's 70/30.
- New widgets: tokens only (`VistaColors`/`VistaType`/`VistaSpace`); empty states sit inside the list above the dock, cleared by `expectPillClear`.

## Open / carried
- F1 (phase 3) MEDIUM, OPEN, user's design call: pill tap target 30px < 44; `opinions_screen.dart:181` is one of the 5 flush footers. Do not fix inside another phase.
- LiveFeed drift after reset (phase 1 M, phase 2 L-5), still open; `resetDemo` is the place for the rebase.
- New at close, LOW: the Change↔Funding chip-label order in `ArenaMock.sorts` is unpinned (aligned fixtures give both chips SOL, BTC, ETH); one assertion on `Scenario.arena.value.sort` after a tap closes it.
- iter-1 carried: L2 joins count fills, not people (Bull then Bear counts the user on both sides); L3 slider semantics "N percent majority" lacks "crowd split"; L4 `allBattles` name; L5 Show all/panel not pinned at 1.3x in suite; L6 caller prices vs MarketPrices.
- Residual: real-device IME heights; widget-path double-tap Confirm actionId (dedupe proven only at Scenario level); no live region for the panel count.

Records: `docs/reviews/2026-10-04-dw-review-phase-4-arena-sort-filter-join.md`, `review-phase-4-dw.json`, `fixer-phase-4.json`, `baton-pass/br-2026-10-04-p0-queue/2026-10-04T195458-phase4-close.md`.
