import '../../design_system/design_system.dart';
import '../live/market_prices.dart';
import 'replay_script.dart';

/// A caller's market question with its entry and live replay, on an asset
/// or on a trader's market. Demo data only.
class TradeIdea {
  TradeIdea({
    required this.callerHandle,
    required this.age,
    required this.side,
    required this.ticker,
    required this.assetName,
    required this.coinAsset,
    required this.callPrice,
    required this.question,
    required this.likes,
    required this.traders,
    required this.fills,
    required String whale,
    this.callerAvatar = VistaAssets.callerAvatar,
    this.traderMarket = false,
    ReplayScript? script,
  }) : script =
           script ??
           ReplayScript.generate(
             seed: ticker,
             callPrice: callPrice,
             nowPrice: MarketPrices.base(ticker),
             side: side,
             age: age,
             whale: whale,
           );

  final String callerHandle;
  final String callerAvatar;
  final String age;
  final TradeSide side;

  /// The market: an asset ticker, or a trader's handle for their market.
  final String ticker;
  final String assetName;
  final String coinAsset;
  final bool traderMarket;

  /// Price when the call was made; the replay starts here.
  final double callPrice;
  final String question;
  final String likes;
  final String traders;
  final List<LiveFill> fills;

  /// The replay the card's chart plays.
  final ReplayScript script;

  /// The market's price where the replay ends (its session base).
  double get price => MarketPrices.base(ticker);
}

/// One entry in the live fills stream shown over the chart.
class LiveFill {
  const LiveFill(this.avatar, this.message, {this.amount, this.side});

  final String avatar;
  final String message;
  final String? amount;
  final TradeSide? side;
}

const _a1 = VistaAssets.fillAvatar1;
const _a2 = VistaAssets.fillAvatar2;
const _a3 = VistaAssets.fillAvatar3;

/// The Figma card (301:102). Simulated; not market data.
final mockTradeIdea = TradeIdea(
  callerHandle: 'kaito.eth',
  age: '5h',
  side: TradeSide.long,
  ticker: 'ETH',
  assetName: 'Ethereum',
  coinAsset: VistaAssets.coinEth,
  callPrice: 2801.10,
  question: r'Is ETH poised for a breakout above $3,000?',
  likes: '4.4k',
  traders: '1.2k',
  whale: r'$4.2M',
  script: ReplayScript.figmaEth,
  fills: const [
    LiveFill(_a1, '3 people joined'),
    LiveFill(_a2, '0xreal shorted', amount: r'$1.2k', side: TradeSide.short),
    LiveFill(_a3, 'kilo.sol went long', amount: r'$500', side: TradeSide.long),
  ],
);

