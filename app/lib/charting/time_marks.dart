/// Label spacings the time axis may use, finest first.
const _spacings = [
  Duration(minutes: 1),
  Duration(minutes: 5),
  Duration(minutes: 15),
  Duration(minutes: 30),
  Duration(hours: 1),
  Duration(hours: 2),
  Duration(hours: 4),
  Duration(hours: 6),
  Duration(hours: 12),
  Duration(days: 1),
  Duration(days: 2),
  Duration(days: 7),
  Duration(days: 14),
  Duration(days: 30),
];

/// Indexes of the candles that get a time label.
///
/// Picks the finest clock spacing (15m, 1h, 2h, 1 day…) that keeps labels at
/// least [minGap] apart when each candle is [slot] wide, then labels only
/// the candles that open on a whole multiple of it, so the axis reads 06:00,
/// 08:00, 10:00 rather than wherever the window happens to start.
List<int> timeMarks(List<DateTime> times, double slot, {double minGap = 56}) {
  if (times.length < 2 || slot <= 0) return const [];
  final period = times[1].difference(times[0]);
  if (period <= Duration.zero) return const [];

  final spacing = _spacings.firstWhere(
    (s) => s >= period && s.inSeconds / period.inSeconds * slot >= minGap,
    orElse: () => _spacings.last,
  );
  return [
    for (var i = 0; i < times.length; i++)
      if (_onBoundary(times[i], spacing)) i,
  ];
}

bool _onBoundary(DateTime t, Duration spacing) {
  if (spacing < const Duration(days: 1)) {
    final minutes = t.hour * 60 + t.minute;
    return t.second == 0 && minutes % spacing.inMinutes == 0;
  }
  if (t.hour != 0 || t.minute != 0) return false;
  final day =
      DateTime.utc(t.year, t.month, t.day).millisecondsSinceEpoch ~/
      Duration.millisecondsPerDay;
  return day % spacing.inDays == 0;
}

/// Month abbreviations as labels and fixture dates write them ("Sep").
const monthAbbrs = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// Clock time for intraday candles ("14:00"), date for daily ones ("26 Sep").
String timeLabel(DateTime t, Duration period) {
  if (period >= const Duration(days: 1)) {
    return '${t.day} ${monthAbbrs[t.month - 1]}';
  }
  String pad(int v) => v.toString().padLeft(2, '0');
  return '${pad(t.hour)}:${pad(t.minute)}';
}

/// [t] rounded down to the start of its [period] in local time: 14:45 →
/// 14:00 for 1h candles, midnight for daily ones.
DateTime alignToPeriod(DateTime t, Duration period) {
  final day = DateTime(t.year, t.month, t.day);
  if (period >= const Duration(days: 1)) return day;
  final minutes = t.hour * 60 + t.minute;
  return day.add(Duration(minutes: minutes - minutes % period.inMinutes));
}
