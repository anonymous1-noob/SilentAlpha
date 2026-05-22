import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

class NotificationProvider extends ChangeNotifier {
  int _unreadCount = 0;
  RealtimeChannel? _channel;

  int get unreadCount => _unreadCount;

  NotificationProvider() {
    _initFromSession();
    SupabaseService.authStateChanges.listen((state) {
      if (state.session != null) {
        _setupRealtime(state.session!.user.id);
      } else {
        _teardown();
      }
    });
  }

  void _initFromSession() {
    final uid = SupabaseService.currentUserId;
    if (uid != null) _setupRealtime(uid);
  }

  void _setupRealtime(String userId) {
    _teardown();
    _channel = SupabaseService.client
        .channel('notifications:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'recipient_id',
            value: userId,
          ),
          callback: (_) {
            _unreadCount++;
            notifyListeners();
          },
        )
        .subscribe();
  }

  void _teardown() {
    _channel?.unsubscribe();
    _channel = null;
    _unreadCount = 0;
  }

  void markAllRead() {
    if (_unreadCount == 0) return;
    _unreadCount = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _teardown();
    super.dispose();
  }
}
