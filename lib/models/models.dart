import 'package:flutter/material.dart';

// ── Badge ─────────────────────────────────────────────────────────────────────

class UserBadge {
  final String name;
  final String emoji;
  final Color color;

  const UserBadge({required this.name, required this.emoji, required this.color});

  static UserBadge fromScore(int score) {
    if (score < 0) return const UserBadge(name: 'Paper Trader',       emoji: '📄', color: Color(0xFF607D8B));
    if (score < 21) return const UserBadge(name: 'Market Lurker',     emoji: '👀', color: Color(0xFF78909C));
    if (score < 76) return const UserBadge(name: 'Bull Rider',        emoji: '🐂', color: Color(0xFFCD7F32));
    if (score < 201) return const UserBadge(name: 'Analyst',          emoji: '🔍', color: Color(0xFF9E9E9E));
    if (score < 501) return const UserBadge(name: 'Portfolio Pro',    emoji: '💼', color: Color(0xFFFFD700));
    if (score < 1501) return const UserBadge(name: 'Quant',           emoji: '⚡', color: Color(0xFF9B59B6));
    return const UserBadge(name: 'Wolf of the Street',                 emoji: '🐺', color: Color(0xFF6C63FF));
  }
}

// ── User / Profile ────────────────────────────────────────────────────────────

class AppUser {
  final String id;
  final String handle;
  final String? avatarUrl;
  final String? bio;
  final String? tagline;
  final int followerCount;
  final int followingCount;
  final int postCount;
  final int userScore;
  final DateTime createdAt;
  final bool isFollowing;
  final bool followRequestPending;

  final String role;

  bool get isAdmin => role == 'admin';

  const AppUser({
    required this.id,
    required this.handle,
    this.avatarUrl,
    this.bio,
    this.tagline,
    this.followerCount = 0,
    this.followingCount = 0,
    this.postCount = 0,
    this.userScore = 0,
    this.role = 'user',
    required this.createdAt,
    this.isFollowing = false,
    this.followRequestPending = false,
  });

  UserBadge get badge => UserBadge.fromScore(userScore);

  factory AppUser.fromMap(Map<String, dynamic> m) => AppUser(
        id: m['id'] as String,
        handle: m['handle'] as String? ?? 'anon',
        avatarUrl: m['avatar_url'] as String?,
        bio: m['bio'] as String?,
        tagline: m['tagline'] as String?,
        followerCount: (m['follower_count'] as int?) ?? 0,
        followingCount: (m['following_count'] as int?) ?? 0,
        postCount: (m['post_count'] as int?) ?? 0,
        userScore: (m['user_score'] as int?) ?? 0,
        role: m['role'] as String? ?? 'user',
        createdAt: DateTime.tryParse(m['created_at'] as String? ?? '') ?? DateTime.now(),
        isFollowing: (m['is_following'] as bool?) ?? false,
        followRequestPending: (m['follow_request_pending'] as bool?) ?? false,
      );

  AppUser copyWith({
    String? handle,
    String? avatarUrl,
    String? bio,
    String? tagline,
    String? role,
    int? followerCount,
    int? followingCount,
    bool? isFollowing,
    bool? followRequestPending,
  }) =>
      AppUser(
        id: id,
        handle: handle ?? this.handle,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        bio: bio ?? this.bio,
        tagline: tagline ?? this.tagline,
        followerCount: followerCount ?? this.followerCount,
        followingCount: followingCount ?? this.followingCount,
        postCount: postCount,
        userScore: userScore,
        role: role ?? this.role,
        createdAt: createdAt,
        isFollowing: isFollowing ?? this.isFollowing,
        followRequestPending: followRequestPending ?? this.followRequestPending,
      );
}

// ── Poll ──────────────────────────────────────────────────────────────────────

class PollResult {
  final int index;
  final String text;
  final int count;

  const PollResult({required this.index, required this.text, required this.count});

  double percentage(int total) => total == 0 ? 0.0 : count / total;

  factory PollResult.fromJson(Map<String, dynamic> m) => PollResult(
        index: (m['index'] as int?) ?? 0,
        text: m['text'] as String? ?? '',
        count: (m['count'] as int?) ?? 0,
      );
}

class Poll {
  final String id;
  final String question;
  final List<String> options;
  final DateTime? deadline;
  final int totalVotes;
  final int? userVote;
  final List<PollResult> results;

  const Poll({
    required this.id,
    required this.question,
    required this.options,
    this.deadline,
    this.totalVotes = 0,
    this.userVote,
    this.results = const [],
  });

  bool get hasVoted => userVote != null;
  bool get isExpired => deadline != null && DateTime.now().isAfter(deadline!);

