import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../design_system/design_system.dart';
import '../portfolio/portfolio_mock.dart';
import '../settings/settings_mock.dart';

/// Your profile's editable parts: a display name and a bio. Held in
/// memory; your profile reads them. Nothing is sent.
abstract final class ProfileEdits {
  static final name = ValueNotifier<String>('');
  static final bio = ValueNotifier<String>(SettingsMock.bio);

  static void reset() {
    name.value = '';
    bio.value = SettingsMock.bio;
  }
}

/// Edit profile (Settings › Edit): your photo, name and bio; the handle is
/// shown but fixed. Save keeps the changes and goes back; Cancel drops them.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  static const nameLength = 30;

  /// The backend caps bios at 60 characters.
  static const bioLength = 60;

  static Route<bool> route() =>
      MaterialPageRoute(builder: (_) => const EditProfileScreen());

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final _name = TextEditingController(text: ProfileEdits.name.value);
  late final _bio = TextEditingController(text: ProfileEdits.bio.value);

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
    _bio.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    super.dispose();
  }

  bool get _changed =>
      _name.text.trim() != ProfileEdits.name.value ||
      _bio.text.trim() != ProfileEdits.bio.value;

  void _save() {
    HapticFeedback.lightImpact();
    ProfileEdits.name.value = _name.text.trim();
    ProfileEdits.bio.value = _bio.text.trim();
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final handle = PortfolioMock.handle;
    final label = VistaType.label.copyWith(
      color: VistaColors.textMuted,
      letterSpacing: 0.6,
    );
    final input = VistaType.subheadMuted.copyWith(
      fontWeight: FontWeight.w400,
      color: VistaColors.textPrimary,
    );
    InputDecoration decoration(String hint) => InputDecoration(
      isDense: true,
      counterText: '',
      hintText: hint,
      hintStyle: input.copyWith(color: VistaColors.textPlaceholder),
      filled: true,
      fillColor: VistaColors.surface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: VistaSpace.gutter,
        vertical: VistaSpace.xl,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(VistaRadius.card),
        borderSide: BorderSide.none,
      ),
    );
    Widget count(TextEditingController c, int max) => Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(top: VistaSpace.xs),
        child: Text(
          '${c.text.characters.length}/$max',
          style: VistaType.caption.copyWith(color: VistaColors.textMuted),
        ),
      ),
    );

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Cancel · Edit profile · Save
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: VistaSpace.gutter,
              ),
              child: SizedBox(
                height: VistaSize.tapTarget + VistaSpace.md,
                child: Row(
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => Navigator.of(context).maybePop(),
                      child: SizedBox(
                        height: VistaSize.tapTarget,
                        child: Center(
                          child: Text(
                            'Cancel',
                            style: VistaType.subhead.copyWith(
                              color: VistaColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Edit profile',
                        textAlign: TextAlign.center,
                        style: VistaType.subhead,
                      ),
                    ),
                    Semantics(
                      button: true,
                      enabled: _changed,
                      label: 'Save',
                      excludeSemantics: true,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _changed ? _save : null,
                        child: SizedBox(
                          height: VistaSize.tapTarget,
                          child: Center(
                            child: Container(
                              height: 34,
                              padding: const EdgeInsets.symmetric(
                                horizontal: VistaSpace.xxl,
                              ),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _changed
                                    ? VistaColors.accent
                                    : VistaColors.surfaceRaised,
                                borderRadius: BorderRadius.circular(
                                  VistaRadius.pill,
                                ),
                              ),
                              child: Text(
                                'Save',
                                style: VistaType.body.copyWith(
                                  fontSize: 14,
                                  color: _changed
                                      ? VistaColors.onAccent
                                      : VistaColors.textMuted,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  VistaSpace.gutter,
                  VistaSpace.lg,
                  VistaSpace.gutter,
                  VistaSpace.section,
                ),
                children: [
                  // Photo: your initial until uploads come.
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: VistaColors.surface,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            (_name.text.trim().isEmpty
                                    ? handle
                                    : _name.text.trim())[0]
                                .toUpperCase(),
                            style: VistaType.displayMedium.copyWith(
                              color: VistaColors.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(height: VistaSpace.sm),
                        Text(
                          'Photo uploads come later',
                          style: VistaType.caption.copyWith(
                            color: VistaColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: VistaSpace.section),
                  Text('NAME', style: label),
                  const SizedBox(height: VistaSpace.sm),
                  TextField(
                    controller: _name,
                    maxLength: EditProfileScreen.nameLength,
                    maxLengthEnforcement: MaxLengthEnforcement.enforced,
                    textCapitalization: TextCapitalization.words,
                    style: input,
                    cursorColor: VistaColors.accent,
                    decoration: decoration('Shown above your handle'),
                  ),
                  count(_name, EditProfileScreen.nameLength),
                  const SizedBox(height: VistaSpace.lg),
                  Text('HANDLE', style: label),
                  const SizedBox(height: VistaSpace.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: VistaSpace.gutter,
                      vertical: VistaSpace.xl,
                    ),
                    decoration: BoxDecoration(
                      color: VistaColors.surface.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(VistaRadius.card),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            handle,
                            style: input.copyWith(
                              color: VistaColors.textSecondary,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.lock_outline_rounded,
                          size: 16,
                          color: VistaColors.textMuted,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: VistaSpace.xs),
                  Text(
                    'Your handle is how people find your calls and market, so '
                    'it stays the same.',
                    style: VistaType.caption.copyWith(
                      color: VistaColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: VistaSpace.section),
                  Text('BIO', style: label),
                  const SizedBox(height: VistaSpace.sm),
                  TextField(
                    controller: _bio,
                    minLines: 2,
                    maxLines: 3,
                    maxLength: EditProfileScreen.bioLength,
                    maxLengthEnforcement: MaxLengthEnforcement.enforced,
                    keyboardType: TextInputType.multiline,
                    textCapitalization: TextCapitalization.sentences,
                    style: input.copyWith(height: 1.35),
                    cursorColor: VistaColors.accent,
                    decoration: decoration('What you trade and how'),
                  ),
                  count(_bio, EditProfileScreen.bioLength),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
