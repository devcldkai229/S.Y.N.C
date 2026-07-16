import 'package:flutter/foundation.dart';

/// Broadcasts when roadmap / AI schedule data changed (SignalR RoadmapUpdated).
class RoadmapRefreshNotifier extends ChangeNotifier {
  int _generation = 0;
  String? _lastKind;

  int get generation => _generation;
  String? get lastKind => _lastKind;

  void notifyUpdated({String? kind}) {
    _generation += 1;
    _lastKind = kind;
    notifyListeners();
  }
}
