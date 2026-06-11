import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sync_app/data/models/notification_models.dart';

/// Global in-app notification badge + realtime stream for toast/snackbar UI.
class NotificationInboxNotifier extends ChangeNotifier {
  int _unreadCount = 0;
  final _incomingController = StreamController<AppNotification>.broadcast();

  int get unreadCount => _unreadCount;
  Stream<AppNotification> get incoming => _incomingController.stream;

  void setUnreadCount(int count) {
    if (_unreadCount == count) return;
    _unreadCount = count;
    notifyListeners();
  }

  void onRealtimeNotification(AppNotification notification) {
    _unreadCount++;
    _incomingController.add(notification);
    notifyListeners();
  }

  void decrementUnread() {
    if (_unreadCount <= 0) return;
    _unreadCount--;
    notifyListeners();
  }

  void clearUnread() {
    _unreadCount = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _incomingController.close();
    super.dispose();
  }
}
