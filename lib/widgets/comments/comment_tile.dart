import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/comments_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/avatar_utils.dart';
import '../../utils/time_utils.dart';

class CommentTile extends StatelessWidget {
  final Comment comment;
  final String postId;
  final String currentUserId;
  final void Function(Comment) onReply;
  final void Function(Comment) onDelete;
  final bool isReply;

  const CommentTile({
    super.key,
    required this.comment,
    required this.postId,
    required this.currentUserId,
    required this.onReply,
    required this.onDelete,
    this.isReply = false,
  });

  @override
  Widget build(BuildContext context) {
    final isOwner = comment.authorId == currentUserId;
    final votes = context.read<CommentsProvider>();

    return Padding(
      padding: EdgeInsets.only(left: isReply ? 40 : 0, bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AvatarUtils.buildAvatar(
            url: comment.authorAvatarUrl,
            userId: comment.authorId,
            username: comment.authorHandle ?? 'anon',
            radius: isReply ? 14 : 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.of(context).surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '@${comment.authorHandle ?? 'anon'}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _CommentText(content: comment.content),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      TimeUtils.format(comment.createdAt),
                      style: TextStyle(
                          fontSize: 11, color: AppTheme.of(context).onSurfaceMuted),
                    ),
                    const SizedBox(width: 10),
                    // Up vote
                    _VoteBtn(
                      icon: Icons.arrow_upward,
                      count: comment.upvotes,
                      active: comment.userVote == 1,
                      activeColor: const Color(0xFF22C55E),
                      onTap: () => votes.voteComment(postId, comment.id, 1),
                    ),
                    const SizedBox(width: 8),
                    // Score
                    Text(
                      '${comment.voteScore > 0 ? '+' : ''}${comment.voteScore}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: comment.voteScore > 0
                            ? const Color(0xFF22C55E)
                            : comment.voteScore < 0
                                ? const Color(0xFFEF4444)
                                : AppTheme.onSurfaceMuted,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Down vote
                    _VoteBtn(
                      icon: Icons.arrow_downward,
                      count: comment.downvotes,
                      active: comment.userVote == -1,
                      activeColor: const Color(0xFFEF4444),
                      onTap: () => votes.voteComment(postId, comment.id, -1),
                    ),
                    if (!isReply) ...[
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () => onReply(comment),
                        child: const Text(
                          'Reply',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                    if (isOwner) ...[
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () => onDelete(comment),
                        child: const Text(
                          'Delete',
                          style: TextStyle(fontSize: 12, color: Colors.redAccent),
                        ),
                      ),
                    ],
                  ],
                ),
                if (comment.replies.isNotEmpty)
                  ...comment.replies.map((r) => Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: CommentTile(
                          comment: r,
                          postId: postId,
                          currentUserId: currentUserId,
                          onReply: onReply,
                          onDelete: onDelete,
                          isReply: true,
                        ),
                      )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentText extends StatelessWidget {
  final String content;
  const _CommentText({required this.content});

  @override
  Widget build(BuildContext context) {
    final spans = <InlineSpan>[];
    int last = 0;
    for (final m in _mentionRegex.allMatches(content)) {
      if (m.start > last) {
        spans.add(TextSpan(
          text: content.substring(last, m.start),
          style: TextStyle(color: AppTheme.of(context).onSurface, fontSize: 14, height: 1.4),
        ));
      }
      spans.add(TextSpan(
        text: m.group(0),
        style: const TextStyle(
          color: AppTheme.primary,
          fontSize: 14,
          height: 1.4,
          fontWeight: FontWeight.w600,
        ),
      ));
      last = m.end;
    }
    if (last < content.length) {
      spans.add(TextSpan(
        text: content.substring(last),
        style: TextStyle(color: AppTheme.of(context).onSurface, fontSize: 14, height: 1.4),
      ));
    }
    return RichText(text: TextSpan(children: spans));
  }
}

// Compiled once at startup, not per-build.
final _mentionRegex = RegExp(r'@([a-z0-9_]+)', caseSensitive: false);

class _VoteBtn extends StatelessWidget {
  final IconData icon;
  final int count;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  const _VoteBtn({
    required this.icon,
    required this.count,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: active ? activeColor : AppTheme.onSurfaceMuted,
          ),
          if (count > 0) ...[
            const SizedBox(width: 2),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 11,
                color: active ? activeColor : AppTheme.onSurfaceMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
