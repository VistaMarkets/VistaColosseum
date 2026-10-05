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
(`yIxjFkwJAwBa07RgSmVv1D`, frames 301:102 Home, 174:110 Portfolio, 168:110 Your market, 308:102/308:244 Follow lists, 303:102 Profile, 236:102/237:*/241:102 Trader market 185:110/222:110 Markets, 33:2 Arena, 48:430 Clash detail 206:110/214:* Asset trade 104:110 Position sheet 258:407 Private profile and 175:218/338:102/329:102/348:624 Make a market); that file defines no Figma variables,
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
- `docs/prd/` — hackathon requirements, delivery roadmap, and dated evidence register
- `docs/assets/` — animated Vista logo and reduced-motion fallback
- `app/` — Flutter demo app (iOS and Android)
- `app/lib/design_system/` — Vista tokens, theme and shared components; import `design_system.dart`
- `app/lib/charting/` — candle chart engine; import `charting.dart`: `Candle` (OHLC in prices), `PriceScale` + `roundTicks` (round-number gridlines), `timeMarks` (clock-boundary time labels), `LiveCandles` (newest candle follows a `LiveFeed` value), `sampleCandles` (seeded generated history) and the `PriceChart` widget (hollow candles or line)
- `app/lib/app_shell.dart` — tab shell with the capsule bottom nav (Home, Explore, Arena, Wallet): pages switch with a fade-through and keep their state; one bottom dock where the Arena crowd panel folds open above the nav
- `app/lib/features/people/` — Followers / Following lists (pushed from Portfolio chips) with search and follow toggles (mock data)
- `app/lib/features/profile/` — another user's profile (from follow lists, callers and the Home card): header, market chart, holdings, call/arena receipts; private accounts without a market get the private layout (mock data)
- `app/lib/features/portfolio/` — Portfolio screen: swipeable portfolio / market-cap pager and chart (`series_chart.dart`: drawn from simulated history over the chosen span, the balance ending at its live value, in the Home line style), spans, fees, positions; tapping a position slides up its P/L sheet, whose chart is that market's price over the span ending at the live price, with take-profit / stop-loss steppers that move the chart lines and swap Close for a simulated Edit/save; Open orders tab lists resting limit orders as compact cards (fill price and distance from the mark, size, partial fill, TP/SL, reduce-only) with a one-tap simulated Cancel and Undo; without a market the chart drops the muted market line (mock data)
- `app/lib/features/live/` — simulated live feed (off under `flutter test`) that nudges headline figures so they roll their digits (Figma 108:125); `MarketPrices` is the one live price per market that every screen reads, so any two screens always agree
- `app/lib/features/make_market/` — make-a-market flow (create → before you list → live with confetti burst), opened from Portfolio when the user has no market
- `app/lib/features/markets/` — Explore tab: Assets / Traders market lists with search, sort chips and favourites (mock data)
- `app/lib/features/market/` — Your market screen (from Portfolio), Trader market screen (from a profile) and `chart_sheet.dart`, the shared chart + drag-up panel layout also used by asset trade (mock data)
- `app/lib/features/account/` — `AccountState` (has the user listed a market, and its ticker; `--dart-define=HAS_MARKET=true` starts with one) and the signed-in user's top bar (avatar, handle over portfolio balance, + Deposit; settings gear on Portfolio) shared by Home and Portfolio
- `app/lib/features/arena/` — Arena tab: Bull vs Bear battle cards; the crowd-split histogram and range filter wrap the bottom nav; "more opinions" opens the clash detail with side filters and a consensus dock (mock data)
- `app/lib/features/share/` — Share call (Figma 462:474): the Home card's Share opens a sheet previewing exactly what the recipient gets (`ShareCallCard`, the 1.91:1 link-preview image with the Vista mark, drawn with the replay line painter, over its title and link), and Messages, Telegram, X and Copy link targets; sending is simulated (Copy link copies)
- `app/lib/features/settings/` — Settings from the Portfolio gear (Figma 442:102 / 442:772): sections open in place; Notifications (backend `NotificationPrefs` + per-trader switches), Display (`DisplayPrefs`: candles/line for every chart that draws both, Long button left/right on every Long/Short or Bull/Bear pair), Security (two-factor, trading permission), Legal and privacy (trade visibility, terms, region), Help; all changes simulated and on-device
- `app/lib/features/watchlist/` — favourites shared by every star: `WatchlistState` (assets = the backend's asset-follow relation; traders device-only) drives Explore's rows and Favorites rail, the asset and trader market page stars, and Edit favorites (drag to reorder, unstar with undo); in memory, simulated
- `app/lib/features/trade/` — asset trade page (Home Details, Explore assets): live `PriceChart` (BTC 15m seeded from the Figma candles, other assets/intervals generated; interval chips and candle/line toggle work) with Market / Book / Callers / Alerts panels (`asset_alerts.dart`: the Home feed's alerts on that market — the call, its replay events and live fills — as a newest-first timeline); Callers is a read-only post thread (each caller's reasoning over their order and live P&L, in the market's own prices) filtered to Following or Everyone; tapping a post's order opens `CallerPlayScreen`, that call as a Home-style trade card (mock data); `order_ticket.dart` is the pro order sheet (Figma 218:608) that Long/Short opens on the trade pages and Arena (Bull = long, Bear = short): side, Market/Limit/Stop, leverage up to the market's cap, price with Mid, size in units or USD with a 0–100% slider, TP/SL, reduce-only, live margin, liquidation and fee; placing is simulated and limit/stop orders land in Portfolio › Open orders via `OrdersState`; `feed_order_ticket.dart` (a part of it) is the first-time ticket Home feed cards open (Figma 472:1359): the card's side, Market/Limit, 2x/5x/10x/custom leverage, a dollar amount, an entry-anchored TP/SL track and the price where the margin is lost
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
│   │       └── OpenRunde-Semibold.otf
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
│   │   │   │   ├── vista_icon.dart
│   │   │   │   ├── vista_list_row.dart
│   │   │   │   ├── vista_market.dart
│   │   │   │   ├── vista_navigation.dart
│   │   │   │   ├── vista_people.dart
│   │   │   │   ├── vista_profile.dart
│   │   │   │   ├── vista_rolling_number.dart
│   │   │   │   └── vista_settings.dart
│   │   │   ├── tokens/
│   │   │   │   ├── vista_colors.dart
│   │   │   │   ├── vista_metrics.dart
│   │   │   │   └── vista_typography.dart
│   │   │   ├── design_system.dart
│   │   │   ├── vista_assets.dart
│   │   │   └── vista_theme.dart
│   │   ├── features/
│   │   │   ├── account/  — `AccountState` (has the user listed a market, and its ticker; `--dart-define=HAS_MARKET=true` starts with one) and the signed-in user's top bar (avatar, handle over portfolio balance, + Deposit; settings gear on Portfolio) shared by Home and Portfolio
│   │   │   │   ├── account_state.dart
│   │   │   │   └── account_top_bar.dart
│   │   │   ├── arena/  — Arena tab: Bull vs Bear battle cards; the crowd-split histogram and range filter wrap the bottom nav; "more opinions" opens the clash detail with side filters and a consensus dock (mock data)
│   │   │   │   ├── arena_mock.dart
│   │   │   │   ├── arena_screen.dart
│   │   │   │   ├── crowd_filter_panel.dart
│   │   │   │   ├── opinions_mock.dart
│   │   │   │   └── opinions_screen.dart
│   │   │   ├── home/  — Home swipe feed: one call card per market Explore offers (5 assets + 7 trader markets; ETH is the Figma card), each with its own `ReplayScript` (price path, call line, events; generated from a seed for all but ETH) played by the signal replay chart (line, or candles when chosen in Settings › Display; a camera opens on the first candle and pulls back; candles grow in a wave; paced by `replay_timeline.dart`, ringed entrances, haptics, labels placed clear of each other and the activity rows; header price and % since call replay in step; then live on the market's price); Details opens the asset or trader market (mock data)
│   │   │   │   ├── active_replay.dart
│   │   │   │   ├── home_screen.dart
│   │   │   │   ├── likes_state.dart
│   │   │   │   ├── live_fills_stream.dart
│   │   │   │   ├── maker_suggestion.dart
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
│   │   │   │   ├── confetti_burst.dart
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
│   │   │   ├── simulation/
│   │   │   │   └── simulation_indicator.dart
│   │   │   ├── trade/  — asset trade page (Home Details, Explore assets): live `PriceChart` (BTC 15m seeded from the Figma candles, other assets/intervals generated; interval chips and candle/line toggle work) with Market / Book / Callers / Alerts panels (`asset_alerts.dart`: the Home feed's alerts on that market — the call, its replay events and live fills — as a newest-first timeline); Callers is a read-only post thread (each caller's reasoning over their order and live P&L, in the market's own prices) filtered to Following or Everyone; tapping a post's order opens `CallerPlayScreen`, that call as a Home-style trade card (mock data); `order_ticket.dart` is the pro order sheet (Figma 218:608) that Long/Short opens on the trade pages and Arena (Bull = long, Bear = short): side, Market/Limit/Stop, leverage up to the market's cap, price with Mid, size in units or USD with a 0–100% slider, TP/SL, reduce-only, live margin, liquidation and fee; placing is simulated and limit/stop orders land in Portfolio › Open orders via `OrdersState`; `feed_order_ticket.dart` (a part of it) is the first-time ticket Home feed cards open (Figma 472:1359): the card's side, Market/Limit, 2x/5x/10x/custom leverage, a dollar amount, an entry-anchored TP/SL track and the price where the margin is lost
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
│   │   ├── scenario/
│   │   │   └── scenario.dart
│   │   ├── app_shell.dart  — tab shell with the capsule bottom nav (Home, Explore, Arena, Wallet): pages switch with a fade-through and keep their state; one bottom dock where the Arena crowd panel folds open above the nav
│   │   └── main.dart
│   ├── test/  — widget tests, including the multi-phone-size overflow checks
│   │   ├── charting_test.dart
│   │   ├── home_screen_test.dart
│   │   ├── order_ticket_test.dart
│   │   ├── replay_live_test.dart
│   │   ├── rolling_number_test.dart
│   │   └── scenario_test.dart
│   ├── tool/  — asset scripts: market-focus Portfolio chart from the Figma export; `app_icon/` renders the launcher icon (Figma 201:1939) and cuts iOS/Android sizes
│   │   └── app_icon/
│   │       ├── app_icon_1024.png
│   │       ├── make_icons.py
│   │       ├── mark_fill.svg
│   │       └── render_app_icon_test.dart
│   ├── .gitignore
│   ├── .metadata
│   ├── analysis_options.yaml
│   ├── pubspec.lock
│   ├── pubspec.yaml
│   └── README.md
├── baton-pass/
│   ├── baton-queue/
│   │   └── 2026-10-04T233424-p0-runner-paused-phase3-review.md
│   └── br-2026-10-04-p0-queue/
│       ├── 2026-10-04T095606-phase1-scenario-store-checkpoint.md
│       ├── 2026-10-04T095757-phase1-scenario-store-half1.md
│       ├── 2026-10-04T100456-phase1-scenario-store-half2-red.md
│       ├── 2026-10-04T101019-phase1-scenario-store-half2.md
│       ├── 2026-10-04T105011-phase1-review-iter1.md
│       ├── 2026-10-04T105911-phase1-fix-iter1.md
│       ├── 2026-10-04T114637-phase1-review-iter2.md
│       ├── 2026-10-04T115639-phase2-order-store-checkpoint.md
│       ├── 2026-10-04T120621-phase2-truthful-order-confirm.md
│       ├── 2026-10-04T124925-phase2-review-iter1.md
│       ├── 2026-10-04T125834-phase2-fix-iter1.md
│       ├── 2026-10-04T135405-phase2-review-iter2.md
│       ├── 2026-10-04T140130-phase2-fix-iter2.md
│       ├── 2026-10-04T150315-phase2-review-iter3.md
│       ├── 2026-10-04T151112-phase3-simulation-indicator-checkpoint.md
│       ├── 2026-10-04T151800-phase3-simulation-indicator.md
│       ├── 2026-10-04T161405-phase3-review-iter1.md
│       ├── 2026-10-04T162325-phase3-fix-iter1-checkpoint.md
│       ├── 2026-10-04T162846-phase3-fix-iter1.md
│       ├── 2026-10-04T181055-phase3-review-iter2.md
│       ├── 2026-10-04T184857-phase3-close.md
│       ├── 2026-10-04T190310-phase4-arena-checkpoint.md
│       ├── 2026-10-04T190946-phase4-arena-sort-filter-join.md
│       ├── 2026-10-04T191813-phase4-review-iter1.md
│       ├── 2026-10-04T195458-phase4-close.md
│       ├── 2026-10-04T200724-phase5-maker-suggestion-checkpoint.md
│       ├── 2026-10-04T201217-phase5-maker-suggestion-green.md
│       ├── 2026-10-04T201519-phase5-maker-suggestion-card.md
│       └── 2026-10-04T202626-phase5-review-iter1.md
├── baton-runner/
│   └── br-2026-10-04-p0-queue/
│       ├── fix-phase-2-iter-2/
│       │   ├── gate/
│       │   │   ├── flutter-analyze.log
│       │   │   ├── flutter-test.log
│       │   │   └── pubspec-frozen.log
│       │   ├── flutter-analyze.log
│       │   ├── flutter-test-has-market.log
│       │   ├── flutter-test.log
│       │   ├── green-targeted.log
│       │   ├── mutant-A-confirm-guard.log
│       │   ├── mutant-B-retry-guard.log
│       │   ├── mutant-C-market-only-notBuilt.log
│       │   ├── mutant-D-fee-round.log
│       │   ├── mutant-E-units-isFinite.log
│       │   ├── mutant-F-retry-any-failure.log
│       │   └── red.log
│       ├── gate-phase-1-iter-1/
│       │   ├── flutter-analyze.log
│       │   ├── flutter-test.log
│       │   └── pubspec-frozen.log
│       ├── gate-phase-1-iter-2/
│       │   ├── extra-flutter-test-has-market-true.log
│       │   ├── flutter-analyze.log
│       │   ├── flutter-test.log
│       │   └── pubspec-frozen.log
│       ├── gate-phase-2-fix-1/
│       │   ├── flutter-analyze.log
│       │   ├── flutter-test-has-market.log
│       │   ├── flutter-test.log
│       │   └── pubspec-frozen.log
│       ├── gate-phase-2-iter-1/
│       │   ├── console.txt
│       │   ├── flutter-analyze.log
│       │   ├── flutter-test-has-market.log
│       │   ├── flutter-test.log
│       │   └── pubspec-frozen.log
│       ├── gate-phase-2-iter-2/
│       │   ├── h1-probe/
│       │   │   ├── h1-probe.log
│       │   │   ├── h1_probe_test.dart
│       │   │   └── overflow_probe_test.dart
│       │   ├── console.txt
│       │   ├── flutter-analyze.log
│       │   ├── flutter-test-has-market.log
│       │   ├── flutter-test.log
│       │   └── pubspec-frozen.log
│       ├── gate-phase-2-iter-3/
│       │   ├── has-market/
│       │   │   └── flutter-test-has-market.log
│       │   ├── probe/
│       │   │   ├── iter3-probe.log
│       │   │   └── iter3_probe_test.dart
│       │   ├── review-probes/
│       │   │   ├── architect-reviewer/
│       │   │   │   ├── arch-probe.log
│       │   │   │   ├── arch-probe2.log
│       │   │   │   ├── arch_probe2_test.dart
│       │   │   │   └── arch_probe_test.dart
│       │   │   ├── code-reviewer/
│       │   │   │   ├── cr_changeline_probe.log
│       │   │   │   ├── cr_changeline_probe_test.dart
│       │   │   │   ├── cr_iter3_probe.log
│       │   │   │   ├── cr_iter3_probe_test.dart
│       │   │   │   ├── cr_nofont_probe.log
│       │   │   │   ├── cr_nofont_probe_test.dart
│       │   │   │   └── parse_cents_probe.dart
│       │   │   ├── critical-thinking/
│       │   │   │   ├── ct-probe.log
│       │   │   │   ├── ct_probe2_test.dart
│       │   │   │   └── ct_probe_test.dart
│       │   │   ├── fintech-engineer/
│       │   │   │   ├── fintech-probe.log
│       │   │   │   ├── fintech-probe2.log
│       │   │   │   ├── fintech_probe2_test.dart
│       │   │   │   ├── fintech_probe_test.dart
│       │   │   │   └── parse_cents.dart
│       │   │   ├── silent-failure-hunter/
│       │   │   │   ├── sfh-overflow-probe.log
│       │   │   │   ├── sfh-probe.log
│       │   │   │   ├── sfh_overflow_probe_test.dart
│       │   │   │   ├── sfh_probe_test.dart
│       │   │   │   └── wrap.dart
│       │   │   └── tdd-guide/
│       │   │       └── tdd_probe_test.dart
│       │   ├── flutter-analyze.log
│       │   ├── flutter-test.log
│       │   └── pubspec-frozen.log
│       ├── gate-phase-3-close/
│       │   ├── flutter-analyze.log
│       │   ├── flutter-test.log
│       │   ├── gate-stdout.log
│       │   └── pubspec-frozen.log
│       ├── gate-phase-3-fix-1/
│       │   ├── flutter-analyze.log
│       │   ├── flutter-test-has-market.log
│       │   ├── flutter-test.log
│       │   ├── gate.out
│       │   └── pubspec-frozen.log
│       ├── gate-phase-3-fixer/
│       │   ├── flutter-analyze.log
│       │   ├── flutter-test.log
│       │   └── pubspec-frozen.log
│       ├── gate-phase-3-iter-1/
│       │   ├── flutter-analyze.log
│       │   ├── flutter-test-has-market.log
│       │   ├── flutter-test.log
│       │   └── pubspec-frozen.log
│       ├── gate-phase-3-iter-2/
│       │   ├── flutter-analyze.log
│       │   ├── flutter-test-has-market.log
│       │   ├── flutter-test.log
│       │   └── pubspec-frozen.log
│       ├── gate-phase-3-work/
│       │   ├── flutter-analyze.log
│       │   ├── flutter-test.log
│       │   └── pubspec-frozen.log
│       ├── gate-phase-4-close/
│       │   ├── flutter-analyze.log
│       │   ├── flutter-test.log
│       │   ├── gate-stdout.log
│       │   └── pubspec-frozen.log
│       ├── gate-phase-4-fixer/
│       │   ├── flutter-analyze.log
│       │   ├── flutter-test.log
│       │   └── pubspec-frozen.log
│       ├── gate-phase-4-iter-1/
│       │   ├── flutter-analyze.log
│       │   ├── flutter-test-has-market.log
│       │   ├── flutter-test.log
│       │   └── pubspec-frozen.log
│       ├── gate-phase-4-work/
│       │   ├── flutter-analyze.log
│       │   ├── flutter-test-has-market.log
│       │   ├── flutter-test.log
│       │   └── pubspec-frozen.log
│       ├── gate-phase-5-iter-1/
│       │   ├── flutter-analyze.log
│       │   ├── flutter-test.log
│       │   ├── pubspec-frozen.log
│       │   └── test-has-market.log
│       ├── gate-phase-5-work/
│       │   ├── flutter-analyze.log
│       │   ├── flutter-test.log
│       │   └── pubspec-frozen.log
│       ├── phase-4-red/
│       │   ├── home-green-1.log
│       │   ├── home-red-1.log
│       │   ├── scenario-green-1.log
│       │   └── scenario-red-1.log
│       ├── phase-5-red/
│       │   ├── full-1.log
│       │   ├── green-1.log
│       │   ├── green-2.log
│       │   ├── green-3.log
│       │   ├── mutation.log
│       │   ├── red-1-compile.log
│       │   └── red-2-assert.log
│       ├── phase-5-verify/
│       │   ├── analyze.log
│       │   ├── test-has-market.log
│       │   └── test.log
│       ├── review-phase-3-iter-2-probe/
│       │   ├── cta_probe.log
│       │   ├── cta_probe_test.dart
│       │   ├── h1_probe.log
│       │   ├── h1_probe_test.dart
│       │   ├── mm_probe_head.log
│       │   ├── mm_probe_main.log
│       │   ├── mm_probe_test.dart
│       │   ├── mut-AC1-AC2-no-padding-reserve-home_screen_test.log
│       │   ├── mut-AC1-AC2-no-pill-in-builder-home_screen_test.log
│       │   ├── mut-AC1-AC2-no-pill-in-builder-scenario_test.log
│       │   ├── mut-AC3-blank-simulated-label-order_ticket_test.log
│       │   ├── mut-H1-revert-isScrollControlled-home_screen_test.log
│       │   ├── mut-H1-revert-probe.log
│       │   ├── mut-M2-no-popUntil-home_screen_test.log
│       │   ├── mut-M2-no-popUntil-scenario_test.log
│       │   ├── mutate.py
│       │   ├── settings_reset_probe.log
│       │   └── settings_reset_probe_test.dart
│       ├── review-phase-4-iter-1-probe/
│       │   ├── arena_layout_probe.log
│       │   ├── arena_layout_probe_test.dart
│       │   ├── mut-arena-no-clashId-home_screen_test.log
│       │   ├── mut-ask-field-ignores-reset-home_screen_test.log
│       │   ├── mut-ask-no-filter-home_screen_test.log
│       │   ├── mut-buckets-constant-home_screen_test.log
│       │   ├── mut-card-ignores-joins-home_screen_test.log
│       │   ├── mut-failure-joins-scenario_test.log
│       │   ├── mut-joins-ignore-side-scenario_test.log
│       │   ├── mut-label-dock-home_screen_test.log
│       │   ├── mut-label-header-home_screen_test.log
│       │   ├── mut-label-panel-home_screen_test.log
│       │   ├── mut-list-ignores-range-home_screen_test.log
│       │   ├── mut-no-participation-write-home_screen_test.log
│       │   ├── mut-no-participation-write-scenario_test.log
│       │   ├── mut-opinions-hardcode-btc-home_screen_test.log
│       │   ├── mut-opinions-no-clashId-home_screen_test.log
│       │   ├── mut-panel-counts-all-home_screen_test.log
│       │   ├── mut-replay-not-deduped-scenario_test.log
│       │   ├── mut-reset-keeps-arena-scenario_test.log
│       │   ├── mut-reset-keeps-participation-scenario_test.log
│       │   ├── mut-show-all-noop-home_screen_test.log
│       │   ├── mut-sort-chips-all-volume-home_screen_test.log
│       │   ├── mut-sort-no-tiebreak-home_screen_test.log
│       │   └── mutate.py
│       ├── review-phase-5-iter-1-probe/
│       │   ├── maker_probe.log
│       │   ├── maker_probe_test.dart
│       │   ├── mut-badge-text.log
│       │   ├── mut-both-live.log
│       │   ├── mut-card-overflow.log
│       │   ├── mut-clock-constant.log
│       │   ├── mut-clock-wallclock.log
│       │   ├── mut-clock-write-on-trade.log
│       │   ├── mut-drop-data-path.log
│       │   ├── mut-drop-reference-line.log
│       │   ├── mut-expired-says-trade-this.log
│       │   ├── mut-no-semantics-container.log
│       │   ├── mut-suggestions-adjacent.log
│       │   ├── mut-vpb-ignores-enabled.log
│       │   ├── mut-wrong-asset.log
│       │   ├── mutate-run-1.txt
│       │   ├── mutate-run-2.txt
│       │   └── mutate.py
│       ├── digest-phase-1.md
│       ├── digest-phase-2.md
│       ├── digest-phase-3.md
│       ├── digest-phase-4.md
│       ├── fixer-phase-3.json
│       ├── fixer-phase-4.json
│       ├── house-rules.md
│       ├── log.md
│       ├── review-phase-1-iter-1-prelude.md
│       ├── review-phase-1-iter-1.md
│       ├── review-phase-1-iter-2-prelude.md
│       ├── review-phase-1-iter-2.md
│       ├── review-phase-2-iter-1.md
│       ├── review-phase-2-iter-2-prelude.md
│       ├── review-phase-2-iter-2.md
│       ├── review-phase-2-iter-3.md
│       ├── review-phase-3-dw.json
│       ├── review-phase-3-iter-1-prelude.md
│       ├── review-phase-3-iter-1.md
│       ├── review-phase-4-dw.json
│       ├── review-phase-5-dw.json
│       └── STATE.md
├── docs/
│   ├── agents/  — issue tracker, triage labels, and domain-document configuration
│   │   ├── domain.md
│   │   ├── issue-tracker.md
│   │   └── triage-labels.md
│   ├── assets/  — animated Vista logo and reduced-motion fallback
│   │   ├── vista-logo-animated.gif
│   │   └── vista-logo-static.png
│   ├── prd/  — hackathon requirements, delivery roadmap, and dated evidence register
│   │   ├── 2026-10-01-vc-hackathon-evidence.md
│   │   ├── 2026-10-01-vc-hackathon-master-prd.md
│   │   ├── 2026-10-01-vc-hackathon-roadmap.md
│   │   └── 2026-10-04-open-decisions-recommendations.md
│   ├── prompts/
│   │   └── social-market-demo-brief-prompt.md
│   ├── reviews/
│   │   ├── 2026-10-04-dw-review-phase-3-simulation-indicator.md
│   │   ├── 2026-10-04-dw-review-phase-4-arena-sort-filter-join.md
│   │   └── 2026-10-04-spec-00-baton-queue-review.md
│   └── specs/
│       ├── 00-baton-queue.md
│       ├── 01-scenario-store.md
│       ├── 02-truthful-order-confirm.md
│       ├── 03-simulation-indicator.md
│       ├── 04-arena-sort-filter-join.md
│       ├── 05-maker-suggestion-card.md
│       ├── 06-fee-ledger-and-receipts.md
│       ├── 07-trader-record-panel.md
│       ├── 08-list-empty-failed-states.md
│       └── 09-copy-story.md
├── scripts/
│   └── gate.sh
├── .gitignore
├── ARCH.md  — generated file tree with curated architecture notes
├── CONTEXT.md  — project acronyms, vocabulary, and reference repositories
└── README.md  — project presentation and animated Vista logo
```

_Generated by `.githooks/gen_arch.py` — do not edit inside the ARCH:TREE markers._
<!-- ARCH:TREE:END -->
