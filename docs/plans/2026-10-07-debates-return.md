# Debates: bringing them back, done right

Status: plan, not started. Figma mock first, then build on the user's go.
Branch: `feat/premium-feel`.

## Where debates stand today

- A debate (`LiveBattle` in `arena_mock.dart`, `BattlesStore` / `Debates` in
  `calls_store.dart`) is a question on a market with a deadline, a long/short
  split and the calls argued on it. `debate_screen.dart` is its thread: the
  question, live price, time left, the split, All / Long / Short, and
  **Argue long / Argue short**, which goes through the position picker (every
  argument stands on a position).
- They're reached from a room's **Debates** tab and a call's debate badge.
- **Nobody can start one.** "Make it a debate" left the composer (521ec14),
  `BattleSetupScreen` (`battle_builder.dart`) is kept but unlinked, and
  `LiveBattlesScreen` is unused code. The only debates are seeded mock ones.

### Why the first version didn't work

1. **Debates started empty.** You made one from your own call, then waited for
   someone to disagree. Most would sit at 100% one side, which reads as dead.
2. **It cluttered posting.** Every call asked "make it a debate?", a decision
   most people don't want to make when they just want to post.
3. **It had its own feed and pages** (Live battles, the carousel), which made
   it a second product next to calls instead of part of them.

## The idea: a debate starts when someone disagrees

**A debate is two opposing calls on a statement that settles itself.** You
don't create one. You **challenge** someone's call by taking the other side
with a position. That means:

- Every debate has both sides from its first second (no empty debates).
- Posting a call stays one step; nobody is asked about debates there.
- Debates are still calls. They live in the same feeds, need positions, and
  count toward % right, so they don't need their own world.

It fits the rules we already have: every call needs a position, no replies
(arguing is posting your own call), and the app should feel like a game
(head-to-head, a countdown, a winner).

## The flows

### 1. Challenge a call (starts a debate)

```
Someone's call (LONG ETH, "breaking $3,000 this week")
  → Challenge
  → Sheet: the statement, prefilled from their call
        "ETH closes above $3,000 by Fri"   [Edit]
        deadline: Today · Fri · Next week
  → Your side is the opposite (Short here). Pick a short position you hold,
    or open one (order ticket prefilled: Short ETH)
  → Write your case (the composer, debate attached, as Argue does today)
  → Post
```

- **Where Challenge shows up:** on Arena call cards (`hub_call_card.dart`)
  next to Join, and on the call's detail page (`caller_play_screen.dart`).
  **Not on the Home card face**: its bottom row is Details / Long / Short,
  and the band above it is the asset event feed. On Home it's one tap away
  in Details.
- **Only on other people's calls**, and only if the call has no live debate
  yet. A call already in a debate shows its debate strip instead (Argue).
- **The statement is generated, not typed.** From the call's side and its take
  profit (or the live price if there's no TP), with the three shapes from the
  old setup page: closes above/below, touches, ends higher/lower than now.
  Reuse `BattleSetupScreen`'s statement and deadline pieces as this sheet, not
  as a full page.
- The original caller gets a notification ("@x challenged your ETH call").

### 2. Join a debate

Unchanged: the debate strip or thread → **Argue long / Argue short** →
position picker (or open one) → composer → it joins and moves the split.
One argument per person; you can't argue both sides.

### 3. Follow it

- **On the call itself**, wherever it shows (Home, Arena, Callers,
  Notifications): a one-line strip, `Debate · 58% long · 4h left`. It's the
  existing debate badge, made into a strip with the split and the countdown.
  Tap → thread.
- **Arena:** a hot debate (most arguments, or closing soon) sits **inline in
  Trending calls** as one card with the split bar. That's the flush feed with
  debate cards among the calls, not a carousel or its own section.
- **Rooms:** the Debates tab, as today.
- **Notifications:** challenged, someone argued against you, 1 hour left,
  settled.

### 4. Settle

- At the deadline it settles from the price feed: no votes, no judge.
- **Every argument settles like a call**: right or wrong, counted in % right.
  There's one record, not a separate debate stat.
- **The winners get a moment:** next time they open the app, a sheet with the
  order-filled burst says "You won the debate · ETH closed at $3,042 ·
  +1 right" with Share. The losers get a quiet line in Notifications.
- The thread shows the final split and the winning side. The settlement post
  (`settlement_item.dart`) already exists for the feed.
- **Closing your position early forfeits** your argument (it counts as
  wrong), so there's no free option to hedge out and still claim the win.

## Game layer (cheap, uses what exists)

- Split bar and countdown on the strip and the thread.
- **"Debates won"** on the profile next to % right (a count, not a second
  record) and a small win badge on calls by people on a debate streak.
- Later: a **Debate wins** chip on the Leaderboard.

## What we won't do

- **No pot or wager between users.** The positions are the stake. A pot turns
  this into peer-to-peer betting, with its own regulatory questions.
- **No replies.** Arguing is a call with a position (the standing rule).
- **No standalone debate feed or carousel.** `LiveBattlesScreen` gets deleted.
- **No debates on trader markets** in v1 (thin liquidity; trader rooms
  already have no Debates tab).

## Decisions for you

| Question | My recommendation |
| --- | --- |
| Can a caller decline a challenge? | **No.** A public call can be challenged; that's what makes it count. |
| Who picks the deadline? | **The challenger**, from presets, and it must land before the call's own expiry if it has one. |
| Can the statement be edited? | **Only between the presets** (level from TP / live price, three shapes). No free text, so it always settles cleanly. |
| Closing early | **Forfeit** (counts as wrong). |
| Does a debate count toward % right? | **Yes**, one record; plus a "debates won" count. |

## Build order (after the mock is approved)

1. **Challenge** on Arena call cards and the call detail page → statement
   sheet (from `battle_builder.dart` pieces) → position picker / order ticket
   → composer → `BattlesStore.add`. Notify the caller.
2. **Debate strip** on the call card everywhere calls show (replaces the
   badge).
3. **Hot debates inline** in Arena's Trending calls.
4. **Settle**: mock a deadline passing → result on the thread, winners' sheet
   (reuse `FillBurst`), notifications, % right and "debates won".
5. **Forfeit** on closing a position that's in a live debate (confirm first:
   "This forfeits your ETH debate").
6. Clean-up: delete `LiveBattlesScreen`, fold `BattleSetupScreen` into the
   sheet.

Mock in Figma first: the Challenge sheet, a call card with the debate strip,
a hot debate inline in Trending calls, and the "You won" sheet.
