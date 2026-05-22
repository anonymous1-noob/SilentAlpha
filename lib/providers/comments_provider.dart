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
      final roots = all.where((c) => c.parentId == null).toList();
      final byParent = <String, List<Comment>>{};
      for (final c in all.where((c) => c.parentId != null)) {
        byParent.putIfAbsent(c.parentId!, () => []).add(c);
      }
      _commentsByPost[postId] = roots.map((r) {
        return Comment(
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
        );
      }).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loadingByPost[postId] = false;
      notifyListeners();
    }
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
    try {
      final comments = _commentsByPost[postId] ?? [];
      final existing = _findVote(comments, commentId);
      if (existing == value) {
        await SupabaseService.removeCommentVote(commentId);
      } else {
        await SupabaseService.voteComment(commentId, value);
      }
      await loadComments(postId);
    } catch (e) {
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
