-- =====================================================
-- SilentAlpha Migration v2
-- Remove campus, add ratings, tags, handle, tagline
-- =====================================================

-- 1. Drop all dependent views first (so column changes are free)
DROP VIEW IF EXISTS posts_with_meta    CASCADE;
DROP VIEW IF EXISTS profile_stats      CASCADE;
DROP VIEW IF EXISTS comments_with_meta CASCADE;
DROP VIEW IF EXISTS notifications_with_actor CASCADE;
DROP VIEW IF EXISTS trending_hashtags  CASCADE;

-- 2. Profiles: rename username → handle, add tagline, drop campus
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns
             WHERE table_name='profiles' AND column_name='username') THEN
    ALTER TABLE profiles RENAME COLUMN username TO handle;
  END IF;
END $$;

ALTER TABLE profiles DROP CONSTRAINT IF EXISTS profiles_handle_unique;
ALTER TABLE profiles ADD CONSTRAINT profiles_handle_unique UNIQUE (handle);
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS tagline text;
ALTER TABLE profiles DROP COLUMN IF EXISTS campus;

-- 3. Posts: add tags + is_anonymous, drop campus
ALTER TABLE posts ADD COLUMN IF NOT EXISTS tags        text[]   DEFAULT '{}';
ALTER TABLE posts ADD COLUMN IF NOT EXISTS is_anonymous boolean DEFAULT false;
ALTER TABLE posts DROP COLUMN IF EXISTS campus;

-- 4. Drop post_likes, create post_ratings (-5 to +5)
DROP TABLE IF EXISTS post_likes;

CREATE TABLE IF NOT EXISTS post_ratings (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id     uuid NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  user_id     uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  value       integer NOT NULL CHECK (value >= -5 AND value <= 5),
  created_at  timestamptz DEFAULT now(),
  UNIQUE(post_id, user_id)
);

ALTER TABLE post_ratings ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "ratings_select" ON post_ratings;
DROP POLICY IF EXISTS "ratings_insert" ON post_ratings;
DROP POLICY IF EXISTS "ratings_update" ON post_ratings;
DROP POLICY IF EXISTS "ratings_delete" ON post_ratings;
CREATE POLICY "ratings_select" ON post_ratings FOR SELECT USING (true);
CREATE POLICY "ratings_insert" ON post_ratings FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "ratings_update" ON post_ratings FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "ratings_delete" ON post_ratings FOR DELETE USING (auth.uid() = user_id);

GRANT SELECT, INSERT, UPDATE, DELETE ON post_ratings TO authenticated;
GRANT SELECT ON post_ratings TO anon;

-- 5. Finance categories (replace all)
DELETE FROM categories;
INSERT INTO categories (id, name, emoji) VALUES
  (gen_random_uuid(), 'Stocks',            '📈'),
  (gen_random_uuid(), 'Mutual Funds',      '💼'),
  (gen_random_uuid(), 'Crypto',            '🪙'),
  (gen_random_uuid(), 'Personal Finance',  '💰'),
  (gen_random_uuid(), 'IPO',               '🚀'),
  (gen_random_uuid(), 'F&O',               '📊'),
  (gen_random_uuid(), 'Commodities',       '🥇'),
  (gen_random_uuid(), 'News & Analysis',   '📰');

-- 6. Recreate trending_hashtags view
CREATE OR REPLACE VIEW trending_hashtags AS
SELECT unnest(hashtags) AS hashtag, COUNT(*) AS count
FROM posts
WHERE created_at > now() - interval '7 days'
GROUP BY hashtag
ORDER BY count DESC;

GRANT SELECT ON trending_hashtags TO authenticated, anon;

-- 7. Recreate posts_with_meta view
CREATE OR REPLACE VIEW posts_with_meta AS
SELECT
  p.id,
  p.author_id,
  pr.handle                                                                AS author_handle,
  pr.avatar_url                                                            AS author_avatar_url,
  p.content,
  p.hashtags,
  COALESCE(p.tags, '{}')                                                   AS tags,
  COALESCE(p.is_anonymous, false)                                          AS is_anonymous,
  p.category_id,
  c.name                                                                   AS category_name,
  p.image_url,
  p.comment_count,
  p.created_at,
  p.edited_at,
  ROUND(COALESCE(
    (SELECT AVG(r.value)::numeric FROM post_ratings r WHERE r.post_id = p.id), 0
  ), 1)                                                                    AS avg_rating,
  (SELECT COUNT(*) FROM post_ratings r WHERE r.post_id = p.id)::int        AS rating_count,
  (SELECT value FROM post_ratings r
     WHERE r.post_id = p.id AND r.user_id = auth.uid() LIMIT 1)            AS user_rating,
  EXISTS(
    SELECT 1 FROM saved_posts sp WHERE sp.post_id = p.id AND sp.user_id = auth.uid()
  )                                                                         AS is_saved
FROM posts p
LEFT JOIN profiles pr  ON pr.id  = p.author_id
LEFT JOIN categories c ON c.id   = p.category_id;

GRANT SELECT ON posts_with_meta TO authenticated, anon;

-- 8. Recreate profile_stats view (with user_score)
CREATE OR REPLACE VIEW profile_stats AS
SELECT
  p.id,
  p.handle,
  p.avatar_url,
  p.bio,
  p.tagline,
  p.created_at,
  COALESCE((SELECT COUNT(*) FROM follows  WHERE following_id = p.id), 0)::int  AS follower_count,
  COALESCE((SELECT COUNT(*) FROM follows  WHERE follower_id  = p.id), 0)::int  AS following_count,
  COALESCE((SELECT COUNT(*) FROM posts    WHERE author_id    = p.id), 0)::int  AS post_count,
  EXISTS(
    SELECT 1 FROM follows WHERE follower_id = auth.uid() AND following_id = p.id
  )                                                                             AS is_following,
  (
    COALESCE((
      SELECT SUM(
        COALESCE((SELECT AVG(r.value) FROM post_ratings r WHERE r.post_id = posts.id), 0)::int * 10
        + posts.comment_count * 2
      )
      FROM posts WHERE author_id = p.id AND COALESCE(is_anonymous, false) = false
    ), 0)::int
    + COALESCE((SELECT COUNT(*) FROM follows WHERE following_id = p.id), 0)::int * 5
  )                                                                             AS user_score
FROM profiles p;

GRANT SELECT ON profile_stats TO authenticated, anon;

-- 9. Recreate comments_with_meta view (handle instead of username)
CREATE OR REPLACE VIEW comments_with_meta AS
SELECT
  c.*,
  pr.handle      AS author_handle,
  pr.avatar_url  AS author_avatar_url,
  false::boolean AS is_liked
FROM comments c
LEFT JOIN profiles pr ON pr.id = c.author_id;

GRANT SELECT ON comments_with_meta TO authenticated, anon;

-- 10. Update on_auth_user_created trigger (uses handle now)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, handle, created_at)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'handle', split_part(NEW.email, '@', 1)),
    now()
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

-- Notify PostgREST to reload schema cache
NOTIFY pgrst, 'reload schema';
