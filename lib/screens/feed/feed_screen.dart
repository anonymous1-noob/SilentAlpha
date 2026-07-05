import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../providers/feed_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/post/post_card.dart';
import '../../widgets/common/shimmer_loader.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> with SingleTickerProviderStateMixin {
  final _scrollCtrl = ScrollController();
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) return;
      final feed = context.read<FeedProvider>();
      feed.setFeedType(_tabCtrl.index == 0 ? FeedType.all : FeedType.following);
    });
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
      context.read<FeedProvider>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final feed = context.watch<FeedProvider>();

    return Scaffold(
      backgroundColor: AppTheme.of(context).surface,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            floating: true,
            snap: true,
            pinned: false,
            backgroundColor: AppTheme.of(context).surfaceVariant,
            title: ShaderMask(
              shaderCallback: (b) => AppTheme.gradient.createShader(b),
              child: const Text(
                'TheSilentAlpha',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48.0),
              child: TabBar(
                controller: _tabCtrl,
                indicatorColor: AppTheme.primary,
                indicatorWeight: 3,
                dividerColor: Colors.transparent,
                labelColor: AppTheme.primary,
                unselectedLabelColor: AppTheme.of(context).onSurfaceMuted,
                labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Following'),
                ],
              ),
            ),
          ),
        ],
        body: Column(
          children: [
            // Realtime "new posts" banner
            if (feed.hasNewPosts)
              GestureDetector(
                onTap: feed.dismissNewPosts,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  color: AppTheme.primary.withValues(alpha: 0.9),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.arrow_upward, color: Colors.white, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'New posts — tap to refresh',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Expanded(child: _buildBody(feed)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(FeedProvider feed) {
    if (feed.loading && feed.posts.isEmpty) {
      return ListView.builder(itemCount: 6, itemBuilder: (_, __) => const PostShimmer());
    }

    if (feed.error != null && feed.posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppTheme.of(context).onSurfaceMuted),
            const SizedBox(height: 12),
            Text(feed.error!, style: TextStyle(color: AppTheme.of(context).onSurfaceMuted)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.read<FeedProvider>().refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (feed.posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              feed.feedType == FeedType.following ? Icons.people_outline : Icons.chat_bubble_outline,
              size: 64,
              color: AppTheme.of(context).onSurfaceMuted,
            ),
            const SizedBox(height: 16),
            Text(
              feed.feedType == FeedType.following
                  ? 'No posts from people you follow.\nFollow some users to see their posts!'
                  : 'No posts yet.\nBe the first to share your analysis!',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.of(context).onSurfaceMuted, height: 1.5),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppTheme.primary,
      backgroundColor: AppTheme.cardBg,
      onRefresh: () => context.read<FeedProvider>().refresh(),
      child: AnimationLimiter(
        child: ListView.builder(
          controller: _scrollCtrl,
          padding: const EdgeInsets.only(bottom: 80),
          itemCount: feed.posts.length + (feed.loadingMore ? 1 : 0),
          itemBuilder: (context, i) {
            if (i >= feed.posts.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
              );
            }
            final card = PostCard(post: feed.posts[i]);
            if (i >= 8) return card;
            return AnimationConfiguration.staggeredList(
              position: i,
              duration: const Duration(milliseconds: 300),
              child: SlideAnimation(
                verticalOffset: 40,
                child: FadeInAnimation(child: card),
              ),
            );
          },
        ),
      ),
    );
  }
}