  factory Poll.fromJson(Map<String, dynamic> m) => Poll(
        id: m['id'] as String,
        question: m['question'] as String? ?? '',
        options: ((m['options'] as List?) ?? []).cast<String>(),
        deadline: m['deadline'] != null ? DateTime.tryParse(m['deadline'] as String) : null,
        totalVotes: (m['total_votes'] as int?) ?? 0,
        userVote: m['user_vote'] as int?,
        results: ((m['results'] as List?) ?? [])
            .map((r) => PollResult.fromJson(r as Map<String, dynamic>))
            .toList(),
      );
}

// ── Category ──────────────────────────────────────────────────────────────────

class Category {
  final String id;
  final String name;
  final String? emoji;
  final int postCount;

  const Category({
    required this.id,
    required this.name,
    this.emoji,
    this.postCount = 0,
  });

  factory Category.fromMap(Map<String, dynamic> m) => Category(
        id: m['id'] as String,
        name: m['name'] as String,
        emoji: m['emoji'] as String?,
        postCount: (m['post_count'] as int?) ?? 0,
      );
}

// ── Post ──────────────────────────────────────────────────────────────────────

class Post {
  final String id;
  final String? authorId;
  final String? authorHandle;
  final String? authorAvatarUrl;
  final int? authorScore;
  final int? authorRank;
  final String content;
  final List<String> hashtags;
  final List<String> tags;
  final bool isAnonymous;
  final bool isPinned;
  final String? categoryId;
  final String? categoryName;
  final String? imageUrl;
  final double avgRating;
  final int ratingCount;
  final int? userRating;
  final int commentCount;
  final int saveCount;
  final bool isSaved;
  final DateTime createdAt;
  final DateTime? editedAt;
  final Poll? poll;

  const Post({
    required this.id,
    this.authorId,
    this.authorHandle,
    this.authorAvatarUrl,
    this.authorScore,
    this.authorRank,
    required this.content,
    this.hashtags = const [],
    this.tags = const [],
    this.isAnonymous = false,
    this.isPinned = false,
    this.categoryId,
    this.categoryName,
    this.imageUrl,
    this.avgRating = 0,
    this.ratingCount = 0,
    this.userRating,
    this.commentCount = 0,
    this.saveCount = 0,
    this.isSaved = false,
    required this.createdAt,
    this.editedAt,
    this.poll,
  });

  factory Post.fromMap(Map<String, dynamic> m) => Post(
        id: m['id'] as String,
        authorId: m['author_id'] as String?,
        authorHandle: m['author_handle'] as String?,
        authorAvatarUrl: m['author_avatar_url'] as String?,
        authorScore: m['author_score'] as int?,
        authorRank: m['author_rank'] as int?,
        content: m['content'] as String? ?? '',
        hashtags: ((m['hashtags'] as List?)?.cast<String>()) ?? [],
        tags: ((m['tags'] as List?)?.cast<String>()) ?? [],
        isAnonymous: (m['is_anonymous'] as bool?) ?? false,
        isPinned: (m['is_pinned'] as bool?) ?? false,
        categoryId: m['category_id'] as String?,
        categoryName: m['category_name'] as String?,
        imageUrl: m['image_url'] as String?,
        avgRating: (m['avg_rating'] as num?)?.toDouble() ?? 0.0,
        ratingCount: (m['rating_count'] as int?) ?? 0,
        userRating: m['user_rating'] as int?,
        commentCount: (m['comment_count'] as int?) ?? 0,
        saveCount: (m['save_count'] as int?) ?? 0,
        isSaved: (m['is_saved'] as bool?) ?? false,
        createdAt: DateTime.tryParse(m['created_at'] as String? ?? '') ?? DateTime.now(),
        editedAt: m['edited_at'] != null ? DateTime.tryParse(m['edited_at'] as String) : null,
        poll: m['poll'] != null ? Poll.fromJson(m['poll'] as Map<String, dynamic>) : null,
      );

  Post copyWith({
    double? avgRating,
    int? ratingCount,
    int? userRating,
    bool clearUserRating = false,
    int? commentCount,
    int? saveCount,
    bool? isSaved,
    bool? isPinned,
    String? content,
    Poll? poll,
  }) =>
      Post(
        id: id,
        authorId: authorId,
        authorHandle: authorHandle,
        authorAvatarUrl: authorAvatarUrl,
        authorScore: authorScore,
        authorRank: authorRank,
        content: content ?? this.content,
        hashtags: hashtags,
        tags: tags,
        isAnonymous: isAnonymous,
        isPinned: isPinned ?? this.isPinned,
        categoryId: categoryId,
        categoryName: categoryName,
        imageUrl: imageUrl,
        avgRating: avgRating ?? this.avgRating,
        ratingCount: ratingCount ?? this.ratingCount,
        userRating: clearUserRating ? null : (userRating ?? this.userRating),
        commentCount: commentCount ?? this.commentCount,
        saveCount: saveCount ?? this.saveCount,
        isSaved: isSaved ?? this.isSaved,
        createdAt: createdAt,
        editedAt: editedAt,
        poll: poll ?? this.poll,
      );
}

