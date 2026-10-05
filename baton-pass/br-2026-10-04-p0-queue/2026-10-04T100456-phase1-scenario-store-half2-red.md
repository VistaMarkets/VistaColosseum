---
source: baton-runner work unit, phase 1 of 8, second half (docs/specs/01-scenario-store.md)
scope: br-2026-10-04-p0-queue
parent_session: 2026-10-04T095757-phase1-scenario-store-half1.md
status: IN PROGRESS: checkpoint after RED, before implementation
---

# Phase 1, second half: checkpoint (RED recorded)

First half is committed as b5940cb. Do not redo it.

## Tests written first (app/test/scenario_test.dart)
- `'Home, detail, Arena and Wallet read one position from Scenario'` (AC1). Puts cash, positions, listing, like and favourite into the store only, then checks Home (top-bar cash, like), detail (star), Arena (no stale cash) and Wallet (cash in the top bar and pager, `Positions · 1`, `$ZED market cap`). Cash also moves while the app is up, which catches the `LiveFeed.watch` cache.
- `'Follow buttons read and write the follows in Scenario'` (follows in the store; backs AC2 at UI level).

## RED output (`flutter test test/scenario_test.dart`, before any lib change)
```
Expected: exactly one matching candidate
  Actual: _DescendantWidgetFinder:<Found 0 widgets with text "$10,000" descending from widgets with
type "AccountTopBar": []>
...
Expected: no matching candidates
  Actual: _TextWidgetFinder:<Found 1 widget with text "sam.sol": [ ... ]>
...
00:02 +4 -2: Some tests failed.
```

## Next step
Implement: `LiveFeed.watch` re-seeds when base changes; `account_top_bar` and `portfolio_pager` read `Scenario.cashCents`; delete `PortfolioMock.balance`; follow_list, profile, private_profile read and toggle `Scenario.followed` (list from `Scenario.followers/following`). Expect `home_screen_test` 'opens from a follower row with their handle' to need `Following` for lunaq (seeded as followed).
