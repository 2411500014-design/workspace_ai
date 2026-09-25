import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

String _locale(BuildContext context) => Localizations.localeOf(context).languageCode;

/// "24 Sep" this year, "24 Sep 2027" otherwise, in the app's language.
String formatDate(BuildContext context, DateTime date, {bool alwaysYear = false}) {
  final now = DateTime.now();
  final pattern = (alwaysYear || date.year != now.year) ? DateFormat.yMMMd(_locale(context)) : DateFormat.MMMd(_locale(context));
  return pattern.format(date);
}

String formatDateLong(BuildContext context, DateTime date) => DateFormat.yMMMMEEEEd(_locale(context)).format(date);

String weekdayShort(BuildContext context, int mondayBasedIndex) {
  // 2024-01-01 was a Monday.
  return DateFormat.E(_locale(context)).format(DateTime(2024, 1, 1 + mondayBasedIndex));
}

/// 2, 1.5 or 0.25 — never "2.0".
String formatHours(double hours) {
  final rounded = (hours * 100).round() / 100;
  return rounded == rounded.roundToDouble() ? rounded.toInt().toString() : rounded.toString();
}

String formatPct(double fraction) => (fraction * 100).round().toString();

String formatNumber(BuildContext context, num value) => NumberFormat.decimalPattern(_locale(context)).format(value);

String isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
