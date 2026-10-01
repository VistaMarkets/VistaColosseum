import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../home/mock_trade_idea.dart';
import '../home/replay_script.dart';
import '../live/market_prices.dart';
import '../market/chart_sheet.dart';

/// One alert on a market, as the Home feed shows it on that market's card:
/// the call, the moments tagged on its replay, and live fills.
class AssetAlert {
  const AssetAlert({
    required this.kind,
    required this.title,
    required this.color,
    required this.minutesAgo,
  });

  /// What sort of alert, e.g. "Whale" or "Funding".
  final String kind;
  final String title;
  final Color color;
  final int minutesAgo;

  String get ago => minutesAgo < 1
      ? 'now'
      : minutesAgo < 60
      ? '${minutesAgo}m'
      : minutesAgo < 1440
      ? '${minutesAgo ~/ 60}h'
      : '${minutesAgo ~/ 1440}d';
}

/// Every alert the feed has on [ticker], newest first. Mock: drawn from the
/// feed cards on that market; an event's time is where it sits along the
/// replay, from the call ("5h") to now.
List<AssetAlert> assetAlerts(String ticker) {
  final alerts = <AssetAlert>[];
  for (final idea in mockFeed.where((i) => i.ticker == ticker)) {
    final age = _minutes(idea.age);
    final last = idea.script.path.length - 1;
    alerts.add(
      AssetAlert(
        kind: 'Call',
        title:
            '${idea.callerHandle} called ${idea.side.label.toLowerCase()} '
            'at ${MarketPrices.format(idea.callPrice)}',
        color: idea.side.color,
        minutesAgo: age,
      ),
    );
    for (final e in idea.script.events) {
      alerts.add(
        AssetAlert(
          kind: switch (e.kind) {
            ReplayEventKind.funding => 'Funding',
            ReplayEventKind.whale => 'Whale',
            ReplayEventKind.payoff => 'Price level',
          },
          title: e.label,
          color: switch (e.kind) {
            ReplayEventKind.funding => VistaColors.fees,
            ReplayEventKind.whale => VistaColors.accent,
            // Green if it went the caller's way, as on the card.
            ReplayEventKind.payoff =>
              e.favourable ? VistaColors.long : VistaColors.short,
          },
          minutesAgo: (age * (1 - e.vertex / last)).round(),
        ),
      );
    }
    for (final (n, f) in idea.fills.indexed) {
      alerts.add(
        AssetAlert(
          kind: f.side == null ? 'Joined' : 'Trade',
          title: f.amount == null ? f.message : '${f.message} ${f.amount}',
          color: f.side?.color ?? VistaColors.textMuted,
          minutesAgo: n * 2,
        ),
      );
    }
  }
  alerts.sort((a, b) => a.minutesAgo.compareTo(b.minutesAgo));
  return alerts;
}

/// "5h" → 300, "1d" → 1440, "12m" → 12.
int _minutes(String age) {
  final n = int.tryParse(age.substring(0, age.length - 1)) ?? 0;
  return switch (age[age.length - 1]) {
    'd' => n * 1440,
    'h' => n * 60,
    _ => n,
  };
}

/// The trade page's Alerts panel: the feed's alerts on this market as a
/// timeline, newest first.
class AssetAlertsPanel extends StatelessWidget {
  const AssetAlertsPanel({super.key, required this.ticker});

  final String ticker;

  @override
  Widget build(BuildContext context) {
    final alerts = assetAlerts(ticker);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        chartSheetTitle('Alerts on $ticker'),
        const SizedBox(height: VistaSpace.lg),
        if (alerts.isEmpty)
          Text(
            'No alerts on $ticker yet',
            style: VistaType.body.copyWith(color: VistaColors.textMuted),
          ),
        for (final (i, a) in alerts.indexed)
          _AlertRow(alert: a, last: i == alerts.length - 1),
      ],
    );
  }
}

class _AlertRow extends StatelessWidget {
  const _AlertRow({required this.alert, required this.last});

  final AssetAlert alert;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 32,
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                alert.ago,
                style: VistaType.label.copyWith(
                  color: VistaColors.textSecondary,
                ),
              ),
            ),
          ),
          // The rail: a dot in the alert's colour, joined to the next.
          SizedBox(
            width: 12,
            child: Column(
              children: [
                const SizedBox(height: 4),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: alert.color,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!last)
                  Expanded(
                    child: Container(width: 1, color: VistaColors.divider),
                  ),
              ],
            ),
          ),
          const SizedBox(width: VistaSpace.xl),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: VistaSpace.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert.kind.toUpperCase(),
                    style: VistaType.labelStrong.copyWith(color: alert.color),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    alert.title,
                    style: VistaType.subhead,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
