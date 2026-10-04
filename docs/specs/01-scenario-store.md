# 01: Scenario store and reset

## Rules for this unit

Common rules for every unit: original lightweight code (CONTEXT.md), no new pub dependencies, money as `int` minor units or fixed-decimal strings (never new `double` money), every success message describes something that actually happened, keep the existing "— not in the demo yet" toast for anything you don't build. Run `scripts/gate.sh <log-dir>` before returning; it must print `GATE: PASS`. Every acceptance criterion names its test as `app/test/<file>.dart: <test name>` or is marked `manual, waived`; add the tests the spec names.

**PRD:** VC-DEM-002 (financial state; identities, prices and calls stay const fixtures, Arena price is a String in `arena_mock.dart:17`), VC-DEM-004 (reset only). **Evidence of gap:** positions are `const` in `app/lib/features/portfolio/portfolio_mock.dart:83`; state lives in four unrelated statics (`AccountState`, `OrdersState`, `LikesState`, `WatchlistState`); `AccountState.reset` is `@visibleForTesting`.

## Behavior

One `Scenario` object (`app/lib/scenario/scenario.dart`) owns all mutable demo state. This unit seeds: cash (int cents), positions, open orders, listing (hasMarket, ticker, marketId), likes, favourites, follows (followers, following, follow toggles; now widget-local in `private_profile_screen.dart:19`), demo clock (`DateTime` fixed at fixture start; reset restores it). Later units add their own types to the store: participation (04), suggestions (05), fee entries and call receipts (06). Fixture version string `fixture-v1` is a constant on the store.

- Seed from the existing mock lists; the mocks become the fixture source, not live state.
- `Scenario.reset()` restores the seed exactly. Two resets in a row produce identical state (deep equality).
- Existing `AccountState`/`OrdersState`/`LikesState`/`WatchlistState` become thin forwarders or are deleted; callers migrate. No screen reads a mutable list from a mock file afterwards.
- Expose as `ValueListenable`s (match existing style); no new state package.
- Presenter reset: a "Reset demo" row at the bottom of Settings (`settings_screen.dart`, after Log out) that calls `reset()` and toasts "Demo reset to fixture-v1". Also honour `--dart-define=HAS_MARKET` as today.
- Right-size: this unit touches about 16 files. If the runner must split it, the seam is store, seed, reset and tests first, then caller migration and the Settings row; both halves land before unit 02. Keeping the four statics as thin forwarders over `Scenario` is allowed and keeps the second half small.

## Acceptance

- [ ] Same cash, position, listing, like and favourite values on Home, detail, Arena, Wallet (one source); prices are not in the store. Test: `app/test/scenario_test.dart: 'Home, detail, Arena and Wallet read one position from Scenario'`.
- [ ] Reset from Settings restores balances, positions, listing, likes, favourites, follows.
- [ ] Test: seed → mutate everything → reset → equals fresh seed. Test: reset twice yields equal state.
- [ ] No `const positions` list read by UI: `cd app && grep -rn 'PortfolioMock.positions' lib` matches only the seed. Unit-scoped check run by the review unit, not by `scripts/gate.sh` (it fails on the tree before this unit).

## Out of scope
Persona switching, scenario phase advance (P1), persistence across restarts.
