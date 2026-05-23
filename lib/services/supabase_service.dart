import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;
  static User? get currentUser => client.auth.currentUser;
  static String? get currentUserId => currentUser?.id;
  static Session? get currentSession => client.auth.currentSession;

  static Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  // ── Auth ──────────────────────────────────────────────────────────────────

  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String handle,
  }) async {
    final res = await client.auth.signUp(
      email: email,
      password: password,
      data: {'handle': handle},
    );
    if (res.user != null) {
      await client.from('profiles').upsert({
        'id': res.user!.id,
        'handle': handle,
        'created_at': DateTime.now().toIso8601String(),
      });
    }
    return res;
  }

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) =>
      client.auth.signInWithPassword(email: email, password: password);

  static Future<void> signOut() => client.auth.signOut();

  // ── Profile ───────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> getProfile(String userId) =>
      client.from('profile_stats').select().eq('id', userId).maybeSingle();

  static Future<void> updateProfile(String userId, Map<String, dynamic> data) =>
      client.from('profiles').update(data).eq('id', userId);

  // ── Posts ─────────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getPosts({
    String? categoryId,
    String? hashtag,
    String? ticker,
    String? authorId,
    int limit = 20,
    int offset = 0,
  }) async {
    var query = client.from('posts_with_meta').select();
    if (categoryId != null) query = query.eq('category_id', categoryId);
    if (authorId != null) query = query.eq('author_id', authorId);
    if (hashtag != null) query = query.contains('hashtags', [hashtag]);
    if (ticker != null) query = query.contains('tickers', [ticker]);
    return await query
        .order('is_pinned', ascending: false)
        .order('edge_rank', ascending: false)
        .range(offset, offset + limit - 1);
  }

  static Future<List<Map<String, dynamic>>> getFollowingPosts({
    int limit = 20,
    int offset = 0,
  }) =>
      client
          .from('following_posts_with_meta')
          .select()
          .order('edge_rank', ascending: false)
          .range(offset, offset + limit - 1);

  static Future<List<Map<String, dynamic>>> searchPosts(String query) async {
    final q = query.trim();
    if (q.isEmpty) return [];
    return await client
        .from('posts_with_meta')
        .select()
        .ilike('content', '%$q%')
        .order('edge_rank', ascending: false)
        .limit(20);
  }

  static Future<Map<String, dynamic>?> getPost(String postId) =>
      client.from('posts_with_meta').select().eq('id', postId).maybeSingle();

  static Future<String> createPost(Map<String, dynamic> data) async {
    final id = const Uuid().v4();
    await client.from('posts').insert({
      'id': id,
      ...data,
      'author_id': currentUserId,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
    return id;
  }

  static Future<void> updatePost(String postId, Map<String, dynamic> data) =>
      client.from('posts').update({
        ...data,
        'edited_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', postId);

  static Future<void> deletePost(String postId) =>
      client.from('posts').delete().eq('id', postId);

  // ── Ratings ───────────────────────────────────────────────────────────────

  static Future<void> ratePost(String postId, int value) async {
    final uid = currentUserId!;
    await client.from('post_ratings').upsert({
      'post_id': postId,
      'user_id': uid,
      'value': value,
      'created_at': DateTime.now().toIso8601String(),
    }, onConflict: 'post_id,user_id');
  }

  static Future<void> removeRating(String postId) async {
    await client.from('post_ratings').delete().match({
      'post_id': postId,
      'user_id': currentUserId!,
    });
  }

  // ── Saved Posts ───────────────────────────────────────────────────────────

  static Future<void> toggleSaved(String postId, bool isSaved) async {
    final uid = currentUserId!;
    if (isSaved) {
      await client.from('saved_posts').delete().match({'post_id': postId, 'user_id': uid});
    } else {
      await client.from('saved_posts').upsert({
        'post_id': postId,
        'user_id': uid,
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }

  static Future<List<Map<String, dynamic>>> getSavedPosts() async {
    return await client
        .from('saved_posts')
        .select('post_id, posts_with_meta(*)')
        .eq('user_id', currentUserId!)
        .order('created_at', ascending: false);
  }

  // ── Comments ──────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getComments(String postId) =>
      client.from('comments_with_meta').select().eq('post_id', postId).order('created_at', ascending: true);

  static Future<void> addComment({
    required String postId,
    required String content,
    String? parentId,
  }) =>
      client.from('comments').insert({
        'post_id': postId,
        'author_id': currentUserId!,
        'content': content,
        if (parentId != null) 'parent_id': parentId,
        'created_at': DateTime.now().toIso8601String(),
      });

  static Future<void> deleteComment(String commentId) =>
      client.from('comments').delete().eq('id', commentId);

  static Future<void> voteComment(String commentId, int value) =>
      client.from('comment_votes').upsert({
        'comment_id': commentId,
        'user_id': currentUserId!,
        'value': value,
        'created_at': DateTime.now().toIso8601String(),
      }, onConflict: 'comment_id,user_id');

  static Future<void> removeCommentVote(String commentId) =>
      client.from('comment_votes').delete().match({
        'comment_id': commentId,
        'user_id': currentUserId!,
      });

  // ── Follow (approval-gated) ───────────────────────────────────────────────

  static Future<void> followUser(String targetId) =>
      client.from('follows').upsert({
        'follower_id': currentUserId!,
        'following_id': targetId,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });

  static Future<void> unfollowUser(String targetId) =>
      client.from('follows').delete().match({
        'follower_id': currentUserId!,
        'following_id': targetId,
      });

  static Future<void> requestFollow(String targetId) async {
    await client.from('follow_requests').upsert({
      'requester_id': currentUserId!,
      'target_id': targetId,
      'status': 'pending',
      'created_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'requester_id,target_id');
    await client.from('notifications').insert({
      'recipient_id': targetId,
      'actor_id': currentUserId!,
      'type': 'follow_request',
      'read': false,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  static Future<void> cancelFollowRequest(String targetId) =>
      client.from('follow_requests').delete().match({
        'requester_id': currentUserId!,
        'target_id': targetId,
      });

  static Future<void> approveFollowRequest(String requesterId) async {
    await client.from('follows').insert({
      'follower_id': requesterId,
      'following_id': currentUserId!,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
    await client.from('follow_requests').update({'status': 'accepted'}).match({
      'requester_id': requesterId,
      'target_id': currentUserId!,
    });
    await client.from('notifications').insert({
      'recipient_id': requesterId,
      'actor_id': currentUserId!,
      'type': 'follow',
      'read': false,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  static Future<void> rejectFollowRequest(String requesterId) =>
      client.from('follow_requests').update({'status': 'rejected'}).match({
        'requester_id': requesterId,
        'target_id': currentUserId!,
      });

  static Future<List<Map<String, dynamic>>> getPendingFollowRequests() =>
      client.from('follow_requests')
          .select('*, profiles!requester_id(id, handle, avatar_url)')
          .eq('target_id', currentUserId!)
          .eq('status', 'pending')
          .order('created_at', ascending: false);

  static Future<int?> getUserLeaderboardRank(String userId) async {
    final top3 = await client
        .from('profile_stats')
        .select('id')
        .order('user_score', ascending: false)
        .limit(3);
    final idx = top3.indexWhere((u) => u['id'] == userId);
    return idx >= 0 ? idx + 1 : null;
  }

  static Future<List<Map<String, dynamic>>> searchUsersForMention(String query) async {
    if (query.isEmpty) return [];
    return client
        .from('profiles')
        .select('id, handle, avatar_url')
        .ilike('handle', '$query%')
        .neq('handle', 'anonymous')
        .limit(5);
  }

  static Future<void> createMentionNotifications({
    required String postId,
    required String content,
  }) async {
    final mentions = RegExp(r'@([a-z0-9_]+)', caseSensitive: false)
        .allMatches(content)
        .map((m) => m.group(1)!.toLowerCase())
        .where((h) => h != 'anonymous')
        .toSet();
    if (mentions.isEmpty) return;
    for (final handle in mentions) {
      final rows = await client
          .from('profiles')
          .select('id')
          .eq('handle', handle)
          .limit(1);
      if (rows.isEmpty) continue;
      final targetId = rows.first['id'] as String;
      if (targetId == currentUserId) continue;
      await client.from('notifications').insert({
        'recipient_id': targetId,
        'actor_id': currentUserId!,
        'type': 'mention',
        'post_id': postId,
        'read': false,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
    }
  }

  // ── Categories ────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getCategories() =>
      client.from('categories').select().order('name');

  static Future<void> createCategory({required String name, String? emoji}) =>
      client.from('categories').insert({
        'name': name,
        if (emoji != null) 'emoji': emoji,
      });

  static Future<void> updateCategory(String id, {String? name, String? emoji}) =>
      client.from('categories').update({
        if (name != null) 'name': name,
        if (emoji != null) 'emoji': emoji,
      }).eq('id', id);

  static Future<void> deleteCategory(String id) =>
      client.from('categories').delete().eq('id', id);

  // ── Admin ─────────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getAllUsers() =>
      client.from('profiles').select('id, handle, role, created_at').order('created_at', ascending: false);

  static Future<void> setUserRole(String userId, String role) =>
      client.from('profiles').update({'role': role}).eq('id', userId);

  // ── Reports ───────────────────────────────────────────────────────────────

  static Future<void> reportContent({
    String? postId,
    String? commentId,
    required String reason,
  }) =>
      client.from('reports').insert({
        'reporter_id': currentUserId!,
        if (postId != null) 'post_id': postId,
        if (commentId != null) 'comment_id': commentId,
        'reason': reason,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });

  // ── Block ─────────────────────────────────────────────────────────────────

  static Future<void> blockUser(String targetId) =>
      client.from('blocks').upsert({
        'blocker_id': currentUserId!,
        'blocked_id': targetId,
        'created_at': DateTime.now().toIso8601String(),
      });

  static Future<void> unblockUser(String targetId) =>
      client.from('blocks').delete().match({
        'blocker_id': currentUserId!,
        'blocked_id': targetId,
      });

  // ── Notifications ─────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getNotifications() =>
      client.from('notifications_with_actor').select().eq('recipient_id', currentUserId!).order('created_at', ascending: false).limit(50);

  static Future<void> markNotificationsRead() =>
      client.from('notifications').update({'read': true}).eq('recipient_id', currentUserId!);

  // ── Storage / Avatars ──────────────────────────────────────────────────────

  static Future<void> uploadAvatar(String path, Uint8List bytes, String ext) =>
      client.storage.from('avatars').uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(contentType: 'image/$ext', upsert: true),
      );

  static String getAvatarPublicUrl(String path) =>
      client.storage.from('avatars').getPublicUrl(path);

  // ── Trending ──────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getTrendingHashtags() =>
      client.from('trending_hashtags').select().order('count', ascending: false).limit(10);

  static Future<List<Map<String, dynamic>>> getTrendingTickers() =>
      client.from('trending_tickers').select().order('count', ascending: false).limit(10);

  // ── Polls ─────────────────────────────────────────────────────────────────

  static Future<void> createPoll({
    required String postId,
    required String question,
    required List<String> options,
    DateTime? deadline,
  }) =>
      client.from('polls').insert({
        'post_id': postId,
        'question': question,
        'options': options,
        if (deadline != null) 'deadline': deadline.toIso8601String(),
      });

  static Future<void> votePoll(String pollId, int optionIndex) =>
      client.from('poll_votes').upsert({
        'poll_id': pollId,
        'user_id': currentUserId!,
        'option_index': optionIndex,
        'created_at': DateTime.now().toIso8601String(),
      }, onConflict: 'poll_id,user_id');

  static Future<void> removePollVote(String pollId) =>
      client.from('poll_votes').delete().match({
        'poll_id': pollId,
        'user_id': currentUserId!,
      });

  // ── Post Images ───────────────────────────────────────────────────────────

  static Future<void> uploadPostImage(String path, Uint8List bytes, String ext) =>
      client.storage.from('post-images').uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(contentType: 'image/$ext', upsert: true),
      );

  static String getPostImagePublicUrl(String path) =>
      client.storage.from('post-images').getPublicUrl(path);

  // ── Pin (admin) ───────────────────────────────────────────────────────────

  static Future<void> setPinned(String postId, bool pinned) =>
      client.from('posts').update({'is_pinned': pinned}).eq('id', postId);

  // ── Leaderboard ───────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getLeaderboard({int limit = 50}) =>
      client.from('profile_stats').select().order('user_score', ascending: false).limit(limit);

  // ── User Search ───────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    final q = query.trim();
    if (q.isEmpty) return [];
    return await client
        .from('profile_stats')
        .select()
        .ilike('handle', '%$q%')
        .limit(20);
  }

  // ── Analytics ─────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getRatingDistribution(String postId) =>
      client.rpc('get_rating_distribution', params: {'p_post_id': postId});

  // ── Moderation Queue ──────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getModerationQueue() =>
      client.from('reports').select('*, posts(*), comments(*)').eq('status', 'pending').order('created_at', ascending: false);

  static Future<void> resolveReport(String reportId, String action) =>
      client.from('reports').update({'status': action}).eq('id', reportId);
}
