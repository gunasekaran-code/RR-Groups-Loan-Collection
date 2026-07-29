import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/overdue.dart';
import 'session_service.dart';
import '../config/api_config.dart';   
import 'package:shared_preferences/shared_preferences.dart';

/// Talks to backend/overdue.php.
///
/// IMPORTANT — this endpoint is READ + RECOMPUTE only, by design of the PHP:
///   • fetchOverdueAccounts()  -> GET  (returns the live derived list)
///   • recomputeOverdues()     -> POST (admin/agent only; flips loans.status
///                                 between 'active' <-> 'overdue')
///
/// There is no create/update/delete of an "overdue" record because overdue
/// accounts aren't stored rows — they're computed from loans + schedule.
/// Follow-up note/date assignment (see assignFollowUp below) has nowhere to
/// persist on the backend today, so it's a local-only, in-memory update.
/// If you want it saved server-side, that needs a new PHP endpoint/table
/// (e.g. a `follow_ups` table) — happy to help with that separately.
class OverdueApiService {
  OverdueApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Uri get _endpoint => Uri.parse('${ApiConfig.baseUrl}/overdue.php');

  Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token'); // match your login save key
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }


  /// GET /backend/overdue.php
  /// Returns the live list of overdue accounts (server also silently
  /// reconciles loan statuses on every GET, per the PHP).
  Future<List<OverdueAccount>> fetchOverdueAccounts() async {
    final res = await _client.get(_endpoint, headers: await _headers());
    _throwIfError(res);

    final decoded = jsonDecode(res.body);
    if (decoded is! List) {
      throw OverdueApiException('Unexpected response format from server.');
    }
    return decoded
        .cast<Map<String, dynamic>>()
        .map(OverdueAccount.fromJson)
        .toList();
  }

  /// POST /backend/overdue.php
  /// Forces a status recompute. Admin/agent only — backend returns 403
  /// otherwise. Returns the number of loans whose status changed.
  Future<int> recomputeOverdues() async {
    final res = await _client.post(_endpoint, headers: await _headers());
    _throwIfError(res);

    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    return (decoded['loans_updated'] as num?)?.toInt() ?? 0;
  }

  /// Convenience: recompute then re-fetch, so the UI reflects the latest
  /// server-side state in one call (used for pull-to-refresh / manual sync).
  Future<List<OverdueAccount>> recomputeAndFetch() async {
    try {
      await recomputeOverdues();
    } on OverdueApiException {
      // Non-admin/agent users get 403 on recompute — that's fine, GET still
      // triggers a recompute server-side anyway. Swallow and continue to fetch.
    }
    return fetchOverdueAccounts();
  }

  void _throwIfError(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) return;

    String message = 'Request failed (${res.statusCode})';
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map && decoded['error'] != null) {
        message = decoded['error'].toString();
      }
    } catch (_) {
      // body wasn't JSON; keep default message
    }
    throw OverdueApiException(message, statusCode: res.statusCode);
  }
}

class OverdueApiException implements Exception {
  OverdueApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}