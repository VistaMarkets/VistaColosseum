/// Paths to vector assets exported from Figma (file yIxjFkwJAwBa07RgSmVv1D).
///
/// Nav icons are single-colour glyphs, tinted by selection state.
abstract final class VistaAssets {
  static const String _dir = 'assets/figma';

  // Icons.
  static const String referral = '$_dir/referral_button.svg';
  static const String notifications = '$_dir/notif_bell.svg';
  static const String back = '$_dir/back_chevron.svg';
  static const String backSmall = '$_dir/back_chevron_small.svg';
  static const String search = '$_dir/search.svg';
  static const String search16 = '$_dir/search_16.svg';
  static const String bell = '$_dir/bell.svg';
  static const String settings = '$_dir/settings.svg';
  static const String topBarAvatar = '$_dir/topbar_avatar.svg';
  static const String lock = '$_dir/lock.svg';
  static const String lockSmall = '$_dir/lock_small.svg';
  static const String lockNotice = '$_dir/lock_notice.svg';
  static const String longArrow = '$_dir/long_arrow.svg';
  static const String navHome = '$_dir/nav_home.svg';
  static const String navExplore = '$_dir/nav_compass.svg';
  static const String navPeople = '$_dir/nav_people.svg';
  static const String navWallet = '$_dir/nav_wallet.svg';

  // Social rail buttons (circle + glyph).
  static const String like = '$_dir/like_button.svg';
  static const String traders = '$_dir/traders_button.svg';
  static const String share = '$_dir/share_button.svg';

  // Avatars and coins (placeholders from the mock).
  static const String personAvatar = '$_dir/person_avatar.svg';
  static const String profileAvatar = '$_dir/profile_avatar.svg';
  static const String callerAvatar = '$_dir/caller_avatar.svg';
  static const String coinEth = '$_dir/coin_eth.svg';
  static const String fillAvatar1 = '$_dir/fill_avatar_1.svg';
  static const String fillAvatar2 = '$_dir/fill_avatar_2.svg';
  static const String fillAvatar3 = '$_dir/fill_avatar_3.svg';

  // Portfolio.
  static const String portfolioAvatar = '$_dir/portfolio_avatar.svg';
  static const String pagerDots = '$_dir/pager_dots.svg';
  static const String pagerDotsMarket = '$_dir/pager_dots_market.svg';
  static const String portfolioChart = '$_dir/portfolio_chart.svg';

  /// [portfolioChart] with the user's market in focus; derived from it by
  /// `tool/derive_market_focus_chart.py` so the two crossfade cleanly.
  static const String portfolioChartMarketFocus =
      '$_dir/portfolio_chart_market_focus.svg';
  // Your market (Figma 168:110): market-cap chart on a 370×150 box, holder
  // avatars and record timeline rails.
  static const String marketDotLattice = '$_dir/market_dot_lattice.svg';
  static const String marketBaseline = '$_dir/market_baseline.svg';
  static const String marketClipAbove = '$_dir/market_clip_above.svg';
  static const String marketClipBelow = '$_dir/market_clip_below.svg';
  static const String marketLiveHalo = '$_dir/market_live_halo.svg';
  static const String holdersAvatars = '$_dir/holders_avatars.svg';
  static const String timelineRight = '$_dir/timeline_rail_right.svg';
  static const String timelineWrong = '$_dir/timeline_rail_wrong.svg';
  static const String timelineOpen = '$_dir/timeline_rail_open.svg';
  // Profile (Figma 303:102).
  static const String verdictsLast10 = '$_dir/verdicts_last10.svg';
  static const String profileDotLattice = '$_dir/profile_dot_lattice.svg';
  static const String profileBaseline = '$_dir/profile_baseline.svg';
  static const String profileClipAbove = '$_dir/profile_clip_above.svg';
  static const String profileClipBelow = '$_dir/profile_clip_below.svg';
  static const String coinSolSmall = '$_dir/coin_sol_20.svg';
  static const String coinEthSmall = '$_dir/coin_eth_20.svg';
  static const String coinBtcBackground = '$_dir/coin_btc_bg.svg';
  static const String coinCashBackground = '$_dir/coin_cash_bg.svg';
  static const String railCallOpen = '$_dir/rail_call_open.svg';
  static const String railCallRight = '$_dir/rail_call_right.svg';
  static const String railArenaOpen = '$_dir/rail_arena_open.svg';
  static const String railArenaRight = '$_dir/rail_arena_right.svg';
  static const String railArenaWrong = '$_dir/rail_arena_wrong.svg';
  static const String opponentAvatarLong = '$_dir/opponent_avatar_long.svg';
  static const String opponentAvatarShort = '$_dir/opponent_avatar_short.svg';
  // Trader market (Figma 236:102 chart open; 237/241 swiped up). The chart
  // is exported at two heights with different price scales: tall (506) when
  // the chart is open, short (196) when the panels are up.
  static const String traderAvatar = '$_dir/trader_avatar.svg';
  static const String star = '$_dir/star.svg';

