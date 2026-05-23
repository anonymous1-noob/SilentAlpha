import 'package:flutter/material.dart';
import '../models/models.dart';

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

  /// Builds an avatar circle. If [score] is provided, wraps with a coloured
  /// badge ring and a tiny emoji indicator at the bottom-right corner.
  static Widget buildAvatar({
    String? url,
    required String userId,
    required String username,
    double radius = 20,
    int? score,
  }) {
    final avatar = _buildCircle(url: url, userId: userId, username: username, radius: radius);

    if (score == null) return avatar;

    final badge = UserBadge.fromScore(score);
    final ringWidth = (radius * 0.12).clamp(2.0, 4.0);
    final badgeSize = (radius * 0.62).clamp(14.0, 22.0);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Coloured ring
        Container(
          width: radius * 2 + ringWidth * 2,
          height: radius * 2 + ringWidth * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [badge.color, badge.color.withValues(alpha: 0.5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: ClipOval(child: SizedBox(width: radius * 2, height: radius * 2, child: avatar)),
          ),
        ),
        // Badge emoji chip at bottom-right
        Positioned(
          bottom: -2,
          right: -2,
          child: Container(
            width: badgeSize,
            height: badgeSize,
            decoration: BoxDecoration(
              color: badge.color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: Center(
              child: Text(
                badge.emoji,
                style: TextStyle(fontSize: badgeSize * 0.52),
              ),
            ),
          ),
        ),
      ],
    );
  }

  static Widget _buildCircle({
    String? url,
    required String userId,
    required String username,
    required double radius,
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
