# Architecture Map — VistaColosseum

> **Auto-maintained.** The file tree below (between the `ARCH:TREE` markers) is regenerated on every commit by `.githooks/pre-commit` and can be refreshed manually with `python3 .githooks/gen_arch.py`. The **Overview** and **Key Paths** sections are curated and preserved across regenerations. Descriptions in *Key Paths* are injected inline into the tree. After cloning, enable the hook with `git config core.hooksPath .githooks`.

## Overview

This repository contains the project presentation, shared vocabulary, agent
workflow configuration, and the Flutter demo app in `app/`. The app currently
implements the design system, the Home feed and the Portfolio (Wallet) tab with mock data; the
application components below describe the agreed demo design, and their entry
points and integrations are not implemented here yet.

### Design system

`app/lib/design_system/` is the single source of colour, type, spacing, radius
and size tokens plus shared widgets. It is derived from the Arena Figma file
(`yIxjFkwJAwBa07RgSmVv1D`, frames 301:102 Home, 174:110 Portfolio, 168:110 Your market, 308:102/308:244 Follow lists, 303:102 Profile, 236:102/237:*/241:102 Trader market 185:110/222:110 Markets, 505:204 Arena feed, 48:430 Clash detail 206:110/214:* Asset trade 104:110 Position sheet 258:407 Private profile and 175:218/338:102/329:102/348:624 Make a market); that file defines no Figma variables,
so token names come from usage. Screens import `design_system.dart` and must not
hardcode colours or font sizes. Figma vectors live in `app/assets/figma/`; the
SF Pro Rounded face is substituted with OFL-licensed Open Runde.

### Core flow

1. **Aggro** aggregates venue prices and supplies market data exclusively to
   **Maker** through an internal interface.
2. **Maker** creates recommended orders from that data and sends them to the
   **Tradefeed**, where users discover and review suggestions.
3. **Merchant** handles purchasing the orders users choose. All financial actions
   in this demo must remain simulated.
4. **Market** lets users post orders for others to discover and copy. The original
   trader can earn value when their orders are copied; the reward mechanism is
   not yet specified.

The social experience connects trader profiles, opposing calls, performance
records, and communities. **TPX** (Trader Performance Exchange) adds long and
short positions on trader performance indices derived from settled results.

Use VistaMobileBE and Flutter-mobile-app as read-only references for lightweight
demo implementations. Preserve existing safety gates and keep credentials and
real financial execution out of the demo.

## Key Paths

