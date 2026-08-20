import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

/// Sends a write as POST while asking the API to handle it as [method].
///
/// Several production web servers reject PATCH and DELETE before they reach
/// PHP.  The API's bootstrap already recognizes the `_method` query parameter,
/// so POST keeps those requests on the same route as successful creates.
///
/// On the web this deliberately uses a CORS-safelisted request: the JSON bytes
/// are sent with a form-safelisted content type and the bearer token is supplied
/// through the API's existing `token` query fallback. This prevents the browser
/// from issuing an OPTIONS request containing `_method`; that preflight would
/// otherwise be interpreted by the legacy backend as PATCH/DELETE and fail
/// authentication.
Future<http.Response> postWithMethodOverride(
  Uri uri, {
  required Map<String, String> headers,
  Object? body,
  String method = 'PATCH',
}) {
  final overrideMethod = method.toUpperCase();
  if (!const {'PATCH', 'PUT', 'DELETE'}.contains(overrideMethod)) {
    throw ArgumentError.value(
      method,
      'method',
      'Only PATCH, PUT, and DELETE are supported.',
    );
  }

  final bearerToken = _bearerToken(headers);
  final requestHeaders = Map<String, String>.from(headers);
  var requestUri = uri.replace(queryParameters: {
    ...uri.queryParameters,
    '_method': overrideMethod,
  });

  if (kIsWeb) {
    // Authorization and application/json both trigger a preflight. Keep the
    // browser request simple; bootstrap.php accepts `token` for this legacy
    // API and still authenticates the exact same bearer token.
    requestHeaders.removeWhere(
      (name, _) => name.toLowerCase() == 'authorization',
    );
    requestHeaders.removeWhere(
      (name, _) => name.toLowerCase() == 'content-type',
    );
    // Keep the JSON string intact. PHP reads php://input and decodes it as JSON,
    // while this CORS-safelisted media type avoids both preflight and hosting
    // rules that reject text/plain bodies on method-override requests.
    if (body != null) {
      requestHeaders['Content-Type'] = 'application/x-www-form-urlencoded';
    }
    if (bearerToken != null) {
      requestUri = requestUri.replace(queryParameters: {
        ...requestUri.queryParameters,
        'token': bearerToken,
      });
    }
  }

  return http.post(requestUri, headers: requestHeaders, body: body);
}

String? _bearerToken(Map<String, String> headers) {
  String? authorization;
  for (final entry in headers.entries) {
    if (entry.key.toLowerCase() == 'authorization') {
      authorization = entry.value.trim();
      break;
    }
  }
  if (authorization == null || authorization.isEmpty) return null;

  final match = RegExp(r'^Bearer\s+(.+)$', caseSensitive: false)
      .firstMatch(authorization);
  return (match?.group(1) ?? authorization).trim();
}
