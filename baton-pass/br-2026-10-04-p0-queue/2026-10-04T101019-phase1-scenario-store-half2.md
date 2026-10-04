---
source: baton-runner work unit, phase 1 of 8, second half (docs/specs/01-scenario-store.md)
scope: br-2026-10-04-p0-queue
parent_session: 2026-10-04T100456-phase1-scenario-store-half2-red.md
status: COMPLETE: every acceptance item green; nothing committed (the manager owns git)
---

# Phase 1 complete: cash and follows read the store; AC1 test green

The first half is commit b5940cb. This half is uncommitted in the worktree, on branch `feat/br-2026-10-04-p0-queue/phase-1`.

## Acceptance criteria

| AC | State | Test | RED evidence |
|---|---|---|---|
| 1. Home, detail, Arena and Wallet show the same cash, position, listing, like and favourite values (one source); prices are not in the store | DONE | `app/test/scenario_test.dart: 'Home, detail, Arena and Wallet read one position from Scenario'` | `Found 0 widgets with text "$10,000" descending from widgets with type "AccountTopBar"` (the top bar read `PortfolioMock.balance`). Mutation check after green: putting back the old `putIfAbsent` in `LiveFeed.watch` fails at line 156 with `Found 0 widgets with text "$12,345" descending from widgets with type "AccountTopBar"`, so the test also guards the cache fix |
| 2. Reset from Settings restores balances, positions, listing, likes, favourites, follows | DONE | `scenario_test.dart: 'Reset demo in Settings restores the fixture and says so'` (half 1, store level). Every screen now listens to the store, so the UI follows a reset. Follows at UI level: `scenario_test.dart: 'Follow buttons read and write the follows in Scenario'` | Follow test before the change: `Found 1 widget with text "sam.sol"` (the follow list read `FollowMock.followers`, not `Scenario.followers`) |
| 3a. seed → mutate everything → reset equals the fresh seed | DONE (half 1, still green) | `scenario_test.dart: 'seed → mutate everything → reset equals the fresh seed'` | half 1: `Undefined name 'Scenario'` |
| 3b. Reset twice yields equal state | DONE (half 1, still green) | `scenario_test.dart: 'reset twice yields equal state'` | as 3a |
| 4. No const positions list read by the UI | DONE | grep below, plus `'Wallet lists the positions held in Scenario'` | half 1 |

How the AC1 test reads the manager's decision (single source, no new UI): it writes cash, positions, listing, a like and a favourite to the store only, pumps the whole app, and checks each screen's existing display:
- **Home:** top-bar cash `$10,000`; the first call's like is toggled. Cash then moves to `$12,345` while the app runs, and the top bar follows.
- **Detail:** the ETH star is off, because the store's favourites no longer hold ETH.
- **Arena:** shows none of these values itself, so the test checks that the old seed cash `$12,480` is nowhere on screen.
- **Wallet:** `$12,345` twice (top bar and pager), no `$12,480`, `Positions · 1`, no `Ethereum`, `$ZED market cap`.

No position display was added anywhere.

### AC4 check (`cd app && grep -rn 'PortfolioMock.positions' lib`)
```
lib/scenario/scenario.dart:23:    PortfolioMock.positions,
lib/scenario/scenario.dart:82:    positions.value = PortfolioMock.positions;
```
Only the seed matches. Also, outside `lib/scenario/`, nothing in lib reads `FollowMock.followers/following`, `PortfolioMock.balance` (deleted), `MarketsMock.assetFavorites/traderFavorites` or `OpenOrdersMock.orders`.

## Final verification (from app/)
- `flutter analyze`: `No issues found!`
- `flutter test`: `00:32 +176: All tests passed!` (174 before, plus 2 new)
- `dart format --set-exit-if-changed lib test`: 0 changed
- `scripts/gate.sh app/build/gate-phase1-half2`: `GATE: PASS` (flutter-analyze, flutter-test, pubspec-frozen). The logs are in `app/build/`, which git ignores.
- pubspec.yaml and pubspec.lock are unchanged. No new dependency.

