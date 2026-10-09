import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../design_system/design_system.dart';
import '../portfolio/portfolio_mock.dart';

/// Referral: your link and code, what you both get, and who has joined.
/// Simulated; nothing is sent and no reward is paid.
Future<void> showInviteSheet(BuildContext context) => showVistaSheet<void>(
  context,
  color: VistaColors.background,
  builder: (_) => const InviteSheet(),
);

/// The green Invite pill (Portfolio, beside "My portfolio").
class InviteButton extends StatelessWidget {
  const InviteButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Invite friends',
      excludeSemantics: true,
      child: VistaPressable(
        onTap: () => showInviteSheet(context),
        child: SizedBox(
          height: VistaSize.tapTarget,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: VistaSpace.xl,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: VistaColors.long,
                borderRadius: BorderRadius.circular(VistaRadius.pill),
              ),
              child: Text(
                'Invite',
                style: VistaType.body.copyWith(color: VistaColors.onAccent),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class InviteSheet extends StatelessWidget {
  const InviteSheet({super.key});

  static const reward = r'$20';
  static const joined = 3;

  static String get code =>
      PortfolioMock.handle.split('.').first.toUpperCase().padRight(4, 'X');

  static String get link => 'vista.app/i/${code.toLowerCase()}';

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final muted = VistaType.body.copyWith(color: VistaColors.textMuted);
    void say(String m) => ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(m)));
    return Padding(
      padding: EdgeInsets.fromLTRB(
        VistaSpace.gutter,
        VistaSpace.section,
        VistaSpace.gutter,
        bottom > 0 ? bottom : VistaSpace.gutter,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Invite friends', style: VistaType.displaySmall),
          const SizedBox(height: VistaSpace.xs),
          Text(
            'You both get $reward when they make their first trade.',
            style: muted,
          ),
          const SizedBox(height: VistaSpace.section),
          // The link, tap to copy.
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              Clipboard.setData(ClipboardData(text: 'https://$link'));
              say('Invite link copied');
            },
            child: Container(
              padding: const EdgeInsets.all(VistaSpace.gutter),
              decoration: BoxDecoration(
                color: VistaColors.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Your link', style: muted),
                        const SizedBox(height: VistaSpace.xxs),
                        Text(link, style: VistaType.headline),
                      ],
                    ),
                  ),
                  Text(
                    'Copy',
                    style: VistaType.body.copyWith(color: VistaColors.accent),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: VistaSpace.md),
          Row(
            children: [
              Expanded(child: Text('Code', style: muted)),
              Text(code, style: VistaType.figures(VistaType.subhead)),
            ],
          ),
          const SizedBox(height: VistaSpace.lg),
          const Divider(height: 1, color: VistaColors.hairline),
          const SizedBox(height: VistaSpace.lg),
          Row(
            children: [
              Expanded(child: Text('Joined', style: muted)),
              Text(
                '$joined friends   \$${20 * joined} earned',
                style: VistaType.figures(VistaType.subhead)
                    .copyWith(color: VistaColors.long),
              ),
            ],
          ),
          const SizedBox(height: VistaSpace.section),
          VistaPillButton(
            label: 'Share invite',
            variant: VistaPillVariant.long,
            onPressed: () => say('Share invite — not in the demo yet'),
          ),
          const SizedBox(height: VistaSpace.md),
          Text(
            'Simulated   no reward is paid in the demo',
            textAlign: TextAlign.center,
            style: VistaType.caption.copyWith(color: VistaColors.textMuted),
          ),
        ],
      ),
    );
  }
}
