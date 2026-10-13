import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../arena/arena_mock.dart';
import '../arena/battle_screen.dart';
import '../arena/hub_call_card.dart';
import '../calls/calls_store.dart';
import '../trade/caller_play_screen.dart';
import '../trade/order_ticket.dart';
import '../market/trader_market_screen.dart';
import '../people/follow_list_screen.dart';
import '../people/follow_state.dart';
import '../portfolio/portfolio_mock.dart';
import '../profile/profile_screen.dart';
import '../profile/receipts_screen.dart';
import '../trade/asset_trade_screen.dart';

/// What a notification is about, for the filter chips and its icon.
enum NoteKind { calls, people, markets }

/// One notification. [handle] is who it's from (null for market alerts);
/// [lead] is the bold part, [rest] the rest of the sentence.
class Note {
  const Note({
    required this.kind,
    required this.lead,
    required this.rest,
    required this.age,
    required this.open,
    this.handle,
    this.detail,
    this.detailColor,
  });

  final NoteKind kind;
  final String? handle;
  final String lead;
  final String rest;

  /// A second line (a result, a price), coloured when it's a gain or loss.
  final String? detail;
  final Color? detailColor;
  final String age;

  /// Where it leads.
  final Route<void> Function() open;
}

/// The viewer's notifications: who joined your calls, new followers, your
/// calls settling (with your market's move), and markets you hold moving.
/// New calls from people you follow come live from `CallsStore` and show
/// as call cards. Mock: the backend's
/// `/v1/notifications` and its stream replace it.
abstract final class Notifications {
  static final unread = ValueNotifier<int>(4);

  static void markRead() => unread.value = 0;
  static void reset() {
    unread.value = 4;
    all.removeRange(0, all.length - _seeded);
  }

  /// A new note goes on top and lights the bell.
  static void add(Note n) {
    // Count the seeded ones before the first addition.
    _seedCount;
    all.insert(0, n);
    unread.value++;
  }

  static int get _seeded => _seedCount;

  static final all = <Note>[
    Note(
      kind: NoteKind.calls,
      handle: 'kilo.sol',
      lead: 'kilo.sol and 11 others',
      rest: ' joined your ETH long',
      detail: r'$4.8K followed your call',
      age: '12m',
      open: () => ReceiptsScreen.route(PortfolioMock.handle),
    ),
    Note(
      kind: NoteKind.markets,
      lead: 'MAYA ▲4.3% today',
      rest: '   26 new holders of your market',
      detail: r'$0.4400   cap $44.0M',
      detailColor: VistaColors.long,
      age: '40m',
      open: () => TraderMarketScreen.route(PortfolioMock.handle),
    ),
    Note(
      kind: NoteKind.people,
      handle: 'sam.sol',
      lead: 'sam.sol',
      rest: ' started following you',
      age: '1h',
      open: () => ProfileScreen.route('sam.sol'),
    ),
    Note(
      kind: NoteKind.calls,
      lead: 'Your ETH long settled right',
      rest: r'   $2,948 → $3,050',
      detail: '+17.3%   MAYA ▲2.1% as it settled',
      detailColor: VistaColors.long,
      age: '1h',
      open: () => ReceiptsScreen.route(PortfolioMock.handle),
    ),
    Note(
      kind: NoteKind.markets,
      lead: 'SOL ▲3.8%',
      rest: '   against your 10x short',
      detail: r'$214.90   your position −2.1%',
      detailColor: VistaColors.short,
      age: '3h',
      open: () => AssetTradeScreen.route('SOL'),
    ),
    Note(
      kind: NoteKind.people,
      handle: 'nara',
      lead: 'nara and 3 others',
      rest: ' started following you',
      age: '1d',
      open: () => FollowListScreen.route(),
    ),
    Note(
      kind: NoteKind.calls,
      lead: 'Your SOL short settled wrong',
      rest: r'   $201 → $209',
      detail: '−6.0%   MAYA ▼0.8% as it settled',
      detailColor: VistaColors.short,
      age: '2d',
      open: () => ReceiptsScreen.route(PortfolioMock.handle),
    ),
  ];

  /// How many seeded notes [all] starts with.
  static final _seedCount = all.length;
}

