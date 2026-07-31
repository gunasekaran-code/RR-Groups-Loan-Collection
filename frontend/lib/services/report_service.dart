import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/report_model.dart';
import 'session_service.dart';

class ReportApiException implements Exception {
  ReportApiException(this.message, this.statusCode);

  final String message;
  final int statusCode;

  @override
  String toString() => message;
}

class ReportService {
  ReportService._();

  static final ReportService instance = ReportService._();

  static const String _reportsEndpoint = '${ApiConfig.baseUrl}reports.php';

  Future<DailyReport> fetchDailyReport({required DateTime date}) {
    return _getReport(
      action: 'daily',
      query: {'date': _formatDate(date)},
      parser: (json) => DailyReport.fromJson(json),
    );
  }

  Future<MonthlyReport> fetchMonthlyReport({
    required DateTime start,
    required DateTime end,
  }) {
    return _getReport(
      action: 'monthly',
      query: {'start': _formatDate(start), 'end': _formatDate(end)},
      parser: (json) => MonthlyReport.fromJson(json),
    );
  }

  Future<AgentReport> fetchAgentReport({
    required DateTime start,
    required DateTime end,
  }) {
    return _getReport(
      action: 'agent',
      query: {'start': _formatDate(start), 'end': _formatDate(end)},
      parser: (json) => AgentReport.fromJson(json),
    );
  }

  Future<T> _getReport<T>({
    required String action,
    required Map<String, String> query,
    required T Function(Map<String, dynamic> json) parser,
  }) async {
    final token = SessionService.instance.token;
    final uri = Uri.parse(_reportsEndpoint).replace(queryParameters: {
      'action': action,
      ...query,
    });

    late http.Response res;
    try {
      res = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 20));
    } catch (_) {
      throw ReportApiException(
        'Could not reach the reports server. Check your connection and try again.',
        0,
      );
    }

    Map<String, dynamic> data;
    try {
      data = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      throw ReportApiException('Unexpected reports response.', res.statusCode);
    }

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ReportApiException(
        (data['error'] ?? data['message'] ?? 'Unable to load report')
            .toString(),
        res.statusCode,
      );
    }

    return parser(data);
  }

  String _formatDate(DateTime date) {
    final yyyy = date.year.toString().padLeft(4, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    return '$yyyy-$mm-$dd';
  }
}
