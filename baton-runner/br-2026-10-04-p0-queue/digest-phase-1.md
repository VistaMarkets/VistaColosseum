# Phase 1 digest: Scenario store and reset (spec 01) — CLEAN at f55c061

## Public surface (`app/lib/scenario/scenario.dart`, `abstract final class Scenario`)
- `static const fixtureVersion = 'fixture-v1'`. All fields are `static final ValueNotifier<T>` (writable; read them as `ValueListenable`s):
  `cashCents<int>` (seed 1248000), `positions<List<PortfolioPosition>>`, `openOrders<List<OpenOrder>>`, `hasMarket<bool>` (seed = `--dart-define=HAS_MARKET`),
  `ticker<String>` ('MAYA'), `marketId<String?>` (ticker when listed, else null), `liked<Set<String>>` (key `callerHandle/ticker`), `favoriteAssets<List<String>>`,
  `favoriteTraders<List<String>>`, `followers<List<FollowPerson>>`, `following<List<FollowPerson>>`, `followed<Set<String>>` (seed {lunaq, kilo.sol, mirin}), `clock<DateTime>` (= `TradeMock.chartEnd`).
- `static void toggleFollow(String handle)`; `static void reset({bool withMarket = _startWithMarket})` assigns all 13 fields from the seed (`withMarket` is a test knob; the app calls `reset()`).
- Forwarders (thin, over Scenario): `AccountState.hasMarket/ticker` + `listMarket(symbol)` (sets ticker, marketId, hasMarket=true);
  `OrdersState.open` + `add`, `remove` (returns index for Undo), `insert`; `LikesState.liked` + `isLiked/toggle/count`; `WatchlistState.assets/traders` + `isAsset/isTrader/toggleAsset/toggleTrader/move`.
- Reset: Settings "Reset demo" row (after Log out) runs `Scenario.reset(); SettingsState.reset();` (also resets DisplayPrefs) then toasts "Demo reset to fixture-v1". Two resets are deep-equal. `LiveFeed` is NOT reset.
- `PortfolioPager.didUpdateWidget` snaps to "My portfolio" when `hasMarket` turns false. Follow buttons and the asset-trade Callers "Following" filter read `Scenario.followed`.

## Conventions phases 02-06 must honour
- Money is int cents in the store; `double` only for display (`cents / 100`) and LiveFeed bases. Spec 02 owns the one formatting helper and `OrderTicket.available` (double).
- Mutate by replacing the whole value with `List.unmodifiable`/`Set.unmodifiable`; never in place. Mocks are fixture sources only; screens read Scenario (`grep -rn 'PortfolioMock.positions' lib` = seed only).
- Prices, identities and calls stay const fixtures, outside the store.
- A new store field (04 participation, 05 suggestions, 06 fee entries/receipts) needs: initializer, a `reset()` line, an entry in `scenario_test.dart` `state()` and `mutateEverything()` (the round-trip test asserts every field changes).
- Tests: `scenario_test.dart` uses `setUp(Scenario.reset)`; `home_screen_test.dart` global setUp = `Scenario.reset(); AccountState.listMarket('MAYA'); SettingsState.reset();`; the make-a-market group uses `reset(withMarket: false)`.
- Also run `flutter test --dart-define=HAS_MARKET=true`; `scripts/gate.sh` does not. Spec 02's `Scenario.placeOrder` should become the single write path for cash/positions.

## Carried forward (report `review-phase-1-iter-2.md`; none blocks spec 01)
- M (spec 03): Reset is two calls inline in the Settings `onTap`; add one `resetDemo()` that spec 03's button reuses, and test it for deep equality.
- M (spec 02/03): Reset leaves LiveFeed drift on screen (base unchanged, so no rebase); add a LiveFeed reset/rebase that disposes old notifiers; fix the `watch` doc comment.
- L: pager `onIncrease` semantics action reaches the cap page with no market (pre-existing); `didUpdateWidget` zeroes `_page` on every no-market rebuild.
- L: `marketId` invariant kept by hand in 3 writers plus 2 seed expressions; `reset({withMarket})` is an unannotated test seam (consider `@visibleForTesting`).
- L: dead `MakeMarketMock.defaultTicker`; `PortfolioPager` defaults `hasMarket=true, ticker='MAYA'` (make required); two read paths (`Scenario.ticker` vs `AccountState.ticker`).
- L: market-cap constants in four places disagree after listing ("$10,000" vs "$44.0M"); `PortfolioMock.marketCapChange24h` unread.
- L: `_change` negative-start case untested; gate lacks a HAS_MARKET=true run.
- L: user can follow herself (maya.eth); Callers Following filter can render empty (spec 08); "Who notifies you" is a third follows list.
- L: "Logged out (simulated)" toast (pre-existing) breaks the letter of the truthful-toast rule.
- Deferred from iter 1: single seed/field registry; writable notifiers; cash vs equity labels ("Portfolio balance"); canonical follow source; `PositionDetail.price` dead;
  `clock`/`marketId` unread; store types in mock files; `_seedFollowed` last-wins; `_loadFonts` duplicated; TP/SL toast touches no store; `MarketsMock.traders` growable;
  import order; order ids use `DateTime.now()`; maya.eth's market on Home/Explore while unlisted (author call; the "AC1 listing on Home" refutation's reason is wrong, outcome holds: calls are const fixtures).
