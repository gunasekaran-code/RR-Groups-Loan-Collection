import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/user_account.dart';
import 'method_override_http.dart';
import 'session_service.dart';

class UserApiService {
  UserApiService._();
  static final UserApiService instance = UserApiService._();

  static String get _baseUrl => ApiConfig.normalizedBaseUrl;
  static String get _restEndpoint => '$_baseUrl/rest.php';
  static String get _usersEndpoint => '$_baseUrl/users.php';

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (SessionService.instance.token != null &&
            SessionService.instance.token!.isNotEmpty)
          'Authorization': 'Bearer ${SessionService.instance.token}',
      };

  static Uri _profilesUri([Map<String, String>? query]) {
    return Uri.parse(_restEndpoint).replace(
      queryParameters: {'table': 'profiles', ...?query},
    );
  }

  static Never _throwFromResponse(http.Response res) {
    String message = 'Request failed (${res.statusCode})';
    try {
      final body = jsonDecode(res.body);
      if (body is Map && body['error'] != null) {
        message = body['error'].toString();
      } else if (body is Map && body['message'] != null) {
        message = body['message'].toString();
      }
    } catch (_) {}
    throw Exception(message);
  }

  /// GET /rest.php?table=profiles — list all user accounts.
  Future<List<UserAccount>> fetchUsers() async {
    final res = await http.get(_profilesUri(), headers: _headers);
    if (res.statusCode != 200) _throwFromResponse(res);

    final data = jsonDecode(res.body);
    final list = (data is Map && data['data'] is List)
        ? data['data'] as List
        : (data is List ? data : const []);

    return list
        .map((e) => UserAccount.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /rest.php?table=profiles&id={id} — fetch a single user.
  Future<UserAccount> fetchUser(String id) async {
    final res = await http.get(_profilesUri({'id': id}), headers: _headers);
    if (res.statusCode != 200) _throwFromResponse(res);

    final data = jsonDecode(res.body);
    final row = (data is Map && data['data'] != null) ? data['data'] : data;
    return UserAccount.fromJson(row as Map<String, dynamic>);
  }

  /// POST /users.php — create a new login account.
  Future<UserAccount> createUser(
    UserAccount user, {
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse(_usersEndpoint),
      headers: _headers,
      body: jsonEncode(user.toCreateJson(password: password)),
    );
    if (res.statusCode != 200 && res.statusCode != 201) _throwFromResponse(res);

    final data = jsonDecode(res.body);
    final row = (data is Map && data['data'] != null) ? data['data'] : data;
    return UserAccount.fromJson(row as Map<String, dynamic>);
  }

  /// PATCH /users.php?id={id} — update an existing login account.
  Future<UserAccount> updateUser(
    UserAccount user, {
    String? password,
  }) async {
    final res = await postWithMethodOverride(
      Uri.parse(_usersEndpoint).replace(queryParameters: {'id': user.id}),
      method: 'PATCH',
      headers: _headers,
      body: jsonEncode(user.toUpdateJson(password: password)),
    );
    if (res.statusCode != 200) _throwFromResponse(res);

    final data = jsonDecode(res.body);
    final row = (data is Map && data['data'] != null) ? data['data'] : data;
    return UserAccount.fromJson(row as Map<String, dynamic>);
  }

  /// DELETE /rest.php?table=profiles&id={id} — remove a user account.
  Future<void> deleteUser(String id) async {
    final res = await postWithMethodOverride(
      _profilesUri({'id': id}),
      method: 'DELETE',
      headers: _headers,
    );
    if (res.statusCode != 200 && res.statusCode != 204) {
      _throwFromResponse(res);
    }
  }
}

class UserApiException implements Exception {
  final String message;
  const UserApiException(this.message);
  @override
  String toString() => message;
}
