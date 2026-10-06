import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../home/mock_trade_idea.dart';
import '../home/trade_idea_card.dart';
import '../live/market_prices.dart';
import '../markets/markets_mock.dart';
import '../profile/profile_screen.dart';
import 'order_ticket.dart';
import 'trade_mock.dart';

/// A caller's play, opened from their post in the trade page's Callers
/// thread: the same trade card as the Home feed, for this one call, under a
/// back bar. The replay runs from their entry to the market's live price.
class CallerPlayScreen extends StatelessWidget {
  const CallerPlayScreen({super.key, required this.idea});

  static Route<void> route(CallerPost post, String ticker) => MaterialPageRoute(
    builder: (_) => CallerPlayScreen(idea: callerPlayIdea(post, ticker)),
  );

  final TradeIdea idea;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            VistaTitleBar(
              title: "${idea.callerHandle}'s call",
              onBack: () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(height: VistaSpace.md),
            Expanded(
              child: TradeIdeaCard(
                idea: idea,
                // Details leads back to the trade page this came from.
                onDetails: () => Navigator.of(context).maybePop(),
                onCaller: () =>
                    Navigator.of(context)
                        .push(ProfileScreen.route(idea.callerHandle)),
                onTrade: () => showFeedOrderTicket(
                  context,
                  symbol: idea.ticker,
                  side: idea.side,
                  sourceCallId: '${idea.callerHandle}/${idea.ticker}',
                  sourceAuthorHandle: idea.callerHandle,
                  onDetails: () => Navigator.of(context).maybePop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A Home-style trade idea for a caller's post on [ticker]: their side and
/// entry as the call, a question from their exits ("Does BTC reach $69,436
/// before $65,910?"), and a replay generated from their entry to now.
TradeIdea callerPlayIdea(CallerPost p, String ticker) {
  final entry = MarketPrices.base(ticker) * p.entryRatio;
  String level(double ratio) =>
      MarketPrices.format(entry * ratio, compact: true);
  final long = p.side == TradeSide.long;
  final quote = TradeMock.quotes[ticker];
  final row = MarketsMock.assets.where((m) => m.id == ticker);
  // Small, steady social counts per caller (the same every time).
  final seed = p.handle.codeUnits.fold<int>(0, (h, c) => h * 31 + c) & 0xffff;
  String count(int base) {
    final n = base + seed % base;
    return n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';
  }

  return TradeIdea(
    callerHandle: p.handle,
    age: p.age,
    side: p.side,
    ticker: ticker,
    assetName: quote?.name ?? ticker,
    coinAsset: row.isEmpty ? VistaAssets.coinPlaceholder : row.first.rowIcon,
    callPrice: entry,
    question: long
        ? 'Does $ticker reach ${level(p.takeProfit)} before '
              '${level(p.stopLoss)}?'
        : 'Does $ticker fall to ${level(p.takeProfit)} before '
              '${level(p.stopLoss)}?',
    likes: count(400),
    traders: count(120),
    whale: _whale(p.size * 1000),
    fills: const [
      LiveFill(VistaAssets.fillAvatar1, '2 people joined'),
      LiveFill(
        VistaAssets.fillAvatar2,
        'kaito.eth went long',
        amount: r'$300',
        side: TradeSide.long,
      ),
      LiveFill(
        VistaAssets.fillAvatar3,
        'nara shorted',
        amount: r'$150',
        side: TradeSide.short,
      ),
    ],
  );
}

/// "$2.4M" or "$400k".
String _whale(double v) =>
    v >= 1e6 ? '\$${(v / 1e6).toStringAsFixed(1)}M' : '\$${(v / 1e3).round()}k';
