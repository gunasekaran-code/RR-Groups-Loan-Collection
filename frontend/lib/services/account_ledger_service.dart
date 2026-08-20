// lib/services/account_ledger_service.dart
//
// CRUD service for the `account_ledger` table via the PHP backend.
//
// Endpoint:
//   GET    {baseUrl}/account_book.php            -> list all entries
//   POST   {baseUrl}/account_book.php            -> create entry (JSON body)
//   POST + method override {baseUrl}/account_book.php?id={id} -> update/delete
//
// Expected JSON list response: either a raw JSON array, or
// { "success": true, "data": [ ... ] } — both are handled below.
// Expected single-entry response on create/update: either the raw entry
// object, or { "success": true, "data": { ... } }.

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/account_ledger_model.dart';
import 'method_override_http.dart';
import 'session_service.dart';

class AccountLedgerException implements Exception {
  final String message;
  AccountLedgerException(this.message);

  @override
  String toString() => message;
}

class AccountLedgerService {
  AccountLedgerService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  /// Uses the one global API base URL and never produces `//account_book.php`.
  static String get _endpoint =>
      '${ApiConfig.normalizedBaseUrl}/account_book.php';
  static String get _restEndpoint => '${ApiConfig.normalizedBaseUrl}/rest.php';

  Map<String, String> get _headers {
    final token = SessionService.instance.token;
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  /// Fetch all ledger entries.
  Future<List<AccountLedgerEntry>> fetchEntries() async {
    final uri = Uri.parse(_endpoint);
    final res = await _client.get(uri, headers: _headers);

    if (res.statusCode != 200) {
      throw AccountLedgerException(
          'Failed to load ledger entries (${res.statusCode}).');
    }

    final decoded = jsonDecode(res.body);
    final list = _extractList(decoded);

    return list
        .map((e) => AccountLedgerEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetch the server-calculated, real-time Account Book totals.
  Future<AccountLedgerSummary> fetchSummary() async {
    final uri = Uri.parse(_endpoint).replace(queryParameters: {
      'action': 'summary',
    });
    final res = await _client.get(uri, headers: _headers);

    if (res.statusCode != 200) {
      throw AccountLedgerException(
        _errorMessage(res, 'Failed to load account book summary'),
      );
    }

    final decoded = jsonDecode(res.body);
    return AccountLedgerSummary.fromJson(_extractMap(decoded));
  }

  /// Create a new ledger entry. Returns the created entry (with server-assigned id).
  Future<AccountLedgerEntry> createEntry(AccountLedgerEntry entry) async {
    final uri = Uri.parse(_endpoint);
    final res = await _client.post(
      uri,
      headers: _headers,
      body: jsonEncode(entry.toCreateJson()),
    );

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw AccountLedgerException(
          'Failed to create ledger entry (${res.statusCode}).');
    }

    final decoded = jsonDecode(res.body);
    final map = _extractSingle(decoded);
    return AccountLedgerEntry.fromJson(map);
  }

  /// Update an existing ledger entry. `entry.id` must be set.
  Future<AccountLedgerEntry> updateEntry(AccountLedgerEntry entry) async {
    if (entry.id.isEmpty) {
      throw AccountLedgerException('Cannot update an entry without an id.');
    }

    // The PHP controller uses the HTTP method and the id query parameter to
    // select the update route. Do not send an action=update POST: that is not
    // a route understood by ResourceController.
    final uri = Uri.parse(_restEndpoint).replace(queryParameters: {
      'table': 'account_ledger',
      'id': 'eq.${entry.id}',
    });
    final res = await postWithMethodOverride(
      uri,
      method: 'PATCH',
      headers: _headers,
      body: jsonEncode(entry.toUpdateJson()),
    );

    if (res.statusCode != 200) {
      throw AccountLedgerException(
          _errorMessage(res, 'Failed to update ledger entry'));
    }

    final decoded = res.body.trim().isEmpty ? {} : jsonDecode(res.body);
    final map = _extractSingle(decoded);
    // Fall back to the entry we sent if the server echoes no body / just {success:true}.
    return map.isEmpty ? entry : AccountLedgerEntry.fromJson(map);
  }

  /// Delete a ledger entry by id.
  Future<void> deleteEntry(String id) async {
    if (id.trim().isEmpty) {
      throw AccountLedgerException('Cannot delete an entry without an id.');
    }
    final uri = Uri.parse(_restEndpoint).replace(queryParameters: {
      'table': 'account_ledger',
      'id': 'eq.$id',
    });
    final res = await postWithMethodOverride(
      uri,
      method: 'DELETE',
      headers: _headers,
    );

    if (res.statusCode != 200 && res.statusCode != 204) {
      throw AccountLedgerException(
          'Failed to delete ledger entry (${res.statusCode}).');
    }

    final decoded = res.body.isEmpty ? {} : jsonDecode(res.body);
    if (decoded is Map && decoded['success'] == false) {
      throw AccountLedgerException(
          decoded['message']?.toString() ?? 'Failed to delete ledger entry.');
    }
  }

  // ---------------------------------------------------------------------
  // Response helpers — tolerate either a raw payload or a
  // { "success": bool, "data": ... } wrapper.
  // ---------------------------------------------------------------------

  List<dynamic> _extractList(dynamic decoded) {
    if (decoded is List) return decoded;
    if (decoded is Map<String, dynamic>) {
      if (decoded['success'] == false) {
        throw AccountLedgerException(
            decoded['message']?.toString() ?? 'Request failed.');
      }
      final data = decoded['data'];
      if (data is List) return data;
    }
    throw AccountLedgerException('Unexpected response format from server.');
  }

  Map<String, dynamic> _extractMap(dynamic decoded) {
    if (decoded is Map) {
      final map = Map<String, dynamic>.from(decoded);
      if (map['success'] == false) {
        throw AccountLedgerException(
          map['message']?.toString() ?? 'Request failed.',
        );
      }
      final data = map['data'];
      if (data is Map) return Map<String, dynamic>.from(data);
      return map;
    }
    throw AccountLedgerException('Unexpected summary response from server.');
  }

  Map<String, dynamic> _extractSingle(dynamic decoded) {
    // ResourceController returns [row] for both insert and update.
    if (decoded is List && decoded.isNotEmpty && decoded.first is Map) {
      return Map<String, dynamic>.from(decoded.first as Map);
    }
    if (decoded is Map<String, dynamic>) {
      if (decoded['success'] == false) {
        throw AccountLedgerException(
            decoded['message']?.toString() ?? 'Request failed.');
      }
      final data = decoded['data'];
      if (data is Map<String, dynamic>) return data;
      // No 'data' wrapper — assume the map itself is the entry.
      if (data == null && decoded.containsKey('id')) return decoded;
      if (data == null) return {};
    }
    return {};
  }

  String _errorMessage(http.Response response, String fallback) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) {
        final message = decoded['error'] ?? decoded['message'];
        if (message != null && message.toString().isNotEmpty) {
          return message.toString();
        }
      }
    } catch (_) {
      // Keep the status fallback for non-JSON responses from a hosting/WAF layer.
    }
    return '$fallback (${response.statusCode}).';
  }

  void dispose() {
    _client.close();
  }
}
