import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../live/live_feed.dart';
import '../../scenario/scenario.dart';
import '../portfolio/portfolio_mock.dart';
import '../settings/settings_screen.dart';

/// The signed-in user's top bar: avatar, handle over portfolio balance, and
/// + Deposit on the right, followed by a settings gear where [showSettings]
/// (Portfolio).
/// Shared by Home and Portfolio so the two stay identical (Figma 174:110).
class AccountTopBar extends StatelessWidget {
  const AccountTopBar({super.key, this.onNotBuilt, this.showSettings = false});

  /// Called with a feature name when a control leads somewhere not built yet.
  final ValueChanged<String>? onNotBuilt;

  /// Adds the settings gear after Deposit (Portfolio only).
  final bool showSettings;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: VistaSize.tapTarget,
      child: Row(
        children: [
          const VistaIcon(
            VistaAssets.portfolioAvatar,
            size: VistaSize.avatarLarge,
          ),
          const SizedBox(width: VistaSpace.lg),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  PortfolioMock.handle,
                  style: VistaType.subhead,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Semantics(
                  label: 'Portfolio balance',
                  child: ValueListenableBuilder(
                    valueListenable: Scenario.cashCents,
                    // The stored cash to the cent, rolling when it moves.
                    builder: (context, cents, _) => VistaRollingNumber(
                      formatCents(cents),
                      style: VistaType.body.copyWith(
                        color: VistaColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          VistaCompactButton(
            label: 'Deposit',
            leading: '+',
            // Simulated only: the demo never moves funds.
            onPressed: () => onNotBuilt?.call('Deposit (simulated)'),
          ),
          if (showSettings)
            VistaIconButton(
              asset: VistaAssets.settings,
              semanticLabel: 'Settings',
              iconSize: 22,
              onPressed: () =>
                  Navigator.of(context).push(SettingsScreen.route()),
            ),
        ],
      ),
    );
  }
}
