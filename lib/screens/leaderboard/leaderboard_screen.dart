import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/models.dart';
import '../../services/supabase_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/avatar_utils.dart';
import '../profile/profile_screen.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<AppUser> _users = [];
  bool _loading = true;
  DateTime? _lastRefreshed;

  static const _prefKey = 'leaderboard_last_refresh_ts';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool force = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final storedTs = prefs.getInt(_prefKey);
    final now = DateTime.now();

    // Auto-refresh once per day
    if (!force && storedTs != null) {
      final lastRefresh = DateTime.fromMillisecondsSinceEpoch(storedTs);
      if (now.difference(lastRefresh).inHours < 24 && _users.isNotEmpty) {
        return;
      }
    }

    setState(() => _loading = true);
    try {
      final raw = await SupabaseService.getLeaderboard(limit: 50);
      if (mounted) {
        setState(() {
          _users = raw.map(AppUser.fromMap).toList();
          _lastRefreshed = now;
        });
        await prefs.setInt(_prefKey, now.millisecondsSinceEpoch);
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentId = SupabaseService.currentUserId;

    return Scaffold(
      backgroundColor: AppTheme.of(context).surface,
      appBar: AppBar(
        backgroundColor: AppTheme.of(context).surfaceVariant,
        title: ShaderMask(
          shaderCallback: (b) => AppTheme.gradient.createShader(b),
          child: const Text(
            'Leaderboard',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
          ),
        ),
        actions: [
          if (_lastRefreshed != null)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Center(
                child: Text(
                  'Updated today',
                  style: TextStyle(
                      color: AppTheme.of(context).onSurfaceMuted, fontSize: 11),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: () => _load(force: true),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : RefreshIndicator(
              color: AppTheme.primary,
              onRefresh: () => _load(force: true),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _users.length,
                itemBuilder: (context, i) {
                  final user = _users[i];
                  final rank = i + 1;
                  final isMe = user.id == currentId;
                  final badge = user.badge;
                  final isTopThree = rank <= 3;

                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => ProfileScreen(userId: user.id)),
                    ),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: isTopThree
                            ? LinearGradient(
                                colors: [
                                  AppTheme.primary.withValues(alpha: isMe ? 0.25 : 0.12),
                                  AppTheme.primary.withValues(alpha: isMe ? 0.15 : 0.06),
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              )
                            : null,
                        color: isTopThree
                            ? null
                            : isMe
                                ? AppTheme.primary.withValues(alpha: 0.12)
                                : AppTheme.of(context).cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isTopThree
                              ? AppTheme.primary.withValues(alpha: 0.5)
                              : isMe
                                  ? AppTheme.primary.withValues(alpha: 0.4)
                                  : AppTheme.of(context).border,
                          width: isTopThree ? 1.5 : 1,
                        ),
                        boxShadow: isTopThree
                            ? [
                                BoxShadow(
                                  color: AppTheme.primary.withValues(alpha: 0.2),
                                  blurRadius: 8,
                                  spreadRadius: 0,
                                ),
                              ]
                            : null,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 36,
                              child: isTopThree
                                  ? Text(
                                      ['🥇', '🥈', '🥉'][rank - 1],
                                      style: const TextStyle(fontSize: 22),
                                      textAlign: TextAlign.center,
                                    )
                                  : Text(
                                      '#$rank',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: isMe
                                            ? AppTheme.primary
                                            : AppTheme.of(context).onSurfaceMuted,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                            ),
                            const SizedBox(width: 12),
                            AvatarUtils.buildAvatar(
                              url: user.avatarUrl,
                              userId: user.id,
                              username: user.handle,
                              radius: 22,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        '@${user.handle}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                          color: isTopThree || isMe
                                              ? AppTheme.primary
                                              : AppTheme.of(context).onSurface,
                                        ),
                                      ),
                                      if (isMe) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primary.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            'you',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: AppTheme.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Text(badge.emoji,
                                          style: const TextStyle(fontSize: 12)),
                                      const SizedBox(width: 4),
                                      Text(
                                        badge.name,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: badge.color,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                ShaderMask(
                                  shaderCallback: (b) =>
                                      AppTheme.gradient.createShader(b),
                                  child: Text(
                                    '${user.userScore}',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                Text(
                                  'pts',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: AppTheme.of(context).onSurfaceMuted),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
