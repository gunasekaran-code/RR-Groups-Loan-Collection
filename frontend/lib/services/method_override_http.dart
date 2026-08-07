import 'package:http/http.dart' as http;

Future<http.Response> postWithMethodOverride(
  Uri uri, {
  required Map<String, String> headers,
  Object? body,
  String method = 'PATCH',
}) {
  final requestHeaders = Map<String, String>.from(headers);
  requestHeaders['X-HTTP-Method-Override'] = method.toUpperCase();
  return http.post(
    uri,
    headers: requestHeaders,
    body: body,
  );
}