// ── Comment ───────────────────────────────────────────────────────────────────

class Comment {
  final String id;
  final String postId;
  final String authorId;
  final String? authorHandle;
  final String? authorAvatarUrl;
  final String? parentId;
  final String content;
  final int voteScore;
  final int upvotes;
  final int downvotes;
  final int? userVote;
  final DateTime createdAt;
  final List<Comment> replies;

  const Comment({
    required this.id,
    required this.postId,
    required this.authorId,
    this.authorHandle,
    this.authorAvatarUrl,
    this.parentId,
    required this.content,
    this.voteScore = 0,
    this.upvotes = 0,
    this.downvotes = 0,
    this.userVote,
    required this.createdAt,
    this.replies = const [],
  });

  factory Comment.fromMap(Map<String, dynamic> m) => Comment(
        id: m['id'] as String,
        postId: m['post_id'] as String,
        authorId: m['author_id'] as String,
        authorHandle: m['author_handle'] as String?,
        authorAvatarUrl: m['author_avatar_url'] as String?,
        parentId: m['parent_id'] as String?,
        content: m['content'] as String? ?? '',
        voteScore: (m['vote_score'] as int?) ?? 0,
        upvotes: (m['upvotes'] as int?) ?? 0,
        downvotes: (m['downvotes'] as int?) ?? 0,
        userVote: m['user_vote'] as int?,
        createdAt: DateTime.tryParse(m['created_at'] as String? ?? '') ?? DateTime.now(),
      );
}

// ── Notification ──────────────────────────────────────────────────────────────

enum NotifType { rating, comment, follow, mention, followRequest, newPost }

class AppNotification {
  final String id;
  final NotifType type;
  final String? actorId;
  final String actorHandle;
  final String? actorAvatarUrl;
  final String? postId;
  final String? body;
  final bool read;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    this.actorId,
    required this.actorHandle,
    this.actorAvatarUrl,
    this.postId,
    this.body,
    this.read = false,
    required this.createdAt,
  });

  factory AppNotification.fromMap(Map<String, dynamic> m) => AppNotification(
        id: m['id'] as String,
        type: _parseType(m['type'] as String? ?? 'rating'),
        actorId: m['actor_id'] as String?,
        actorHandle: m['actor_handle'] as String? ?? m['actor_username'] as String? ?? 'someone',
        actorAvatarUrl: m['actor_avatar_url'] as String?,
        postId: m['post_id'] as String?,
        body: m['body'] as String?,
        read: (m['read'] as bool?) ?? false,
        createdAt: DateTime.tryParse(m['created_at'] as String? ?? '') ?? DateTime.now(),
      );

  static NotifType _parseType(String t) => switch (t) {
        'comment' => NotifType.comment,
        'follow' => NotifType.follow,
        'mention' => NotifType.mention,
        'follow_request' => NotifType.followRequest,
        'new_post' => NotifType.newPost,
        _ => NotifType.rating,
      };

  String get label {
    return switch (type) {
      NotifType.rating => '@$actorHandle rated your post',
      NotifType.comment => '@$actorHandle commented on your post',
      NotifType.follow => '@$actorHandle started following you',
      NotifType.mention => '@$actorHandle mentioned you in a comment',
      NotifType.followRequest => '@$actorHandle wants to follow you',
      NotifType.newPost => body != null && body!.isNotEmpty
          ? '@$actorHandle posted: ${body!.length > 80 ? '${body!.substring(0, 80)}…' : body!}'
          : '@$actorHandle shared a new post',
    };
  }

  IconData get icon => switch (type) {
        NotifType.rating => Icons.star,
        NotifType.comment => Icons.chat_bubble,
        NotifType.follow => Icons.person_add,
        NotifType.mention => Icons.alternate_email,
        NotifType.followRequest => Icons.person_add_outlined,
        NotifType.newPost => Icons.article_outlined,
      };

  Color get iconColor => switch (type) {
        NotifType.rating => Colors.amber,
        NotifType.comment => Colors.blueAccent,
        NotifType.follow => Colors.greenAccent,
        NotifType.mention => Colors.purpleAccent,
        NotifType.followRequest => Colors.orangeAccent,
        NotifType.newPost => Colors.tealAccent,
      };
}

// ── Report ────────────────────────────────────────────────────────────────────

class Report {
  final String id;
  final String reporterId;
  final String? postId;
  final String? commentId;
  final String reason;
  final String status;
  final DateTime createdAt;

  const Report({
    required this.id,
    required this.reporterId,
    this.postId,
    this.commentId,
    required this.reason,
    this.status = 'pending',
    required this.createdAt,
  });
}
