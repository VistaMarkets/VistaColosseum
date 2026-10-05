import 'package:flutter/foundation.dart';

import '../../scenario/scenario.dart';
import 'mock_trade_idea.dart';

/// Calls the viewer has liked, shared by every card showing the same call.
/// The set lives in [Scenario]: the demo sends nothing and likes reset on
/// restart or Reset demo.
abstract final class LikesState {
  static ValueNotifier<Set<String>> get liked => Scenario.liked;

  static String _key(TradeIdea i) => '${i.callerHandle}/${i.ticker}';

  static bool isLiked(TradeIdea i) => liked.value.contains(_key(i));

  /// Likes or unlikes [i]; returns whether it is now liked.
  static bool toggle(TradeIdea i) {
    final k = _key(i);
    final on = !liked.value.contains(k);
    liked.value = on
        ? Set.unmodifiable({...liked.value, k})
        : Set.unmodifiable(liked.value.where((e) => e != k));
    return on;
  }

  /// The count with the viewer's like: "980" → "981"; rounded counts
  /// ("4.4k") don't move for one like.
  static String count(TradeIdea i) {
    final n = int.tryParse(i.likes);
    return n != null && isLiked(i) ? '${n + 1}' : i.likes;
  }
}
