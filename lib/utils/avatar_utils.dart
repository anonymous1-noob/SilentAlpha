import 'package:flutter/material.dart';

class AvatarUtils {
  static final _colors = [
    const Color(0xFF6C63FF),
    const Color(0xFFFF6B9D),
    const Color(0xFF4ECDC4),
    const Color(0xFFFFBE0B),
    const Color(0xFFFF006E),
    const Color(0xFF8338EC),
    const Color(0xFF06D6A0),
    const Color(0xFF118AB2),
  ];

  static Color colorFor(String userId) {
    final index = userId.codeUnits.fold(0, (a, b) => a + b) % _colors.length;
    return _colors[index];
  }

  static String initialsFor(String username) {
    final parts = username.trim().split(RegExp(r'[\s_]'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return username.substring(0, username.length.clamp(1, 2)).toUpperCase();
  }

  static Widget buildAvatar({
    String? url,
    required String userId,
    required String username,
    double radius = 20,
  }) {
    if (url != null && url.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(url),
        backgroundColor: colorFor(userId),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: colorFor(userId),
      child: Text(
        initialsFor(username),
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.7,
        ),
      ),
    );
  }
}
