import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/collection_point.dart';
import 'customer_api_service.dart';
import 'session_service.dart';

class FieldMapApiService {
  static String get _restEndpoint => '${ApiConfig.normalizedBaseUrl}/rest.php';

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (SessionService.instance.token != null &&
            SessionService.instance.token!.isNotEmpty)
          'Authorization': 'Bearer ${SessionService.instance.token}',
      };

  static Uri _uri(String resource, [Map<String, String>? query]) {
    return Uri.parse(_restEndpoint).replace(
      queryParameters: {
        'table': resource,
        ...?query,
      },
    );
  }

  static Never _throwFromResponse(http.Response res) {
    String message = 'Request failed (${res.statusCode})';

    try {
      final body = jsonDecode(res.body);

      if (body is Map && body['error'] != null) {
        message = body['error'].toString();
      }
    } catch (_) {}

    throw Exception(message);
  }

  // IMPORTANT:
  // Only allow real finite coordinates.
  static bool _hasCoords(Map<String, dynamic> row) {
    final lat = row['latitude'];
    final lng = row['longitude'];

    if (lat is! double || lng is! double) {
      return false;
    }

    return lat.isFinite &&
        lng.isFinite &&
        lat >= -90 &&
        lat <= 90 &&
        lng >= -180 &&
        lng <= 180;
  }

  static Future<List<Map<String, dynamic>>> _fetchCustomerRows() async {
    final service = CustomerApiService();
    final customers = await service.fetchAll();

    return customers
        .map((c) {
          final lat = double.tryParse(
            c.latitude?.toString() ?? '',
          );

          final lng = double.tryParse(
            c.longitude?.toString() ?? '',
          );

          return <String, dynamic>{
            'id': c.id,
            'customer_id': c.customerId,
            'full_name': c.fullName,
            'mobile': c.mobile,
            'address': c.address,
            'aadhaar': c.aadhaar,
            'pan': c.pan,
            'occupation': c.occupation,
            'photo_url': c.photoUrl,
            'assigned_agent': c.assignedAgent,
            'assigned_agent_name': c.assignedAgentName,

            // Normalized coordinates
            'latitude': lat,
            'longitude': lng,

            'loan_status': c.loanStatus,
            'created_at': c.createdAt?.toIso8601String(),
          };
        })
        .where(_hasCoords)
        .toList();
  }

  static Future<List<CollectionPoint>> fetchPoints() async {
    final rows = await _fetchCustomerRows();

    return rows.map((row) {
      return CollectionPoint.fromJson({
        ...row,

        'customer_name': row['full_name'] ?? 'Unknown',

        'agent_id': '',

        // Temporary address mapping
        'agent_name': row['address'] ?? 'No address provided',

        'amount': 0,

        'collected_at': row['created_at'],

        'collected':
            (row['loan_status']?.toString().toLowerCase() ?? '') == 'active',
      });
    }).toList();
  }

  static Future<FieldMapSummary> fetchSummary() async {
    final points = await _fetchCustomerRows();

    final activeCustomers = points
        .where(
          (p) => (p['loan_status']?.toString().toLowerCase() ?? '') == 'active',
        )
        .length;

    return FieldMapSummary(
      onMap: points.length,
      collectedCount: activeCustomers,
      activeAgents: 0,
      totalCollected: 0,
    );
  }
}
