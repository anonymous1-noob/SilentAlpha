import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/supabase_service.dart';
import '../../utils/app_theme.dart';

class PostAnalyticsSheet extends StatefulWidget {
  final Post post;
  const PostAnalyticsSheet({super.key, required this.post});

  @override
  State<PostAnalyticsSheet> createState() => _PostAnalyticsSheetState();
}

class _PostAnalyticsSheetState extends State<PostAnalyticsSheet> {
  List<Map<String, dynamic>> _distribution = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final dist = await SupabaseService.getRatingDistribution(widget.post.id);
      if (mounted) setState(() => _distribution = dist);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _ratingColor(double v) {
    if (v > 0.5) return const Color(0xFF22C55E);
    if (v < -0.5) return const Color(0xFFEF4444);
    return AppTheme.onSurfaceMuted;
  }

  String _ratingLabel(double v) {
    if (v == 0) return '0';
    return v > 0 ? '+${v.toStringAsFixed(1)}' : v.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final avgColor = _ratingColor(post.avgRating);

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppTheme.onSurfaceMuted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Post Analytics',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
          ),
          const SizedBox(height: 20),

          // Summary stats
          Row(
            children: [
              _StatTile(
                icon: Icons.star_rounded,
                iconColor: avgColor,
                label: 'Avg Rating',
                value: _ratingLabel(post.avgRating),
                valueColor: avgColor,
              ),
              const SizedBox(width: 12),
              _StatTile(
                icon: Icons.people_outline,
                iconColor: AppTheme.primary,
                label: 'Ratings',
                value: '${post.ratingCount}',
              ),
              const SizedBox(width: 12),
              _StatTile(
                icon: Icons.chat_bubble_outline,
                iconColor: Colors.blueAccent,
                label: 'Comments',
                value: '${post.commentCount}',
              ),
              const SizedBox(width: 12),
              _StatTile(
                icon: Icons.bookmark_border,
                iconColor: Colors.purpleAccent,
                label: 'Saves',
                value: '${post.saveCount}',
              ),
            ],
          ),

          const SizedBox(height: 20),
          const Text(
            'Rating Distribution',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 12),

          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(color: AppTheme.primary),
              ),
            )
          else if (_distribution.isEmpty)
            const Text(
              'No ratings yet.',
              style: TextStyle(color: AppTheme.onSurfaceMuted),
            )
          else ..._buildDistributionBars(),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  List<Widget> _buildDistributionBars() {
    final maxCount = _distribution
        .map((r) => (r['vote_count'] as int? ?? r['vote_count'] as num? ?? 0).toInt())
        .fold<int>(0, (a, b) => a > b ? a : b);

    return _distribution.map((r) {
      final val = (r['rating_value'] as int?) ?? 0;
      final cnt = (r['vote_count'] as int? ?? (r['vote_count'] as num?)?.toInt() ?? 0);
      final frac = maxCount == 0 ? 0.0 : cnt / maxCount;
      final color = _ratingColor(val.toDouble());
      final label = val > 0 ? '+$val' : '$val';

      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
                textAlign: TextAlign.right,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Stack(
                children: [
                  Container(
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: frac,
                    child: Container(
                      height: 20,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 28,
              child: Text(
                '$cnt',
                style: const TextStyle(fontSize: 12, color: AppTheme.onSurfaceMuted),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color? valueColor;

  const _StatTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF1A2545)),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: valueColor ?? AppTheme.onSurface,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: AppTheme.onSurfaceMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
