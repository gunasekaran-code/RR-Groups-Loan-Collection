import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import 'api_client.dart';

class AppBranding {
  final String companyName;
  final String? logoUrl;

  const AppBranding({
    required this.companyName,
    required this.logoUrl,
  });

  const AppBranding.fallback()
      : companyName = 'FinCollect',
        logoUrl = null;

  factory AppBranding.fromJson(Map<String, dynamic> json) {
    final name = (json['company_name'] ?? '').toString().trim();
    final rawLogo = (json['logo_url'] ?? '').toString().trim();
    return AppBranding(
      companyName: name.isEmpty ? 'FinCollect' : name,
      logoUrl: _resolveLogoUrl(rawLogo),
    );
  }

  Map<String, dynamic> toJson() => {
        'company_name': companyName,
        'logo_url': logoUrl,
      };

  static String? _resolveLogoUrl(String raw) {
    if (raw.isEmpty) return null;
    if (raw.startsWith('data:')) return raw;
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return raw;
    }

    // Keep the `/backend/` part of the configured API URL for relative
    // values such as `uploads/company-logo.png`. Uri.resolve treats a base
    // URL without a trailing slash as a file and would otherwise remove the
    // last path segment (`backend`).
    final base = Uri.parse('${ApiConfig.normalizedBaseUrl}/');
    return base.resolve(raw).toString();
  }
}

class BrandingService {
  BrandingService._();

  static final BrandingService instance = BrandingService._();

  static const String _cacheKey = 'app_branding_cache';

  final ValueNotifier<AppBranding> branding =
      ValueNotifier<AppBranding>(const AppBranding.fallback());

  Future<void> initialize() async {
    await _loadCached();
    await refreshFromServer();
  }

Future<void> refreshFromServer() async {
  final token = ApiClient.instance.authToken;
  if (token == null || token.isEmpty) {
    debugPrint('BrandingService: no auth token yet, skipping refresh');
    return;
  }

  try {
    final rows = await ApiClient.instance.list('settings');
    debugPrint('BrandingService: settings rows = $rows');
    if (rows.isEmpty) {
      debugPrint('BrandingService: settings table returned no rows');
      return;
    }

    final fresh = AppBranding.fromJson(rows.first);
    debugPrint('BrandingService: parsed company_name=${fresh.companyName} logo_url=${fresh.logoUrl}');
    branding.value = fresh;
    await _save(fresh);
  } catch (e, st) {
    debugPrint('BrandingService: refreshFromServer failed: $e');
    debugPrint('$st');
  }
}

  Future<void> _loadCached() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null || raw.isEmpty) return;

      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        // Re-run URL normalization for caches created with an older app
        // version, where relative logo paths may have been stored directly.
        branding.value = AppBranding.fromJson(decoded);
      }
    } catch (_) {
      // Ignore cache corruption and keep the fallback branding.
    }
  }

  Future<void> _save(AppBranding brand) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(brand.toJson()));
    } catch (_) {
      // Cache persistence is optional.
    }
  }
}
