import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/feed_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/avatar_utils.dart';
import '../../utils/hashtag_utils.dart';
import '../../utils/time_utils.dart';
import '../../screens/post/post_detail_screen.dart';
import '../../screens/post/edit_post_screen.dart';
import '../../screens/post/post_analytics_sheet.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/feed/hashtag_feed_screen.dart';
import '../../services/supabase_service.dart';
import '../common/report_dialog.dart';
import 'poll_widget.dart';

class PostCard extends StatefulWidget {
  final Post post;
  final bool compact;

  const PostCard({super.key, required this.post, this.compact = false});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late double _slider;
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    _slider = (widget.post.userRating ?? 0).toDouble();
  }

  @override
  void didUpdateWidget(PostCard old) {
    super.didUpdateWidget(old);
    if (!_dragging && widget.post.userRating != old.post.userRating) {
      _slider = (widget.post.userRating ?? 0).toDouble();
    }
  }

  String _emoji(double v) {
    if (v >= 4.5) return '🚀';
    if (v >= 3.5) return '😄';
    if (v >= 2.5) return '📈';
    if (v >= 1.5) return '😊';
    if (v >= 0.5) return '🟢';
    if (v > -0.5) return '😐';
    if (v > -1.5) return '🔴';
    if (v > -2.5) return '😟';
    if (v > -3.5) return '📉';
    if (v > -4.5) return '😡';
    return '💣';
  }

  Color _sliderColor(double v) {
    if (v > 0.5) return const Color(0xFF22C55E);
    if (v < -0.5) return const Color(0xFFEF4444);
    return AppTheme.onSurfaceMuted;
  }

  void _showAnalytics(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => PostAnalyticsSheet(post: widget.post),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final feed = context.read<FeedProvider>();
    final isOwner = auth.user?.id == widget.post.authorId;
    final isAdmin = auth.user?.isAdmin ?? false;
    final canModify = isOwner || isAdmin;

    return GestureDetector(
      onTap: widget.compact
          ? () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => PostDetailScreen(post: widget.post)),
              )
          : null,
      onLongPress: isOwner ? () => _showAnalytics(context) : null,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.of(context).cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.post.isPinned
                ? AppTheme.primary.withValues(alpha: 0.3)
                : isAdmin && !isOwner
                    ? AppTheme.primary.withValues(alpha: 0.15)
                    : AppTheme.of(context).border,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pinned banner
              if (widget.post.isPinned) ...[
                Row(
                  children: [
                    const Icon(Icons.push_pin, size: 13, color: AppTheme.primary),
                    const SizedBox(width: 4),
                    const Text(
                      'Pinned',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              _buildHeader(context, canModify, isOwner, isAdmin, feed, auth),
              const SizedBox(height: 12),
              _buildContent(context),


              if (widget.post.imageUrl != null) ...[
                const SizedBox(height: 12),
                _buildImage(),
              ],

              // Poll
              if (widget.post.poll != null && !widget.compact) ...[
                const SizedBox(height: 12),
                PollWidget(
                  poll: widget.post.poll!,
                  postId: widget.post.id,
                ),
              ],

              if (!widget.compact) ...[
                const SizedBox(height: 14),
                _buildRatingSlider(feed),
                const SizedBox(height: 10),
                _buildFooter(context, feed, isOwner),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Rating slider ─────────────────────────────────────────────────────────

  Widget _buildRatingSlider(FeedProvider feed) {
    final post = widget.post;
    final color = _sliderColor(_slider);
    final avgLabel = post.avgRating == 0
        ? '0'
        : post.avgRating > 0
            ? '+${post.avgRating.toStringAsFixed(1)}'
            : post.avgRating.toStringAsFixed(1);

    return GestureDetector(
      onTap: () {},
      child: Row(
        children: [
          SizedBox(
            width: 26,
            child: Text(_emoji(_slider), style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                activeTrackColor: color,
                inactiveTrackColor: AppTheme.onSurfaceMuted.withValues(alpha: 0.15),
                thumbColor: color,
                overlayColor: color.withValues(alpha: 0.15),
              ),
              child: Slider(
                min: -5,
                max: 5,
                divisions: 10,
                value: _slider,
                onChangeStart: (_) => setState(() => _dragging = true),
                onChanged: (v) => setState(() => _slider = v),
                onChangeEnd: (v) {
                  setState(() => _dragging = false);
                  feed.ratePost(post.id, v.round());
                },
              ),
            ),
          ),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                avgLabel,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _sliderColor(post.avgRating),
                ),
              ),
              if (post.ratingCount > 0)
                Text(
                  '${post.ratingCount} rated',
                  style: TextStyle(
                      fontSize: 9, color: AppTheme.of(context).onSurfaceMuted),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, bool canModify, bool isOwner,
      bool isAdmin, FeedProvider feed, AuthProvider auth) {
    final showAnon = widget.post.isAnonymous;
    final displayHandle = showAnon ? null : widget.post.authorHandle;

    return Row(
      children: [
        if (showAnon)
          _AnonAvatar()
        else
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => ProfileScreen(userId: widget.post.authorId)),
            ),
            child: AvatarUtils.buildAvatar(
              url: widget.post.authorAvatarUrl,
              userId: widget.post.authorId,
              username: displayHandle ?? 'anon',
              radius: 20,
              rank: widget.post.authorRank,
            ),
          ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: showAnon
                        ? Text(
                            '@anonymous',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: AppTheme.of(context).onSurfaceMuted,
                              fontStyle: FontStyle.italic,
                            ),
                            overflow: TextOverflow.ellipsis,
                          )
                        : GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => ProfileScreen(
                                      userId: widget.post.authorId)),
                            ),
                            child: Text(
                              '@${displayHandle ?? 'anon'}',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: AppTheme.of(context).onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                  ),
                  if (isAdmin && !isOwner) ...[
                    const SizedBox(width: 4),
                    _MiniChip(label: 'admin', color: AppTheme.primary),
                  ],
                ],
              ),
              Text(
                TimeUtils.format(widget.post.createdAt),
                style: TextStyle(fontSize: 12, color: AppTheme.of(context).onSurfaceMuted),
              ),
            ],
          ),
        ),
        _buildMoreMenu(context, canModify, isOwner, isAdmin, feed),
      ],
    );
  }

  Widget _buildMoreMenu(BuildContext context, bool canModify, bool isOwner,
      bool isAdmin, FeedProvider feed) {
    return PopupMenuButton<String>(
      color: AppTheme.of(context).surfaceVariant,
      icon: Icon(Icons.more_vert, color: AppTheme.of(context).onSurfaceMuted, size: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (val) async {
        switch (val) {
          case 'edit':
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => EditPostScreen(post: widget.post)),
            );
            feed.refresh();
          case 'delete':
            final confirm = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                backgroundColor: AppTheme.of(context).surfaceVariant,
                title: const Text('Delete post?'),
                content: const Text('This action cannot be undone.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel')),
                  TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Delete',
                          style: TextStyle(color: Colors.red))),
                ],
              ),
            );
            if (confirm == true) feed.removePost(widget.post.id);
          case 'pin':
            try {
              await _pinPost(true);
              feed.refresh();
            } catch (_) {}
          case 'unpin':
            try {
              await _pinPost(false);
              feed.refresh();
            } catch (_) {}
          case 'analytics':
            _showAnalytics(context);
          case 'report':
            showDialog(
                context: context,
                builder: (_) => ReportDialog(postId: widget.post.id));
        }
      },
      itemBuilder: (_) => [
        if (canModify) ...[
          const PopupMenuItem(
            value: 'edit',
            child: Row(children: [
              Icon(Icons.edit, size: 16),
              SizedBox(width: 8),
              Text('Edit'),
            ]),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: Row(children: [
              Icon(Icons.delete, size: 16, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete', style: TextStyle(color: Colors.red)),
            ]),
          ),
        ],
        if (isOwner)
          const PopupMenuItem(
            value: 'analytics',
            child: Row(children: [
              Icon(Icons.bar_chart, size: 16, color: AppTheme.primary),
              SizedBox(width: 8),
              Text('Analytics'),
            ]),
          ),
        if (isAdmin) ...[
          if (!widget.post.isPinned)
            const PopupMenuItem(
              value: 'pin',
              child: Row(children: [
                Icon(Icons.push_pin, size: 16, color: AppTheme.primary),
                SizedBox(width: 8),
                Text('Pin post'),
              ]),
            )
          else
            const PopupMenuItem(
              value: 'unpin',
              child: Row(children: [
                Icon(Icons.push_pin_outlined, size: 16),
                SizedBox(width: 8),
                Text('Unpin post'),
              ]),
            ),
        ],
        if (!isOwner)
          const PopupMenuItem(
            value: 'report',
            child: Row(children: [
              Icon(Icons.flag, size: 16, color: Colors.orange),
              SizedBox(width: 8),
              Text('Report'),
            ]),
          ),
      ],
    );
  }

  Future<void> _pinPost(bool pinned) async {
    await SupabaseService.setPinned(widget.post.id, pinned);
  }

  Widget _buildContent(BuildContext context) {
    final base = TextStyle(color: AppTheme.of(context).onSurface, fontSize: 15, height: 1.5);
    final text = widget.post.content;
    final hashSpans = HashtagUtils.buildRichSpans(
      text,
      baseStyle: base,
      onTap: (tag) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => HashtagFeedScreen(hashtag: tag)),
      ),
    );

    return RichText(
      text: TextSpan(children: hashSpans),
      maxLines: widget.compact ? 3 : null,
      overflow: widget.compact ? TextOverflow.ellipsis : TextOverflow.clip,
    );
  }

  Widget _buildImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        widget.post.imageUrl!,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildFooter(BuildContext context, FeedProvider feed, bool isOwner) {
    final post = widget.post;
    final avgLabel = post.avgRating == 0
        ? '0'
        : post.avgRating > 0
            ? '+${post.avgRating.toStringAsFixed(1)}'
            : post.avgRating.toStringAsFixed(1);

    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)),
          ),
          child: Row(
            children: [
              Icon(Icons.chat_bubble_outline,
                  color: AppTheme.of(context).onSurfaceMuted, size: 18),
              if (post.commentCount > 0) ...[
                const SizedBox(width: 4),
                Text('${post.commentCount}',
                    style: TextStyle(
                        color: AppTheme.of(context).onSurfaceMuted, fontSize: 13)),
              ],
            ],
          ),
        ),
        if (post.ratingCount > 0) ...[
          const SizedBox(width: 12),
          Icon(Icons.star_rounded, size: 15, color: _sliderColor(post.avgRating)),
          const SizedBox(width: 3),
          Text(
            avgLabel,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _sliderColor(post.avgRating),
            ),
          ),
          const SizedBox(width: 3),
          Text(
            '(${post.ratingCount})',
            style: TextStyle(fontSize: 11, color: AppTheme.of(context).onSurfaceMuted),
          ),
        ],
        const Spacer(),
        if (isOwner)
          GestureDetector(
            onTap: () => _showAnalytics(context),
            child: Padding(
              padding: EdgeInsets.only(right: 10),
              child: Icon(Icons.bar_chart, color: AppTheme.of(context).onSurfaceMuted, size: 18),
            ),
          ),
        GestureDetector(
          onTap: () => feed.toggleSaved(post.id),
          child: Icon(
            post.isSaved ? Icons.bookmark : Icons.bookmark_border,
            color: post.isSaved ? AppTheme.primary : AppTheme.onSurfaceMuted,
            size: 20,
          ),
        ),
      ],
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _AnonAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppTheme.onSurfaceMuted.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.person_outline,
          color: AppTheme.of(context).onSurfaceMuted, size: 22),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  final Color color;
  const _MiniChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 9, color: color, fontWeight: FontWeight.w600)),
    );
  }
}
