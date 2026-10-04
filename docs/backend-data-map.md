# Backend data map

What data the app shows, which pages share it, and where it should come from
once the app talks to VistaMobileBE (VMBE). Written 2026-10-04 against branch
`feat/premium-feel` and VMBE `d9fcd7d6`.

Every value in the app today is mock data (`*_mock.dart`) or in-memory state
(`*_state.dart`). The point of this page is to replace each source **once**:
several real-world things are modelled two to five times today, one per page,
and wiring them separately would let the same price, person or call disagree
across screens.

VMBE references:

- `docs/api/frontend-api-contract.md` — the rules every request follows.
- `docs/specs/2026-09-16-client-gateway-openapi.yaml` — the staged REST
  contract (66 paths). Most of it is **designed, not built**.
- `docs/api/gateway-openapi.yaml` — what is actually served today: 13
  operations (prices, price history, suggestions, accounts, terms,
  delegation).

## The shared entities at a glance

| Entity | Pages that show it | App sources today | VMBE source | Served today? |
| --- | --- | --- | --- | --- |
| [Market price](#1-market-and-price) | Almost every page | `MarketPrices` (one store) + per-page copies | `/v1/prices`, `prices` stream, `/v1/assets/*` | Prices yes; assets staged |
| [Person](#2-person-and-record) | Home, trade, Arena, profile, follows | Handles and accuracy strings in 7 models | `CallAuthor`, `TraderProfile`, `TraderStats` | Staged |
| [Call](#3-call) | Home, trade Callers, Arena, profile, trader market | 6 models | `Call`, `/v1/feed`, `/v1/calls` | Staged |
| [Position](#4-position) | Portfolio, position sheet, Arena composer, profile | 3 models | `Position`, `/v1/positions`, `positions` stream | Staged |
| [Order](#5-order) | Order tickets, Portfolio | `OrdersState` | `/v1/orders` | Staged; submission gated |
| [Account](#6-account-and-balance) | Account bar on all four tabs, Portfolio, settings | `PortfolioMock`, `AccountState` | `/v1/accounts/me`, `/v1/portfolio/summary` | Account yes; summary staged |
| [Likes, follows, favourites](#7-likes-follows-favourites) | Home, Arena, Explore, trade, profile | 4 stores | `/v1/calls/{id}/like`, `.../follow` | Staged |
| [Market events](#8-market-events-and-alerts) | Home card strip, trade Alerts | Replay scripts in `mockFeed` | `CallEvent`, notifications | Staged |
| [Battles](#9-battles-arena) | Arena, Live battles, battle detail | `ArenaMock`, `OpinionsMock` | **None** | No contract |
| [Trader markets](#10-trader-markets-tpx) | Explore Traders, trader market, your market, make a market | 4 mocks | **None** for TPX | No contract |

---

## 1. Market and price

The single most shared piece of data. Already centralised for the live
price: `app/lib/features/live/market_prices.dart` (`MarketPrices.of(symbol)`,
fed by `LiveFeed` every 3s) is read by 23 files.

Duplicates to fold into it:

| Copy | File | Holds |
| --- | --- | --- |
| `MarketItem` | `markets/markets_mock.dart` | name, badge (max leverage), subline (OI), price string, `changePct`, funding, sort values |
| `AssetQuote` | `trade/trade_mock.dart` | the trade page header quote |
| `LiveBattle.change` | `arena/arena_mock.dart` | a typed-in "+1.2%" string |
| `TradeIdea.ticker`, `assetName`, `coinAsset` | `home/mock_trade_idea.dart` | asset identity per Home card |
| `PositionDetail.symbol`, `price` | `portfolio/portfolio_mock.dart` | a frozen price per position |

**Wire to:**

- Live price → the `prices` stream (`/v1/ws`, broadcast of all assets; filter
  locally) with `GET /v1/prices` as the snapshot. Keep `MarketPrices` as the
  one client store and feed it from the stream instead of `LiveFeed`.
- Name, icon, max leverage → `GET /v1/assets` (`AssetSummary`).
- 24h change, volume, open interest, funding, range → `GET /v1/assets/{id}`
  (`AssetDetail`). Every "change %" in the app should come from here, not
  from strings.
- Sparklines on Explore and Portfolio rows → `GET /v1/assets/sparklines`.
- Candles → `GET /v1/assets/{id}/candles`; order book →
  `/v1/assets/{id}/orderbook`.

**Rule:** money and prices arrive as **strings** (contract rule 1). Parse
once at the edge; never round-trip a price through `double` before display
of an order value.

## 2. Person and record

The same person is described differently on each page:

| Where | Model | How the record is written |
| --- | --- | --- |
| Home card | `TradeIdea.callerHandle`, `callerAvatar` | — |
| Trade page Callers | `CallerPost.handle` | — |
| Arena takes | `Take.handle`, `accuracy` | "82% right" |
| Battle cards | `VistaBattleSide.caller`, `accuracy` | "82% accuracy" |
| Battle detail | `Opinion.handle`, `hitRate` | free text |
| Profile | `ProfileMock` | "Record since Jun 2026", last-10 verdicts |
| Follow lists | `FollowPerson` | — |

**Wire to:** `CallAuthor` / `TraderRef` (`traderId`, `handle`, `avatarUrl`,
`isFollowedByMe`) everywhere a person appears; `TraderProfile` for the
profile header; `TraderStats` (`winRatePct`, `callCount`, `avgReturnPct`,
`period`) from `GET /v1/traders/{id}/stats` for every accuracy figure.

**Before wiring:** one `Person` model and one formatter for the record, so
"82% right" reads the same on Home, Arena and the profile. Avatars come from
`avatarUrl`; the app's grey circles are placeholders. Records come only from
in-app trades.

## 3. Call

A published trade idea. Six models in the app describe it:

**Product decision (2026-10-04): the Home feed is users' calls.** Home,
Arena and each trade page's Callers are three views of the same calls, not
separate content. Home shows them as replay cards, Arena as a debate feed
with battles, and Callers filters them to one asset.

Arena takes and trade-page Callers already share one list:
`app/lib/features/calls/calls_store.dart` (`CallsStore`). Arena shows every
call; a trade page's Callers shows the backed calls on its asset; Home ranks
them into its Following and For You tabs (`app/lib/features/home/home_feed.dart`).
The ranking is a demo stand-in for the backend's: √(agrees + 3 × joined) ×
1/(hours + 2)^0.8, ×1.5 for people you follow, ×1.2 when backed, your
just-posted call first. `GET /v1/feed?type=following|for-you` replaces it.

A Home card needs more than Arena's row does: the call's entry time and
price for the replay, the market events tagged along it (funding, whale,
price level), and recent fills. In VMBE terms that is `Call` plus
`/v1/calls/{id}/events` and the Signal Replay contract (#883); the saved
entry must be the author's real entry, never the current price.

| Model | File | Page |
| --- | --- | --- |
| `TradeIdea` | `home/mock_trade_idea.dart` | Home feed card, share card, caller play |
| `CallerPost` | `trade/trade_mock.dart` | The position behind a call (Callers posts and backed takes are built from `CallsStore`), caller play, battle opinions |
| `Take` | `arena/arena_mock.dart` | Every call in `CallsStore`: Arena feed and trade-page Callers |
| `Opinion` | `arena/opinions_mock.dart` | Battle detail |
| `ProfileReceipt` | `profile/profile_mock.dart` | Profile calls timeline |
| `RecordCall`, `RecordEntry` | `market/*_mock.dart` | Trader market record |

**Wire to:** VMBE `Call` — `id`, `author`, `asset`, `direction`, `thesis`,
`entryPrice`, `markPrice`, `performanceSincePostedPct`, `createdAt`,
`closedAt`, `likeCount`, `likedByMe`, `tradedCount`, `participantCount`,
`shareUrl`.

| Page | Endpoint |
| --- | --- |
| Home feed | `GET /v1/feed?type=for-you\|following` + `feed` stream |
| Trade page Callers | `GET /v1/assets/{id}/calls` |
| Profile, trader market record | `GET /v1/traders/{id}/calls` |
| Caller play, live P/L on a card | `GET /v1/calls/{id}` + `calls` stream (`CallLive`) |
| Posting a take | `POST /v1/calls` (`CallCreate`) |
| Join long / Join short, Take on Home | your own `POST /v1/orders`, then `POST /v1/calls/{id}/participation` with the `orderId` |

Field mapping:

| App | VMBE |
| --- | --- |
| `Take.body`, `TradeIdea` reasoning, `CallerPost.message` | `thesis` |
| `Take.likes`, Home like count | `likeCount`, `likedByMe` |
| `Take.joined`, Home "people in" | `participantCount` / `tradedCount` |
| `CallerPost.entryRatio` × base price | `entryPrice` |
| Live % on backed cards | `performanceSincePostedPct` or computed from `markPrice` |
| `Take.age`, `TradeIdea.age` | `createdAt` (format on device) |

**Rule:** the app owns the `LONG`/`SHORT` → `BUY`/`SELL` translation on the
join path (contract, "Taking a Call"). A short call joined as a buy is a
wrong-way trade at leverage.

## 4. Position

| Model | File | Page |
| --- | --- | --- |
| `PortfolioPosition` + `PositionDetail` | `portfolio/portfolio_mock.dart` | Portfolio rows, position sheet, Arena "What's your take on?", composer card |
| `Holding` | `profile/profile_mock.dart` | Another user's "Holding now" |
| `CallerPost` (leverage, size, TP/SL) | `trade/trade_mock.dart` | The position behind a backed call |

**Wire to:** `GET /v1/positions` + the `positions` stream for the viewer's
own (`Position`: `direction`, `leverage`, `entryPrice`, `markPrice`,
`liquidationPrice`, `unrealizedPnlUsd/Pct`, `stopLossPrice`,
`takeProfitPrice`, `notionalUsd`, `openedAt`). Close and edit exits:
`/v1/positions/{id}/close`, `/v1/positions/{id}/exits`.

## 5. Order

`portfolio/orders_state.dart` collects limit and stop orders placed from both
tickets (`order_ticket.dart`, `feed_order_ticket.dart`) and Portfolio shows
them under Open orders.

**Wire to:** `POST /v1/orders` (with an `Idempotency-Key`),
`GET /v1/orders/constraints` for ticket limits (leverage tiers, minimum size,
fees), `/v1/orders/{id}/cancel`, `/v1/orders/{id}/modify`.

**Rule:** submission is gated in VMBE and stays simulated in this demo. A
`200` can still be a refusal; read `OrderStatus`.

## 6. Account and balance

`AccountTopBar` (handle, balance, Deposit, settings) sits on all four tabs and
reads `PortfolioMock.handle` / `balance`. `AccountState` holds whether the
viewer has their own trader market. The composer stamps posts with
`PortfolioMock.handle`.

**Wire to:** `GET /v1/accounts/me` (`handle`, `bio`, `avatarKey`,
`tradeVisibility`, onboarding and gate state) and `GET /v1/portfolio/summary`
+ `portfolio` stream (`equityUsd`, `change24hUsd/Pct`) for the balance and
the Portfolio header. Daily P/L chart: `/v1/portfolio/pnl/daily`.

**Rule:** identity comes from the Privy token, never from a request body.

## 7. Likes, follows, favourites

| Store | File | Pages | VMBE |
| --- | --- | --- | --- |
| `LikesState` | `home/likes_state.dart` | Home | `POST/DELETE /v1/calls/{id}/like`, `Call.likedByMe` |
| `TakeLikes` | `arena/take_card.dart` | Arena | same as above |
| `WatchlistState` | `watchlist/watchlist_state.dart` | Explore favourites, trade page star, trader market, edit favourites | `/v1/assets/{id}/follow`, `/v1/traders/{id}/follow`, `/v1/accounts/me/markets` |
| `FollowMock` | `people/follow_mock.dart` | Follow lists, profile counts | `/v1/accounts/me/following`, `/followers` |

**Before wiring:** merge `LikesState` and `TakeLikes` into one store keyed by
`callId`; today Home keys by handle + ticker and Arena by handle.

## 8. Market events and alerts

Home cards carry a scripted replay (`home/replay_script.dart`) with funding,
whale and price-level events plus live fills. The trade page's Alerts panel
(`trade/asset_alerts.dart`) is derived from those same Home cards.

**Wire to:** `GET /v1/calls/{id}/events` + `calls` stream (`CallEvent`) for
events on a call; `GET /v1/notifications` + `notifications` stream for the
viewer's alerts. Signal Replay needs saved entry, venue and candle coverage
that VMBE has not specified yet (#883).

## 9. Battles (Arena)

`LiveBattle` (carousel, Live battles page), `OpinionsMock` (battle detail) and
`Take.battle` (the chip on a take). **VMBE defines no Arena endpoint**:
ADR-0021 retains Arena behind #884–#886.

Needed from the backend: a `Battle` (id, asset, question, settles-at,
long/short share, take count, outcome), a list endpoint with the three sorts
the app uses (most takes, closing soon, closest split), and a `battleId` on
`Call` (or `CallCreate`) so a take can sit on a battle. `AssetPost`
(`/v1/assets/{id}/posts`, `stance` + `body`) is the nearest existing shape
for an unbacked take.

## 10. Trader markets (TPX)

`TraderMarketMock`, `YourMarketMock`, `MakeMarketMock`, the Traders tab of
`MarketsMock`, and the trader-token prices in `MarketPrices` (`maya.eth`,
`0xreal`, …). VMBE excludes trader-token prices from the Explore contract and
gates TPX behind #885/#886. Keep these on mock data until that lands.

## Device-only (no backend)

`SettingsState`, `DisplayPrefs` (long on the right, chart prefs), and the
demo's `CallsStore` until posting is wired. Private position notes are
device-only by VMBE's decision.

---

## Suggested wiring order

1. **Prices.** Feed `MarketPrices` from the `prices` stream. Every page that
   shows a number picks it up at once.
2. **Account and portfolio summary.** Account bar on all four tabs.
3. **Positions and orders.** Portfolio, position sheet, the take picker.
4. **One `Call` model**, then Home feed, trade Callers and Arena takes from
   `/v1/feed` and `/v1/assets/{id}/calls`.
5. **One `Person` model + `TraderStats`** for every handle and record.
6. **Likes, follows, favourites** as one store each.
7. Battles and TPX when VMBE specifies them.

## Open questions for the backend

- Does `Call` carry leverage, size and exits, or does a backed take join
  `Call` to the author's `Position`? The app shows all four on backed takes.
- Can a viewer read another user's positions ("Holding now" on profiles)?
  `Account.tradeVisibility` suggests a privacy setting but no endpoint.
- Where does "right / wrong" on a call come from — `TraderStats` only, or a
  per-call verdict?
- The Battle shape and its link to calls (section 9).
