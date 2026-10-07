# Explore (tab 2) redesign plan

Status: plan, not started. Figma mock first, then build on the user's go.
Branch: `feat/premium-feel`.

## The tab's job

Each tab has one job:

| Tab | Job |
| --- | --- |
| Home | Watch calls |
| **Explore** | **Find markets and traders worth acting on** |
| Arena | Debate and settle |
| Wallet | Your money and record |

Explore already does "find markets". What it doesn't do is connect a market to
what people are saying about it, or show what makes a trader worth trading.
This is a refresh of the existing screen, not a new layout.

## Who comes here and why

| Intention | Today | After |
| --- | --- | --- |
| See what's moving | Sort chips: Volume / Change / Funding | Same |
| Find a market by name | Bottom search, 3 taps | Same |
| See what people say about a market | Open it → Callers tab (3 taps) | Call and debate counts on the row; tap → Callers (2) |
| Find a good trader | Traders tab shows price, cap, call count; no record | Record on every row; sort by accuracy |
| Understand trader markets | No explanation anywhere | One-line explainer on first visit |
| Find your own market | Mixed in with everyone else's | Marked "You" |

## What's wrong today (from the 2026-10-05 review renders)

1. **Traders rows leave out the one number that matters.** They show price,
   change, market cap and "62 calls", but not how often the trader is right.
   There's no accuracy sort either (`markets_mock.dart` `traderSorts`).
2. **Asset rows don't show activity.** Nothing says a market has 12 calls and
   a live debate, so Explore feels disconnected from Home and Arena.
3. **Trader markets go unexplained.** The first-time-user reviewer read
   "maya.eth $0.4400 · Cap $44.0M" as "am I a stock now?".
4. **Your own market isn't marked.** maya.eth sits in the list like anyone
   else's.
5. **"A–Z" looks like a control but does nothing.**

## The design

The structure stays the same: account bar, Assets | Traders, Favorites rail,
sort chips, list, bottom search. What changes:

### Assets tab
- **Row second line:** `14 calls · 2 debates` in place of `OI $412M`, in
  accent to show it can be tapped. OI and counts together don't fit the
  name column at 402. OI stays on the Favorites card and the trade page.
  Counts come from `CallsStore` (calls on that ticker) and `BattlesStore`
  (live debates on it). Zero counts are left out, and a market with neither
  falls back to `OI $30M`. At 360 the line truncates, so the debate count
  goes first.
- **Tapping the counts** opens the trade page on its Callers panel. Tapping
  the rest of the row still opens the Market panel.
- **New sort chip "Most called"** after Funding.
- **Favorites cards:** unchanged.

### Traders tab
- **Row second line:** `58% right · 62 calls` instead of `62 calls`. Accuracy
  is coloured: green ≥ 55%, muted below. The "N open" badge stays.
- **New sort chip "Accuracy"**, second, after Market cap. Five chips no
  longer fit at 402, so the chip row scrolls sideways on one line instead
  of wrapping.
- **"You" tag** on your own market's row and Favorites card. It replaces
  the star (you can't favourite yourself) and the "N open" badge, which
  would otherwise clip.
- **Explainer card** above the list on first visit: *"Trader markets move
  with a trader's record: right calls push them up, wrong ones down. Long or
  short anyone."* With a "Got it" button. Session-only for the demo.

### Both tabs
- **Remove "A–Z"**, or make it a real sort (alphabetical). Recommend remove.

## Data

| Needed | Demo source | Backend later |
| --- | --- | --- |
| Calls per asset | `CallsStore.all` filtered by ticker | `GET /v1/assets/{id}/calls` (count) |
| Live debates per asset | `BattlesStore.all` filtered by ticker | No contract yet (#884–886) |
| Trader accuracy | New mock map in `markets_mock.dart` | `TraderStats.winRatePct` from `/v1/traders/{id}/stats` |
| Your market | `PortfolioMock.handle` / `AccountState` | `/v1/accounts/me/markets` |

## Out of scope
- New asset types, chart changes, search behaviour.
- Merging Assets and Traders into one list (open question below).
- The Arena debate-first redesign (separate plan).

## Build order

1. **Figma**: done. Section "Explore redesign · EXPLORE-REDESIGN" (540:204):
   Assets 540:433, Traders 540:205. Get sign-off.
2. **Traders**: record line, Accuracy sort, "You" tag. The highest-value
   change.
3. **Assets**: call and debate counts, "Most called" sort, counts → Callers.
4. **Explainer card**, then remove "A–Z".

Each step is its own commit, with tests and 360 / 402 renders.

## Acceptance checks
- Every Traders row shows accuracy; the Accuracy sort orders by it.
- An asset with calls shows the count; tapping it opens that asset's Callers.
- A call posted from + on ETH raises ETH's count on Explore.
- Your own market reads "You" in the list and the Favorites rail.
- No overflow at 360×640, 375×667, 393, 412 and 430 widths; 44pt targets.

## Open questions for the founder
1. Should the Assets tab also show a small "Top traders" strip, so newcomers
   meet trader markets without finding the toggle?
2. Should the explainer card stay dismissed for good (needs storage) or
   reappear each session (demo default)?
3. Is accuracy the right headline for a trader, or should it be return
   (e.g. "+41% · 62 calls")? Accuracy matches the record everywhere else.