## Files touched in this half (10 code files, plus 2 baton notes)
- `app/lib/features/live/live_feed.dart`: `watch` keeps the base per key. A new base gets a fresh notifier instead of the cached one, and there is no notify during build. `parseUsd` is deleted (no callers left).
- `app/lib/features/account/account_top_bar.dart`: the balance is `ValueListenableBuilder(Scenario.cashCents)` → `LiveUsd(base: cents / 100)`.
- `app/lib/features/portfolio/portfolio_pager.dart`: `_balance` is a getter over `Scenario.cashCents`. The pager rebuilds on `Listenable.merge([_page, Scenario.cashCents])`, a `late final` field. `_NumberPage.live` changed from `bool` to `double?` (the feed base), so the top bar and the pager feed the `'portfolio'` key the same base.
- `app/lib/features/portfolio/portfolio_mock.dart`: `PortfolioMock.balance` deleted; `cashCents` is the only cash seed.
- `app/lib/features/people/follow_list_screen.dart`: the lists come from `Scenario.followers/following`, the buttons from `Scenario.followed`, and taps call `Scenario.toggleFollow`. The widget-local map is gone.
- `app/lib/features/profile/profile_screen.dart`, `app/lib/features/profile/private_profile_screen.dart`: the Follow button is `ValueListenableBuilder(Scenario.followed)`; the local `_following` is gone.
- `app/lib/scenario/scenario.dart`: adds `toggleFollow`.
- `app/test/scenario_test.dart`: adds the AC1 test and the follow test.
- `app/test/home_screen_test.dart`: `'profile opens from a follower row with their handle'` now expects `Following` for lunaq, who is followed in the fixture. This is a deliberate behaviour change: the profile now agrees with the follow list.

## Scenario public surface (lib/scenario/scenario.dart)
```dart
abstract final class Scenario {
  static const fixtureVersion = 'fixture-v1';
  static final ValueNotifier<int> cashCents;                         // seed PortfolioMock.cashCents (1248000)
  static final ValueNotifier<List<PortfolioPosition>> positions;     // seed PortfolioMock.positions
  static final ValueNotifier<List<OpenOrder>> openOrders;            // seed OpenOrdersMock.orders
  static final ValueNotifier<bool> hasMarket;                        // seed bool.fromEnvironment('HAS_MARKET')
  static final ValueNotifier<String> ticker;                         // seed PortfolioMock.marketSymbol
  static final ValueNotifier<String?> marketId;                      // null until listed; = symbol once listed
  static final ValueNotifier<Set<String>> liked;                     // 'callerHandle/ticker'
  static final ValueNotifier<List<String>> favoriteAssets, favoriteTraders;
  static final ValueNotifier<List<FollowPerson>> followers, following;
  static final ValueNotifier<Set<String>> followed;                  // handles the user follows
  static final ValueNotifier<DateTime> clock;                        // seed TradeMock.chartEnd; no readers yet
  static void toggleFollow(String handle);                           // NEW: replaces `followed` with an unmodifiable set
  static void reset();
}
```
The forwarders are unchanged from half 1: `AccountState.{hasMarket,ticker,listMarket}`, `OrdersState.{open,add,remove,insert}`, `LikesState.{liked,isLiked,toggle,count}`, `WatchlistState.{assets,traders,isAsset,isTrader,toggleAsset,toggleTrader,move}`.

Other public changes: `PortfolioMock.balance` and `parseUsd` are deleted. `LiveFeed.watch(key, base, step)` now starts a fresh value whenever `base` differs from the last call for that key.

## Decisions later phases must honour
- **Cash is shown only from `Scenario.cashCents`.** Phase 2's `placeOrder` debit will show on Home and Wallet with no UI change; the AC1 test already proves a mid-run cash change propagates.
- **Cents become dollars only at the display edge**, as `cents / 100`, in two places: the top bar and the pager. Spec 02 asks for "display formatting via one helper"; if phase 2 adds one, route these two through it.
- **All `'portfolio'` feed callers must pass the same base** (`cents / 100`). Two different bases on one key would keep replacing each other's notifier.
- **The `'portfolio'` drift is simulated and off under test.** A new base drops the drift; a reset puts the seed back exactly.
- **Follows:** toggle only through `Scenario.toggleFollow`. The follower and following counts (`FollowMock.followerCount/followingCount`, shown on Wallet, Settings and the follow tabs) stay const strings. The lists are samples, not the counted population.
- **Adding a store field still takes three edits:** the notifier, a line in `reset()`, and a line in `scenario_test.dart`'s `state()` and `mutateEverything()`.

## Remaining / for the manager
- **Known single-source gap, owned by spec 02 and not touched here:** `OrderTicket.available = 1000` (double, `order_ticket.dart:72`) is a cash figure the ticket shows ("$1,000" available, "% of available"). Home, detail and Arena all open that ticket. Spec 02's Gap line names it ("money is `double` (`available = 1000`)"), and about ten `home_screen_test` order-ticket tests assert the $1,000 figures. Wiring it to `Scenario.cashCents` is phase 2's rework (margin ≤ cash, int cents). Doing it here would be scope creep and would change ticket behaviour.
- Nothing else remains in spec 01. Both halves are done, so unit 02 can start.
- Untouched, manager-owned: `baton-runner/br-2026-10-04-p0-queue/STATE.md` and `log.md` show as modified in the worktree. That is the manager's work, not mine.