/// Notifications (the bell on Home, Explore and Arena): All, Calls, People
/// or Markets; today first, then earlier. Opening it marks everything read.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  static Route<void> route() =>
      MaterialPageRoute(builder: (_) => const NotificationsScreen());

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const _filters = ['All', 'Calls', 'People', 'Markets'];
  int _filter = 0;

  /// What was unread when the page opened, so those keep their dot.
  late final int _fresh = Notifications.unread.value;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => Notifications.markRead(),
    );
  }

  void _push(Route<void> route) => Navigator.of(context).push(route);

  /// New calls from people you follow, as call cards (newest first).
  static const _postsShown = 5;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: CallsStore.all,
      builder: (context, calls, _) => ValueListenableBuilder(
        valueListenable: FollowState.following,
        builder: (context, following, _) => _page(calls, following),
      ),
    );
  }

  Widget _page(List<Take> calls, Set<String> following) {
    final posts =
        [
          for (final t in calls)
            // Only calls with a position behind them.
            if (t.backed &&
                following.contains(t.handle) &&
                t.handle != PortfolioMock.handle)
              t,
        ]..sort(
          (a, b) =>
              CallsStore.minutesAgo(a.age)
                  .compareTo(CallsStore.minutesAgo(b.age)),
        );
    // Everything in time order: notes and your follows' calls.
    final items = <(int, Object)>[
      for (final n in Notifications.all)
        if (_filter == 0 || n.kind.index == _filter - 1)
          (CallsStore.minutesAgo(n.age), n),
      if (_filter <= 1)
        for (final t in posts.take(_postsShown))
          (CallsStore.minutesAgo(t.age), t),
    ]..sort((a, b) => a.$1.compareTo(b.$1));
    final today = [
      for (final e in items)
        if (e.$1 < 1440) e,
    ];
    final earlier = [
      for (final e in items)
        if (e.$1 >= 1440) e,
    ];
    Widget head(String t) => Padding(
      padding: const EdgeInsets.fromLTRB(
        VistaSpace.gutter + VistaSpace.xs,
        VistaSpace.lg,
        VistaSpace.gutter + VistaSpace.xs,
        VistaSpace.xs,
      ),
      child: Text(
        t.toUpperCase(),
        style: VistaType.label.copyWith(
          color: VistaColors.textMuted,
          letterSpacing: 0.6,
        ),
      ),
    );
    Widget row(int i, Object item) {
      final unread = i < _fresh;
      if (item is Take) {
        return _PostNote(
          take: item,
          unread: unread,
          onCaller: () => _push(ProfileScreen.route(item.handle)),
          onMarket: () => _push(TraderMarketScreen.route(item.handle)),
          onDebate: Debates.of(item) == null
              ? null
              : () => _push(BattleScreen.route(Debates.of(item)!)),
          onPosition: () {
            if (item.call == null) return;
            _push(CallerPlayScreen.route(CallsStore.postOf(item), item.ticker));
          },
          // Simulated only: joining places nothing real.
          onJoin: () =>
              showOrderTicket(context, symbol: item.ticker, side: item.side),
        );
      }
      final n = item as Note;
      return _NoteRow(note: n, unread: unread, onTap: () => _push(n.open()));
    }

    final notes = items;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                VistaSpace.gutter,
                VistaSpace.md,
                VistaSpace.gutter,
                0,
              ),
              child: Row(
                children: [
                  VistaIconButton(
                    asset: VistaAssets.backSmall,
                    semanticLabel: 'Back',
                    iconSize: VistaSize.icon,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: VistaSpace.xs),
                  Text('Notifications', style: VistaType.title),
                ],
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(
                VistaSpace.gutter,
                VistaSpace.md,
                VistaSpace.gutter,
                VistaSpace.xs,
              ),
              child: Row(
                children: [
                  for (var i = 0; i < _filters.length; i++) ...[
                    if (i > 0) const SizedBox(width: VistaSpace.md),
                    VistaFilterChip(
                      label: _filters[i],
                      accent: true,
                      selected: i == _filter,
                      onPressed: () => setState(() => _filter = i),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: notes.isEmpty
                  ? Center(
                      child: Text(
                        'Nothing here yet',
                        style: VistaType.body.copyWith(
                          color: VistaColors.textMuted,
                        ),
                      ),
                    )
                  : ListView(
                      padding: EdgeInsets.only(
                        bottom:
                            VistaSpace.gutter +
                            MediaQuery.paddingOf(context).bottom,
                      ),
                      children: [
                        if (today.isNotEmpty) head('Today'),
                        for (final (i, e) in today.indexed) row(i, e.$2),
                        if (earlier.isNotEmpty) head('Earlier'),
                        for (final (i, e) in earlier.indexed)
                          row(today.length + i, e.$2),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One notification: who (or what), the sentence, a detail line, the age,
/// and a dot while it's new. Follows get a Follow back button.
class _NoteRow extends StatelessWidget {
  const _NoteRow({
    required this.note,
    required this.unread,
    required this.onTap,
  });

  final Note note;
  final bool unread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final n = note;
    final icon = switch (n.kind) {
      NoteKind.calls => Icons.campaign_outlined,
      NoteKind.people => Icons.person_add_alt_1_outlined,
      NoteKind.markets => Icons.show_chart_rounded,
    };
    final followBack =
        n.kind == NoteKind.people && n.handle != null && !n.lead.contains(' ');
    return Semantics(
      button: true,
      label: '${n.lead}${n.rest}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: VistaSpace.gutter + VistaSpace.xs,
            vertical: VistaSpace.xl,
          ),
          decoration: BoxDecoration(
            color: unread ? VistaColors.accent.withValues(alpha: 0.06) : null,
            border: const Border(
              bottom: BorderSide(color: VistaColors.hairline),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Who it's from, with what kind of note on their corner.
              SizedBox(
                width: 44,
                height: 44,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    if (n.handle != null)
                      PersonInitial(
                        n.handle!,
                        size: 40,
                        ring: VistaColors.surfaceRaised,
                      )
                    else
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: VistaColors.surfaceRaised,
                          shape: BoxShape.circle,
                        ),
                      ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 20,
                        height: 20,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: VistaColors.accent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: VistaColors.background,
                            width: 2,
                          ),
                        ),
                        child: Icon(icon, size: 11, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: VistaSpace.xl),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: n.lead,
                            style: const TextStyle(
                              color: VistaColors.textPrimary,
                            ),
                          ),
                          TextSpan(
                            text: n.rest,
                            style: const TextStyle(
                              color: VistaColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      style: VistaType.body.copyWith(
                        fontSize: 14,
                        height: 1.35,
                      ),
                    ),
                    if (n.detail != null) ...[
                      const SizedBox(height: VistaSpace.xxs),
                      Text(
                        n.detail!,
                        style: VistaType.bodyMedium.copyWith(
                          color: n.detailColor ?? VistaColors.textMuted,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: VistaSpace.xxs),
                    Text(
                      n.age,
                      style: VistaType.caption.copyWith(
                        color: VistaColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (followBack) ...[
                const SizedBox(width: VistaSpace.md),
                ValueListenableBuilder(
                  valueListenable: FollowState.following,
                  builder: (context, following, _) => VistaFollowButton(
                    following: following.contains(n.handle),
                    onPressed: () => FollowState.toggle(n.handle!),
                  ),
                ),
              ] else if (unread) ...[
                const SizedBox(width: VistaSpace.md),
                Padding(
                  padding: const EdgeInsets.only(top: VistaSpace.md),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: VistaColors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A new call from someone you follow, as the call card it is everywhere
/// else, with a line saying why it's here.
class _PostNote extends StatelessWidget {
  const _PostNote({
    required this.take,
    required this.unread,
    required this.onCaller,
    required this.onMarket,
    required this.onPosition,
    required this.onJoin,
    this.onDebate,
  });

  final Take take;
  final bool unread;
  final VoidCallback onCaller;
  final VoidCallback onMarket;
  final VoidCallback onPosition;
  final VoidCallback onJoin;
  final VoidCallback? onDebate;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: unread ? VistaColors.accent.withValues(alpha: 0.06) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              VistaSpace.gutter + VistaSpace.xs + 52,
              VistaSpace.lg,
              VistaSpace.gutter + VistaSpace.xs,
              0,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.campaign_outlined,
                  size: 14,
                  color: VistaColors.accent,
                ),
                const SizedBox(width: VistaSpace.xs),
                Text(
                  'New call from someone you follow',
                  style: VistaType.caption.copyWith(
                    color: VistaColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          HubCallCard(
            take: take,
            onCaller: onCaller,
            onMarket: onMarket,
            onDebate: onDebate,
            onPosition: onPosition,
            onJoin: onJoin,
          ),
        ],
      ),
    );
  }
}
