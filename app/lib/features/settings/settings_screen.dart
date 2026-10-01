import 'package:flutter/cupertino.dart' show CupertinoPageRoute;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../charting/charting.dart';
import '../../design_system/design_system.dart';
import '../people/follow_mock.dart';
import 'settings_mock.dart';
import 'settings_state.dart';

/// Settings, opened from the Portfolio gear (Figma 442:102; sections open
/// in place as in 442:772). Rows follow the backend's account contract;
/// every change is simulated and nothing leaves the device.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  /// Slides in from the right on both platforms (Figma "Settings 1").
  static Route<void> route() =>
      CupertinoPageRoute(builder: (_) => const SettingsScreen());

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

enum _Section { notifications, display, security, legal, help }

class _SettingsScreenState extends State<SettingsScreen> {
  final _open = <_Section>{};

  void _toggle(_Section s) =>
      setState(() => _open.contains(s) ? _open.remove(s) : _open.add(s));

  void _say(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _notBuilt(String what) => _say('$what — not in the demo yet');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                VistaSpace.gutter,
                VistaSpace.xs,
                VistaSpace.gutter,
                VistaSpace.xs,
              ),
              child: Row(
                children: [
                  VistaIconButton(
                    asset: VistaAssets.back,
                    semanticLabel: 'Back',
                    iconSize: VistaSize.icon,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: VistaSpace.xs),
                  Text('Settings', style: VistaType.title),
                ],
              ),
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: Listenable.merge([
                  SettingsState.notify,
                  SettingsState.notifyFrom,
                  SettingsState.tradesPublic,
                  SettingsState.tradingPermission,
                  DisplayPrefs.chartMode,
                  DisplayPrefs.longOnRight,
                ]),
                builder: (context, _) => ListView(
                  padding: EdgeInsets.fromLTRB(
                    VistaSpace.gutter,
                    VistaSpace.md,
                    VistaSpace.gutter,
                    MediaQuery.paddingOf(context).bottom + VistaSpace.xl,
                  ),
                  children: [
                    _account(),
                    const VistaSettingsDivider(),
                    Text(SettingsMock.bio, style: VistaType.bodyRegular),
                    const VistaSettingsDivider(),
                    VistaSettingRow(
                      title: 'Wallet',
                      subtitle: 'Tap to copy',
                      trailing: VistaSettingValue(SettingsMock.walletShort),
                      onTap: () {
                        Clipboard.setData(
                          const ClipboardData(text: SettingsMock.wallet),
                        );
                        _say('Wallet address copied');
                      },
                    ),
                    const SizedBox(height: VistaSpace.section),
                    _notifications(),
                    const VistaSettingsDivider(),
                    _display(),
                    const VistaSettingsDivider(),
                    _security(),
                    const VistaSettingsDivider(),
                    _legal(),
                    const VistaSettingsDivider(),
                    _help(),
                    const VistaSettingsDivider(),
                    const SizedBox(height: VistaSpace.section),
                    VistaSettingRow(
                      title: 'Log out',
                      titleColor: VistaColors.short,
                      verticalPadding: 13,
                      onTap: () => _say('Logged out (simulated)'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _account() {
    final counts = VistaType.caption.copyWith(color: VistaColors.textMuted);
    final strong = VistaType.label.copyWith(color: VistaColors.textPrimary);
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: VistaColors.surfaceRaised,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: VistaSpace.xl),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(SettingsMock.handle, style: VistaType.subhead),
              const SizedBox(height: 4),
              Text.rich(
                TextSpan(
                  style: counts,
                  children: [
                    TextSpan(text: FollowMock.followingCount, style: strong),
                    const TextSpan(text: ' Following    '),
                    TextSpan(text: FollowMock.followerCount, style: strong),
                    const TextSpan(text: ' Followers'),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: VistaSpace.md),
        Semantics(
          button: true,
          label: 'Edit profile',
          excludeSemantics: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _notBuilt('Edit profile'),
            child: SizedBox(
              height: VistaSize.tapTarget,
              child: Center(
                child: Container(
                  height: 30,
                  padding: const EdgeInsets.symmetric(
                    horizontal: VistaSpace.xl,
                  ),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: VistaColors.surfaceRaised,
                    borderRadius: BorderRadius.circular(VistaRadius.pill),
                  ),
                  child: Text('Edit', style: VistaType.bodyMedium),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _notifications() {
    final notify = SettingsState.notify.value;
    final from = SettingsState.notifyFrom.value;
    return VistaExpandingSection(
      title: 'Notifications',
      subtitle: SettingsState.notifySummary,
      open: _open.contains(_Section.notifications),
      onToggle: () => _toggle(_Section.notifications),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (i, (key, title, subtitle))
              in SettingsMock.categories.indexed) ...[
            if (i > 0) const VistaSettingsDivider(),
            VistaSettingRow(
              title: title,
              subtitle: subtitle,
              trailing: VistaSwitch(
                value: notify[key] ?? false,
                semanticLabel: '$title notifications',
                onChanged: (on) => SettingsState.setNotify(key, on),
              ),
            ),
          ],
          const SizedBox(height: 24),
          const VistaSettingsHeading('Who notifies you'),
          for (final (i, MapEntry(key: handle, value: on))
              in from.entries.indexed) ...[
            if (i > 0) const VistaSettingsDivider(),
            VistaSettingRow(
              title: handle,
              trailing: VistaSwitch(
                value: on,
                semanticLabel: 'Notifications from $handle',
                onChanged: (v) => SettingsState.setNotifyFrom(handle, v),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _display() {
    return VistaExpandingSection(
      title: 'Display',
      open: _open.contains(_Section.display),
      onToggle: () => _toggle(_Section.display),
      child: Column(
        children: [
          VistaSettingRow(
            title: 'Charts',
            subtitle: 'Candles or a line on every chart',
            trailing: VistaSegmentedToggle(
              labels: const ['Candles', 'Line'],
              selectedIndex: DisplayPrefs.chartMode.value == PlotMode.candles
                  ? 0
                  : 1,
              onChanged: (i) => DisplayPrefs.chartMode.value = i == 0
                  ? PlotMode.candles
                  : PlotMode.line,
            ),
          ),
          const VistaSettingsDivider(),
          VistaSettingRow(
            title: 'Long button',
            subtitle: 'Which side it sits on in a pair',
            trailing: VistaSegmentedToggle(
              labels: const ['Left', 'Right'],
              selectedIndex: DisplayPrefs.longOnRight.value ? 1 : 0,
              onChanged: (i) => DisplayPrefs.longOnRight.value = i == 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _security() {
    final permitted = SettingsState.tradingPermission.value;
    return VistaExpandingSection(
      title: 'Security',
      open: _open.contains(_Section.security),
      onToggle: () => _toggle(_Section.security),
      child: Column(
        children: [
          VistaSettingRow(
            title: 'Two-factor sign-in',
            subtitle: 'A second check when you sign in',
            trailing: const VistaSettingValue('On'),
            onTap: () => _notBuilt('Two-factor settings'),
          ),
          const VistaSettingsDivider(),
          VistaSettingRow(
            title: 'Trading permission',
            subtitle: permitted
                ? 'Places the trades you confirm · until '
                      '${SettingsMock.permissionUntil}'
                : 'Off · you will be asked again before your next trade',
            trailing: permitted
                ? const VistaSettingValue('Revoke', color: VistaColors.short)
                : const VistaSettingValue('Off'),
            onTap: permitted
                ? () {
                    SettingsState.tradingPermission.value = false;
                    _say('Trading permission revoked (simulated)');
                  }
                : () {
                    SettingsState.tradingPermission.value = true;
                    _say('Trading permission granted (simulated)');
                  },
          ),
        ],
      ),
    );
  }

  Widget _legal() {
    final public = SettingsState.tradesPublic.value;
    return VistaExpandingSection(
      title: 'Legal and privacy',
      open: _open.contains(_Section.legal),
      onToggle: () => _toggle(_Section.legal),
      child: Column(
        children: [
          VistaSettingRow(
            title: 'Who can see your trades',
            subtitle: public
                ? 'Anyone. Needed for the leaderboard'
                : 'Nobody. You can still follow and trade',
            trailing: VistaSegmentedToggle(
              labels: const ['Public', 'Private'],
              selectedIndex: public ? 0 : 1,
              onChanged: (i) => SettingsState.tradesPublic.value = i == 0,
            ),
          ),
          const VistaSettingsDivider(),
          VistaSettingRow(
            title: 'Terms of service',
            subtitle: 'Accepted · version ${SettingsMock.termsVersion}',
            trailing: const VistaSettingChevron(),
            onTap: () => _notBuilt('Terms of service'),
          ),
          const VistaSettingsDivider(),
          VistaSettingRow(
            title: 'Privacy policy',
            trailing: const VistaSettingChevron(),
            onTap: () => _notBuilt('Privacy policy'),
          ),
          const VistaSettingsDivider(),
          const VistaSettingRow(
            title: 'Region',
            subtitle: 'Where you told us you live',
            trailing: VistaSettingValue(SettingsMock.country),
          ),
          const VistaSettingsDivider(),
          VistaSettingRow(
            title: 'Delete account',
            titleColor: VistaColors.short,
            onTap: () => _notBuilt('Delete account'),
          ),
        ],
      ),
    );
  }

  Widget _help() {
    return VistaExpandingSection(
      title: 'Help and support',
      open: _open.contains(_Section.help),
      onToggle: () => _toggle(_Section.help),
      child: Column(
        children: [
          for (final (i, title) in const [
            'Help center',
            'Contact support',
            'Report a problem',
          ].indexed) ...[
            if (i > 0) const VistaSettingsDivider(),
            VistaSettingRow(
              title: title,
              trailing: const VistaSettingChevron(),
              onTap: () => _notBuilt(title),
            ),
          ],
          const VistaSettingsDivider(),
          const VistaSettingRow(
            title: 'Version',
            trailing: VistaSettingValue(SettingsMock.appVersion),
          ),
        ],
      ),
    );
  }
}
