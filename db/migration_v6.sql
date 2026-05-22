-- =====================================================
-- SilentAlpha Migration v6
-- Tickers, pinned posts, polls, following feed view,
-- trending tickers, post-images bucket, rating distribution,
-- realtime channels enabled
-- =====================================================

-- 1. Add columns to posts
ALTER TABLE posts ADD COLUMN IF NOT EXISTS tickers   text[]  DEFAULT '{}';
ALTER TABLE posts ADD COLUMN IF NOT EXISTS is_pinned boolean DEFAULT false;

-- 2. Polls table
CREATE TABLE IF NOT EXISTS polls (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id    uuid NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  question   text NOT NULL CHECK (char_length(question) <= 200),
  options    text[] NOT NULL CHECK (array_length(options,1) BETWEEN 2 AND 4),
  deadline   timestamptz,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE polls ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "polls_select" ON polls;
DROP POLICY IF EXISTS "polls_insert" ON polls;
DROP POLICY IF EXISTS "polls_delete" ON polls;
CREATE POLICY "polls_select" ON polls FOR SELECT USING (true);
CREATE POLICY "polls_insert" ON polls FOR INSERT WITH CHECK (
  EXISTS (SELECT 1 FROM posts WHERE id = post_id AND author_id = auth.uid())
);
CREATE POLICY "polls_delete" ON polls FOR DELETE USING (
  EXISTS (SELECT 1 FROM posts WHERE id = post_id AND author_id = auth.uid())
  OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);
GRANT SELECT, INSERT, DELETE ON polls TO authenticated;
GRANT SELECT ON polls TO anon;

-- 3. Poll votes table
CREATE TABLE IF NOT EXISTS poll_votes (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  poll_id      uuid NOT NULL REFERENCES polls(id) ON DELETE CASCADE,
  user_id      uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  option_index integer NOT NULL,
  created_at   timestamptz DEFAULT now(),
  UNIQUE(poll_id, user_id)
);

ALTER TABLE poll_votes ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "pvotes_select" ON poll_votes;
DROP POLICY IF EXISTS "pvotes_insert" ON poll_votes;
DROP POLICY IF EXISTS "pvotes_delete" ON poll_votes;
CREATE POLICY "pvotes_select" ON poll_votes FOR SELECT USING (true);
CREATE POLICY "pvotes_insert" ON poll_votes FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "pvotes_delete" ON poll_votes FOR DELETE USING (auth.uid() = user_id);
GRANT SELECT, INSERT, DELETE ON poll_votes TO authenticated;
GRANT SELECT ON poll_votes TO anon;

-- 4. Rebuild posts_with_meta with tickers, is_pinned, embedded poll
DROP VIEW IF EXISTS posts_with_meta CASCADE;
CREATE OR REPLACE VIEW posts_with_meta AS
SELECT
  p.id,
  p.author_id,
  CASE WHEN COALESCE(p.is_anonymous,false) AND p.author_id != auth.uid()
       THEN NULL ELSE pr.handle END                                               AS author_handle,
  CASE WHEN COALESCE(p.is_anonymous,false) AND p.author_id != auth.uid()
       THEN NULL ELSE pr.avatar_url END                                           AS author_avatar_url,
  p.content,
  p.hashtags,
  COALESCE(p.tickers, '{}')                                                      AS tickers,
  COALESCE(p.tags, '{}')                                                         AS tags,
  COALESCE(p.is_anonymous,false)                                                 AS is_anonymous,
  COALESCE(p.is_pinned,false)                                                    AS is_pinned,
  p.category_id,
  c.name                                                                         AS category_name,
  p.image_url,
  p.comment_count,
  p.created_at,
  p.edited_at,
  ROUND(COALESCE(
    (SELECT AVG(r.value)::numeric FROM post_ratings r WHERE r.post_id = p.id), 0
  ),1)                                                                            AS avg_rating,
  (SELECT COUNT(*) FROM post_ratings r WHERE r.post_id = p.id)::int              AS rating_count,
  (SELECT value FROM post_ratings r
     WHERE r.post_id = p.id AND r.user_id = auth.uid() LIMIT 1)                  AS user_rating,
  (SELECT COUNT(*) FROM saved_posts sp WHERE sp.post_id = p.id)::int             AS save_count,
  EXISTS(
    SELECT 1 FROM saved_posts sp WHERE sp.post_id = p.id AND sp.user_id = auth.uid()
  )                                                                               AS is_saved,
  (
    (
      COALESCE((SELECT AVG(r.value)::float FROM post_ratings r WHERE r.post_id = p.id),0.0)
        * LN(1.0+(SELECT COUNT(*) FROM post_ratings r WHERE r.post_id = p.id)::float)
      + LN(1.0+p.comment_count::float)
      + LN(1.0+(SELECT COUNT(*) FROM saved_posts sp WHERE sp.post_id = p.id)::float)
      + 1.0
    ) /
    POWER(EXTRACT(EPOCH FROM (now()-p.created_at))/3600.0+2.0,1.5)
  )::float                                                                        AS edge_rank,
  -- Embedded poll JSONB (NULL if no poll)
  (
    SELECT jsonb_build_object(
      'id',         pol.id,
      'question',   pol.question,
      'options',    pol.options,
      'deadline',   pol.deadline,
      'total_votes',(SELECT COUNT(*)::int FROM poll_votes pv WHERE pv.poll_id = pol.id),
      'user_vote',  (SELECT pv2.option_index FROM poll_votes pv2
                     WHERE pv2.poll_id = pol.id AND pv2.user_id = auth.uid() LIMIT 1),
      'results', (
        SELECT jsonb_agg(
          jsonb_build_object('index',s.idx-1,'text',s.opt,'count',COALESCE(vc.cnt,0))
          ORDER BY s.idx
        )
        FROM unnest(pol.options) WITH ORDINALITY s(opt,idx)
        LEFT JOIN (
          SELECT option_index, COUNT(*)::int AS cnt
          FROM poll_votes WHERE poll_id = pol.id GROUP BY option_index
        ) vc ON vc.option_index = s.idx-1
      )
    )
    FROM polls pol WHERE pol.post_id = p.id LIMIT 1
  )                                                                               AS poll
FROM posts p
LEFT JOIN profiles pr ON pr.id = p.author_id
LEFT JOIN categories c ON c.id = p.category_id;

GRANT SELECT ON posts_with_meta TO authenticated, anon;

-- 5. Following feed view (filtered to followed users)
DROP VIEW IF EXISTS following_posts_with_meta CASCADE;
CREATE OR REPLACE VIEW following_posts_with_meta AS
SELECT p.* FROM posts_with_meta p
WHERE p.author_id IN (
  SELECT following_id FROM follows WHERE follower_id = auth.uid()
);

GRANT SELECT ON following_posts_with_meta TO authenticated;

-- 6. Rebuild notifications_with_actor (dropped by CASCADE above)
DROP VIEW IF EXISTS notifications_with_actor CASCADE;
CREATE OR REPLACE VIEW notifications_with_actor AS
SELECT n.id, n.recipient_id, n.actor_id, n.type, n.post_id, n.body,
       n.read, n.created_at,
       pr.handle     AS actor_handle,
       pr.avatar_url AS actor_avatar_url
FROM notifications n
LEFT JOIN profiles pr ON pr.id = n.actor_id;

GRANT SELECT ON notifications_with_actor TO authenticated;

-- 7. Trending tickers view
DROP VIEW IF EXISTS trending_tickers CASCADE;
CREATE OR REPLACE VIEW trending_tickers AS
SELECT unnest(tickers) AS ticker, COUNT(*) AS count
FROM posts
WHERE created_at > now() - interval '7 days'
  AND tickers IS NOT NULL
  AND array_length(tickers,1) > 0
GROUP BY ticker
ORDER BY count DESC;

GRANT SELECT ON trending_tickers TO authenticated, anon;

-- 8. Rating distribution function (for post analytics)
CREATE OR REPLACE FUNCTION get_rating_distribution(p_post_id uuid)
RETURNS TABLE(rating_value int, vote_count bigint)
LANGUAGE sql SECURITY INVOKER STABLE AS $$
  SELECT value AS rating_value, COUNT(*) AS vote_count
  FROM post_ratings
  WHERE post_id = p_post_id
  GROUP BY value
  ORDER BY value DESC;
$$;

GRANT EXECUTE ON FUNCTION get_rating_distribution(uuid) TO authenticated;

-- 9. post-images storage bucket
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'post-images','post-images', true, 10485760,
  ARRAY['image/jpeg','image/jpg','image/png','image/webp','image/gif']
)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "post_images_public_read"  ON storage.objects;
DROP POLICY IF EXISTS "post_images_auth_upload"  ON storage.objects;
DROP POLICY IF EXISTS "post_images_auth_delete"  ON storage.objects;

CREATE POLICY "post_images_public_read" ON storage.objects
  FOR SELECT USING (bucket_id = 'post-images');
CREATE POLICY "post_images_auth_upload" ON storage.objects
  FOR INSERT WITH CHECK (bucket_id = 'post-images' AND auth.role() = 'authenticated');
CREATE POLICY "post_images_auth_delete" ON storage.objects
  FOR DELETE USING (bucket_id = 'post-images' AND auth.role() = 'authenticated');

NOTIFY pgrst, 'reload schema';
