// notification_state.dart

import 'package:flutter/foundation.dart';
import '../../services/NotificationService.dart';

class NotificationState extends ChangeNotifier {
  static final NotificationState instance = NotificationState._();
  NotificationState._();

  int _unreadCount = 0;
  int get unreadCount => _unreadCount;
  bool _refreshing = false;

  Future<void> refreshUnreadCount() async {
    if (_refreshing) return;
    _refreshing = true;
    try {
      final count = await NotificationService.fetchUnreadCount();
      if (_unreadCount != count) {
        _unreadCount = count;
        notifyListeners();
      }
    } catch (_) {
      // A badge failure must never prevent the rest of the screen from loading.
    } finally {
      _refreshing = false;
    }
  }

  void setCount(int count) {
    final normalizedCount = count < 0 ? 0 : count;
    if (_unreadCount == normalizedCount) return;
    _unreadCount = normalizedCount;
    notifyListeners();
  }
}