/// The Home feed: one call on every market Explore offers, the five assets
/// then the seven trader markets, the Figma card first. Simulated.
final mockFeed = <TradeIdea>[
  mockTradeIdea,
  TradeIdea(
    callerHandle: '0xreal',
    age: '9h',
    side: TradeSide.short,
    ticker: 'BTC',
    assetName: 'Bitcoin',
    coinAsset: VistaAssets.coinBtcRow,
    callPrice: 68650,
    question: r'Does BTC lose $67,000 before the weekly close?',
    likes: '3.1k',
    traders: '860',
    whale: r'$11M',
    fills: const [
      LiveFill(_a2, '5 people joined'),
      LiveFill(_a1, 'nara went long', amount: r'$2.4k', side: TradeSide.long),
      LiveFill(_a3, 'lunaq shorted', amount: r'$800', side: TradeSide.short),
    ],
  ),
  TradeIdea(
    callerHandle: 'kilo.sol',
    age: '8h',
    side: TradeSide.long,
    ticker: 'SOL',
    assetName: 'Solana',
    coinAsset: VistaAssets.coinSolRow,
    callPrice: 205.30,
    question: r'Is SOL heading back to $230 this week?',
    likes: '2.7k',
    traders: '940',
    whale: r'$3.1M',
    fills: const [
      LiveFill(_a3, '2 people joined'),
      LiveFill(
        _a1,
        'kaito.eth went long',
        amount: r'$1.5k',
        side: TradeSide.long,
      ),
      LiveFill(_a2, 'kestrel shorted', amount: r'$300', side: TradeSide.short),
    ],
  ),
  TradeIdea(
    callerHandle: 'lunaq',
    age: '14h',
    side: TradeSide.short,
    ticker: 'ARB',
    assetName: 'Arbitrum',
    coinAsset: VistaAssets.coinArbRow,
    callPrice: 1.01,
    question: r'Is the ARB bounce running out of steam under $1.10?',
    likes: '980',
    traders: '310',
    whale: r'$640k',
    fills: const [
      LiveFill(
        _a1,
        'deltaone went long',
        amount: r'$700',
        side: TradeSide.long,
      ),
      LiveFill(_a2, '4 people joined'),
      LiveFill(_a3, 'nara shorted', amount: r'$250', side: TradeSide.short),
    ],
  ),
  TradeIdea(
    callerHandle: 'nara',
    age: '1d',
    side: TradeSide.long,
    ticker: 'AVAX',
    assetName: 'Avalanche',
    coinAsset: VistaAssets.coinAvaxRow,
    callPrice: 36.90,
    question: r'Can AVAX reclaim $40 by Friday?',
    likes: '1.4k',
    traders: '420',
    whale: r'$1.1M',
    fills: const [
      LiveFill(
        _a2,
        'kilo.sol went long',
        amount: r'$900',
        side: TradeSide.long,
      ),
      LiveFill(_a3, '3 people joined'),
      LiveFill(_a1, '0xreal shorted', amount: r'$400', side: TradeSide.short),
    ],
  ),
  TradeIdea(
    callerHandle: 'deltaone',
    age: '2d',
    side: TradeSide.long,
    ticker: 'maya.eth',
    assetName: 'Trader market',
    coinAsset: VistaAssets.traderAvatarRow,
    traderMarket: true,
    callPrice: 0.4120,
    question: r"Does maya.eth's market keep climbing past $0.45?",
    likes: '2.2k',
    traders: '730',
    whale: r'$220k',
    fills: const [
      LiveFill(_a1, '6 people joined'),
      LiveFill(
        _a3,
        'kaito.eth went long',
        amount: r'$1.1k',
        side: TradeSide.long,
      ),
      LiveFill(_a2, 'lunaq shorted', amount: r'$350', side: TradeSide.short),
    ],
  ),
  TradeIdea(
    callerHandle: 'kaito.eth',
    age: '6h',
    side: TradeSide.short,
    ticker: '0xreal',
    assetName: 'Trader market',
    coinAsset: VistaAssets.traderAvatarRow,
    traderMarket: true,
    callPrice: 0.3950,
    question: r"Is 0xreal's market topping out below $0.40?",
    likes: '1.9k',
    traders: '610',
    whale: r'$180k',
    fills: const [
      LiveFill(_a2, 'maya.eth shorted', amount: r'$600', side: TradeSide.short),
      LiveFill(_a1, '2 people joined'),
      LiveFill(_a3, 'kestrel went long', amount: r'$200', side: TradeSide.long),
    ],
  ),
  TradeIdea(
    callerHandle: 'kestrel',
    age: '1d',
    side: TradeSide.long,
    ticker: 'lunaq',
    assetName: 'Trader market',
    coinAsset: VistaAssets.traderAvatarRow,
    traderMarket: true,
    callPrice: 0.3300,
    question: r"Does lunaq's market bounce off $0.31?",
    likes: '840',
    traders: '270',
    whale: r'$95k',
    fills: const [
      LiveFill(
        _a3,
        'deltaone went long',
        amount: r'$450',
        side: TradeSide.long,
      ),
      LiveFill(_a2, 'kilo.sol shorted', amount: r'$300', side: TradeSide.short),
      LiveFill(_a1, '3 people joined'),
    ],
  ),
  TradeIdea(
    callerHandle: 'maya.eth',
    age: '3h',
    side: TradeSide.long,
    ticker: 'deltaone',
    assetName: 'Trader market',
    coinAsset: VistaAssets.traderAvatarRow,
    traderMarket: true,
    callPrice: 0.2480,
    question: r"Is deltaone's market breaking out above $0.26?",
    likes: '1.2k',
    traders: '390',
    whale: r'$120k',
    fills: const [
      LiveFill(_a1, '4 people joined'),
      LiveFill(_a2, 'nara went long', amount: r'$250', side: TradeSide.long),
      LiveFill(_a3, '0xreal shorted', amount: r'$150', side: TradeSide.short),
    ],
  ),
  TradeIdea(
    callerHandle: 'lunaq',
    age: '11h',
    side: TradeSide.short,
    ticker: 'kestrel',
    assetName: 'Trader market',
    coinAsset: VistaAssets.traderAvatarRow,
    traderMarket: true,
    callPrice: 0.2060,
    question: r"Does kestrel's market slide under $0.19?",
    likes: '610',
    traders: '190',
    whale: r'$60k',
    fills: const [
      LiveFill(_a3, '2 people joined'),
      LiveFill(_a1, 'maya.eth shorted', amount: r'$200', side: TradeSide.short),
      LiveFill(
        _a2,
        'kaito.eth went long',
        amount: r'$120',
        side: TradeSide.long,
      ),
    ],
  ),
  TradeIdea(
    callerHandle: 'nara',
    age: '7h',
    side: TradeSide.long,
    ticker: 'kilo.sol',
    assetName: 'Trader market',
    coinAsset: VistaAssets.traderAvatarRow,
    traderMarket: true,
    callPrice: 0.1650,
    question: r"Is kilo.sol's market on its way to $0.18?",
    likes: '520',
    traders: '160',
    whale: r'$48k',
    fills: const [
      LiveFill(_a2, '3 people joined'),
      LiveFill(
        _a3,
        'deltaone went long',
        amount: r'$180',
        side: TradeSide.long,
      ),
      LiveFill(_a1, 'lunaq shorted', amount: r'$90', side: TradeSide.short),
    ],
  ),
  TradeIdea(
    callerHandle: 'kilo.sol',
    age: '2d',
    side: TradeSide.short,
    ticker: 'nara',
    assetName: 'Trader market',
    coinAsset: VistaAssets.traderAvatarRow,
    traderMarket: true,
    callPrice: 0.1450,
    question: r"Does nara's market hold $0.14 or crack?",
    likes: '430',
    traders: '120',
    whale: r'$35k',
    fills: const [
      LiveFill(_a1, 'kestrel shorted', amount: r'$110', side: TradeSide.short),
      LiveFill(_a2, '2 people joined'),
      LiveFill(_a3, 'maya.eth went long', amount: r'$75', side: TradeSide.long),
    ],
  ),
];
