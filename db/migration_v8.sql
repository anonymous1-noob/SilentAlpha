-- =====================================================
-- SilentAlpha Migration v8
-- Features:
--   1. follow_requests table (approval-gated follows)
--   2. profile_stats view updated with follow_request_pending
--   3. Reserved 'anonymous' handle constraint on profiles
--   4. notifications type check updated for follow_request type
-- =====================================================

-- ── 1. follow_requests table ──────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS follow_requests (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  requester_id  UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  target_id     UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  status        TEXT NOT NULL DEFAULT 'pending'
                  CHECK (status IN ('pending', 'accepted', 'rejected')),
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (requester_id, target_id)
);

ALTER TABLE follow_requests ENABLE ROW LEVEL SECURITY;

CREATE POLICY "follow_requests: viewer" ON follow_requests
  FOR SELECT USING (requester_id = auth.uid() OR target_id = auth.uid());

CREATE POLICY "follow_requests: sender" ON follow_requests
  FOR INSERT WITH CHECK (requester_id = auth.uid());

CREATE POLICY "follow_requests: target update" ON follow_requests
  FOR UPDATE USING (target_id = auth.uid());

CREATE POLICY "follow_requests: either party delete" ON follow_requests
  FOR DELETE USING (requester_id = auth.uid() OR target_id = auth.uid());

-- ── 2. profile_stats view ─────────────────────────────────────────────────────

DROP VIEW IF EXISTS profile_stats CASCADE;

CREATE OR REPLACE VIEW profile_stats AS
SELECT
  p.id,
  p.handle,
  p.avatar_url,
  p.bio,
  p.tagline,
  p.role,
  p.created_at,
  (SELECT COUNT(*) FROM follows WHERE following_id = p.id)::int        AS follower_count,
  (SELECT COUNT(*) FROM follows WHERE follower_id  = p.id)::int        AS following_count,
  (SELECT COUNT(*) FROM posts   WHERE author_id    = p.id)::int        AS post_count,
  COALESCE(
    (SELECT SUM(pr.value)::int
     FROM post_ratings pr
     JOIN posts po ON po.id = pr.post_id
     WHERE po.author_id = p.id), 0
  )                                                                     AS user_score,
  EXISTS(
    SELECT 1 FROM follows
    WHERE follower_id = auth.uid() AND following_id = p.id
  )                                                                     AS is_following,
  EXISTS(
    SELECT 1 FROM follow_requests
    WHERE requester_id = auth.uid() AND target_id = p.id
      AND status = 'pending'
  )                                                                     AS follow_request_pending
FROM profiles p;

GRANT SELECT ON profile_stats TO authenticated, anon;

-- ── 3. Reserved 'anonymous' handle ───────────────────────────────────────────

ALTER TABLE profiles
  ADD CONSTRAINT handle_not_anonymous
  CHECK (lower(handle) <> 'anonymous');

-- ── 4. notifications type constraint ─────────────────────────────────────────

ALTER TABLE notifications
  DROP CONSTRAINT IF EXISTS notifications_type_check;

ALTER TABLE notifications
  ADD CONSTRAINT notifications_type_check
  CHECK (type IN ('rating', 'comment', 'follow', 'mention', 'follow_request'));

NOTIFY pgrst, 'reload schema';