  /// [star] filled in the favourite colour, for the watched state.
  static const String starFilled = '$_dir/star_filled.svg';
  static const String chevronBox = '$_dir/chevron_box.svg';
  static const String chartTypeToggle = '$_dir/chart_type_toggle.svg';
  static const String tmBaseline = '$_dir/tm_baseline.svg';
  static const String tmLastPrice = '$_dir/tm_last_price.svg';
  static const String tmTallLattice = '$_dir/tm_tall_lattice.svg';
  static const String tmTallClipAbove = '$_dir/tm_tall_clip_above.svg';
  static const String tmTallClipBelow = '$_dir/tm_tall_clip_below.svg';
  static const String tmShortLattice = '$_dir/tm_short_lattice.svg';
  static const String tmShortClipAbove = '$_dir/tm_short_clip_above.svg';
  static const String tmShortClipBelow = '$_dir/tm_short_clip_below.svg';
  static const String liveDotSmall = '$_dir/live_dot_small.svg';
  static const String railRecordOpen = '$_dir/rail_record_open.svg';
  static const String railRecordRight = '$_dir/rail_record_right.svg';
  static const String railRecordWrong = '$_dir/rail_record_wrong.svg';
  static const String holderAvatarLong = '$_dir/holder_avatar_long.svg';
  static const String holderAvatarShort = '$_dir/holder_avatar_short.svg';
  // Markets (Figma 185:110 Assets, 222:110 Traders). Coins come at 20pt for
  // the favourites rail and 22pt for list rows.
  static const String coinBtcRail = '$_dir/coin_btc_rail.svg';
  static const String coinEthRail = '$_dir/coin_eth_rail.svg';
  static const String coinSolRail = '$_dir/coin_sol_rail.svg';
  static const String coinBtcRow = '$_dir/coin_btc_row.svg';
  static const String coinEthRow = '$_dir/coin_eth_row.svg';
  static const String coinSolRow = '$_dir/coin_sol_row.svg';
  static const String coinArbRow = '$_dir/coin_arb_row.svg';
  static const String coinAvaxRow = '$_dir/coin_avax_row.svg';
  static const String traderAvatarRail = '$_dir/trader_avatar_rail.svg';
  static const String traderAvatarRow = '$_dir/trader_avatar_row.svg';
  static const String spark24UpA = '$_dir/spark24_up_a.svg';
  static const String spark24UpB = '$_dir/spark24_up_b.svg';
  static const String spark24Down = '$_dir/spark24_down.svg';
  // Arena (Figma 33:2).
  static const String battleAvatarBull = '$_dir/battle_avatar_bull.svg';
  static const String battleAvatarBear = '$_dir/battle_avatar_bear.svg';
  static const String opinionsAvatars = '$_dir/opinions_avatars.svg';
  // Clash detail / opinions (Figma 48:430).
  static const String initialsAvatar = '$_dir/initials_avatar_36.svg';
  // Asset trade (Figma 206:110 chart open; 214:110 / 214:428 / 214:746).
  static const String assetAvatar = '$_dir/asset_avatar_32.svg';
  static const String tradeLastPrice = '$_dir/trade_last_price.svg';
  static const String chartTypeCandles = '$_dir/chart_type_candles.svg';
  static const String rangeDot = '$_dir/range_dot.svg';
  static const String callerAvatarShort = '$_dir/caller_avatar_short_32.svg';
  // Position sheet (Figma 104:110).
  static const String positionAvatarEth = '$_dir/position_avatar_eth.svg';
  static const String positionLattice = '$_dir/position_lattice.svg';
  static const String positionTpLine = '$_dir/position_tp_line.svg';
  static const String positionSlLine = '$_dir/position_sl_line.svg';
  static const String positionClipAbove = '$_dir/position_clip_above.svg';
  static const String positionClipBelow = '$_dir/position_clip_below.svg';
  // Make a market (Figma 175:218 button, 338:102 create, 329:102 consent,
  // 348:624 live).
  static const String makeMarketButtonDots =
      '$_dir/make_market_button_dots.svg';
  static const String mmCardLattice = '$_dir/mm_card_lattice.svg';
  static const String mmPreviewChart = '$_dir/mm_preview_chart.svg';
  static const String mmImageGlow = '$_dir/mm_image_glow.svg';
  static const String mmImageInner = '$_dir/mm_image_inner.svg';
  static const String mmAddImage = '$_dir/mm_add_image.svg';
  static const String termsDashedLine = '$_dir/terms_dashed_line.svg';
  static const String mmLiveLattice = '$_dir/mm_live_lattice.svg';
  static const String mmLiveAvatar = '$_dir/mm_live_avatar.svg';
  static const String feesDot = '$_dir/fees_dot.svg';
  static const String coinPlaceholder = '$_dir/coin_placeholder.svg';
  static const String sparkEth = '$_dir/spark_eth.svg';
  static const String sparkSol = '$_dir/spark_sol.svg';
  static const String spark0xreal = '$_dir/spark_0xreal.svg';

  // Signal replay chart layers (drawn on a 360×403 canvas in Figma).
  static const String chartDotLattice = '$_dir/dot_lattice.svg';
  static const String chartBaseline = '$_dir/baseline_entry.svg';
  static const String chartAboveEntry = '$_dir/clip_above_entry.svg';
  static const String chartBelowEntry = '$_dir/clip_below_entry.svg';
  static const String markerEntry = '$_dir/marker_entry.svg';
  static const String markerFunding = '$_dir/marker_funding.svg';
  static const String markerWhale = '$_dir/marker_whale.svg';
  static const String markerBreakoutHalo = '$_dir/marker_breakout_halo.svg';
  static const String markerBreakout = '$_dir/marker_breakout.svg';
  static const String markerLiveHalo = '$_dir/marker_live_halo.svg';
  static const String markerLive = '$_dir/marker_live.svg';
}
