import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../live/live_feed.dart';
import '../notifications/notifications_screen.dart';
import '../portfolio/portfolio_mock.dart';
import '../settings/settings_screen.dart';

/// The signed-in user's top bar: avatar, handle over portfolio balance, and
/// + Deposit on the right, followed by a settings gear where [showSettings]
/// (Portfolio).
/// Shared by Home and Portfolio so the two stay identical (Figma 174:110).
class AccountTopBar extends StatelessWidget {
  const AccountTopBar({
    super.key,
    this.onNotBuilt,
    this.showSettings = false,
    this.showNotifications = false,
  });

  /// Called with a feature name when a control leads somewhere not built yet.
  final ValueChanged<String>? onNotBuilt;

  /// Adds the settings gear after Deposit (Portfolio only).
  final bool showSettings;

  /// Adds the notifications bell after Deposit instead (Home, Explore,
  /// Arena); settings stay on Wallet.
  final bool showNotifications;

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
                  child: LiveUsd(
                    feedKey: 'portfolio',
                    base: parseUsd(PortfolioMock.balance),
                    step: 9,
                    style: VistaType.body.copyWith(
                      color: VistaColors.textSecondary,
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
          if (showNotifications)
            // The bell, with a dot while there's something new.
            ValueListenableBuilder(
              valueListenable: Notifications.unread,
              builder: (context, unread, _) => Stack(
                children: [
                  VistaIconButton(
                    asset: VistaAssets.bell,
                    semanticLabel: unread > 0
                        ? 'Notifications, $unread new'
                        : 'Notifications',
                    iconSize: 22,
                    onPressed: () =>
                        Navigator.of(context).push(NotificationsScreen.route()),
                  ),
                  if (unread > 0)
                    Positioned(
                      right: 11,
                      top: 10,
                      child: IgnorePointer(
                        child: Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            color: VistaColors.short,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: VistaColors.background,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            )
          else if (showSettings)
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