<!-- ARCH:DESC:START — curated; one line per key path, preserved across regens -->
- `.githooks/` — shared Git hook and generator that refresh this architecture map
- `ARCH.md` — generated file tree with curated architecture notes
- `README.md` — project presentation and animated Vista logo
- `CONTEXT.md` — project acronyms, vocabulary, and reference repositories
- `docs/agents/` — issue tracker, triage labels, and domain-document configuration
- `docs/assets/` — animated Vista logo and reduced-motion fallback
- `app/` — Flutter demo app (iOS and Android)
- `app/lib/design_system/` — Vista tokens, theme and shared components; import `design_system.dart`
- `app/lib/charting/` — candle chart engine; import `charting.dart`: `Candle` (OHLC in prices), `PriceScale` + `roundTicks` (round-number gridlines), `timeMarks` (clock-boundary time labels), `LiveCandles` (newest candle follows a `LiveFeed` value), `sampleCandles` (seeded generated history) and the `PriceChart` widget (hollow candles or line)
- `app/lib/app_shell.dart` — tab shell with the capsule bottom nav (Home, Explore, Arena, Wallet): pages switch with a fade-through and keep their state; the nav is a floating glass pill
- `app/lib/features/people/` — Followers / Following lists (pushed from Portfolio chips) with search and follow toggles (mock data)
- `app/lib/features/profile/` — another user's profile (from follow lists, callers and the Home card): header, market chart, holdings, call/arena receipts; private accounts without a market get the private layout (mock data)
- `app/lib/features/portfolio/` — Portfolio screen: swipeable portfolio / market-cap pager and chart (`series_chart.dart`: drawn from simulated history over the chosen span, the balance ending at its live value, in the Home line style), spans, fees, positions; tapping a position slides up its P/L sheet, whose chart is that market's price over the span ending at the live price, with take-profit / stop-loss steppers that move the chart lines and swap Close for a simulated Edit/save; Open orders tab lists resting limit orders as compact cards (fill price and distance from the mark, size, partial fill, TP/SL, reduce-only) with a one-tap simulated Cancel and Undo; without a market the chart drops the muted market line (mock data)
- `app/lib/features/live/` — simulated live feed (off under `flutter test`) that nudges headline figures so they roll their digits (Figma 108:125); `MarketPrices` is the one live price per market that every screen reads, so any two screens always agree
- `app/lib/features/make_market/` — make-a-market flow (create → before you list → live with confetti burst), opened from Portfolio when the user has no market
- `app/lib/features/markets/` — Explore tab: Assets / Traders market lists with search, sort chips and favourites (mock data)
- `app/lib/features/market/` — Your market screen (from Portfolio), Trader market screen (from a profile) and `chart_sheet.dart`, the shared chart + drag-up panel layout also used by asset trade (mock data)
- `app/lib/features/account/` — `AccountState` (has the user listed a market, and its ticker; `--dart-define=HAS_MARKET=true` starts with one) and the signed-in user's top bar (avatar, handle over portfolio balance, + Deposit; settings gear on Portfolio) shared by Home and Portfolio
- `app/lib/features/arena/` — Arena tab (Figma 505:204): an X-style feed under the account bar and sort chips: a sideways carousel of live battles (`BattleTile`, top three; tap opens the clash detail; "See all" opens `live_battles_screen.dart`, every battle as a flush row sorted by Most takes / Closing soon / Closest split), then flush take rows (`take_card.dart`) — a take is on a battle (battle chip) or a plain call on a market (market chip), backed takes carry their live position, with agree, joined count and Join (opens the order ticket); a floating + in the lower right (above the nav) opens `pick_position_screen.dart`, the viewer's open positions; tapping one opens `compose_take_screen.dart`, an X-style composer (Cancel / Post, avatar beside the text, the position's live card under it); Post adds the call to `CallsStore`; "Make it a battle" under the position card opens `BattleSetupScreen` in `battle_builder.dart` (Figma 517:205), its own page: statements that follow the position's side (long: closes above / touches / stays above / ends higher; short: closes below / touches / stays below / ends lower; first picked), the battle as a sentence with tappable parts, a typed level (grouped digits) with shortcuts, deadline chips (today, Fri, next week, next month) and the side set by the position; statements sit on one sideways-scrolling line and the statement in the sentence is not a button; it returns a `BattleSpec` the composer shows with Edit / Remove, and Start battle also adds the battle to `BattlesStore` (in `calls_store.dart`), which the carousel and Live battles read. The clash detail (`opinions_screen.dart`) keeps side filters and a consensus dock (mock data)
- `app/lib/features/calls/calls_store.dart` — `CallsStore`, the one in-memory list of published calls (seeded from `ArenaMock.takes` plus the Home cards in `mockFeed`): Arena's feed shows all of them, backed first then newest; each trade page's Callers panel shows the backed calls on its asset; a take posted from Arena lands in both; `app/lib/features/home/home_feed.dart` (`HomeFeed`) ranks them for Home's Following and For You tabs (√engagement × freshness, ×1.5 for people you follow, ×1.2 when backed; your just-posted call first) and builds a replay card for calls without one
- `app/lib/features/share/` — Share call (Figma 462:474): the Home card's Share opens a sheet previewing exactly what the recipient gets (`ShareCallCard`, the 1.91:1 link-preview image with the Vista mark, drawn with the replay line painter, over its title and link), and Messages, Telegram, X and Copy link targets; sending is simulated (Copy link copies)
- `app/lib/features/settings/` — Settings from the Portfolio gear (Figma 442:102 / 442:772): sections open in place; Notifications (backend `NotificationPrefs` + per-trader switches), Display (`DisplayPrefs`: candles/line for every chart that draws both, Long button left/right on every Long/Short or Bull/Bear pair), Security (two-factor, trading permission), Legal and privacy (trade visibility, terms, region), Help; all changes simulated and on-device
- `app/lib/features/watchlist/` — favourites shared by every star: `WatchlistState` (assets = the backend's asset-follow relation; traders device-only) drives Explore's rows and Favorites rail, the asset and trader market page stars, and Edit favorites (drag to reorder, unstar with undo); in memory, simulated
- `app/lib/features/trade/` — asset trade page (Home Details, Explore assets): live `PriceChart` (BTC 15m seeded from the Figma candles, other assets/intervals generated; interval chips and candle/line toggle work) with Market / Book / Callers / Alerts panels (`asset_alerts.dart`: the Home feed's alerts on that market — the call, its replay events and live fills — as a newest-first timeline); Callers is a read-only post thread of the backed calls on that asset from `CallsStore` (the same calls as Arena) (each caller's reasoning over their order and live P&L, in the market's own prices) filtered to Following or Everyone; tapping a post's order opens `CallerPlayScreen`, that call as a Home-style trade card (mock data); `order_ticket.dart` is the pro order sheet (Figma 218:608) that Long/Short opens on the trade pages and Arena (Join long / Join short): side, Market/Limit/Stop, leverage up to the market's cap, price with Mid, size in units or USD with a 0–100% slider, TP/SL, reduce-only, live margin, liquidation and fee; placing is simulated and limit/stop orders land in Portfolio › Open orders via `OrdersState`; `feed_order_ticket.dart` (a part of it) is the first-time ticket Home feed cards open (Figma 472:1359): the card's side, Market/Limit, 2x/5x/10x/custom leverage, a dollar amount, an entry-anchored TP/SL track and the price where the margin is lost
- `app/lib/features/home/` — Home swipe feed: one call card per market Explore offers (5 assets + 7 trader markets; ETH is the Figma card), each with its own `ReplayScript` (price path, call line, events; generated from a seed for all but ETH) played by the signal replay chart (line, or candles when chosen in Settings › Display; a camera opens on the first candle and pulls back; candles grow in a wave; paced by `replay_timeline.dart`, ringed entrances, haptics, labels placed clear of each other and the activity rows; header price and % since call replay in step; then live on the market's price); Details opens the asset or trader market (mock data)
- `app/assets/figma/` — SVGs exported from the Arena Figma file
- `app/assets/fonts/` — Open Runde font files and OFL license
- `app/tool/` — asset scripts: market-focus Portfolio chart from the Figma export; `app_icon/` renders the launcher icon (Figma 201:1939) and cuts iOS/Android sizes
- `app/test/` — widget tests, including the multi-phone-size overflow checks
<!-- ARCH:DESC:END -->

## File Tree

<!-- ARCH:TREE:START — generated by gen_arch.py; do not edit inside, do not remove -->
```
VistaColosseum/
├── .claude/
│   └── skills/
│       └── vista-app-review/
│           ├── references/
│           │   └── reviewers.md
│           ├── scripts/
│           │   ├── render_screens.sh
│           │   └── render_screens_test.dart.tmpl
│           └── SKILL.md
├── .githooks/  — shared Git hook and generator that refresh this architecture map
│   ├── gen_arch.py
│   └── pre-commit
├── app/  — Flutter demo app (iOS and Android)
│   ├── android/
│   │   ├── app/
│   │   │   ├── src/
│   │   │   │   ├── debug/
│   │   │   │   │   └── AndroidManifest.xml
│   │   │   │   ├── main/
│   │   │   │   │   ├── kotlin/
│   │   │   │   │   │   └── com/
│   │   │   │   │   │       └── vistamarkets/
│   │   │   │   │   │           └── vista_colosseum/
│   │   │   │   │   │               └── MainActivity.kt
│   │   │   │   │   ├── res/
│   │   │   │   │   │   ├── drawable/
│   │   │   │   │   │   │   └── launch_background.xml
│   │   │   │   │   │   ├── drawable-v21/
│   │   │   │   │   │   │   └── launch_background.xml
│   │   │   │   │   │   ├── mipmap-hdpi/
│   │   │   │   │   │   │   └── ic_launcher.png
│   │   │   │   │   │   ├── mipmap-mdpi/
│   │   │   │   │   │   │   └── ic_launcher.png
│   │   │   │   │   │   ├── mipmap-xhdpi/
│   │   │   │   │   │   │   └── ic_launcher.png
│   │   │   │   │   │   ├── mipmap-xxhdpi/
│   │   │   │   │   │   │   └── ic_launcher.png
│   │   │   │   │   │   ├── mipmap-xxxhdpi/
│   │   │   │   │   │   │   └── ic_launcher.png
│   │   │   │   │   │   ├── values/
│   │   │   │   │   │   │   └── styles.xml
│   │   │   │   │   │   └── values-night/
│   │   │   │   │   │       └── styles.xml
│   │   │   │   │   └── AndroidManifest.xml
│   │   │   │   └── profile/
│   │   │   │       └── AndroidManifest.xml
│   │   │   └── build.gradle.kts
│   │   ├── gradle/
│   │   │   └── wrapper/
│   │   │       └── gradle-wrapper.properties
│   │   ├── .gitignore
│   │   ├── build.gradle.kts
│   │   ├── gradle.properties
│   │   └── settings.gradle.kts
│   ├── assets/
│   │   ├── figma/  — SVGs exported from the Arena Figma file
│   │   │   ├── asset_avatar_32.svg
│   │   │   ├── back_chevron.svg
│   │   │   ├── back_chevron_small.svg
│   │   │   ├── baseline_entry.svg
│   │   │   ├── battle_avatar_bear.svg
│   │   │   ├── battle_avatar_bull.svg
│   │   │   ├── bell.svg
│   │   │   ├── caller_avatar.svg
│   │   │   ├── caller_avatar_short_32.svg
│   │   │   ├── change_arrow_up.svg
│   │   │   ├── chart_type_candles.svg
│   │   │   ├── chart_type_toggle.svg
│   │   │   ├── chevron_box.svg
│   │   │   ├── clip_above_entry.svg
│   │   │   ├── clip_below_entry.svg
│   │   │   ├── coin_arb_row.svg
│   │   │   ├── coin_avax_row.svg
│   │   │   ├── coin_btc_bg.svg
│   │   │   ├── coin_btc_rail.svg
│   │   │   ├── coin_btc_row.svg
│   │   │   ├── coin_cash_bg.svg
│   │   │   ├── coin_eth.svg
│   │   │   ├── coin_eth_20.svg
│   │   │   ├── coin_eth_rail.svg
│   │   │   ├── coin_eth_row.svg
│   │   │   ├── coin_placeholder.svg
│   │   │   ├── coin_sol_20.svg
│   │   │   ├── coin_sol_rail.svg
│   │   │   ├── coin_sol_row.svg
│   │   │   ├── dot_lattice.svg
│   │   │   ├── fees_dot.svg
│   │   │   ├── fill_avatar_1.svg
│   │   │   ├── fill_avatar_2.svg
│   │   │   ├── fill_avatar_3.svg
│   │   │   ├── holders_avatars.svg
│   │   │   ├── initials_avatar_36.svg
│   │   │   ├── like_button.svg
│   │   │   ├── like_outline_button.svg
│   │   │   ├── live_dot_small.svg
│   │   │   ├── lock.svg
│   │   │   ├── lock_notice.svg
│   │   │   ├── lock_small.svg
│   │   │   ├── long_arrow.svg
│   │   │   ├── make_market_button_dots.svg
│   │   │   ├── marker_breakout.svg
│   │   │   ├── marker_entry.svg
│   │   │   ├── marker_funding.svg
│   │   │   ├── marker_live.svg
│   │   │   ├── marker_live_halo.svg
│   │   │   ├── marker_whale.svg
│   │   │   ├── market_baseline.svg
│   │   │   ├── market_clip_above.svg
│   │   │   ├── market_clip_below.svg
│   │   │   ├── market_dot_lattice.svg
│   │   │   ├── market_live_halo.svg
│   │   │   ├── mm_add_image.svg
│   │   │   ├── mm_card_lattice.svg
│   │   │   ├── mm_image_glow.svg
│   │   │   ├── mm_image_inner.svg
│   │   │   ├── mm_live_avatar.svg
│   │   │   ├── mm_live_lattice.svg
│   │   │   ├── mm_preview_chart.svg
│   │   │   ├── nav_arena.svg
│   │   │   ├── nav_compass.svg
│   │   │   ├── nav_home.svg
│   │   │   ├── nav_wallet.svg
│   │   │   ├── notif_bell.svg
│   │   │   ├── opinions_avatars.svg
│   │   │   ├── opponent_avatar_long.svg
│   │   │   ├── opponent_avatar_short.svg
│   │   │   ├── pager_dots.svg
│   │   │   ├── pager_dots_market.svg
│   │   │   ├── people_in_button.svg
│   │   │   ├── person_avatar.svg
│   │   │   ├── portfolio_avatar.svg
│   │   │   ├── position_avatar_eth.svg
│   │   │   ├── position_sl_line.svg
│   │   │   ├── position_tp_line.svg
│   │   │   ├── profile_avatar.svg
│   │   │   ├── profile_baseline.svg
│   │   │   ├── profile_clip_above.svg
│   │   │   ├── profile_clip_below.svg
│   │   │   ├── profile_dot_lattice.svg
│   │   │   ├── rail_arena_open.svg
│   │   │   ├── rail_arena_right.svg
│   │   │   ├── rail_arena_wrong.svg
│   │   │   ├── rail_call_open.svg
│   │   │   ├── rail_call_right.svg
│   │   │   ├── rail_record_open.svg
│   │   │   ├── rail_record_right.svg
│   │   │   ├── rail_record_wrong.svg
│   │   │   ├── range_dot.svg
│   │   │   ├── referral_button.svg
│   │   │   ├── search.svg
│   │   │   ├── search_16.svg
│   │   │   ├── settings.svg
│   │   │   ├── share_avatar.svg
│   │   │   ├── share_button.svg
│   │   │   ├── share_copy_link.svg
│   │   │   ├── share_logo.svg
│   │   │   ├── share_messages.svg
│   │   │   ├── share_telegram.svg
│   │   │   ├── share_x.svg
│   │   │   ├── spark24_down.svg
│   │   │   ├── spark24_up_a.svg
│   │   │   ├── spark24_up_b.svg
│   │   │   ├── spark_0xreal.svg
│   │   │   ├── spark_eth.svg
│   │   │   ├── spark_sol.svg
│   │   │   ├── star.svg
│   │   │   ├── star_filled.svg
│   │   │   ├── take_people.svg
│   │   │   ├── terms_dashed_line.svg
│   │   │   ├── timeline_rail_open.svg
│   │   │   ├── timeline_rail_right.svg
│   │   │   ├── timeline_rail_wrong.svg
│   │   │   ├── tm_baseline.svg
│   │   │   ├── tm_last_price.svg
│   │   │   ├── tm_short_clip_above.svg
│   │   │   ├── tm_short_clip_below.svg
│   │   │   ├── tm_short_lattice.svg
│   │   │   ├── tm_tall_clip_above.svg
│   │   │   ├── tm_tall_clip_below.svg
│   │   │   ├── tm_tall_lattice.svg
│   │   │   ├── topbar_avatar.svg
│   │   │   ├── trade_last_price.svg
│   │   │   ├── trader_avatar.svg
│   │   │   ├── trader_avatar_rail.svg
│   │   │   ├── trader_avatar_row.svg
│   │   │   ├── traders_button.svg
│   │   │   └── verdicts_last10.svg
│   │   └── fonts/  — Open Runde font files and OFL license
│   │       ├── OFL-Open-Runde.txt
│   │       ├── OpenRunde-Bold.otf
│   │       ├── OpenRunde-Medium.otf
│   │       ├── OpenRunde-Regular.otf
│   │       ├── OpenRunde-Semibold.otf
│   │       ├── OpenRundeTabular-Bold.otf
│   │       ├── OpenRundeTabular-Medium.otf
│   │       ├── OpenRundeTabular-Regular.otf
│   │       └── OpenRundeTabular-Semibold.otf
│   ├── ios/
│   │   ├── Flutter/
│   │   │   ├── AppFrameworkInfo.plist
│   │   │   ├── Debug.xcconfig
│   │   │   └── Release.xcconfig
│   │   ├── Runner/
│   │   │   ├── Assets.xcassets/
│   │   │   │   ├── AppIcon.appiconset/
│   │   │   │   │   ├── Contents.json
│   │   │   │   │   ├── Icon-App-1024x1024@1x.png
│   │   │   │   │   ├── Icon-App-20x20@1x.png
│   │   │   │   │   ├── Icon-App-20x20@2x.png
│   │   │   │   │   ├── Icon-App-20x20@3x.png
│   │   │   │   │   ├── Icon-App-29x29@1x.png
│   │   │   │   │   ├── Icon-App-29x29@2x.png
│   │   │   │   │   ├── Icon-App-29x29@3x.png
│   │   │   │   │   ├── Icon-App-40x40@1x.png
│   │   │   │   │   ├── Icon-App-40x40@2x.png
│   │   │   │   │   ├── Icon-App-40x40@3x.png
│   │   │   │   │   ├── Icon-App-60x60@2x.png
│   │   │   │   │   ├── Icon-App-60x60@3x.png
│   │   │   │   │   ├── Icon-App-76x76@1x.png
│   │   │   │   │   ├── Icon-App-76x76@2x.png
│   │   │   │   │   └── Icon-App-83.5x83.5@2x.png
│   │   │   │   └── LaunchImage.imageset/
│   │   │   │       ├── Contents.json
│   │   │   │       ├── LaunchImage.png
│   │   │   │       ├── LaunchImage@2x.png
│   │   │   │       ├── LaunchImage@3x.png
│   │   │   │       └── README.md
│   │   │   ├── Base.lproj/
│   │   │   │   ├── LaunchScreen.storyboard
│   │   │   │   └── Main.storyboard
│   │   │   ├── AppDelegate.swift
│   │   │   ├── Info.plist
│   │   │   ├── Runner-Bridging-Header.h
│   │   │   └── SceneDelegate.swift
│   │   ├── Runner.xcodeproj/
│   │   │   ├── project.xcworkspace/
│   │   │   │   ├── xcshareddata/
│   │   │   │   │   ├── IDEWorkspaceChecks.plist
│   │   │   │   │   └── WorkspaceSettings.xcsettings
│   │   │   │   └── contents.xcworkspacedata
│   │   │   ├── xcshareddata/
│   │   │   │   └── xcschemes/
│   │   │   │       └── Runner.xcscheme
│   │   │   └── project.pbxproj
│   │   ├── Runner.xcworkspace/
│   │   │   ├── xcshareddata/
│   │   │   │   ├── IDEWorkspaceChecks.plist
│   │   │   │   └── WorkspaceSettings.xcsettings
│   │   │   └── contents.xcworkspacedata
│   │   ├── RunnerTests/
│   │   │   └── RunnerTests.swift
│   │   └── .gitignore
│   ├── lib/
│   │   ├── charting/  — candle chart engine; import `charting.dart`: `Candle` (OHLC in prices), `PriceScale` + `roundTicks` (round-number gridlines), `timeMarks` (clock-boundary time labels), `LiveCandles` (newest candle follows a `LiveFeed` value), `sampleCandles` (seeded generated history) and the `PriceChart` widget (hollow candles or line)
│   │   │   ├── candle.dart
│   │   │   ├── charting.dart
│   │   │   ├── live_candles.dart
│   │   │   ├── price_chart.dart
│   │   │   ├── price_scale.dart
│   │   │   ├── sample_candles.dart
│   │   │   └── time_marks.dart
│   │   ├── design_system/  — Vista tokens, theme and shared components; import `design_system.dart`
│   │   │   ├── components/
│   │   │   │   ├── vista_battle.dart
│   │   │   │   ├── vista_buttons.dart
│   │   │   │   ├── vista_chips.dart
│   │   │   │   ├── vista_controls.dart
│   │   │   │   ├── vista_detail.dart
│   │   │   │   ├── vista_flow.dart
│   │   │   │   ├── vista_glass.dart
│   │   │   │   ├── vista_icon.dart
│   │   │   │   ├── vista_list_row.dart
│   │   │   │   ├── vista_market.dart
│   │   │   │   ├── vista_navigation.dart
│   │   │   │   ├── vista_people.dart
│   │   │   │   ├── vista_pressable.dart
│   │   │   │   ├── vista_profile.dart
│   │   │   │   ├── vista_rolling_number.dart
│   │   │   │   ├── vista_settings.dart
│   │   │   │   └── vista_sheet.dart
│   │   │   ├── tokens/
│   │   │   │   ├── vista_colors.dart
│   │   │   │   ├── vista_metrics.dart
│   │   │   │   ├── vista_motion.dart
│   │   │   │   └── vista_typography.dart
│   │   │   ├── design_system.dart
│   │   │   ├── vista_assets.dart
│   │   │   └── vista_theme.dart
│   │   ├── features/
│   │   │   ├── account/  — `AccountState` (has the user listed a market, and its ticker; `--dart-define=HAS_MARKET=true` starts with one) and the signed-in user's top bar (avatar, handle over portfolio balance, + Deposit; settings gear on Portfolio) shared by Home and Portfolio
│   │   │   │   ├── account_state.dart
│   │   │   │   └── account_top_bar.dart
│   │   │   ├── arena/  — Arena tab (Figma 505:204): an X-style feed under the account bar and sort chips: a sideways carousel of live battles (`BattleTile`, top three; tap opens the clash detail; "See all" opens `live_battles_screen.dart`, every battle as a flush row sorted by Most takes / Closing soon / Closest split), then flush take rows (`take_card.dart`) — a take is on a battle (battle chip) or a plain call on a market (market chip), backed takes carry their live position, with agree, joined count and Join (opens the order ticket); a floating + in the lower right (above the nav) opens `pick_position_screen.dart`, the viewer's open positions; tapping one opens `compose_take_screen.dart`, an X-style composer (Cancel / Post, avatar beside the text, the position's live card under it); Post adds the call to `CallsStore`; "Make it a battle" under the position card opens `BattleSetupScreen` in `battle_builder.dart` (Figma 517:205), its own page: statements that follow the position's side (long: closes above / touches / stays above / ends higher; short: closes below / touches / stays below / ends lower; first picked), the battle as a sentence with tappable parts, a typed level (grouped digits) with shortcuts, deadline chips (today, Fri, next week, next month) and the side set by the position; statements sit on one sideways-scrolling line and the statement in the sentence is not a button; it returns a `BattleSpec` the composer shows with Edit / Remove, and Start battle also adds the battle to `BattlesStore` (in `calls_store.dart`), which the carousel and Live battles read. The clash detail (`opinions_screen.dart`) keeps side filters and a consensus dock (mock data)
│   │   │   │   ├── arena_mock.dart
│   │   │   │   ├── arena_screen.dart
│   │   │   │   ├── battle_builder.dart
│   │   │   │   ├── compose_take_screen.dart
│   │   │   │   ├── live_battles_screen.dart
│   │   │   │   ├── opinions_mock.dart
│   │   │   │   ├── opinions_screen.dart
│   │   │   │   ├── pick_position_screen.dart
│   │   │   │   └── take_card.dart
│   │   │   ├── calls/
│   │   │   │   └── calls_store.dart  — `CallsStore`, the one in-memory list of published calls (seeded from `ArenaMock.takes` plus the Home cards in `mockFeed`): Arena's feed shows all of them, backed first then newest; each trade page's Callers panel shows the backed calls on its asset; a take posted from Arena lands in both; `app/lib/features/home/home_feed.dart` (`HomeFeed`) ranks them for Home's Following and For You tabs (√engagement × freshness, ×1.5 for people you follow, ×1.2 when backed; your just-posted call first) and builds a replay card for calls without one
│   │   │   ├── home/  — Home swipe feed: one call card per market Explore offers (5 assets + 7 trader markets; ETH is the Figma card), each with its own `ReplayScript` (price path, call line, events; generated from a seed for all but ETH) played by the signal replay chart (line, or candles when chosen in Settings › Display; a camera opens on the first candle and pulls back; candles grow in a wave; paced by `replay_timeline.dart`, ringed entrances, haptics, labels placed clear of each other and the activity rows; header price and % since call replay in step; then live on the market's price); Details opens the asset or trader market (mock data)
│   │   │   │   ├── active_replay.dart
│   │   │   │   ├── home_feed.dart
│   │   │   │   ├── home_screen.dart
│   │   │   │   ├── likes_state.dart
│   │   │   │   ├── live_fills_stream.dart
│   │   │   │   ├── mock_trade_idea.dart
│   │   │   │   ├── people_in_sheet.dart
│   │   │   │   ├── replay_script.dart
│   │   │   │   ├── replay_timeline.dart
│   │   │   │   ├── signal_replay_chart.dart
│   │   │   │   └── trade_idea_card.dart
│   │   │   ├── live/  — simulated live feed (off under `flutter test`) that nudges headline figures so they roll their digits (Figma 108:125); `MarketPrices` is the one live price per market that every screen reads, so any two screens always agree
│   │   │   │   ├── live_feed.dart
│   │   │   │   └── market_prices.dart
│   │   │   ├── make_market/  — make-a-market flow (create → before you list → live with confetti burst), opened from Portfolio when the user has no market
│   │   │   │   ├── make_market_flow.dart
│   │   │   │   └── make_market_mock.dart
│   │   │   ├── market/  — Your market screen (from Portfolio), Trader market screen (from a profile) and `chart_sheet.dart`, the shared chart + drag-up panel layout also used by asset trade (mock data)
│   │   │   │   ├── chart_sheet.dart
│   │   │   │   ├── market_mock.dart
│   │   │   │   ├── trader_market_chart.dart
│   │   │   │   ├── trader_market_mock.dart
│   │   │   │   ├── trader_market_screen.dart
│   │   │   │   └── your_market_screen.dart
│   │   │   ├── markets/  — Explore tab: Assets / Traders market lists with search, sort chips and favourites (mock data)
│   │   │   │   ├── markets_mock.dart
│   │   │   │   └── markets_screen.dart
│   │   │   ├── people/  — Followers / Following lists (pushed from Portfolio chips) with search and follow toggles (mock data)
│   │   │   │   ├── follow_list_screen.dart
│   │   │   │   └── follow_mock.dart
│   │   │   ├── portfolio/  — Portfolio screen: swipeable portfolio / market-cap pager and chart (`series_chart.dart`: drawn from simulated history over the chosen span, the balance ending at its live value, in the Home line style), spans, fees, positions; tapping a position slides up its P/L sheet, whose chart is that market's price over the span ending at the live price, with take-profit / stop-loss steppers that move the chart lines and swap Close for a simulated Edit/save; Open orders tab lists resting limit orders as compact cards (fill price and distance from the mark, size, partial fill, TP/SL, reduce-only) with a one-tap simulated Cancel and Undo; without a market the chart drops the muted market line (mock data)
│   │   │   │   ├── open_order_card.dart
│   │   │   │   ├── orders_state.dart
│   │   │   │   ├── portfolio_mock.dart
│   │   │   │   ├── portfolio_pager.dart
│   │   │   │   ├── portfolio_screen.dart
│   │   │   │   ├── position_sheet.dart
│   │   │   │   └── series_chart.dart
│   │   │   ├── profile/  — another user's profile (from follow lists, callers and the Home card): header, market chart, holdings, call/arena receipts; private accounts without a market get the private layout (mock data)
│   │   │   │   ├── holdings_table.dart
│   │   │   │   ├── private_profile_screen.dart
│   │   │   │   ├── profile_mock.dart
│   │   │   │   └── profile_screen.dart
│   │   │   ├── settings/  — Settings from the Portfolio gear (Figma 442:102 / 442:772): sections open in place; Notifications (backend `NotificationPrefs` + per-trader switches), Display (`DisplayPrefs`: candles/line for every chart that draws both, Long button left/right on every Long/Short or Bull/Bear pair), Security (two-factor, trading permission), Legal and privacy (trade visibility, terms, region), Help; all changes simulated and on-device
│   │   │   │   ├── settings_mock.dart
│   │   │   │   ├── settings_screen.dart
│   │   │   │   └── settings_state.dart
│   │   │   ├── share/  — Share call (Figma 462:474): the Home card's Share opens a sheet previewing exactly what the recipient gets (`ShareCallCard`, the 1.91:1 link-preview image with the Vista mark, drawn with the replay line painter, over its title and link), and Messages, Telegram, X and Copy link targets; sending is simulated (Copy link copies)
│   │   │   │   ├── share_call_card.dart
│   │   │   │   └── share_call_sheet.dart
│   │   │   ├── trade/  — asset trade page (Home Details, Explore assets): live `PriceChart` (BTC 15m seeded from the Figma candles, other assets/intervals generated; interval chips and candle/line toggle work) with Market / Book / Callers / Alerts panels (`asset_alerts.dart`: the Home feed's alerts on that market — the call, its replay events and live fills — as a newest-first timeline); Callers is a read-only post thread of the backed calls on that asset from `CallsStore` (the same calls as Arena) (each caller's reasoning over their order and live P&L, in the market's own prices) filtered to Following or Everyone; tapping a post's order opens `CallerPlayScreen`, that call as a Home-style trade card (mock data); `order_ticket.dart` is the pro order sheet (Figma 218:608) that Long/Short opens on the trade pages and Arena (Join long / Join short): side, Market/Limit/Stop, leverage up to the market's cap, price with Mid, size in units or USD with a 0–100% slider, TP/SL, reduce-only, live margin, liquidation and fee; placing is simulated and limit/stop orders land in Portfolio › Open orders via `OrdersState`; `feed_order_ticket.dart` (a part of it) is the first-time ticket Home feed cards open (Figma 472:1359): the card's side, Market/Limit, 2x/5x/10x/custom leverage, a dollar amount, an entry-anchored TP/SL track and the price where the margin is lost
│   │   │   │   ├── asset_alerts.dart
│   │   │   │   ├── asset_trade_screen.dart
│   │   │   │   ├── caller_play_screen.dart
│   │   │   │   ├── caller_thread.dart
│   │   │   │   ├── candle_chart.dart
│   │   │   │   ├── feed_order_ticket.dart
│   │   │   │   ├── order_ticket.dart
│   │   │   │   └── trade_mock.dart
│   │   │   └── watchlist/  — favourites shared by every star: `WatchlistState` (assets = the backend's asset-follow relation; traders device-only) drives Explore's rows and Favorites rail, the asset and trader market page stars, and Edit favorites (drag to reorder, unstar with undo); in memory, simulated
│   │   │       ├── edit_favorites_screen.dart
│   │   │       └── watchlist_state.dart
│   │   ├── app_shell.dart  — tab shell with the capsule bottom nav (Home, Explore, Arena, Wallet): pages switch with a fade-through and keep their state; the nav is a floating glass pill
│   │   └── main.dart
│   ├── test/  — widget tests, including the multi-phone-size overflow checks
│   │   ├── charting_test.dart
│   │   ├── home_screen_test.dart
│   │   ├── replay_live_test.dart
│   │   └── rolling_number_test.dart
│   ├── tool/  — asset scripts: market-focus Portfolio chart from the Figma export; `app_icon/` renders the launcher icon (Figma 201:1939) and cuts iOS/Android sizes
│   │   ├── app_icon/
│   │   │   ├── app_icon_1024.png
│   │   │   ├── make_icons.py
│   │   │   ├── mark_fill.svg
│   │   │   └── render_app_icon_test.dart
│   │   └── tabular_digits.py
│   ├── .gitignore
│   ├── .metadata
│   ├── analysis_options.yaml
│   ├── pubspec.lock
│   ├── pubspec.yaml
│   └── README.md
├── docs/
│   ├── agents/  — issue tracker, triage labels, and domain-document configuration
│   │   ├── domain.md
│   │   ├── issue-tracker.md
│   │   └── triage-labels.md
│   ├── assets/  — animated Vista logo and reduced-motion fallback
│   │   ├── vista-logo-animated.gif
│   │   └── vista-logo-static.png
│   ├── prompts/
│   │   └── social-market-demo-brief-prompt.md
│   └── backend-data-map.md
├── .gitignore
├── ARCH.md  — generated file tree with curated architecture notes
├── CONTEXT.md  — project acronyms, vocabulary, and reference repositories
└── README.md  — project presentation and animated Vista logo
```

_Generated by `.githooks/gen_arch.py` — do not edit inside the ARCH:TREE markers._
<!-- ARCH:TREE:END -->
