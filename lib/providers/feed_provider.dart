import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../services/supabase_service.dart';

enum FeedType { all, following }

class FeedProvider extends ChangeNotifier {
  final List<Post> _posts = [];
  bool _loading = false;
  bool _loadingMore = false;
  bool _hasMore = true;
  bool _hasNewPosts = false;
  String? _error;
  String? _categoryId;
  String? _hashtag;
  FeedType _feedType = FeedType.all;
  RealtimeChannel? _realtimeChannel;
  static const _pageSize = 20;

  List<Post> get posts => List.unmodifiable(_posts);
  bool get loading => _loading;
  bool get loadingMore => _loadingMore;
  bool get hasMore => _hasMore;
  bool get hasNewPosts => _hasNewPosts;
  String? get error => _error;
  String? get categoryId => _categoryId;
  FeedType get feedType => _feedType;

  FeedProvider() {
    _setupRealtime();
    SupabaseService.authStateChanges.listen((state) {
      if (state.session != null) {
        _setupRealtime();
      } else {
        _teardownRealtime();
      }
    });
  }

  void _setupRealtime() {
    _teardownRealtime();
    _realtimeChannel = SupabaseService.client
        .channel('public:posts:new')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'posts',
          callback: (_) {
            _hasNewPosts = true;
            notifyListeners();
          },
        )
        .subscribe();
  }

  void _teardownRealtime() {
    _realtimeChannel?.unsubscribe();
    _realtimeChannel = null;
  }

  void dismissNewPosts() {
    _hasNewPosts = false;
    notifyListeners();
    refresh();
  }

  void setFeedType(FeedType type) {
    if (_feedType == type) return;
    _feedType = type;
    refresh();
  }

  void setFilters({String? categoryId, String? hashtag}) {
    _categoryId = categoryId;
    _hashtag = hashtag;
    refresh();
  }

  Future<void> refresh() async {
    _posts.clear();
    _hasMore = true;
    _hasNewPosts = false;
    await loadPosts();
  }

  Future<void> loadPosts() async {
    if (_loading) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final List<Map<String, dynamic>> raw;
      if (_feedType == FeedType.following) {
        raw = await SupabaseService.getFollowingPosts(limit: _pageSize, offset: 0);
      } else {
        raw = await SupabaseService.getPosts(
          categoryId: _categoryId,
          hashtag: _hashtag,
          limit: _pageSize,
          offset: 0,
        );
      }
      _posts..clear()..addAll(raw.map(Post.fromMap));
      _hasMore = raw.length == _pageSize;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_loadingMore || !_hasMore) return;
    _loadingMore = true;
    notifyListeners();
    try {
      final List<Map<String, dynamic>> raw;
      if (_feedType == FeedType.following) {
        raw = await SupabaseService.getFollowingPosts(
            limit: _pageSize, offset: _posts.length);
      } else {
        raw = await SupabaseService.getPosts(
          categoryId: _categoryId,
          hashtag: _hashtag,
          limit: _pageSize,
          offset: _posts.length,
        );
      }
      _posts.addAll(raw.map(Post.fromMap));
      _hasMore = raw.length == _pageSize;
    } catch (_) {
    } finally {
      _loadingMore = false;
      notifyListeners();
    }
  }

  Future<void> ratePost(String postId, int value) async {
    final idx = _posts.indexWhere((p) => p.id == postId);
    if (idx < 0) {
      // Post not in current feed (e.g. from Discovery or profile) — persist anyway.
      try { await SupabaseService.ratePost(postId, value); } catch (_) {}
      return;
    }
    final post = _posts[idx];
    final prevRating = post.userRating;

    if (prevRating == value) {
      final newCount = (post.ratingCount - 1).clamp(0, 99999);
      final newAvg = newCount == 0 ? 0.0 : (post.avgRating * post.ratingCount - value) / newCount;
      _posts[idx] = post.copyWith(
        avgRating: newAvg,
        ratingCount: newCount,
        clearUserRating: true,
      );
      notifyListeners();
      try {
        await SupabaseService.removeRating(postId);
      } catch (_) {
        _posts[idx] = post;
        notifyListeners();
      }
    } else {
      final wasRated = prevRating != null;
      final newCount = wasRated ? post.ratingCount : post.ratingCount + 1;
      final newAvg = wasRated
          ? (post.avgRating * post.ratingCount - prevRating + value) / newCount
          : (post.avgRating * post.ratingCount + value) / newCount;
      _posts[idx] = post.copyWith(
        avgRating: newAvg,
        ratingCount: newCount,
        userRating: value,
      );
      notifyListeners();
      try {
        await SupabaseService.ratePost(postId, value);
      } catch (_) {
        _posts[idx] = post;
        notifyListeners();
      }
    }
  }

  Future<void> toggleSaved(String postId, {required bool currentlySaved}) async {
    final idx = _posts.indexWhere((p) => p.id == postId);
    if (idx < 0) {
      // Post not in current feed (e.g. from Discovery or profile) — persist anyway.
      try { await SupabaseService.toggleSaved(postId, currentlySaved); } catch (_) {}
      return;
    }
    final post = _posts[idx];
    _posts[idx] = post.copyWith(isSaved: !post.isSaved);
    notifyListeners();
    try {
      await SupabaseService.toggleSaved(postId, post.isSaved);
    } catch (_) {
      _posts[idx] = post;
      notifyListeners();
    }
  }

  void incrementCommentCount(String postId) {
    final idx = _posts.indexWhere((p) => p.id == postId);
    if (idx < 0) return;
    _posts[idx] = _posts[idx].copyWith(commentCount: _posts[idx].commentCount + 1);
    notifyListeners();
  }

  void removePost(String postId) {
    _posts.removeWhere((p) => p.id == postId);
    notifyListeners();
  }

  Future<void> hidePost(String postId) async {
    _posts.removeWhere((p) => p.id == postId);
    notifyListeners();
    try {
      await SupabaseService.hidePost(postId);
    } catch (_) {}
  }

  void removePostsByAuthor(String authorId) {
    _posts.removeWhere((p) => p.authorId == authorId);
    notifyListeners();
  }

  @override
  void dispose() {
    _teardownRealtime();
    super.dispose();
  }
}
