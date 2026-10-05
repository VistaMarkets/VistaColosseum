---
source: baton-runner work unit, phase 5 of 8 (docs/specs/05-maker-suggestion-card.md)
scope: br-2026-10-04-p0-queue
parent_session: 2026-10-04T201217-phase5-maker-suggestion-green.md
status: COMPLETE: both acceptance items green and mutation-proven; gate PASS; analyze clean; 251/251 tests, 251/251 with HAS_MARKET=true
---

# Phase 5: Maker suggestion card (VC-FED-004)

Branch `feat/br-2026-10-04-p0-queue/phase-5`, **uncommitted** (no git mutations by this unit). Logs: `baton-runner/br-2026-10-04-p0-queue/phase-5-red/` (RED, green, mutation), `phase-5-verify/` (final runs), `gate-phase-5-work/`.

## Criteria done, with failing-test evidence
| Criterion | Test (`app/test/home_screen_test.dart`, group `maker suggestion`) | RED (actual output) |
|---|---|---|
| Behavior: two seeded, one live / one expired on the demo clock, source label, 2-line rationale, reference price, between idea cards | `two are seeded on the demo clock, one live and one expired, each from Maker and between two idea cards` | RED-1 compile: `Error when reading 'lib/features/home/maker_suggestion.dart'`, `Undefined name 'makerSuggestions'`, `'Suggestion' isn't a type`, `Undefined name 'homeFeed'` |
| AC1: both cards render without overflow on the test device list | `both cards render without overflow on <phone> at <1.0\|1.3>x text` (5 `phones` × 2 scales = 10). Each turns to both cards, asserts `takeException()` null, badge / source / data-path / rationale hit-testable, and `expectPillClear` on the button | RED-2 (data layer only): all 10 `Found 0 widgets with text "Maker suggestion · advisory"` |
| AC2: live → ticket prefilled with asset/direction | `Trade this opens the ticket on the suggestion's asset and side`: `FeedOrderTicket` `(symbol, side) == (SOL, long)` and its button reads `Long $200 · 2x` | RED-2: `The finder "Found 0 widgets with text "Trade this"" (used in a call to "tap()") could not find any matching widgets` |
| AC2: expired → confirm unavailable | `an expired suggestion says Expired, is disabled and opens no ticket, so nothing can be confirmed`: no "Trade this"; `VistaPrimaryButton.enabled == false`; semantics node `Expired` is a button with enabled state and not enabled; a tap opens no `BottomSheet`; no "Confirm" text | RED-2: `Bad state: No element` |
| AC2: no store mutation from rendering or opening | `viewing both suggestions and opening the ticket leave the store untouched`: `state()` (scenario_test's full field list) before == after: render, turn to live, Trade this, pop ticket, turn to expired, tap Expired | RED-2: `Found 0 widgets with text "Trade this"` at the tap |

Mutation proof (`phase-5-red/mutation.log`; source restored byte-identical after each):
- Store write in the button's handler → no-mutation test fails, `at location [0] is <1247999> instead of <1248000>`. (The first attempt, M1, did not compile and is marked invalid in the log; M1b is the valid run.)
- Ticket opened on the wrong side → prefill test fails, `Expected: (SOL, TradeSide.long) Actual: (SOL, TradeSide.short)`.
- Expired button `enabled: true` → expired test fails, `Expected: false Actual: <true>`.

Final verification (`phase-5-verify/`): `flutter analyze` → `No issues found!`; `flutter test` → `+251: All tests passed!`; `flutter test --dart-define=HAS_MARKET=true` → `+251: All tests passed!`; `scripts/gate.sh` → `GATE: PASS` (pubspec-frozen PASS).

## Files touched
- NEW `app/lib/features/home/maker_suggestion.dart`: `Suggestion`, `makerSuggestions`, `MakerSuggestionCard`.
- `app/lib/features/home/home_screen.dart`: `homeFeed` page list; the `PageView` builds from it (a `Suggestion` page is a centred `MakerSuggestionCard`; idea pages unchanged except `mockFeed[i]` became `idea`).
- `app/test/home_screen_test.dart`: `maker suggestion` group (14 tests); imports `maker_suggestion.dart`, `trade_mock.dart`, and `scenario_test.dart show state`. The markets-everywhere trader-market test now indexes `homeFeed`.
- `app/test/order_ticket_test.dart`: `homeCard()` jumps by `homeFeed` index (+ `home_screen.dart` import).
- `pubspec.yaml` / `pubspec.lock`: unchanged.

## Public surface added
- `class Suggestion { asset, direction (TradeSide), rationale (two lines, '\n'), expiresAt (DateTime on the demo clock), source = 'Maker · demo recommendation'; String get referencePrice => TradeMock.quotes[asset]!.price; bool liveAt(DateTime now) }`.
- `final makerSuggestions`: `[SOL long, expires chartEnd+4h (live)], [ETH short, expired chartEnd−2h]`.
- `MakerSuggestionCard({required suggestion, required VoidCallback onTrade})`: accent outline on `VistaColors.surface`, `VistaTag` "Maker suggestion · advisory", asset + `VistaSideBadge`, rationale, "Reference $214.90 · expires in 4h" / "… · expired 2h ago", source, "Built from Aggro demo prices", `VistaPrimaryButton` "Trade this" (`enabled: live`) or "Expired" (disabled). Tokens only.
- `final homeFeed = <Object>[idea0, idea1, live, idea2, expired, idea3…]` in `home_screen.dart`.

## Decisions phases 06-08 must honour
- Suggestions are fixtures, **not** a Scenario field (like calls and prices). If a later phase makes them mutable (dismiss, accept, history), move them into Scenario with initializer + `reset()` + `state()` + `mutateEverything()`.
- Home's pages are `homeFeed` (`TradeIdea | Suggestion`), not `mockFeed`. A test that jumps the feed indexes `homeFeed.indexWhere((i) => i is TradeIdea && …)`. Spec 08 Home empty/failed states must handle both page kinds.
- Expiry reads `Scenario.clock` through a `ValueListenableBuilder`. Nothing advances the clock (VC-DEM-004 phase advance stays excluded), so the live card stays live. An advanced clock would flip the card to Expired, but a ticket already open would stay open (no re-check at Confirm).
- "Trade this" reuses `showFeedOrderTicket(symbol, side, onDetails: AssetTradeScreen.route(asset))`. There is no new order path and no suggestion id flows into `OrderIntent` or the receipt (unlike `clashId`). Spec 06's fee ledger and receipts cannot tell a suggestion fill from a call fill; add `suggestionId` plumbing like `clashId` only if a spec asks.
- A card with exactly one button must wrap it in `Semantics(container: true)`. Without that wrapper the button merges with the sibling texts and the whole card reads as one button (seen in `green-2.log`).
- `home_screen_test.dart` imports `state` from `scenario_test.dart`, so any new store field added to `state()` is covered by the no-mutation test automatically. `order_ticket_test.dart` already imports `phones` from `home_screen_test.dart` the same way.
- The reference price is the demo quote string, a getter rather than a copy. If the quote changes, the card follows it. Rationale wording matches Markets (SOL +3.8% leads; ETH −0.4% lags BTC +1.2%).

## Remaining / open (none blocks spec 05)
- PRD VC-ORD-001 says the ticket shows the reference price. The feed ticket shows the live price, and spec 05's acceptance does not require the reference price. Author call.
- An open ticket isn't closed if the suggestion expires mid-flight. That can't happen today because the clock is fixed.
- Spec checkboxes left unticked, as earlier phases did. Test names are recorded here.
- Carried items untouched: F1 pill tap target (phase 3), LiveFeed drift after reset, phase-4 LOWs.
- Uncommitted. The manager commits. If the repo's pre-commit hook regenerates ARCH.md, it will pick up `maker_suggestion.dart`.
