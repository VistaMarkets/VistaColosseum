import '../../design_system/design_system.dart';

/// A caller's market question with its entry and live replay. Demo data only.
class TradeIdea {
  const TradeIdea({
    required this.callerHandle,
    required this.callerAvatar,
    required this.age,
    required this.side,
    required this.ticker,
    required this.assetName,
    required this.coinAsset,
    required this.price,
    required this.callPrice,
    required this.changeSinceCall,
    required this.question,
    required this.likes,
    required this.traders,
    required this.fills,
  });

  final String callerHandle;
  final String callerAvatar;
  final String age;
  final TradeSide side;
  final String ticker;
  final String assetName;
  final String coinAsset;
  final String price;

  /// Price when the call was made; the replay starts here.
  final String callPrice;
  final String changeSinceCall;
  final String question;
  final String likes;
  final String traders;
  final List<LiveFill> fills;
}

/// One entry in the live fills stream shown over the chart.
class LiveFill {
  const LiveFill(this.avatar, this.message, {this.amount, this.side});

  final String avatar;
  final String message;
  final String? amount;
  final TradeSide? side;
}

/// Mock content from the Figma frame (301:102). Simulated; not market data.
const mockTradeIdea = TradeIdea(
  callerHandle: 'kaito.eth',
  callerAvatar: VistaAssets.callerAvatar,
  age: '5h',
  side: TradeSide.long,
  ticker: 'ETH',
  assetName: 'Ethereum',
  coinAsset: VistaAssets.coinEth,
  price: r'$2,968.40',
  callPrice: r'$2,801.10',
  changeSinceCall: '+5.97% since call',
  question: r'Is ETH poised for a breakout above $3,000?',
  likes: '4.4k',
  traders: '1.2k',
  fills: [
    LiveFill(VistaAssets.fillAvatar1, '3 people joined'),
    LiveFill(
      VistaAssets.fillAvatar2,
      '0xreal shorted',
      amount: r'$1.2k',
      side: TradeSide.short,
    ),
    LiveFill(
      VistaAssets.fillAvatar3,
      'kilo.sol went long',
      amount: r'$500',
      side: TradeSide.long,
    ),
  ],
);

/// Feed contents. Only one card is designed in Figma so far, so the feed
/// repeats it to demonstrate swiping; swap in real cards as they are designed.
const mockFeed = [mockTradeIdea, mockTradeIdea, mockTradeIdea];
