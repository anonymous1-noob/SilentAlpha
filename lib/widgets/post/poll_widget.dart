import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/supabase_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/time_utils.dart';

class PollWidget extends StatefulWidget {
  final Poll poll;
  final String postId;
  final void Function(Poll updated)? onVoted;

  const PollWidget({super.key, required this.poll, required this.postId, this.onVoted});

  @override
  State<PollWidget> createState() => _PollWidgetState();
}

class _PollWidgetState extends State<PollWidget> {
  bool _voting = false;
  late Poll _poll;

  @override
  void initState() {
    super.initState();
    _poll = widget.poll;
  }

  @override
  void didUpdateWidget(PollWidget old) {
    super.didUpdateWidget(old);
    if (old.poll != widget.poll) _poll = widget.poll;
  }

  Future<void> _vote(int index) async {
    if (_voting || _poll.isExpired) return;
    setState(() => _voting = true);
    try {
      if (_poll.hasVoted && _poll.userVote == index) {
        await SupabaseService.removePollVote(_poll.id);
      } else {
        await SupabaseService.votePoll(_poll.id, index);
      }
      // Refresh the poll data
      final postData = await SupabaseService.getPost(_getPostId());
      if (postData != null && postData['poll'] != null && mounted) {
        final updated = Poll.fromJson(postData['poll'] as Map<String, dynamic>);
        setState(() => _poll = updated);
        widget.onVoted?.call(updated);
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _voting = false);
    }
  }

  String _getPostId() => widget.postId;

  @override
  Widget build(BuildContext context) {
    final showResults = _poll.hasVoted || _poll.isExpired;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.of(context).surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.of(context).border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.poll_outlined, size: 16, color: AppTheme.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _poll.question,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...List.generate(_poll.options.length, (i) {
            final result = _poll.results.isNotEmpty && i < _poll.results.length
                ? _poll.results[i]
                : null;
            final pct = result?.percentage(_poll.totalVotes) ?? 0.0;
            final isMyVote = _poll.userVote == i;

            if (showResults) {
              return _ResultBar(
                label: _poll.options[i],
                pct: pct,
                count: result?.count ?? 0,
                isMyVote: isMyVote,
              );
            } else {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: _voting ? null : () => _vote(i),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      _poll.options[i],
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
              );
            }
          }),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                '${_poll.totalVotes} vote${_poll.totalVotes == 1 ? '' : 's'}',
                style: TextStyle(fontSize: 12, color: AppTheme.of(context).onSurfaceMuted),
              ),
              if (_poll.deadline != null) ...[
                const SizedBox(width: 8),
                Text('·', style: TextStyle(color: AppTheme.of(context).onSurfaceMuted)),
                const SizedBox(width: 8),
                Text(
                  _poll.isExpired
                      ? 'Closed'
                      : 'Ends ${TimeUtils.format(_poll.deadline!)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: _poll.isExpired ? Colors.redAccent : AppTheme.onSurfaceMuted,
                  ),
                ),
              ],
              if (_voting) ...[
                const SizedBox(width: 8),
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ResultBar extends StatelessWidget {
  final String label;
  final double pct;
  final int count;
  final bool isMyVote;

  const _ResultBar({
    required this.label,
    required this.pct,
    required this.count,
    required this.isMyVote,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Stack(
        children: [
          // Background bar
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isMyVote
                    ? AppTheme.primary.withValues(alpha: 0.5)
                    : AppTheme.of(context).border,
              ),
            ),
          ),
          // Fill
          FractionallySizedBox(
            widthFactor: pct,
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: isMyVote
                    ? AppTheme.primary.withValues(alpha: 0.2)
                    : AppTheme.onSurfaceMuted.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          // Label + percentage
          SizedBox(
            height: 40,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  if (isMyVote) ...[
                    const Icon(Icons.check_circle, size: 14, color: AppTheme.primary),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isMyVote ? FontWeight.w600 : FontWeight.normal,
                        color: isMyVote ? AppTheme.primary : AppTheme.onSurface,
                      ),
                    ),
                  ),
                  Text(
                    '${(pct * 100).round()}%',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isMyVote ? AppTheme.primary : AppTheme.onSurfaceMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
