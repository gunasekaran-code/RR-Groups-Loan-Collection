import '../models/AppNotification.dart';
import 'api_service.dart';

class NotificationService {
  static const String _table = 'notifications';

  static Future<List<AppNotification>> fetchAll() async {
    final res = await ApiService.get(_table);
    final List data = res is List ? res : (res['data'] as List? ?? []);
    return data
        .map((e) => AppNotification.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<void> markRead(String id) async {
    await ApiService.put(_table, id: id, body: {'read': 1});
  }

  static Future<void> markAllRead(List<String> ids) async {
    await Future.wait(ids.map((id) => markRead(id)));
  }

  static Future<void> delete(String id) async {
    await ApiService.delete(_table, id: id);
  }

  static Future<AppNotification> create(AppNotification n) async {
    final res = await ApiService.post(_table, body: n.toCreateJson());
    return AppNotification.fromJson(Map<String, dynamic>.from(res));
  }
}