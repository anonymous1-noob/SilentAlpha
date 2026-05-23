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
  final Set<String> _processingIds = {};

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

  Future<void> _approveRequest(AppNotification n) async {
    if (n.actorId == null) return;
    setState(() => _processingIds.add(n.id));
    try {
      await SupabaseService.approveFollowRequest(n.actorId!);
      if (mounted) setState(() => _notifs.remove(n));
    } finally {
      if (mounted) setState(() => _processingIds.remove(n.id));
    }
  }

  Future<void> _rejectRequest(AppNotification n) async {
    if (n.actorId == null) return;
    setState(() => _processingIds.add(n.id));
    try {
      await SupabaseService.rejectFollowRequest(n.actorId!);
      if (mounted) setState(() => _notifs.remove(n));
    } finally {
      if (mounted) setState(() => _processingIds.remove(n.id));
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
              child: CircularProgressIndicator(color: AppTheme.primary))
          : _notifs.isEmpty
              ? Center(
                  child: FadeIn(
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.notifications_none,
                            size: 64, color: AppTheme.onSurfaceMuted),
                        SizedBox(height: 16),
                        Text(
                          'No notifications yet',
                          style: TextStyle(color: AppTheme.onSurfaceMuted),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: _notifs.length,
                  itemBuilder: (_, i) {
                    final n = _notifs[i];
                    final isProcessing = _processingIds.contains(n.id);

                    return FadeInUp(
                      delay: Duration(milliseconds: i * 50),
                      child: Container(
                        color: n.read
                            ? null
                            : AppTheme.primary.withValues(alpha: 0.07),
                        child: Column(
                          children: [
                            ListTile(
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
                                          size: 10, color: Colors.white),
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
                            ),
                            if (n.type == NotifType.followRequest) ...[
                              Padding(
                                padding: const EdgeInsets.fromLTRB(72, 0, 16, 12),
                                child: isProcessing
                                    ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppTheme.primary,
                                        ),
                                      )
                                    : Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton(
                                              onPressed: () =>
                                                  _rejectRequest(n),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor:
                                                    AppTheme.onSurfaceMuted,
                                                side: const BorderSide(
                                                    color: Color(0xFF2A2A4A)),
                                                padding: const EdgeInsets.symmetric(
                                                    vertical: 6),
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(8)),
                                              ),
                                              child: const Text('Decline',
                                                  style: TextStyle(fontSize: 13)),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: ElevatedButton(
                                              onPressed: () =>
                                                  _approveRequest(n),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: AppTheme.primary,
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(
                                                    vertical: 6),
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(8)),
                                              ),
                                              child: const Text('Accept',
                                                  style: TextStyle(fontSize: 13)),
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ],
                            const Divider(height: 1, color: Color(0xFF1A2545)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
