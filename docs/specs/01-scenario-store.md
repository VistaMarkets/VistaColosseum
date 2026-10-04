# 01 — Scenario store and reset

**PRD:** VC-DEM-002, VC-DEM-004 (reset only). **Evidence of gap:** positions are `const` in `app/lib/features/portfolio/portfolio_mock.dart:83`; state lives in four unrelated statics (`AccountState`, `OrdersState`, `LikesState`, `WatchlistState`); `AccountState.reset` is `@visibleForTesting`.

## Behavior

One `Scenario` object (`app/lib/scenario/scenario.dart`) owns all mutable demo state: cash (int cents), positions, open orders, participation (clash id → side), listing (hasMarket, ticker, marketId), likes, favourites, fee ledger entries, demo clock (`DateTime` fixed at fixture start, advanced only by reset). Fixture version string `fixture-v1` is a constant on the store.

- Seed from the existing mock lists; the mocks become the fixture source, not live state.
- `Scenario.reset()` restores the seed exactly. Two resets in a row produce identical state (deep equality).
- Existing `AccountState`/`OrdersState`/`LikesState`/`WatchlistState` become thin forwarders or are deleted; callers migrate. No screen reads a mutable list from a mock file afterwards.
- Expose as `ValueListenable`s (match existing style); no new state package.
- Presenter reset: a "Reset demo" row at the bottom of Settings (`settings_screen.dart`, after Log out) that calls `reset()` and toasts "Demo reset to fixture-v1". Also honour `--dart-define=HAS_MARKET` as today.

## Acceptance

- [ ] Same entity shows the same value on Home, detail, Arena, Wallet (one source).
- [ ] Reset from Settings restores balances, positions, listing, likes, favourites.
- [ ] Test: seed → mutate everything → reset → equals fresh seed. Test: reset twice yields equal state.
- [ ] No `const positions` list read by UI; `grep -rn 'PortfolioMock.positions' lib` only in the seed.

## Out of scope
Persona switching, scenario phase advance (P1), persistence across restarts.
