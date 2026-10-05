# Phase 5 digest: Maker suggestion card (spec 05) — APPROVE at d935436 (dw-review 5 confirmed, 5 applied; gate PASS 252, HAS_MARKET 252)

## Public surface
- `Suggestion` (`features/home/maker_suggestion.dart`): `asset` (ticker with a `TradeMock.quotes` entry), `direction` (`TradeSide`), `rationale` (two lines, `\n`), `expiresAt` (DateTime on the demo clock), `source` (default `'Maker · demo recommendation'`); getter `referencePrice` = `TradeMock.quotes[asset]!.price` (display String, not money); `liveAt(now)` = `now.isBefore(expiresAt)`. A fixture, not a Scenario field.
- `makerSuggestions`: `[SOL long, expires chartEnd+4h (live), ETH short, expired chartEnd−2h]`.
- `MakerSuggestionCard({required suggestion, required VoidCallback onTrade})`: surface fill, accent outline, `VistaTag` "Maker suggestion · advisory", asset + `VistaSideBadge`, rationale, "Reference $214.90 · expires in 4h" / "Reference $2,968.40 · expired 2h ago", source, "Built from Aggro demo prices", `VistaPrimaryButton` "Trade this" (`enabled: live`) or "Expired" (disabled). Rebuilds on `Scenario.clock` via `ValueListenableBuilder`.
- `homeFeed` (`home_screen.dart:15`) = `<Object>[idea0, idea1, makerSuggestions[0], idea2, makerSuggestions[1], idea3…]`; the PageView builds from it. A `Suggestion` page is a centred card whose `onTrade` calls the existing `showFeedOrderTicket(symbol: item.asset, side: item.direction, onDetails: AssetTradeScreen.route(item.asset))`. No new order path.
- Index-based feed tests MUST use `homeFeed`, never `mockFeed`: `homeFeed.indexWhere((i) => i is TradeIdea && …)` or `homeFeed.indexOf(s)` (`order_ticket_test` `homeCard()` and the trader-market test already do).
- Button semantics: the card wraps its one button in `Semantics(container: true)` (`maker_suggestion.dart:122-123`). Without it the button merges with the sibling texts and the whole card reads as one button. Any new card with exactly one button does the same. `VistaPrimaryButton` itself is unchanged.
- Tests: group `maker suggestion` (15) at `home_screen_test.dart:2810`; it imports `state` from `scenario_test.dart`, so a new store field is covered by the no-mutation test automatically.

## Decisions 06 fee ledger, 07 trader record, 08 empty states must honour
- Expiry runs on `Scenario.clock`, never wall-clock. The only lib writer of the clock is still `Scenario.reset` (`scenario.dart:266`); tests may move it, the file setUp resets it. If a phase ever advances the clock (VC-DEM-004, excluded), the card flips to Expired but an already-open ticket stays confirmable.
- Viewing mutates no store: the card reads only `Scenario.clock`; "Trade this" only opens the ticket; fills still go through `Scenario.placeOrder`. Pinned by `viewing both suggestions and opening the ticket leave the store untouched`. Making suggestions mutable (dismiss, accept) means a Scenario field + initializer + `reset()` + `state()` + `mutateEverything()`.
- Badge label is `VistaColors.textPrimary` on `VistaColors.accentTint` (10.28:1); accent on accentTint is 4.26:1 and fails AA for 11pt text. Colour pinned in `Trade this opens the ticket on the suggestion's asset and side`. Tokens only.
- The ticket prices at the live mark (`MarketPrices.now`); the suggestion's reference price does not seed it. Author call against PRD VC-ORD-001, not a spec 05 gap. No suggestion id reaches `OrderIntent` or the receipt, so spec 06 cannot tell a suggestion fill from a call fill; add `suggestionId` like `clashId` only if a spec asks.
- Spec 08: Home empty/failed states must handle both page kinds. `homeFeed` is `List<Object>` read with `item as TradeIdea` (iter-1 L5), so a third page kind crashes at runtime; prefer a sealed type or exhaustive switch.

## Open / carried
- Phase 3 F1 MEDIUM, OPEN, user's design call: pill tap target 30px < 44; 5 flush footers. Do not fix inside another phase.
- LiveFeed drift after reset (phase 1 M, phase 2 L-5), open; `resetDemo` is where the rebase goes. The SOL "leads the majors" rationale is static text while LiveFeed ticks.
- Phase 4: the Change↔Funding chip-label order in `ArenaMock.sorts` is unpinned.
- Phase 5 iter-1 LOWs not taken: L4 (seed test's RED was compile-only; mutants now kill it), L5 (`homeFeed` cast), L6 pre-existing `VistaPrimaryButton` semantics exposes no tap action (design-system item, author).
- Residual: live "Trade this" semantics node and the suggestion ticket's `onDetails` route are unasserted; landscape, tablets, mid-swipe frames unchecked.

Records: `docs/reviews/2026-10-04-dw-review-phase-5-maker-suggestion-card.md`, `review-phase-5-dw.json`, `fixer-phase-5.json`, `baton-pass/br-2026-10-04-p0-queue/2026-10-04T205139-phase5-close.md`.
