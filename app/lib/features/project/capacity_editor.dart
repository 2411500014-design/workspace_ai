import 'package:material_ui/material_ui.dart';

import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/common.dart';

@immutable
class CapacityValue {
  const CapacityValue({required this.hours, required this.blockedDates, required this.bufferPct});

  final List<double> hours;
  final List<DateTime> blockedDates;
  final double bufferPct;

  double get weekly => hours.fold(0, (a, b) => a + b);

  CapacityValue copyWith({List<double>? hours, List<DateTime>? blockedDates, double? bufferPct}) =>
      CapacityValue(hours: hours ?? this.hours, blockedDates: blockedDates ?? this.blockedDates, bufferPct: bufferPct ?? this.bufferPct);
}

/// Hours per weekday, days off, and the time buffer (master plan §8 scheduler input).
class CapacityEditor extends StatelessWidget {
  const CapacityEditor({super.key, required this.value, required this.onChanged});

  final CapacityValue value;
  final ValueChanged<CapacityValue> onChanged;

  static const double _step = 0.5;
  static const double _max = 12;

  void _setHours(int day, double hours) {
    final next = [...value.hours]..[day] = hours.clamp(0, _max);
    onChanged(value.copyWith(hours: next));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l.capacityIntro, style: theme.textTheme.bodyLarge),
        const SizedBox(height: Space.md),
        for (var day = 0; day < 7; day++)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.xs),
            child: Row(
              children: [
                SizedBox(width: 72, child: Text(weekdayShort(context, day), style: theme.textTheme.titleSmall)),
                IconButton(
                  tooltip: '−${formatHours(_step)}',
                  onPressed: value.hours[day] <= 0 ? null : () => _setHours(day, value.hours[day] - _step),
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                SizedBox(
                  width: 72,
                  child: Text(l.hoursValue(formatHours(value.hours[day])), textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
                ),
                IconButton(
                  tooltip: '+${formatHours(_step)}',
                  onPressed: value.hours[day] >= _max ? null : () => _setHours(day, value.hours[day] + _step),
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
          ),
        const SizedBox(height: Space.sm),
        Text(l.capacityWeekly(formatHours(value.weekly)), style: theme.textTheme.titleMedium),
        const SizedBox(height: Space.xl),
        Text(l.blockedDates, style: theme.textTheme.titleMedium),
        const SizedBox(height: Space.sm),
        Wrap(
          spacing: Space.sm,
          runSpacing: Space.sm,
          children: [
            for (final d in value.blockedDates)
              InputChip(
                label: Text(formatDate(context, d, alwaysYear: true)),
                onDeleted: () => onChanged(value.copyWith(blockedDates: [...value.blockedDates]..remove(d))),
                deleteButtonTooltipMessage: l.actionDelete,
              ),
            ActionChip(
              avatar: const Icon(Icons.add, size: 18),
              label: Text(l.addBlockedDate),
              onPressed: () async {
                final now = DateTime.now();
                final picked = await pickDate(context, first: now, last: DateTime(now.year + 3));
                if (picked != null && !value.blockedDates.any((d) => isoDate(d) == isoDate(picked))) {
                  onChanged(value.copyWith(blockedDates: [...value.blockedDates, dateOnly(picked)]..sort()));
                }
              },
            ),
          ],
        ),
        const SizedBox(height: Space.xl),
        Text(l.bufferLabel(formatPct(value.bufferPct)), style: theme.textTheme.titleMedium),
        const SizedBox(height: Space.sm),
        SegmentedButton<double>(
          showSelectedIcon: false,
          segments: [
            for (final pct in const [0.10, 0.15, 0.20, 0.30]) ButtonSegment(value: pct, label: Text('${formatPct(pct)}%')),
          ],
          selected: {value.bufferPct},
          onSelectionChanged: (s) => onChanged(value.copyWith(bufferPct: s.first)),
        ),
      ],
    );
  }
}
