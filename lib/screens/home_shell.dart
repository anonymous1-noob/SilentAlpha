import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/feed_provider.dart';
import '../providers/categories_provider.dart';
import '../providers/notification_provider.dart';
import '../utils/app_theme.dart';
import 'feed/feed_screen.dart';
import 'discovery/discovery_screen.dart';
import 'post/create_post_screen.dart';
import 'notifications_screen.dart';
import 'profile/profile_screen.dart';
import 'leaderboard/leaderboard_screen.dart';
import '../providers/auth_provider.dart';
import '../services/supabase_service.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FeedProvider>().loadPosts();
      context.read<CategoriesProvider>().load();
    });
  }

  void _showCreatePost() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const CreatePostScreen(),
      ),
    );
    if (mounted) {
      setState(() => _index = 0);
      context.read<FeedProvider>().refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId =
        context.select<AuthProvider, String?>((a) => a.user?.id);
    final unread = context.watch<NotificationProvider>().unreadCount;

    final screens = [
      const FeedScreen(),
      const DiscoveryScreen(),
      const SizedBox.shrink(),
      const NotificationsScreen(),
      ProfileScreen(userId: userId ?? SupabaseService.currentUserId ?? ''),
    ];

    return Scaffold(
      backgroundColor: AppTheme.of(context).surface,
      body: IndexedStack(
        index: _index,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: Color(0xFF2A2A4A), width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _index,
          onTap: (i) {
            if (i == 2) {
              _showCreatePost();
            } else {
              if (i == 3 && unread > 0) {
                context.read<NotificationProvider>().markAllRead();
              }
              setState(() => _index = i);
            }
          },
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined),
              activeIcon: Icon(Icons.explore),
              label: 'Explore',
            ),
            const BottomNavigationBarItem(
              icon: _CreateIcon(),
              label: 'Post',
            ),
            BottomNavigationBarItem(
              icon: _NotifIcon(unread: unread, active: false),
              activeIcon: _NotifIcon(unread: unread, active: true),
              label: 'Activity',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
      floatingActionButton: _index == 0
          ? FloatingActionButton.small(
              heroTag: 'leaderboard',
              backgroundColor: AppTheme.of(context).surfaceVariant,
              foregroundColor: AppTheme.primary,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
              ),
              child: const Icon(Icons.leaderboard_outlined, size: 20),
            )
          : null,
    );
  }
}

class _CreateIcon extends StatelessWidget {
  const _CreateIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 32,
      decoration: BoxDecoration(
        gradient: AppTheme.gradient,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.add, color: Colors.white, size: 22),
    );
  }
}

class _NotifIcon extends StatelessWidget {
  final int unread;
  final bool active;
  const _NotifIcon({required this.unread, required this.active});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(
          active ? Icons.notifications : Icons.notifications_outlined,
        ),
        if (unread > 0)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                unread > 9 ? '9+' : '$unread',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
