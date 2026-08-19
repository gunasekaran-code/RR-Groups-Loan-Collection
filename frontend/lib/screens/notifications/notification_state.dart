// notification_state.dart

import 'package:flutter/foundation.dart';
import '../../services/NotificationService.dart';

class NotificationState extends ChangeNotifier {
  static final NotificationState instance = NotificationState._();
  NotificationState._();

  int _unreadCount = 0;
  int get unreadCount => _unreadCount;

  Future<void> refreshUnreadCount() async {
    try {
      final count = await NotificationService.fetchUnreadCount();
      _unreadCount = count;
      notifyListeners();
    } catch (_) {
    }
  }

  void setCount(int count) {
    _unreadCount = count;
    notifyListeners();
  }
}