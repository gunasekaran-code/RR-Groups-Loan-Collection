import 'package:http/http.dart' as http;

Future<http.Response> postWithMethodOverride(
  Uri uri, {
  required Map<String, String> headers,
  Object? body,
  String method = 'PATCH',
}) {
  // Use native methods for Flutter Web. A query-string `_method` is copied to
  // the browser's OPTIONS preflight, which makes this backend authenticate the
  // preflight as PATCH/DELETE and return 401. Native methods keep the
  // preflight as OPTIONS; the API already permits PATCH/PUT/DELETE in CORS.
  switch (method.toUpperCase()) {
    case 'PATCH':
      return http.patch(uri, headers: headers, body: body);
    case 'PUT':
      return http.put(uri, headers: headers, body: body);
    case 'DELETE':
      return http.delete(uri, headers: headers, body: body);
    default:
      throw ArgumentError.value(
        method,
        'method',
        'Only PATCH, PUT, and DELETE are supported.',
      );
  }
}
