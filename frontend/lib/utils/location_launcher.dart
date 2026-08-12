import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../routes/app_routes.dart';
import '../models/agent_collection.dart';

/// Opens [group]'s location in the device's default maps app.
///
/// Prefers exact coordinates when the backend provides them, falls back to
/// a text-address search, and — only if neither is available — falls back
/// to the app's own in-app Route Map screen so "Visit" never dead-ends.
Future<void> openCustomerLocation(
  BuildContext context,
  AgentCustomerGroup group,
) async {
  Uri? uri;
  if (group.latitude != null && group.longitude != null) {
    uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${group.latitude},${group.longitude}',
    );
  } else if (group.address != null && group.address!.trim().isNotEmpty) {
    uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(group.address!.trim())}',
    );
  }

  if (uri != null) {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (launched) return;
  }

  if (!context.mounted) return;

  // No coordinates or address on file for this customer — fall back to the
  // app's own Route Map screen so the "Visit" action still does something
  // useful instead of failing silently.
  Navigator.of(context).pushNamed(
    AppRoutes.routeMap,
    arguments: {
      'customerId': group.customerId,
      'loanId': group.items.isNotEmpty ? group.items.first.loanId : null,
    },
  );
}