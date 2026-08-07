class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://rrgroupscbe.com/backend/',
    // defaultValue: 'http://localhost:8889/',
  );

  static String get normalizedBaseUrl => baseUrl.replaceAll(RegExp(r'/+$'), '');
}
