import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/AppNotification.dart';
import 'session_service.dart';

class NotificationApiException implements Exception {
  final String message;
  final int? statusCode;
  NotificationApiException(this.message, [this.statusCode]);
  @override
  String toString() => message;
}

class NotificationService {
  static final http.Client _client = http.Client();

  static const String _baseUrl = ApiConfig.baseUrl;
  static const String _restEndpoint = '$_baseUrl/rest.php';
  static final Uri _notifCreateUri = Uri.parse(_restEndpoint)
      .replace(queryParameters: {'table': 'notifications'});

  static String? currentUserNotificationId() {
    final user = SessionService.instance.currentUser;
    if (user == null) return null;

    final userId = user.userId.trim();
    if (userId.isNotEmpty) return userId;

    return null;
  }

  static Map<String, String> get _headers {
    final token = SessionService.instance.token;
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static dynamic _decodeBody(http.Response res) {
    if (res.body.isEmpty) return {};
    try {
      return jsonDecode(res.body);
    } catch (_) {
      throw NotificationApiException('Invalid server response', res.statusCode);
    }
  }

  static List<dynamic> _decodeList(http.Response res) {
    final data = _decodeBody(res);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      final msg = data is Map<String, dynamic>
          ? (data['message']?.toString() ??
              data['error']?.toString() ??
              'Request failed')
          : 'Request failed (${res.statusCode})';
      throw NotificationApiException(msg, res.statusCode);
    }
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      final nested = data['data'];
      if (nested is List) return nested;
    }
    return [];
  }

  /// Fetch notifications for the currently logged-in account only.
  static Future<List<AppNotification>> fetchForCurrentUser() async {
    final currentUserId = currentUserNotificationId();
    if (currentUserId == null) return [];

    final uri = Uri.parse(
      '$_restEndpoint?table=notifications&user_id=eq.$currentUserId&order=created_at.desc',
    );

    final res = await _client.get(uri, headers: _headers);
    final list = _decodeList(res);
    return list
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .where((n) => n.userId == currentUserId)
        .toList();
  }

  static Future<void> markRead(String id) async {
    final res = await _client.patch(
      Uri.parse('$_restEndpoint?table=notifications&id=eq.$id'),
      headers: _headers,
      body: jsonEncode({'read': 1}),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw NotificationApiException('Failed to mark as read', res.statusCode);
    }
  }

  static Future<void> markAllRead(List<String> ids) async {
    for (final id in ids) {
      await markRead(id);
    }
  }

  static Future<void> delete(String id) async {
    final res = await _client.delete(
      Uri.parse('$_restEndpoint?table=notifications&id=eq.$id'),
      headers: _headers,
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw NotificationApiException(
          'Failed to delete notification', res.statusCode);
    }
  }

  /// Send a notification to one or more user_ids
  static Future<void> send({
    required List<String> userIds,
    required String type,
    required String title,
    required String message,
  }) async {
    for (final uid in userIds) {
      final res = await _client.post(
        _notifCreateUri,
        headers: _headers,
        body: jsonEncode({
          'user_id': uid,
          'title': title,
          'message': message,
          'type': type,
          'read': 0,
        }),
      );
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw NotificationApiException(
            'Failed to send to $uid', res.statusCode);
      }
    }
  }

  /// Returns just the count of unread notifications for a user.
  static Future<int> fetchUnreadCount({String? userId}) async {
    final effectiveUserId = userId ?? currentUserNotificationId();
    final uri = effectiveUserId == null
        ? Uri.parse('$_restEndpoint?table=notifications&read=eq.0')
        : Uri.parse(
            '$_restEndpoint?table=notifications&user_id=eq.$effectiveUserId&read=eq.0');

    final res = await _client.get(uri, headers: _headers);
    final list = _decodeList(res);
    return list.length;
  }
}
