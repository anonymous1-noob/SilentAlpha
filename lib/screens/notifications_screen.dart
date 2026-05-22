import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../models/models.dart';
import '../services/supabase_service.dart';
import '../utils/app_theme.dart';
import '../utils/avatar_utils.dart';
import '../utils/time_utils.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotification> _notifs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final raw = await SupabaseService.getNotifications();
      _notifs = raw.map(AppNotification.fromMap).toList();
      await SupabaseService.markNotificationsRead();
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceVariant,
        title: const Text('Activity'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                  color: AppTheme.primary))
          : _notifs.isEmpty
              ? Center(
                  child: FadeIn(
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.notifications_none,
                            size: 64,
                            color: AppTheme.onSurfaceMuted),
                        SizedBox(height: 16),
                        Text(
                          'No notifications yet',
                          style: TextStyle(
                              color: AppTheme.onSurfaceMuted),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: _notifs.length,
                  itemBuilder: (_, i) {
                    final n = _notifs[i];
                    return FadeInUp(
                      delay: Duration(milliseconds: i * 50),
                      child: ListTile(
                        leading: Stack(
                          children: [
                            AvatarUtils.buildAvatar(
                              url: n.actorAvatarUrl,
                              userId: n.actorHandle,
                              username: n.actorHandle,
                              radius: 22,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: n.iconColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(n.icon,
                                    size: 10,
                                    color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        title: Text(
                          n.label,
                          style: TextStyle(
                            color: AppTheme.onSurface,
                            fontWeight: n.read
                                ? FontWeight.normal
                                : FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          TimeUtils.format(n.createdAt),
                          style: const TextStyle(
                            color: AppTheme.onSurfaceMuted,
                            fontSize: 12,
                          ),
                        ),
                        tileColor: n.read
                            ? null
                            : AppTheme.primary
                                .withValues(alpha: 0.07),
                      ),
                    );
                  },
                ),
    );
  }
}
