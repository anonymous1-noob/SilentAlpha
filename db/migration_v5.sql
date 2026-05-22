-- =====================================================
-- SilentAlpha Migration v5
-- Edge rank, anon identity fix, notifications triggers,
-- avatars storage bucket, notifications_with_actor view
-- =====================================================

-- 1. Rebuild posts_with_meta:
--    · Fix anonymous identity leak
--    · Add edge_rank (time-decay formula)
--    · Add save_count
DROP VIEW IF EXISTS posts_with_meta CASCADE;
CREATE OR REPLACE VIEW posts_with_meta AS
SELECT
  p.id,
  p.author_id,
  -- Anonymous masking: hide author identity unless viewer is the author
  CASE WHEN COALESCE(p.is_anonymous, false) AND p.author_id != auth.uid()
       THEN NULL ELSE pr.handle END                                               AS author_handle,
  CASE WHEN COALESCE(p.is_anonymous, false) AND p.author_id != auth.uid()
       THEN NULL ELSE pr.avatar_url END                                           AS author_avatar_url,
  p.content,
  p.hashtags,
  COALESCE(p.tags, '{}')                                                          AS tags,
  COALESCE(p.is_anonymous, false)                                                 AS is_anonymous,
  p.category_id,
  c.name                                                                          AS category_name,
  p.image_url,
  p.comment_count,
  p.created_at,
  p.edited_at,
  ROUND(COALESCE(
    (SELECT AVG(r.value)::numeric FROM post_ratings r WHERE r.post_id = p.id), 0
  ), 1)                                                                           AS avg_rating,
  (SELECT COUNT(*) FROM post_ratings r WHERE r.post_id = p.id)::int               AS rating_count,
  (SELECT value FROM post_ratings r
     WHERE r.post_id = p.id AND r.user_id = auth.uid() LIMIT 1)                   AS user_rating,
  (SELECT COUNT(*) FROM saved_posts sp WHERE sp.post_id = p.id)::int              AS save_count,
  EXISTS(
    SELECT 1 FROM saved_posts sp WHERE sp.post_id = p.id AND sp.user_id = auth.uid()
  )                                                                                AS is_saved,
  -- Edge rank: engagement / time-decay (inspired by HN)
  -- Numerator: rating_score * ln(rating_count+1) + ln(comments+1) + ln(saves+1) + 1
  -- Denominator: (hours_since_post + 2)^1.5
  (
    (
      COALESCE((SELECT AVG(r.value)::float FROM post_ratings r WHERE r.post_id = p.id), 0.0)
        * LN(1.0 + (SELECT COUNT(*) FROM post_ratings r WHERE r.post_id = p.id)::float)
      + LN(1.0 + p.comment_count::float)
      + LN(1.0 + (SELECT COUNT(*) FROM saved_posts sp WHERE sp.post_id = p.id)::float)
      + 1.0
    ) /
    POWER(EXTRACT(EPOCH FROM (now() - p.created_at)) / 3600.0 + 2.0, 1.5)
  )::float                                                                         AS edge_rank
FROM posts p
LEFT JOIN profiles pr  ON pr.id  = p.author_id
LEFT JOIN categories c ON c.id   = p.category_id;

GRANT SELECT ON posts_with_meta TO authenticated, anon;

-- 2. Update notifications type CHECK to include 'rating'
ALTER TABLE notifications
  DROP CONSTRAINT IF EXISTS notifications_type_check;
ALTER TABLE notifications
  ADD CONSTRAINT notifications_type_check
  CHECK (type IN ('like', 'comment', 'follow', 'mention', 'rating'));

-- 3. Create notifications_with_actor view (joins actor profile)
DROP VIEW IF EXISTS notifications_with_actor CASCADE;
CREATE OR REPLACE VIEW notifications_with_actor AS
SELECT
  n.id,
  n.recipient_id,
  n.actor_id,
  n.type,
  n.post_id,
  n.body,
  n.read,
  n.created_at,
  pr.handle     AS actor_handle,
  pr.avatar_url AS actor_avatar_url
