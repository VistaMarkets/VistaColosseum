/// Sample account shown on the Settings screen (Figma 442:102). Simulated.
abstract final class SettingsMock {
  static const handle = 'maya.eth';

  /// Bio as designed; the backend caps bios at 60 characters.
  static const bio = 'Macro-first. Mostly BTC and SOL, rarely past 5x.';

  /// The design shows an Ethereum-style `0x7a3f…C41b`, but the backend's
  /// Phase 1 wallet is a Solana (base58) address, so the demo shows one.
  /// Not a real wallet.
  static const wallet = '7a3fQm9ZkL2vXcR8tHy4NbW1uPe6sDgJ5oViC41b';

  /// First four and last four characters.
  static String get walletShort =>
      '${wallet.substring(0, 4)}…${wallet.substring(wallet.length - 4)}';

  /// Notification categories, in the design's order, keyed like the
  /// backend's `NotificationPrefs` fields.
  static const categories = [
    ('calls', 'Calls', 'When someone you follow makes a call'),
    ('technicals', 'Technicals', 'When we spot something on a chart'),
    ('traders', 'Traders', 'When someone takes a call you are in'),
    ('flips', 'Flips', 'When a call turns green or red'),
  ];

  static const permissionUntil = 'Mar 26, 2027';
  static const termsVersion = '2026-09-16';
  static const country = 'United States';
  static const appVersion = '1.0.0 (demo)';
}
