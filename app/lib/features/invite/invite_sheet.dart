import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../design_system/design_system.dart';
import '../portfolio/portfolio_mock.dart';

/// Referral: your link and code, what you both get, and who has joined.
/// Simulated; nothing is sent and no reward is paid.
Future<void> showInviteSheet(BuildContext context) => showVistaSheet<void>(
  context,
  color: const Color(0xFF161616),
  builder: (_) => const InviteSheet(),
);

/// The green Invite button. [chip] matches the Followers / Following
/// stat chips it sits beside on Portfolio; otherwise a pill (Settings).
class InviteButton extends StatelessWidget {
  const InviteButton({super.key, this.chip = false});

  final bool chip;

  @override
  Widget build(BuildContext context) {
    final pill = Container(
      padding: chip
          ? const EdgeInsets.symmetric(horizontal: 10, vertical: 5)
          : const EdgeInsets.symmetric(horizontal: VistaSpace.xl, vertical: 5),
      decoration: BoxDecoration(
        color: VistaColors.long,
        borderRadius: BorderRadius.circular(VistaRadius.pill),
      ),
      child: Text(
        chip
            // Short on narrow phones so it stays on the chips' line.
            ? MediaQuery.sizeOf(context).width < 390
                  ? '+ Invite'
                  : '+ Invite friends'
            : 'Invite',
        style: (chip ? VistaType.bodyStrong : VistaType.body).copyWith(
          color: VistaColors.onAccent,
        ),
      ),
    );
    return Semantics(
      button: true,
      label: 'Invite friends',
      excludeSemantics: true,
      child: VistaPressable(
        onTap: () => showInviteSheet(context),
        child: chip
            ? pill
            : SizedBox(
                height: VistaSize.tapTarget,
                child: Center(child: pill),
              ),
      ),
    );
  }
}

/// The referral popup (Figma 1396:9883): what you've earned from people
/// you brought in with Claim, your link to copy, how many you referred and
/// your rank, and Share your code. Simulated; nothing is paid or sent.
class InviteSheet extends StatelessWidget {
  const InviteSheet({super.key});

  static const earned = r'$4,812';
  static const traders = 41;
  static const claimable = r'$318.60';
  static const referred = 43;
  static const rank = '14th';

  static String get link =>
      'Vistamarkets.xyz/${PortfolioMock.handle.split('.').first}';

  /// "Group" is a SVG at a box given as Figma fractions of the card
  /// (left, top, right, bottom insets).
  static Widget _art(
    String name,
    double l,
    double t,
    double r,
    double b, {
    double turns = 0,
  }) => Positioned.fill(
    child: LayoutBuilder(
      builder: (context, c) => Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: c.maxWidth * l,
            top: c.maxHeight * t,
            right: c.maxWidth * r,
            bottom: c.maxHeight * b,
            child: RotationTransition(
              turns: AlwaysStoppedAnimation(turns),
              child: SvgPicture.asset(
                'assets/figma/$name.svg',
                fit: BoxFit.fill,
              ),
            ),
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final width = MediaQuery.sizeOf(context).width;
    // The card keeps Figma's 345 x 210 proportions.
    final cardW = width - 2 * 24 > 345 ? 345.0 : width - 2 * 24;
    void say(String m) => ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(m)));
    const boxes = Color(0xFF1F1F1F);
    const muted = Color(0xFF8A8A91);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        bottom > 0 ? bottom : VistaSpace.section,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Grabber.
          SizedBox(
            height: 34,
            child: Center(
              child: Container(
                width: 140,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
          ),
          // Earned, with coins and sparkles.
          Container(
            width: cardW,
            height: cardW * 210 / 345,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: boxes,
              borderRadius: BorderRadius.circular(35),
            ),
            child: Stack(
              children: [
                _art('ref_coin_right', .8406, .2499, -.2232, .1215),
                _art(
                  'ref_coin_top',
                  .8595,
                  .1762,
                  -.0072,
                  .5811,
                  turns: 10 / 360,
                ),
                _art('ref_spark_red', .8058, .4023, .113, .4644),
                _art('ref_dot', .7768, .6404, .1884, .3024),
                _art('ref_coin_left', -.229, -.1048, .7391, .3775),
                _art('ref_dot2', .9188, .5595, .029, .3548),
                _art('ref_spark_blue', .8696, .7261, .0725, .1786),
                Positioned.fill(
                  child: Column(
                    children: [
                      const Spacer(flex: 42),
                      Text(
                        'YOU HAVE EARNED',
                        style: VistaType.labelStrong.copyWith(
                          fontSize: 13,
                          color: muted,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        earned,
                        style: VistaType.figures(VistaType.displayMedium)
                            .copyWith(
                              fontSize: 40,
                              fontWeight: FontWeight.w700,
                              color: VistaColors.long,
                              height: 1.1,
                            ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'from $traders traders',
                        style: VistaType.caption.copyWith(color: muted),
                      ),
                      const Spacer(flex: 20),
                      VistaPressable(
                        onTap: () => say('Claimed $claimable (simulated)'),
                        child: Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 56),
                          alignment: Alignment.center,
                          constraints: const BoxConstraints(maxWidth: 260),
                          decoration: BoxDecoration(
                            color: VistaColors.long,
                            borderRadius: BorderRadius.circular(79),
                          ),
                          child: Text(
                            'Claim $claimable',
                            style: VistaType.headline.copyWith(
                              fontSize: 16,
                              color: VistaColors.onAccent,
                            ),
                          ),
                        ),
                      ),
                      const Spacer(flex: 14),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Your link, copy on the right.
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              Clipboard.setData(ClipboardData(text: 'https://$link'));
              say('Invite link copied');
            },
            child: Container(
              width: cardW,
              height: 47,
              padding: const EdgeInsets.only(left: 25, right: 3),
              decoration: BoxDecoration(
                color: boxes,
                borderRadius: BorderRadius.circular(42),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      link,
                      style: VistaType.body.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: 'Copy link',
                    child: SvgPicture.asset(
                      'assets/figma/ref_copy.svg',
                      width: 41,
                      height: 41,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Friends referred and your rank, with the rising bars.
          Container(
            width: cardW,
            height: 104,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: boxes,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Stack(
              children: [
                _art('ref_chart', .6188, .1346, -.0029, -.1949),
                Positioned(
                  left: 21,
                  top: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$referred',
                        style: VistaType.figures(
                          VistaType.title,
                        ).copyWith(fontSize: 20, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'Friends referred',
                        style: VistaType.subhead.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF858585),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 20.5,
                  top: 71,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: VistaColors.long,
                      borderRadius: BorderRadius.circular(38),
                    ),
                    child: Text(
                      'Rank $rank',
                      style: VistaType.labelStrong.copyWith(
                        fontSize: 12,
                        color: VistaColors.onAccent,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          VistaPressable(
            onTap: () => say('Share your code — not in the demo yet'),
            child: Container(
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: VistaColors.accent,
                borderRadius: BorderRadius.circular(42),
              ),
              child: Text(
                'SHARE YOUR CODE',
                style: VistaType.body.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: VistaColors.onAccent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
