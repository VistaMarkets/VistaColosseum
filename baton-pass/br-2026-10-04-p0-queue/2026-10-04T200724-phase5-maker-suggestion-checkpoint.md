---
source: baton-runner work unit, phase 5 of 8 (docs/specs/05-maker-suggestion-card.md)
scope: br-2026-10-04-p0-queue
parent_session: 2026-10-04T195458-phase4-close.md
status: IN PROGRESS: RED recorded for every acceptance item; fixture data layer written; card UI not yet built
---

# Phase 5 checkpoint: RED tests in place

Branch `feat/br-2026-10-04-p0-queue/phase-5`, uncommitted. Raw logs: `baton-runner/br-2026-10-04-p0-queue/phase-5-red/`.

## RED evidence
- RED-1 (`red-1-compile.log`), `flutter test test/home_screen_test.dart --name 'maker suggestion'`, before any lib code: compile fails,
  `Error when reading 'lib/features/home/maker_suggestion.dart'`, `Undefined name 'makerSuggestions'`, `'Suggestion' isn't a type`, `Undefined name 'homeFeed'`.
- RED-2 (`red-2-assert.log`), after only the data layer (`Suggestion`, `makerSuggestions`, `homeFeed` list; HomeScreen still renders `mockFeed`): +1 −13.
  - fixture test passes (two seeded, one live / one expired on the demo clock, between idea cards in `homeFeed`).
  - AC1, 10 tests `both cards render without overflow on <phone> at {1.0,1.3}x text`: `Found 0 widgets with text "Maker suggestion · advisory"`.
  - AC2 live: `The finder "Found 0 widgets with text "Trade this"" (used in a call to "tap()") could not find any matching widgets`.
  - AC2 expired: `Bad state: No element` (no `VistaPrimaryButton` "Expired").
  - AC2 no mutation: `Found 0 widgets with text "Trade this"` at the tap.

## Next step
Card widget in `home/maker_suggestion.dart`, HomeScreen itemBuilder over `homeFeed`; then re-point the two tests that jump the feed by `mockFeed` index (`home_screen_test.dart` markets-everywhere trader-market Details; `order_ticket_test.dart` `homeCard`) to `homeFeed`.
