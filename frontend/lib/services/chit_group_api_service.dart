import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/chit_schedule.dart';
import 'method_override_http.dart';
import 'session_service.dart';
import '../models/chit_group.dart';
import '../models/chit_member.dart';
import '../models/chit_passbook.dart';

class ChitGroupApiService {
  static String get _restEndpoint => '${ApiConfig.normalizedBaseUrl}/rest.php';
  static String get _chitEndpoint => '${ApiConfig.normalizedBaseUrl}/chit.php';

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (SessionService.instance.token != null)
          'Authorization': 'Bearer ${SessionService.instance.token}',
      };

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

  // ---- SCHEDULE: REBUILD (admin/agent) ----
  // Rebuilds the group's draw sheet on the server from its stored fields
  // (scheme, duration, contribution, start date) and resyncs every member's
  // chit_passbook against it — the same rules the initial auto-generation on
  // group creation uses. Used after editing a group's numbers so the sheet
  // and every member's passbook are regenerated together, in one place,
  // instead of the app deleting and reinserting rows by hand.
  static Future<List<ChitSchedule>> regenerateSchedule(String groupId) async {
    final uri =
        Uri.parse('$_chitEndpoint?action=generate_schedule');
    final res = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({'group_id': groupId}),
    );
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
  //
  // One request to chit.php?action=collect: the server writes the cash-book
  // receipt and the chit_payments row in one transaction, then derives the
  // member's chit_passbook, payment_status and the group's running totals
  // from what was actually stored — rather than the app writing a ledger
  // receipt, guessing a flat paid/partial status itself, and patching the
  // group totals by hand in three separate calls that could each half-fail.
  static Future<ChitCollectionResult> collectContribution({
    required String groupId,
    required String memberId,
    required double amount,
    required String paymentMethod,
    required DateTime paymentDate,
    String? notes,
  }) async {
    final uri = Uri.parse('$_chitEndpoint?action=collect');
    final res = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({
        'group_id': groupId,
        'member_id': memberId,
        'amount': amount,
        'payment_method': paymentMethod,
        'payment_date': paymentDate.toIso8601String().split('T').first,
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      }),
    );
    _throwIfError(res);
    final decoded = jsonDecode(res.body);
    if (decoded is! Map<String, dynamic>) {
      throw ChitGroupApiException(
          'Unexpected response shape from server', res.statusCode);
    }
    return ChitCollectionResult.fromJson(decoded);
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

  // ---- PASSBOOK: the member's stored draw statement and receipts ----
  //
  // Reads straight from `chit_passbook` — the table the server derives from
  // the draw schedule and every recorded chit_payments row, with the settled
  // Paid / Partial / Overdue / Pending status already computed. This used to
  // be assembled here: read the schedule, read the whole account-book, guess
  // which receipts were this member's chit payments by matching customer name
  // and a "Draw #n" substring in the notes, and call anything not fully paid
  // "pending" — so a late instalment could never show as Overdue. There is
  // nothing left to derive; the same rows this fetches are what every other
  // screen (and a customer's own login) reads.
  static Future<ChitPassbookData> fetchPassbook(String memberId) async {
    final passbookUri = Uri.parse(_restEndpoint).replace(queryParameters: {
      'table': 'chit_passbook',
      'member_id': memberId,
      'order': 'installment_no.asc',
    });
    final passbookRes = await http.get(passbookUri, headers: _headers);
    _throwIfError(passbookRes);
    final rows = _listFrom(passbookRes);
    if (rows.isEmpty) {
      // No stored statement yet (a brand-new member whose passbook hasn't
      // synced) — fall back to the member's own record so the screen can
      // still say "not found" vs. "nothing to show" correctly.
      final memberUri = Uri.parse(_restEndpoint).replace(queryParameters: {
        'table': 'chit_members',
        'id': memberId,
        'limit': '1',
      });
      final memberRes = await http.get(memberUri, headers: _headers);
      _throwIfError(memberRes);
      if (_listFrom(memberRes).isEmpty) {
        throw ChitGroupApiException('Chit member not found', 404);
      }
    }

    final draws = rows.map(ChitDraw.fromJson).toList();

    final paymentsUri = Uri.parse(_restEndpoint).replace(queryParameters: {
      'table': 'chit_payments',
      'member_id': memberId,
      'order': 'payment_date.desc',
    });
    final paymentsRes = await http.get(paymentsUri, headers: _headers);
    _throwIfError(paymentsRes);
    final receipts =
        _listFrom(paymentsRes).map(ChitPaymentReceipt.fromJson).toList();

    return ChitPassbookData(
      draws: draws,
      receipts: receipts,
      totalDraws: draws.length,
    );
  }

  // ---- SCHEDULE: PAYMENT STATUS SUMMARY (aggregated across the group) ----
  //
  // Reads every member's `chit_passbook` row for the group in one call and
  // folds them by installment number, so the Installment Schedule tab can
  // show, per draw, how many of the group's members have paid it and how
  // much has been collected — without a passbook round trip per member.
  static Future<Map<int, ChitScheduleStatusSummary>>
      fetchScheduleStatusSummary(String groupId) async {
    final uri = Uri.parse(_restEndpoint).replace(queryParameters: {
      'table': 'chit_passbook',
      'group_id': groupId,
      'order': 'installment_no.asc',
    });
    final res = await http.get(uri, headers: _headers);
    _throwIfError(res);

    final byDraw = <int, List<Map<String, dynamic>>>{};
    for (final row in _listFrom(res)) {
      final installmentNo = int.tryParse('${row['installment_no']}') ?? 0;
      byDraw.putIfAbsent(installmentNo, () => []).add(row);
    }

    return byDraw.map((installmentNo, rows) {
      final total = rows.length;
      final paid =
          rows.where((r) => '${r['payment_status']}' == 'paid').length;
      final paidAmount = rows.fold<double>(
          0, (sum, r) => sum + (double.tryParse('${r['paid_amount']}') ?? 0));
      final hasOverdue =
          rows.any((r) => '${r['payment_status']}' == 'overdue');
      final status = total > 0 && paid == total
          ? ChitPaymentStatus.paid
          : paid > 0
              ? ChitPaymentStatus.partial
              : hasOverdue
                  ? ChitPaymentStatus.overdue
                  : ChitPaymentStatus.pending;
      return MapEntry(
        installmentNo,
        ChitScheduleStatusSummary(
          installmentNo: installmentNo,
          paidMembers: paid,
          totalMembers: total,
          paidAmount: paidAmount,
          status: status,
        ),
      );
    });
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
