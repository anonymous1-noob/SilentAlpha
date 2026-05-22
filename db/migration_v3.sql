-- =====================================================
-- SilentAlpha Migration v3
-- Admin role, category RLS, single Finance category
-- =====================================================

-- 1. Add role to profiles
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS role text DEFAULT 'user';

-- 2. Single Finance category
DELETE FROM categories;
INSERT INTO categories (id, name, emoji) VALUES
  (gen_random_uuid(), 'Finance', '💹');

-- 3. Category RLS: only admin can INSERT/UPDATE/DELETE
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "cats_select" ON categories;
DROP POLICY IF EXISTS "cats_insert" ON categories;
DROP POLICY IF EXISTS "cats_update" ON categories;
DROP POLICY IF EXISTS "cats_delete" ON categories;

CREATE POLICY "cats_select" ON categories FOR SELECT USING (true);
CREATE POLICY "cats_insert" ON categories FOR INSERT WITH CHECK (
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);
CREATE POLICY "cats_update" ON categories FOR UPDATE USING (
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);
CREATE POLICY "cats_delete" ON categories FOR DELETE USING (
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);

-- 4. Admin can update/delete any post (drop & recreate policies)
--    First check what policies exist
DROP POLICY IF EXISTS "posts_select"          ON posts;
DROP POLICY IF EXISTS "posts_insert"          ON posts;
DROP POLICY IF EXISTS "posts_update"          ON posts;
DROP POLICY IF EXISTS "posts_delete"          ON posts;
DROP POLICY IF EXISTS "Enable read access"    ON posts;
DROP POLICY IF EXISTS "Enable insert"         ON posts;
DROP POLICY IF EXISTS "Enable update"         ON posts;
DROP POLICY IF EXISTS "Enable delete"         ON posts;

CREATE POLICY "posts_select" ON posts FOR SELECT USING (true);
CREATE POLICY "posts_insert" ON posts FOR INSERT WITH CHECK (auth.uid() = author_id);
CREATE POLICY "posts_update" ON posts FOR UPDATE USING (
  auth.uid() = author_id OR
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);
CREATE POLICY "posts_delete" ON posts FOR DELETE USING (
  auth.uid() = author_id OR
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);

-- 5. Admin can update any profile (e.g. change roles)
DROP POLICY IF EXISTS "profiles_select"       ON profiles;
DROP POLICY IF EXISTS "profiles_insert"       ON profiles;
DROP POLICY IF EXISTS "profiles_update"       ON profiles;
DROP POLICY IF EXISTS "Enable read access"    ON profiles;

CREATE POLICY "profiles_select" ON profiles FOR SELECT USING (true);
CREATE POLICY "profiles_insert" ON profiles FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "profiles_update" ON profiles FOR UPDATE USING (
  auth.uid() = id OR
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);

-- 6. Rebuild profile_stats to include role
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

-- Reload PostgREST schema cache
NOTIFY pgrst, 'reload schema';
