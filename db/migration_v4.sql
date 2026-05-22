-- =====================================================
-- SilentAlpha Migration v4
-- Comment votes (up/down), drop tags from posts UI
-- =====================================================

-- 1. Comment votes table
CREATE TABLE IF NOT EXISTS comment_votes (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  comment_id  uuid NOT NULL REFERENCES comments(id) ON DELETE CASCADE,
  user_id     uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  value       integer NOT NULL CHECK (value IN (1, -1)),
  created_at  timestamptz DEFAULT now(),
  UNIQUE(comment_id, user_id)
);

ALTER TABLE comment_votes ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "cvotes_select" ON comment_votes;
DROP POLICY IF EXISTS "cvotes_insert" ON comment_votes;
DROP POLICY IF EXISTS "cvotes_update" ON comment_votes;
DROP POLICY IF EXISTS "cvotes_delete" ON comment_votes;
CREATE POLICY "cvotes_select" ON comment_votes FOR SELECT USING (true);
CREATE POLICY "cvotes_insert" ON comment_votes FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "cvotes_update" ON comment_votes FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "cvotes_delete" ON comment_votes FOR DELETE USING (auth.uid() = user_id);

GRANT SELECT, INSERT, UPDATE, DELETE ON comment_votes TO authenticated;
GRANT SELECT ON comment_votes TO anon;

-- 2. Rebuild comments_with_meta to include vote data
DROP VIEW IF EXISTS comments_with_meta CASCADE;
CREATE OR REPLACE VIEW comments_with_meta AS
SELECT
  c.*,
  pr.handle         AS author_handle,
  pr.avatar_url     AS author_avatar_url,
  COALESCE(
    (SELECT SUM(v.value) FROM comment_votes v WHERE v.comment_id = c.id), 0
  )::int            AS vote_score,
  (SELECT COUNT(*) FROM comment_votes v WHERE v.comment_id = c.id AND v.value =  1)::int AS upvotes,
  (SELECT COUNT(*) FROM comment_votes v WHERE v.comment_id = c.id AND v.value = -1)::int AS downvotes,
  (SELECT value FROM comment_votes v
     WHERE v.comment_id = c.id AND v.user_id = auth.uid() LIMIT 1)           AS user_vote
FROM comments c
LEFT JOIN profiles pr ON pr.id = c.author_id;

GRANT SELECT ON comments_with_meta TO authenticated, anon;

NOTIFY pgrst, 'reload schema';
