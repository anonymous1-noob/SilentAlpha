import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/categories_provider.dart';
import '../../services/supabase_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/avatar_utils.dart';
import '../../widgets/post/post_card.dart';
import '../feed/hashtag_feed_screen.dart';
import '../feed/ticker_feed_screen.dart';
import '../profile/profile_screen.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _searchCtrl = TextEditingController();
  String _activeQuery = '';

  List<Post> _topPosts = [];
  List<Post> _postResults = [];
  List<AppUser> _userResults = [];
  List<Map<String, dynamic>> _trendingTickers = [];

  bool _loadingTop = true;
  bool _loadingTickers = true;
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() => setState(() {}));
    _loadTopPosts();
    _loadTrendingTickers();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final q = _searchCtrl.text.trim();
    if (q == _activeQuery) return;
    setState(() {
      _activeQuery = q;
      if (q.isEmpty) {
        _postResults = [];
        _userResults = [];
      }
    });
    if (q.length >= 2) _runSearch(q);
  }

  Future<void> _loadTopPosts() async {
    try {
      final raw = await SupabaseService.getPosts(limit: 10, offset: 0);
      if (mounted) setState(() => _topPosts = raw.map(Post.fromMap).toList());
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingTop = false);
    }
  }

  Future<void> _loadTrendingTickers() async {
    try {
      final raw = await SupabaseService.getTrendingTickers();
      if (mounted) setState(() => _trendingTickers = raw);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingTickers = false);
    }
  }

  Future<void> _runSearch(String q) async {
    setState(() => _searching = true);
    try {
      if (_tabCtrl.index == 0) {
        final raw = await SupabaseService.searchPosts(q);
        if (mounted && _searchCtrl.text.trim() == q) {
          setState(() => _postResults = raw.map(Post.fromMap).toList());
        }
      } else {
        final raw = await SupabaseService.searchUsers(q);
        if (mounted && _searchCtrl.text.trim() == q) {
          setState(() => _userResults = raw.map(AppUser.fromMap).toList());
        }
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _clearSearch() {
    _searchCtrl.clear();
    setState(() {
      _activeQuery = '';
      _postResults = [];
      _userResults = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final trending = context.watch<CategoriesProvider>().trending;
    final isSearching = _activeQuery.length >= 2;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header + Search
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Explore',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: _tabCtrl.index == 0 ? 'Search posts...' : 'Search people...',
                      prefixIcon: const Icon(Icons.search, color: AppTheme.onSurfaceMuted),
                      suffixIcon: _activeQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: _clearSearch,
                            )
                          : null,
                    ),
                    onChanged: (_) {
                      if (_activeQuery.length >= 2) _runSearch(_activeQuery);
                    },
                  ),
                  const SizedBox(height: 12),
                  TabBar(
                    controller: _tabCtrl,
                    indicatorColor: AppTheme.primary,
                    labelColor: AppTheme.primary,
                    unselectedLabelColor: AppTheme.onSurfaceMuted,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w700),
                    tabs: const [
                      Tab(text: 'Posts'),
                      Tab(text: 'People'),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  _PostsTab(
                    isSearching: isSearching,
                    searching: _searching,
                    query: _activeQuery,
                    searchResults: _postResults,
                    topPosts: _topPosts,
                    loadingTop: _loadingTop,
                    trendingHashtags: trending,
                    trendingTickers: _trendingTickers,
                    loadingTickers: _loadingTickers,
                  ),
                  _PeopleTab(
                    isSearching: isSearching,
                    searching: _searching,
                    query: _activeQuery,
                    results: _userResults,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Posts tab ─────────────────────────────────────────────────────────────────

class _PostsTab extends StatelessWidget {
  final bool isSearching;
  final bool searching;
  final String query;
  final List<Post> searchResults;
  final List<Post> topPosts;
  final bool loadingTop;
  final List<dynamic> trendingHashtags;
  final List<Map<String, dynamic>> trendingTickers;
  final bool loadingTickers;

  const _PostsTab({
    required this.isSearching,
    required this.searching,
    required this.query,
    required this.searchResults,
    required this.topPosts,
    required this.loadingTop,
    required this.trendingHashtags,
    required this.trendingTickers,
    required this.loadingTickers,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Trending Hashtags
        if (trendingHashtags.isNotEmpty && !isSearching) ...[
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text('🔥 Trending Topics',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: trendingHashtags.length,
                itemBuilder: (_, i) {
                  final tag = (trendingHashtags[i]['hashtag'] ??
                      trendingHashtags[i]['tag'] ?? '') as String;
                  if (tag.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text('#$tag',
                          style: const TextStyle(
                              color: AppTheme.primary, fontWeight: FontWeight.w600)),
                      backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                      side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.3)),
                      onPressed: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => HashtagFeedScreen(hashtag: tag))),
                    ),
                  );
                },
              ),
            ),
          ),
        ],

        // Trending Tickers
        if (trendingTickers.isNotEmpty && !isSearching) ...[
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text('📈 Trending Tickers',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: trendingTickers.length,
                itemBuilder: (_, i) {
                  final ticker = (trendingTickers[i]['ticker'] ?? '') as String;
                  if (ticker.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text('\$$ticker',
                          style: const TextStyle(
                              color: Color(0xFF22C55E), fontWeight: FontWeight.w600)),
                      backgroundColor: const Color(0xFF22C55E).withValues(alpha: 0.12),
                      side: BorderSide(
                          color: const Color(0xFF22C55E).withValues(alpha: 0.3)),
                      onPressed: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => TickerFeedScreen(ticker: ticker))),
                    ),
                  );
                },
              ),
            ),
          ),
        ],

        // Section header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
            child: Text(
              isSearching ? 'Results for "$query"' : '🏆 Top Posts',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
        ),

        // Results
        if (isSearching && searching)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
            ),
          )
        else if (isSearching && searchResults.isEmpty && !searching)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.search_off, size: 48, color: AppTheme.onSurfaceMuted),
                    const SizedBox(height: 12),
                    Text('No results for "$query"',
                        style: const TextStyle(color: AppTheme.onSurfaceMuted)),
                  ],
                ),
              ),
            ),
          )
        else if (!isSearching && loadingTop)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) {
                final list = isSearching ? searchResults : topPosts;
                if (i >= list.length) return null;
                return PostCard(post: list[i]);
              },
              childCount: (isSearching ? searchResults : topPosts).length,
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }
}

