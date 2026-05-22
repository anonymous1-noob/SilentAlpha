import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/feed_provider.dart';
import '../../services/supabase_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/avatar_utils.dart';
import '../../utils/time_utils.dart';
import '../../widgets/post/post_card.dart';
import '../../widgets/common/gradient_button.dart';
import 'edit_profile_screen.dart';
import '../admin/admin_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;
  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  AppUser? _profile;
  List<Post> _userPosts = [];
  List<Post> _savedPosts = [];
  bool _loading = true;
  bool _followLoading = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  bool get _isOwn => widget.userId == SupabaseService.currentUserId;

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await SupabaseService.getProfile(widget.userId);
      if (data != null) _profile = AppUser.fromMap(data);
      final postRaw = await SupabaseService.getPosts(authorId: widget.userId, limit: 50);
      _userPosts = postRaw.map(Post.fromMap).toList();
      if (_isOwn) {
        final savedRaw = await SupabaseService.getSavedPosts();
        _savedPosts = savedRaw
            .map((r) {
              final p = r['posts_with_meta'];
              if (p == null) return null;
              return Post.fromMap(p as Map<String, dynamic>);
            })
            .whereType<Post>()
            .toList();
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleFollow() async {
    if (_profile == null) return;
    setState(() => _followLoading = true);
    try {
      if (_profile!.isFollowing) {
        await SupabaseService.unfollowUser(widget.userId);
      } else {
        await SupabaseService.followUser(widget.userId);
      }
      setState(() {
        _profile = _profile!.copyWith(
          isFollowing: !_profile!.isFollowing,
          followerCount: _profile!.followerCount + (_profile!.isFollowing ? -1 : 1),
        );
      });
    } finally {
      if (mounted) setState(() => _followLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppTheme.surface,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceVariant,
        title: Text(_profile?.handle != null ? '@${_profile!.handle}' : 'Profile'),
        actions: [
          if (_isOwn) ...[
            if (auth.user?.isAdmin == true)
              IconButton(
                icon: ShaderMask(
                  shaderCallback: (b) => AppTheme.gradient.createShader(b),
                  child: const Icon(Icons.shield, color: Colors.white, size: 22),
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminScreen()),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => EditProfileScreen(user: auth.user!)),
                );
                _load();
              },
            ),
          ]
          else
            PopupMenuButton<String>(
              color: AppTheme.surfaceVariant,
              onSelected: (v) async {
                if (v == 'block') {
                  await SupabaseService.blockUser(widget.userId);
                  if (context.mounted) Navigator.pop(context);
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'block',
                  child: Row(children: [
                    Icon(Icons.block, color: Colors.red, size: 16),
                    SizedBox(width: 8),
                    Text('Block user', style: TextStyle(color: Colors.red)),
                  ]),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          _buildProfileHeader(auth),
          _buildTabBar(),
          Expanded(child: _buildTabContent()),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(AuthProvider auth) {
    final badge = _profile?.badge;
    return FadeInUp(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AvatarUtils.buildAvatar(
                  url: _profile?.avatarUrl,
                  userId: widget.userId,
                  username: _profile?.handle ?? 'anon',
                  radius: 36,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              '@${_profile?.handle ?? 'anonymous'}',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (_profile?.tagline != null && _profile!.tagline!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          _profile!.tagline!,
                          style: const TextStyle(
                            color: AppTheme.onSurfaceMuted,
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (badge != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _BadgeChip(badge: badge),
                            if (_profile?.isAdmin == true) ...[
                              const SizedBox(width: 6),
                              _AdminChip(),
                            ],
                          ],
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        'Joined ${TimeUtils.formatFull(_profile?.createdAt ?? DateTime.now())}',
                        style: const TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                if (!_isOwn) ...[
                  const SizedBox(width: 8),
                  GradientButton(
                    label: _profile?.isFollowing ?? false ? 'Following' : 'Follow',
                    loading: _followLoading,
                    width: 100,
                    onPressed: _toggleFollow,
                  ),
                ],
              ],
            ),
            if (_profile?.bio != null && _profile!.bio!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                _profile!.bio!,
                style: const TextStyle(color: AppTheme.onSurface, height: 1.4),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _Stat(label: 'Posts', value: _userPosts.length.toString()),
                _Stat(label: 'Followers', value: '${_profile?.followerCount ?? 0}'),
                _Stat(label: 'Following', value: '${_profile?.followingCount ?? 0}'),
                _Stat(
                  label: 'Score',
                  value: '${_profile?.userScore ?? 0}',
                  valueColor: AppTheme.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabs,
      labelColor: AppTheme.primary,
      unselectedLabelColor: AppTheme.onSurfaceMuted,
      indicatorColor: AppTheme.primary,
      tabs: [
        const Tab(text: 'Posts'),
        if (_isOwn) const Tab(text: 'Saved') else const Tab(text: ''),
      ],
    );
  }

  Widget _buildTabContent() {
    return TabBarView(
      controller: _tabs,
      children: [
        _PostsList(posts: _userPosts),
        if (_isOwn) _PostsList(posts: _savedPosts) else const SizedBox.shrink(),
      ],
    );
  }
}

class _AdminChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (b) => AppTheme.gradient.createShader(b),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.5)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shield, size: 11, color: Colors.white),
            SizedBox(width: 3),
            Text(
              'Admin',
              style: TextStyle(
                  color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  final UserBadge badge;
  const _BadgeChip({required this.badge});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: badge.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badge.color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(badge.emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            badge.name,
            style: TextStyle(
              color: badge.color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _Stat({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: valueColor ?? AppTheme.onSurface,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 12),
        ),
      ],
    );
  }
}

class _PostsList extends StatelessWidget {
  final List<Post> posts;
  const _PostsList({required this.posts});

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return const Center(
        child: Text('No posts yet', style: TextStyle(color: AppTheme.onSurfaceMuted)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: posts.length,
      itemBuilder: (_, i) => ChangeNotifierProvider(
        create: (_) => FeedProvider(),
        child: PostCard(post: posts[i], compact: true),
      ),
    );
  }
}