FROM notifications n
LEFT JOIN profiles pr ON pr.id = n.actor_id;

GRANT SELECT ON notifications_with_actor TO authenticated;

-- 4. Ensure INSERT policy exists (for SECURITY DEFINER trigger functions)
DROP POLICY IF EXISTS "System can insert notifs" ON notifications;
CREATE POLICY "System can insert notifs" ON notifications
  FOR INSERT WITH CHECK (true);

-- 5. Trigger: new comment → notify post author
CREATE OR REPLACE FUNCTION notify_on_comment()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_author uuid;
BEGIN
  SELECT author_id INTO v_author FROM posts WHERE id = NEW.post_id;
  IF v_author IS NOT NULL AND v_author != NEW.author_id THEN
    INSERT INTO notifications (recipient_id, actor_id, type, post_id, body)
    VALUES (v_author, NEW.author_id, 'comment', NEW.post_id, LEFT(NEW.content, 100));
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notify_comment ON comments;
CREATE TRIGGER trg_notify_comment
  AFTER INSERT ON comments
  FOR EACH ROW EXECUTE FUNCTION notify_on_comment();

-- 6. Trigger: new follow → notify followed user
CREATE OR REPLACE FUNCTION notify_on_follow()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM notifications
    WHERE recipient_id = NEW.following_id AND actor_id = NEW.follower_id AND type = 'follow'
  ) THEN
    INSERT INTO notifications (recipient_id, actor_id, type)
    VALUES (NEW.following_id, NEW.follower_id, 'follow');
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notify_follow ON follows;
CREATE TRIGGER trg_notify_follow
  AFTER INSERT ON follows
  FOR EACH ROW EXECUTE FUNCTION notify_on_follow();

-- 7. Trigger: new rating → notify post author (deduped per actor+post)
CREATE OR REPLACE FUNCTION notify_on_rating()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_author uuid;
BEGIN
  SELECT author_id INTO v_author FROM posts WHERE id = NEW.post_id;
  IF v_author IS NOT NULL AND v_author != NEW.user_id THEN
    IF NOT EXISTS (
      SELECT 1 FROM notifications
      WHERE recipient_id = v_author AND actor_id = NEW.user_id
        AND type = 'rating' AND post_id = NEW.post_id
    ) THEN
      INSERT INTO notifications (recipient_id, actor_id, type, post_id)
      VALUES (v_author, NEW.user_id, 'rating', NEW.post_id);
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notify_rating ON post_ratings;
CREATE TRIGGER trg_notify_rating
  AFTER INSERT ON post_ratings
  FOR EACH ROW EXECUTE FUNCTION notify_on_rating();

-- 8. Create avatars storage bucket (public, 5 MB limit)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'avatars', 'avatars', true, 5242880,
  ARRAY['image/jpeg','image/jpg','image/png','image/webp','image/gif']
)
ON CONFLICT (id) DO NOTHING;

-- Storage RLS policies
DROP POLICY IF EXISTS "avatars_public_read"  ON storage.objects;
DROP POLICY IF EXISTS "avatars_auth_upload"  ON storage.objects;
DROP POLICY IF EXISTS "avatars_auth_update"  ON storage.objects;
DROP POLICY IF EXISTS "avatars_auth_delete"  ON storage.objects;

CREATE POLICY "avatars_public_read" ON storage.objects
  FOR SELECT USING (bucket_id = 'avatars');

CREATE POLICY "avatars_auth_upload" ON storage.objects
  FOR INSERT WITH CHECK (bucket_id = 'avatars' AND auth.role() = 'authenticated');

CREATE POLICY "avatars_auth_update" ON storage.objects
  FOR UPDATE USING (bucket_id = 'avatars' AND auth.role() = 'authenticated');

CREATE POLICY "avatars_auth_delete" ON storage.objects
  FOR DELETE USING (bucket_id = 'avatars' AND auth.role() = 'authenticated');

-- Reload PostgREST schema cache
NOTIFY pgrst, 'reload schema';