// ── People tab ────────────────────────────────────────────────────────────────

class _PeopleTab extends StatelessWidget {
  final bool isSearching;
  final bool searching;
  final String query;
  final List<AppUser> results;

  const _PeopleTab({
    required this.isSearching,
    required this.searching,
    required this.query,
    required this.results,
  });

  @override
  Widget build(BuildContext context) {
    if (!isSearching) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_search, size: 64, color: AppTheme.onSurfaceMuted),
            SizedBox(height: 12),
            Text('Type to search for users',
                style: TextStyle(color: AppTheme.onSurfaceMuted)),
          ],
        ),
      );
    }

    if (searching) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.primary));
    }

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, size: 48, color: AppTheme.onSurfaceMuted),
            const SizedBox(height: 12),
            Text('No users found for "$query"',
                style: const TextStyle(color: AppTheme.onSurfaceMuted)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: results.length,
      itemBuilder: (context, i) {
        final user = results[i];
        return ListTile(
          leading: AvatarUtils.buildAvatar(
            url: user.avatarUrl,
            userId: user.id,
            username: user.handle,
            radius: 22,
          ),
          title: Text('@${user.handle}',
              style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Row(
            children: [
              Text(user.badge.emoji, style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 4),
              Text(user.badge.name,
                  style: TextStyle(fontSize: 12, color: user.badge.color)),
              const SizedBox(width: 8),
              Text('${user.followerCount} followers',
                  style: const TextStyle(fontSize: 12, color: AppTheme.onSurfaceMuted)),
            ],
          ),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ProfileScreen(userId: user.id)),
          ),
        );
      },
    );
  }
}
