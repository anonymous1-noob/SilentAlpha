import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/comments_provider.dart';
import '../../providers/feed_provider.dart';
import '../../services/supabase_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/avatar_utils.dart';
import '../../widgets/comments/comment_tile.dart';
import '../../widgets/post/post_card.dart';

class PostDetailScreen extends StatefulWidget {
  final Post post;
  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _commentCtrl = TextEditingController();
  final _commentFocus = FocusNode();
  Comment? _replyTo;
  bool _sending = false;
  List<Map<String, dynamic>> _mentionSuggestions = [];
  String? _activeMentionQuery;

  @override
  void initState() {
    super.initState();
    _commentCtrl.addListener(_onCommentChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommentsProvider>().loadComments(widget.post.id);
    });
  }

  @override
  void dispose() {
    _commentCtrl.removeListener(_onCommentChanged);
    _commentCtrl.dispose();
    _commentFocus.dispose();
    super.dispose();
  }

  void _onCommentChanged() {
    final text = _commentCtrl.text;
    final query = _extractActiveMention(text);
    if (query != _activeMentionQuery) {
      _activeMentionQuery = query;
      if (query != null) {
        _fetchMentionSuggestions(query);
      } else {
        setState(() => _mentionSuggestions = []);
      }
    }
    setState(() {});
  }

  // Extract partial @handle at end of current text (e.g. "@jo" → "jo")
  String? _extractActiveMention(String text) {
    final match = RegExp(r'(?:^|[\s])@([a-z0-9_]*)$', caseSensitive: false).firstMatch(text);
    if (match == null) return null;
    return match.group(1)!;
  }

  Future<void> _fetchMentionSuggestions(String query) async {
    final results = await SupabaseService.searchUsersForMention(query);
    if (mounted && _activeMentionQuery == query) {
      setState(() => _mentionSuggestions = results);
    }
  }

  void _completeMention(String handle) {
    final text = _commentCtrl.text;
    final newText = text.replaceAll(RegExp(r'@([a-z0-9_]*)$', caseSensitive: false), '@$handle ');
    _commentCtrl.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
    setState(() => _mentionSuggestions = []);
    _commentFocus.requestFocus();
  }

  Future<void> _sendComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;
    final auth = context.read<AuthProvider>();
    setState(() => _sending = true);
    try {
      await context.read<CommentsProvider>().addComment(
            postId: widget.post.id,
            content: text,
            parentId: _replyTo?.id,
            authorId: auth.user!.id,
            authorHandle: auth.user!.handle,
            authorAvatarUrl: auth.user!.avatarUrl,
          );
      context.read<FeedProvider>().incrementCommentCount(widget.post.id);
      // Notify mentioned users
      await SupabaseService.createMentionNotifications(
        postId: widget.post.id,
        content: text,
      );
      _commentCtrl.clear();
      setState(() {
        _replyTo = null;
        _mentionSuggestions = [];
      });
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final comments =
        context.watch<CommentsProvider>().commentsFor(widget.post.id);
    final loading =
        context.watch<CommentsProvider>().loadingFor(widget.post.id);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceVariant,
        title: const Text('Post'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 16),
              children: [
                PostCard(post: widget.post, compact: false),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Text(
                    'Comments',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (loading)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.primary),
                    ),
                  )
                else if (comments.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'No comments yet. Start the conversation!',
                        style: TextStyle(color: AppTheme.onSurfaceMuted),
                      ),
                    ),
                  )
                else
                  ...comments.map(
                    (c) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: CommentTile(
                        comment: c,
                        postId: widget.post.id,
                        currentUserId: auth.user?.id ?? '',
                        onReply: (c) =>
                            setState(() => _replyTo = c),
                        onDelete: (c) =>
                            context.read<CommentsProvider>().deleteComment(
                                  widget.post.id,
                                  c.id,
                                ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (_mentionSuggestions.isNotEmpty)
            _MentionSuggestions(
              suggestions: _mentionSuggestions,
              onSelect: _completeMention,
            ),
          _buildCommentInput(context, auth),
        ],
      ),
    );
  }

  Widget _buildCommentInput(BuildContext context, AuthProvider auth) {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 8,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceVariant,
        border: Border(
            top: BorderSide(color: Color(0xFF2A2A4A), width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_replyTo != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text(
                    'Replying to @${_replyTo!.authorHandle ?? 'anonymous'}',
                    style: const TextStyle(
                        color: AppTheme.primary, fontSize: 12),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() => _replyTo = null),
                    child: const Icon(Icons.close,
                        size: 14, color: AppTheme.primary),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              AvatarUtils.buildAvatar(
                url: auth.user?.avatarUrl,
                userId: auth.user?.id ?? '',
                username: auth.user?.handle ?? 'anon',
                radius: 16,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _commentCtrl,
                  focusNode: _commentFocus,
                  decoration: InputDecoration(
                    hintText: _replyTo != null
                        ? 'Write a reply... use @handle to mention'
                        : 'Add a comment... use @handle to mention',
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _sendComment(),
                ),
              ),
              const SizedBox(width: 8),
              _sending
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primary,
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.send, color: AppTheme.primary),
                      onPressed: _commentCtrl.text.trim().isEmpty
                          ? null
                          : _sendComment,
                    ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MentionSuggestions extends StatelessWidget {
  final List<Map<String, dynamic>> suggestions;
  final void Function(String handle) onSelect;

  const _MentionSuggestions({required this.suggestions, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceVariant,
        border: Border(
          top: BorderSide(color: Color(0xFF2A2A4A)),
          bottom: BorderSide(color: Color(0xFF2A2A4A)),
        ),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: suggestions.length,
        itemBuilder: (_, i) {
          final u = suggestions[i];
          final handle = u['handle'] as String? ?? '';
          return ListTile(
            dense: true,
            leading: AvatarUtils.buildAvatar(
              url: u['avatar_url'] as String?,
              userId: u['id'] as String? ?? '',
              username: handle,
              radius: 14,
            ),
            title: Text(
              '@$handle',
              style: const TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            onTap: () => onSelect(handle),
          );
        },
      ),
    );
  }
}
