import 'package:flutter/foundation.dart';

/// Broadcasts when daily nutrition data changed (meal log, order auto-log, etc.).
class NutritionRefreshNotifier extends ChangeNotifier {
  DateTime? _lastChangedDate;

  DateTime? get lastChangedDate => _lastChangedDate;

  void notifyDateChanged(DateTime date) {
    _lastChangedDate = DateTime(date.year, date.month, date.day);
    notifyListeners();
  }
}
