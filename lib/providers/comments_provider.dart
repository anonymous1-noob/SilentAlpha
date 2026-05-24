import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/supabase_service.dart';

class CommentsProvider extends ChangeNotifier {
  final Map<String, List<Comment>> _commentsByPost = {};
  final Map<String, bool> _loadingByPost = {};
  String? _error;

  List<Comment> commentsFor(String postId) => _commentsByPost[postId] ?? [];
  bool loadingFor(String postId) => _loadingByPost[postId] ?? false;
  String? get error => _error;

  Future<void> loadComments(String postId) async {
    if (_loadingByPost[postId] == true) return;
    _loadingByPost[postId] = true;
    notifyListeners();
    try {
      final raw = await SupabaseService.getComments(postId);
      final all = raw.map(Comment.fromMap).toList();
      _commentsByPost[postId] = _buildTree(all);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loadingByPost[postId] = false;
      notifyListeners();
    }
  }

  List<Comment> _buildTree(List<Comment> all) {
    final roots = all.where((c) => c.parentId == null).toList();
    final byParent = <String, List<Comment>>{};
    for (final c in all.where((c) => c.parentId != null)) {
      byParent.putIfAbsent(c.parentId!, () => []).add(c);
    }
    return roots.map((r) => Comment(
      id: r.id,
      postId: r.postId,
      authorId: r.authorId,
      authorHandle: r.authorHandle,
      authorAvatarUrl: r.authorAvatarUrl,
      parentId: r.parentId,
      content: r.content,
      voteScore: r.voteScore,
      upvotes: r.upvotes,
      downvotes: r.downvotes,
      userVote: r.userVote,
      createdAt: r.createdAt,
      replies: byParent[r.id] ?? [],
    )).toList();
  }

  Future<void> addComment({
    required String postId,
    required String content,
    String? parentId,
    required String authorId,
    required String authorHandle,
    String? authorAvatarUrl,
  }) async {
    try {
      await SupabaseService.addComment(
        postId: postId,
        content: content,
        parentId: parentId,
      );
      await loadComments(postId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> voteComment(String postId, String commentId, int value) async {
    final comments = _commentsByPost[postId] ?? [];
    final existing = _findVote(comments, commentId);
    final isToggle = existing == value;
    final newVote = isToggle ? null : value;

    // Optimistic update
    _commentsByPost[postId] = _applyVote(comments, commentId, newVote, existing);
    notifyListeners();

    try {
      if (isToggle) {
        await SupabaseService.removeCommentVote(commentId);
      } else {
        await SupabaseService.voteComment(commentId, value);
      }
    } catch (e) {
      // Rollback
      _commentsByPost[postId] = _applyVote(
        _commentsByPost[postId] ?? [],
        commentId,
        existing,
        newVote,
      );
      _error = e.toString();
      notifyListeners();
    }
  }

  int? _findVote(List<Comment> comments, String commentId) {
    for (final c in comments) {
      if (c.id == commentId) return c.userVote;
      for (final r in c.replies) {
        if (r.id == commentId) return r.userVote;
      }
    }
    return null;
  }

  List<Comment> _applyVote(
    List<Comment> comments,
    String commentId,
    int? newVote,
    int? oldVote,
  ) {
    return comments.map((c) {
      if (c.id == commentId) return _withVote(c, newVote, oldVote);
      if (c.replies.isEmpty) return c;
      final updatedReplies = _applyVote(c.replies, commentId, newVote, oldVote);
      return Comment(
        id: c.id,
        postId: c.postId,
        authorId: c.authorId,
        authorHandle: c.authorHandle,
        authorAvatarUrl: c.authorAvatarUrl,
        parentId: c.parentId,
        content: c.content,
        voteScore: c.voteScore,
        upvotes: c.upvotes,
        downvotes: c.downvotes,
        userVote: c.userVote,
        createdAt: c.createdAt,
        replies: updatedReplies,
      );
    }).toList();
  }

  Comment _withVote(Comment c, int? newVote, int? oldVote) {
    var upvotes = c.upvotes;
    var downvotes = c.downvotes;
    if (oldVote == 1) upvotes--;
    if (oldVote == -1) downvotes--;
    if (newVote == 1) upvotes++;
    if (newVote == -1) downvotes++;
    return Comment(
      id: c.id,
      postId: c.postId,
      authorId: c.authorId,
      authorHandle: c.authorHandle,
      authorAvatarUrl: c.authorAvatarUrl,
      parentId: c.parentId,
      content: c.content,
      voteScore: upvotes - downvotes,
      upvotes: upvotes,
      downvotes: downvotes,
      userVote: newVote,
      createdAt: c.createdAt,
      replies: c.replies,
    );
  }

  Future<void> deleteComment(String postId, String commentId) async {
    try {
      await SupabaseService.deleteComment(commentId);
      await loadComments(postId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
