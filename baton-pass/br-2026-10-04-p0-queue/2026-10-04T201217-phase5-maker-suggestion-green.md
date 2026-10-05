---
source: baton-runner work unit, phase 5 of 8 (docs/specs/05-maker-suggestion-card.md)
scope: br-2026-10-04-p0-queue
parent_session: 2026-10-04T200724-phase5-maker-suggestion-checkpoint.md
status: IN PROGRESS: both acceptance items GREEN and mutation-proven; full-suite verification and final baton pending
---

# Phase 5 progress: both criteria green

- `flutter test test/home_screen_test.dart --name 'maker suggestion'`: `+14: All tests passed!` (`phase-5-red/green-3.log`).
- First full run (`phase-5-red/full-1.log`): +248 −3, exactly the tests that jump the feed by `mockFeed` index (both `homeCard('maya.eth')` tests in `order_ticket_test.dart`, `markets everywhere a trader-market card opens that trader market`). They now index `homeFeed`; green.
- Semantics defect found on the way (`green-2.log`): the card's single button merged with its texts into one node, so the whole card read as one disabled button. Fixed with `Semantics(container: true)` around the button; the expired test pins it via `find.bySemanticsLabel('Expired')`.
- Mutations (`phase-5-red/mutation.log`): store write on Trade this → no-mutation test fails (`at location [0] is <1247999> instead of <1248000>`); wrong side → prefill test fails; expired `enabled: true` → expired test fails. Source restored byte-identical after each.

Next: `flutter analyze`, `flutter test`, `flutter test --dart-define=HAS_MARKET=true`, `scripts/gate.sh`, final baton.
