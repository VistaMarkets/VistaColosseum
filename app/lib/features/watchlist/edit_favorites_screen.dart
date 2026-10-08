import 'package:flutter/cupertino.dart' show CupertinoPageRoute;
import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../markets/markets_mock.dart';
import '../live/market_prices.dart';
import 'watchlist_state.dart';

/// Edit favourites (Explore › Favorites › Edit): drag to reorder, tap the
/// star to remove. Works on the Assets or the Traders list, whichever tab it
/// was opened from. Changes apply at once; there is nothing to save.
class EditFavoritesScreen extends StatelessWidget {
  const EditFavoritesScreen({super.key, required this.traders});

  static Route<void> route({required bool traders}) =>
      CupertinoPageRoute(builder: (_) => EditFavoritesScreen(traders: traders));

  final bool traders;

  ValueNotifier<List<String>> get _list =>
      traders ? WatchlistState.traders : WatchlistState.assets;

  MarketItem? _item(String id) {
    for (final m in traders ? MarketsMock.traders : MarketsMock.assets) {
      if (m.id == id) return m;
    }
    return null;
  }

  void _remove(BuildContext context, String id, int index) {
    final list = _list;
    list.value = List.unmodifiable(list.value.where((e) => e != id));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Removed $id from Favorites'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              if (list.value.contains(id)) return;
              final items = [...list.value];
              items.insert(index.clamp(0, items.length), id);
              list.value = List.unmodifiable(items);
            },
          ),
        ),
      );
  }

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
                  Expanded(
                    child: Text(
                      traders ? 'Favorite traders' : 'Favorite markets',
                      style: VistaType.title,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                VistaSpace.gutter,
                VistaSpace.xs,
                VistaSpace.gutter,
                VistaSpace.md,
              ),
              child: Text(
                'Drag to reorder. Tap the star to remove.',
                style: VistaType.bodyRegular,
              ),
            ),
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: _list,
                builder: (context, ids, _) {
                  if (ids.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(VistaSpace.gutter),
                      child: Text(
                        'No favorites yet. Tap ☆ on a market to add it.',
                        style: VistaType.bodyRegular,
                      ),
                    );
                  }
                  return ReorderableListView.builder(
                    buildDefaultDragHandles: false,
                    padding: EdgeInsets.fromLTRB(
                      VistaSpace.gutter,
                      0,
                      VistaSpace.gutter,
                      MediaQuery.paddingOf(context).bottom + VistaSpace.xl,
                    ),
                    itemCount: ids.length,
                    onReorderItem: (from, to) =>
                        WatchlistState.move(_list, from, to),
                    itemBuilder: (context, i) {
                      final id = ids[i];
                      final m = _item(id);
                      return _FavoriteRow(
                        key: ValueKey(id),
                        index: i,
                        name: id,
                        icon: m?.rowIcon,
                        detail: m == null
                            ? null
                            : '${MarketPrices.format(MarketPrices.now(id), compact: true)}'
                                  '   ${m.subline}',
                        onRemove: () => _remove(context, id, i),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoriteRow extends StatelessWidget {
  const _FavoriteRow({
    super.key,
    required this.index,
    required this.name,
    required this.onRemove,
    this.icon,
    this.detail,
  });

  final int index;
  final String name;
  final String? icon;
  final String? detail;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: VistaColors.background,
      child: Column(
        children: [
          Row(
            children: [
              ReorderableDragStartListener(
                index: index,
                child: Semantics(
                  label: 'Reorder $name',
                  child: SizedBox.square(
                    dimension: VistaSize.tapTarget,
                    // Three short rules (the font has no ≡ glyph).
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < 3; i++)
                          Container(
                            width: 16,
                            height: 2,
                            margin: const EdgeInsets.symmetric(vertical: 1.5),
                            decoration: BoxDecoration(
                              color: VistaColors.textSecondary,
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              if (icon != null) ...[
                VistaIcon(icon!, size: 32),
                const SizedBox(width: VistaSpace.lg),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: VistaType.subhead),
                    if (detail != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        detail!,
                        style: VistaType.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              VistaStarButton(starred: true, onPressed: onRemove, size: 18),
            ],
          ),
          const VistaSettingsDivider(),
        ],
      ),
    );
  }
}
