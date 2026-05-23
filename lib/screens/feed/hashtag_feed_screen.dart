import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/feed_provider.dart';
import '../../services/supabase_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/post/post_card.dart';

class HashtagFeedScreen extends StatefulWidget {
  final String hashtag; // without #
  const HashtagFeedScreen({super.key, required this.hashtag});

  @override
  State<HashtagFeedScreen> createState() => _HashtagFeedScreenState();
}

class _HashtagFeedScreenState extends State<HashtagFeedScreen> {
  List<Post> _posts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final raw = await SupabaseService.getPosts(
        hashtag: widget.hashtag,
        limit: 30,
        offset: 0,
      );
      if (mounted) setState(() => _posts = raw.map(Post.fromMap).toList());
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: context.read<FeedProvider>(),
      child: Scaffold(
        backgroundColor: AppTheme.of(context).surface,
        appBar: AppBar(
          backgroundColor: AppTheme.of(context).surfaceVariant,
          title: Text('#${widget.hashtag}'),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
            : _posts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.tag, size: 64, color: AppTheme.onSurfaceMuted),
                        const SizedBox(height: 16),
                        Text(
                          'No posts tagged #${widget.hashtag}',
                          style: const TextStyle(color: AppTheme.onSurfaceMuted),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    color: AppTheme.primary,
                    onRefresh: _load,
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: _posts.length,
                      itemBuilder: (_, i) => PostCard(post: _posts[i]),
                    ),
                  ),
      ),
    );
  }
}
