-- migration_v20: Add indexes for query performance at scale
-- Every index here covers a column used in WHERE, JOIN, or ORDER BY across
-- the feed, profile, comments, notifications, and admin flows.

-- ── posts ─────────────────────────────────────────────────────────────────────

-- Feed filtered by author (profile page, following feed)
CREATE INDEX IF NOT EXISTS idx_posts_author_id
  ON public.posts (author_id);

-- Feed filtered by category
CREATE INDEX IF NOT EXISTS idx_posts_category_id
  ON public.posts (category_id);

-- Feed ordered by creation time (recent posts, cursor pagination)
CREATE INDEX IF NOT EXISTS idx_posts_created_at
  ON public.posts (created_at DESC);

-- Composite: author + time — profile post list ordered newest first
CREATE INDEX IF NOT EXISTS idx_posts_author_created
  ON public.posts (author_id, created_at DESC);

-- GIN index for hashtag array containment queries (.contains([hashtag]))
CREATE INDEX IF NOT EXISTS idx_posts_hashtags
  ON public.posts USING GIN (hashtags);

-- Pinned posts sorted first in feed (is_pinned DESC, edge_rank DESC)
CREATE INDEX IF NOT EXISTS idx_posts_pinned
  ON public.posts (is_pinned DESC);

-- ── post_ratings ─────────────────────────────────────────────────────────────

-- posts_with_meta view: avg/count/user_rating subqueries all filter by post_id
CREATE INDEX IF NOT EXISTS idx_post_ratings_post_id
  ON public.post_ratings (post_id);

-- posts_with_meta: user_rating lookup filters by (post_id, user_id)
CREATE INDEX IF NOT EXISTS idx_post_ratings_post_user
  ON public.post_ratings (post_id, user_id);

-- author_score / author_rank subqueries join post_ratings → posts on post_id
-- then filter posts.author_id; covering index speeds those inner joins
CREATE INDEX IF NOT EXISTS idx_post_ratings_post_id_value
  ON public.post_ratings (post_id, value);

-- ── saved_posts ───────────────────────────────────────────────────────────────

-- posts_with_meta: save_count subquery filters by post_id
CREATE INDEX IF NOT EXISTS idx_saved_posts_post_id
  ON public.saved_posts (post_id);

-- getSavedPosts: filters by user_id ordered by created_at
CREATE INDEX IF NOT EXISTS idx_saved_posts_user_created
  ON public.saved_posts (user_id, created_at DESC);

-- ── comments ──────────────────────────────────────────────────────────────────

-- getComments: filters by post_id, ordered by created_at
CREATE INDEX IF NOT EXISTS idx_comments_post_id
  ON public.comments (post_id);

CREATE INDEX IF NOT EXISTS idx_comments_post_created
  ON public.comments (post_id, created_at ASC);

-- Thread replies: parent_id lookup
CREATE INDEX IF NOT EXISTS idx_comments_parent_id
  ON public.comments (parent_id);

-- ── comment_votes ─────────────────────────────────────────────────────────────

-- comments_with_meta: vote lookups by comment_id
CREATE INDEX IF NOT EXISTS idx_comment_votes_comment_id
  ON public.comment_votes (comment_id);

-- User's own vote lookup (comment_id, user_id)
CREATE INDEX IF NOT EXISTS idx_comment_votes_comment_user
  ON public.comment_votes (comment_id, user_id);

-- ── follows ───────────────────────────────────────────────────────────────────

-- following_posts_with_meta: WHERE follower_id = auth.uid()
CREATE INDEX IF NOT EXISTS idx_follows_follower_id
  ON public.follows (follower_id);

-- profile_stats follower_count: WHERE following_id = p.id
CREATE INDEX IF NOT EXISTS idx_follows_following_id
  ON public.follows (following_id);

-- ── notifications ─────────────────────────────────────────────────────────────

-- getNotifications: filters by recipient_id, ordered by created_at DESC
CREATE INDEX IF NOT EXISTS idx_notifications_recipient_created
  ON public.notifications (recipient_id, created_at DESC);

-- markNotificationsRead: filters by recipient_id
CREATE INDEX IF NOT EXISTS idx_notifications_recipient_id
  ON public.notifications (recipient_id);

-- ── follow_requests ───────────────────────────────────────────────────────────

-- getPendingFollowRequests: filters by target_id + status
CREATE INDEX IF NOT EXISTS idx_follow_requests_target_status
  ON public.follow_requests (target_id, status);

-- cancelFollowRequest / requestFollow: filters by requester_id
CREATE INDEX IF NOT EXISTS idx_follow_requests_requester_id
  ON public.follow_requests (requester_id);

-- ── reports ───────────────────────────────────────────────────────────────────

-- getModerationQueue: filters by status = 'pending', ordered by created_at
CREATE INDEX IF NOT EXISTS idx_reports_status_created
  ON public.reports (status, created_at DESC);

-- ── blocks ────────────────────────────────────────────────────────────────────

-- Block lookups by blocker
CREATE INDEX IF NOT EXISTS idx_blocks_blocker_id
  ON public.blocks (blocker_id);

-- ── polls ─────────────────────────────────────────────────────────────────────

-- posts_with_meta poll subquery: WHERE post_id = p.id
CREATE INDEX IF NOT EXISTS idx_polls_post_id
  ON public.polls (post_id);

-- ── poll_votes ────────────────────────────────────────────────────────────────

-- Poll result aggregation: GROUP BY poll_id
CREATE INDEX IF NOT EXISTS idx_poll_votes_poll_id
  ON public.poll_votes (poll_id);

-- User vote lookup: (poll_id, user_id)
CREATE INDEX IF NOT EXISTS idx_poll_votes_poll_user
  ON public.poll_votes (poll_id, user_id);

-- ── profiles (handle search) ──────────────────────────────────────────────────

-- searchUsers / searchUsersForMention: ILIKE 'query%' on handle
-- pg_trgm GIN index makes ILIKE fast; falls back to btree if extension absent
CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE INDEX IF NOT EXISTS idx_profiles_handle_trgm
  ON public.profiles USING GIN (handle gin_trgm_ops);

-- ── Materialized trending_hashtags (fix #2) ───────────────────────────────────
-- The live view scans and unnests all posts from the last 7 days on every
-- Discovery screen load. Replace it with a materialized view so the result
-- is pre-computed and reads are instant.

DROP VIEW IF EXISTS public.trending_hashtags;

CREATE MATERIALIZED VIEW IF NOT EXISTS public.trending_hashtags AS
SELECT unnest(hashtags) AS hashtag, count(*)::int AS count
FROM public.posts
WHERE created_at > now() - interval '7 days'
GROUP BY hashtag
ORDER BY count DESC
WITH NO DATA;

-- Unique index required for CONCURRENTLY refresh
CREATE UNIQUE INDEX IF NOT EXISTS idx_trending_hashtags_hashtag
  ON public.trending_hashtags (hashtag);

-- Populate on first deploy
REFRESH MATERIALIZED VIEW public.trending_hashtags;

GRANT SELECT ON public.trending_hashtags TO authenticated, anon;

-- Refresh function — call this from a pg_cron job (e.g. every hour):
--   SELECT cron.schedule('refresh-trending', '0 * * * *', 'SELECT refresh_trending_hashtags()');
CREATE OR REPLACE FUNCTION public.refresh_trending_hashtags()
RETURNS void
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  REFRESH MATERIALIZED VIEW CONCURRENTLY public.trending_hashtags;
$$;

GRANT EXECUTE ON FUNCTION public.refresh_trending_hashtags() TO authenticated;
