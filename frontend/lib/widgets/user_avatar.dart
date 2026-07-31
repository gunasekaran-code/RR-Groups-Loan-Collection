import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/app_user.dart';

class UserAvatar extends StatelessWidget {
  final AppUser? user;
  final double radius;
  final Color backgroundColor;
  final TextStyle? textStyle;

  const UserAvatar({
    super.key,
    required this.user,
    required this.radius,
    required this.backgroundColor,
    this.textStyle,
  });

  Uint8List? _decodeAvatar(String? avatarUrl) {
    if (avatarUrl == null || avatarUrl.isEmpty) return null;
    final commaIndex = avatarUrl.indexOf(',');
    final base64Part =
        commaIndex == -1 ? avatarUrl : avatarUrl.substring(commaIndex + 1);
    try {
      return base64Decode(base64Part);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatarBytes = _decodeAvatar(user?.avatarUrl);
    final initials = user?.initials ?? '?';

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      foregroundImage:
          avatarBytes != null ? MemoryImage(avatarBytes) : null,
      onForegroundImageError: avatarBytes != null
          ? (_, __) {}
          : null,
      child: avatarBytes == null
          ? Text(
              initials,
              style: textStyle ??
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            )
          : null,
    );
  }
}
