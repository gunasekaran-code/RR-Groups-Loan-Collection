import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/chit_schedule.dart';
import 'method_override_http.dart';
import 'session_service.dart';
import '../models/chit_group.dart';
import '../models/chit_member.dart';
import '../models/chit_passbook.dart';
import 'collection_api_service.dart';

class ChitGroupApiService {
  static String get _restEndpoint => '${ApiConfig.normalizedBaseUrl}/rest.php';

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (SessionService.instance.token != null)
          'Authorization': 'Bearer ${SessionService.instance.token}',
      };

  // ---- SCHEDULE: BATCH SAVE / CREATE ----
  static Future<void> saveSchedules(
      List<Map<String, dynamic>> schedules) async {
    if (schedules.isEmpty) return;
    final uri = Uri.parse('$_restEndpoint?table=chit_schedules');
    final res = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode(schedules),
    );
    _throwIfError(res);
  }

  // ---- SCHEDULE: DELETE FOR GROUP ----
  static Future<void> deleteSchedulesForGroup(String groupId) async {
    final uri =
        Uri.parse('$_restEndpoint?table=chit_schedules&group_id=$groupId');
    final res = await postWithMethodOverride(
      uri,
      method: 'DELETE',
      headers: _headers,
    );
    _throwIfError(res);
  }

  // ---- SCHEDULE: READ ----
  static Future<List<ChitSchedule>> fetchSchedules(String groupId) async {
    final uri = Uri.parse(_restEndpoint).replace(queryParameters: {
      'table': 'chit_schedules',
      'group_id': groupId,
      'order': 'installment_no.asc',
    });
    final res = await http.get(uri, headers: _headers);
    _throwIfError(res);
    return _listFrom(res).map((e) => ChitSchedule.fromJson(e)).toList();
  }

  // ---- SCHEDULE: OVERRIDE (admin only — enforced in UI below) ----
  static Future<ChitSchedule> overrideSchedule({
    required String scheduleId,
    required DateTime dueDate,
    required double payableAmount,
    required double poolAmount,
    String? notes,
  }) async {
    final uri = Uri.parse('$_restEndpoint?table=chit_schedules&id=$scheduleId');
    final res = await postWithMethodOverride(
      uri,
      method: 'PATCH',
      headers: _headers,
      body: jsonEncode({
        'due_date': dueDate.toIso8601String().split('T').first,
        'payable_amount': payableAmount,
        'pool_amount': poolAmount,
        'is_custom': 1,
        if (notes != null && notes.isNotEmpty) 'override_notes': notes,
      }),
    );
    _throwIfError(res);
    return ChitSchedule.fromJson(_rowFrom(res));
  }

  // ---- GROUPS: READ ----
  static Future<List<ChitGroup>> fetchAll() async {
    final uri = Uri.parse('$_restEndpoint?table=chit_groups');
    final res = await http.get(uri, headers: _headers);
    _throwIfError(res);
    return _listFrom(res).map((e) => ChitGroup.fromJson(e)).toList();
  }

  /// Returns only the groups in which the signed-in customer has a member row.
  static Future<List<ChitGroup>> fetchMyGroups() async {
    final customerId = SessionService.instance.currentUser?.customerId;
    if (customerId == null || customerId.isEmpty) return const [];

    final membershipUri = Uri.parse(_restEndpoint).replace(
      queryParameters: {
        'table': 'chit_members',
        'customer_id': customerId,
      },
    );
    final membershipRes = await http.get(membershipUri, headers: _headers);
    _throwIfError(membershipRes);

    final groupIds = _listFrom(membershipRes)
        .map((member) => member['group_id']?.toString() ?? '')
        .where((groupId) => groupId.isNotEmpty)
        .toSet()
        .toList();
    if (groupIds.isEmpty) return const [];

    final groupUri = Uri.parse(_restEndpoint).replace(
      queryParameters: {
        'table': 'chit_groups',
        'id': 'in.(${groupIds.join(',')})',
      },
    );
    final groupRes = await http.get(groupUri, headers: _headers);
    _throwIfError(groupRes);
    return _listFrom(groupRes).map((e) => ChitGroup.fromJson(e)).toList();
  }

  // ---- GROUPS: CREATE (admin only — enforced server-side) ----
  static Future<ChitGroup> create(ChitGroup group) async {
    final uri = Uri.parse('$_restEndpoint?table=chit_groups');
    final res = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode(group.toJson()),
    );
    _throwIfError(res);
    return ChitGroup.fromJson(_rowFrom(res));
  }

  // ---- GROUPS: UPDATE (admin full edit) ----
  static Future<ChitGroup> update(ChitGroup group) async {
    final uri = Uri.parse('$_restEndpoint?table=chit_groups&id=${group.id}');
    final res = await postWithMethodOverride(
      uri,
      method: 'PATCH',
      headers: _headers,
      body: jsonEncode(group.toJson()),
    );
    _throwIfError(res);
    return ChitGroup.fromJson(_rowFrom(res));
  }

  // ---- GROUPS: UPDATE (admin or agent — collection fields only,
  // per the PHP allow-list). Called after a member's payment is
  // recorded so the group's running totals + status stay in sync.
  static Future<ChitGroup> recordCollection({
    required String groupId,
    required double collectedAmount,
    required double pendingAmount,
    String? status,
  }) async {
    final uri = Uri.parse('$_restEndpoint?table=chit_groups&id=$groupId');
    final res = await postWithMethodOverride(
      uri,
      method: 'PATCH',
      headers: _headers,
      body: jsonEncode({
        'collected_amount': collectedAmount,
        'pending_amount': pendingAmount,
        if (status != null) 'status': status,
      }),
    );
    _throwIfError(res);
    return ChitGroup.fromJson(_rowFrom(res));
  }

  // ---- GROUPS: DELETE (admin only — enforced server-side) ----
  static Future<void> delete(String id) async {
    final uri = Uri.parse('$_restEndpoint?table=chit_groups&id=$id');
    final res = await postWithMethodOverride(
      uri,
      method: 'DELETE',
      headers: _headers,
    );
    _throwIfError(res);
  }

  // ---- MEMBERS: READ ----
  static Future<List<ChitMember>> fetchMembers(String groupId) async {
    final uri =
        Uri.parse('$_restEndpoint?table=chit_members&group_id=$groupId');
    final res = await http.get(uri, headers: _headers);
    _throwIfError(res);
    final members = _listFrom(res).map(ChitMember.fromJson).toList();

    // The mobile number is maintained in profiles, not chit_members. Hydrate
    // members from their linked customer profile for the tracking table.
    try {
      final customers = await fetchCustomers();
      final customersById = {
        for (final customer in customers) customer.id: customer,
      };
      return members
          .map((member) => member.copyWith(
                phone: member.customerId == null
                    ? null
                    : customersById[member.customerId]?.phone,
              ))
          .toList();
    } catch (_) {
      return members;
    }
  }

  // ---- MEMBERS: find the signed-in customer's own row in a group ----
  // The customer id is stored on the current AppUser in SessionService.
  // The backend supports filtering chit_members by both group_id and
  // customer_id.
  // Returns null if the current user isn't a member of this group.
  static Future<ChitMember?> fetchMyMembership(String groupId) async {
    final customerId = SessionService.instance.currentUser?.customerId;
    if (customerId == null || customerId.isEmpty) return null;

    final uri = Uri.parse(_restEndpoint).replace(
      queryParameters: {
        'table': 'chit_members',
        'group_id': groupId,
        'customer_id': customerId,
      },
    );
    final res = await http.get(uri, headers: _headers);
    _throwIfError(res);
    final rows = _listFrom(res);
    if (rows.isEmpty) return null;
    return ChitMember.fromJson(rows.first);
  }

  // ---- MEMBERS: CREATE ----
  // Gated to admin only in the UI (see ChitGroupsScreen role checks) —
  // no member-level role check was shown on the backend, so this is a
  // frontend-only restriction per your request.
  static Future<ChitMember> addMember({
    required String groupId,
    required String customerId,
    required String memberName,
    String? phone,
    required double contributionAmount,
    DateTime? dueDate,
  }) async {
    final uri = Uri.parse('$_restEndpoint?table=chit_members');
    final res = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({
        'group_id': groupId,
        'customer_id': customerId,
        'member_name': memberName,
        'contribution_amount': contributionAmount,
        if (dueDate != null)
          'due_date': dueDate.toIso8601String().split('T').first,
        'payment_status': 'pending',
      }),
    );
    _throwIfError(res);
    return ChitMember.fromJson(_rowFrom(res));
  }

  // ---- MEMBERS: DELETE ----
  // Gated to admin only in the UI, same note as addMember above.
  static Future<void> deleteMember(String memberId) async {
    final uri = Uri.parse('$_restEndpoint?table=chit_members&id=$memberId');
    final res = await postWithMethodOverride(
      uri,
      method: 'DELETE',
      headers: _headers,
    );
    _throwIfError(res);
  }

  // ---- MEMBERS: record a contribution (admin or agent) ----
  static Future<ChitMember> collectFromMember({
    required String memberId,
    required ChitPaymentStatus status,
  }) async {
    final uri = Uri.parse('$_restEndpoint?table=chit_members&id=$memberId');
    final res = await postWithMethodOverride(
      uri,
      method: 'PATCH',
      headers: _headers,
      body: jsonEncode({'payment_status': ChitMember.statusToString(status)}),
    );
    _throwIfError(res);
    return ChitMember.fromJson(_rowFrom(res));
  }

  // ---- CUSTOMERS (for the Add Member dropdown) ----
  // Customer contact details live in profiles. This is equivalent to
  // SELECT * FROM profiles WHERE role = 'customer' ORDER BY mobile ASC.
  static Future<List<ChitCustomerOption>> fetchCustomers() async {
    final uri = Uri.parse(_restEndpoint).replace(queryParameters: {
      'table': 'profiles',
      'role': 'eq.customer',
      'order': 'mobile.asc',
    });
    final res = await http.get(uri, headers: _headers);
    _throwIfError(res);
    return _listFrom(res).map((e) => ChitCustomerOption.fromJson(e)).toList();
  }

  // ---- PASSBOOK: the member's group schedule and collection receipts ----
  static Future<ChitPassbookData> fetchPassbook(String memberId) async {
    final memberUri = Uri.parse(_restEndpoint).replace(
      queryParameters: {
        'table': 'chit_members',
        'id': memberId,
        'limit': '1',
      },
    );
    final memberRes = await http.get(memberUri, headers: _headers);
    _throwIfError(memberRes);
    final memberRows = _listFrom(memberRes);
    if (memberRows.isEmpty) {
      throw ChitGroupApiException('Chit member not found', 404);
    }

    final member = memberRows.first;
    final groupId = member['group_id']?.toString();
    if (groupId == null || groupId.isEmpty) {
      throw ChitGroupApiException('Chit member has no group', 400);
    }

    final scheduleUri = Uri.parse(_restEndpoint).replace(
      queryParameters: {
        'table': 'chit_schedules',
        'group_id': groupId,
        'order': 'installment_no.asc',
      },
    );
    final scheduleRes = await http.get(scheduleUri, headers: _headers);
    _throwIfError(scheduleRes);

    final customerId = member['customer_id']?.toString();
    final collectionRows = await CollectionApiService.fetchCollections();
    final groupMarker = 'Chit group: $groupId';
    final receipts = collectionRows
        .where((row) =>
            (customerId != null &&
                row['customer_id']?.toString() == customerId) ||
            (customerId == null &&
                row['customer_name']?.toString() ==
                    member['member_name']?.toString()))
        .where((row) =>
            row['notes']?.toString().contains(groupMarker) == true ||
            row['loan_number']?.toString() ==
                member['group_number']?.toString())
        .toList();

    final paidByDraw = <int, double>{};
    final drawPattern = RegExp(r'Draw #(\d+)');
    for (final receipt in receipts) {
      final match = drawPattern.firstMatch(receipt['notes']?.toString() ?? '');
      if (match == null) continue;
      final drawNumber = int.tryParse(match.group(1)!) ?? 0;
      final amount =
          double.tryParse('${receipt['collection_amount'] ?? 0}') ?? 0;
      paidByDraw[drawNumber] = (paidByDraw[drawNumber] ?? 0) + amount;
    }

    final draws = _listFrom(scheduleRes).map(
      (schedule) {
        final drawNumber = int.tryParse('${schedule['installment_no']}') ?? 0;
        final amountPaid = paidByDraw[drawNumber] ?? 0;
        return ChitDraw.fromJson({
          'draw_number': schedule['installment_no'],
          'scheduled_date': schedule['due_date'],
          'payable_contribution': schedule['payable_amount'],
          'dividend_pool_value': schedule['pool_amount'],
          'payment_status': amountPaid >=
                  (double.tryParse('${schedule['payable_amount']}') ?? 0) - 0.01
              ? 'paid'
              : 'pending',
          'amount_paid': amountPaid,
        });
      },
    ).toList();

    return ChitPassbookData(
      draws: draws,
      receipts: receipts.map(ChitPaymentReceipt.fromJson).toList(),
      totalDraws: draws.length,
    );
  }

  // ---- helpers ----
  static List<Map<String, dynamic>> _listFrom(http.Response res) {
    final decoded = jsonDecode(res.body);
    final List list = decoded is Map && decoded.containsKey('data')
        ? decoded['data']
        : decoded as List;
    return list.cast<Map<String, dynamic>>();
  }

  static Map<String, dynamic> _rowFrom(http.Response res) {
    final decoded = jsonDecode(res.body);
    if (decoded is Map<String, dynamic>) {
      final data = decoded['data'];
      if (data is Map<String, dynamic>) return Map<String, dynamic>.from(data);
      if (data is List && data.isNotEmpty && data.first is Map) {
        return Map<String, dynamic>.from(data.first as Map);
      }
      return Map<String, dynamic>.from(decoded);
    }
    if (decoded is List && decoded.isNotEmpty && decoded.first is Map) {
      return Map<String, dynamic>.from(decoded.first as Map);
    }
    throw ChitGroupApiException(
      'Unexpected response shape from server',
      res.statusCode,
    );
  }

  static void _throwIfError(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    String message = 'Request failed (${res.statusCode})';
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map && decoded['error'] != null) {
        message = decoded['error'].toString();
      }
    } catch (_) {}
    throw ChitGroupApiException(message, res.statusCode);
  }
}

class ChitGroupApiException implements Exception {
  ChitGroupApiException(this.message, this.statusCode);
  final String message;
  final int statusCode;

  @override
  String toString() => message;
}
