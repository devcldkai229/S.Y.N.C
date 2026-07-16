/// Calendar-day helpers for the nutrition diary (local timezone, no UTC day drift).
abstract final class NutritionDateHelpers {
  static DateTime dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  /// yyyy-MM-dd for API query/body fields (calendar day, not UTC).
  static String toApiDate(DateTime date) {
    final d = dateOnly(date);
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  /// Instant to store when logging a meal on [diaryDate] in the diary.
  static DateTime logInstantForDiaryDate(DateTime diaryDate) {
    final day = dateOnly(diaryDate);
    final today = dateOnly(DateTime.now());
    if (day == today) return DateTime.now();
    return DateTime(day.year, day.month, day.day, 12, 0);
  }

  /// Parse API date-only strings without shifting to previous UTC day.
  static DateTime? parseApiDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final datePart = raw.split('T').first.trim();
    final parts = datePart.split('-');
    if (parts.length == 3) {
      final y = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      final d = int.tryParse(parts[2]);
      if (y != null && m != null && d != null) {
        return DateTime(y, m, d);
      }
    }
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return null;
    final local = parsed.toLocal();
    return DateTime(local.year, local.month, local.day);
  }
}
