import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/feed_provider.dart';
import '../../services/supabase_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/post/post_card.dart';

class TickerFeedScreen extends StatefulWidget {
  final String ticker; // without $
  const TickerFeedScreen({super.key, required this.ticker});

  @override
  State<TickerFeedScreen> createState() => _TickerFeedScreenState();
}

class _TickerFeedScreenState extends State<TickerFeedScreen> {
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
        ticker: widget.ticker,
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
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.3)),
                ),
                child: Text(
                  '\$${widget.ticker}',
                  style: const TextStyle(
                    color: Color(0xFF22C55E),
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
            : _posts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.show_chart, size: 64, color: AppTheme.of(context).onSurfaceMuted),
                        const SizedBox(height: 16),
                        Text(
                          'No posts about \$${widget.ticker}',
                          style: TextStyle(color: AppTheme.of(context).onSurfaceMuted),
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
