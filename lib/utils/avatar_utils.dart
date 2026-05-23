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

  static const _medalEmojis = ['🥇', '🥈', '🥉'];
  static const _medalColors = [Color(0xFFFFD700), Color(0xFFC0C0C0), Color(0xFFCD7F32)];

  /// Builds an avatar circle. If [rank] is 1–3, overlays the matching medal
  /// emoji at the bottom-right. No decoration for rank > 3 or null.
  static Widget buildAvatar({
    String? url,
    required String userId,
    required String username,
    double radius = 20,
    int? rank,
  }) {
    final avatar = _buildCircle(url: url, userId: userId, username: username, radius: radius);

    if (rank == null || rank > 3) return avatar;

    final medalEmoji = _medalEmojis[rank - 1];
    final medalColor = _medalColors[rank - 1];
    final chipSize = (radius * 0.72).clamp(14.0, 24.0);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(
          bottom: -3,
          right: -3,
          child: Container(
            width: chipSize,
            height: chipSize,
            decoration: BoxDecoration(
              color: medalColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
              boxShadow: [BoxShadow(color: medalColor.withValues(alpha: 0.5), blurRadius: 4)],
            ),
            child: Center(
              child: Text(
                medalEmoji,
                style: TextStyle(fontSize: chipSize * 0.55),
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
