-- migration_v21: Feed quality + notification deduplication
--
-- 1. hidden_posts table (Not Interested)
-- 2. Notification deduplication: partial unique indexes + updated trigger/RPCs
-- 3. Rebuild posts_with_meta:
--      · Filter hidden posts, reporter's own reported posts, blocked authors
--      · 1.5× edge_rank boost for posts from users the viewer follows
-- 4. Rebuild following_posts_with_meta + notifications_with_actor (CASCADE deps)

-- ── 1. hidden_posts ────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS hidden_posts (
  user_id    uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  post_id    uuid NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  PRIMARY KEY (user_id, post_id)
);

ALTER TABLE hidden_posts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "users manage own hidden" ON hidden_posts;
CREATE POLICY "users manage own hidden" ON hidden_posts
  FOR ALL USING (auth.uid() = user_id);

-- Grant SELECT to anon so posts_with_meta subquery works for anonymous viewers
-- (RLS keeps their result-set empty; no data is exposed)
GRANT SELECT, INSERT, DELETE ON hidden_posts TO authenticated;
GRANT SELECT ON hidden_posts TO anon;

-- Ensure anon can also read blocks/reports for the new view subqueries
GRANT SELECT ON blocks TO anon;
GRANT SELECT ON reports TO anon;

-- ── 2. Notification deduplication ─────────────────────────────────────────────

-- Remove existing exact duplicates before adding unique indexes
-- (keep the newest row per group)

DELETE FROM notifications n
WHERE type = 'follow_request'
  AND id NOT IN (
    SELECT DISTINCT ON (actor_id, recipient_id) id
    FROM notifications
    WHERE type = 'follow_request'
    ORDER BY actor_id, recipient_id, created_at DESC
  );

DELETE FROM notifications n
WHERE type = 'comment'
  AND post_id IS NOT NULL
  AND id NOT IN (
    SELECT DISTINCT ON (actor_id, recipient_id, post_id) id
    FROM notifications
    WHERE type = 'comment' AND post_id IS NOT NULL
    ORDER BY actor_id, recipient_id, post_id, created_at DESC
  );

DELETE FROM notifications n
WHERE type = 'mention'
  AND post_id IS NOT NULL
  AND id NOT IN (
    SELECT DISTINCT ON (actor_id, recipient_id, post_id) id
    FROM notifications
    WHERE type = 'mention' AND post_id IS NOT NULL
    ORDER BY actor_id, recipient_id, post_id, created_at DESC
  );

-- Partial unique indexes (one notification per actor→recipient per context)
CREATE UNIQUE INDEX IF NOT EXISTS uq_notif_follow_request
  ON notifications (actor_id, recipient_id)
  WHERE type = 'follow_request';

CREATE UNIQUE INDEX IF NOT EXISTS uq_notif_comment
  ON notifications (actor_id, recipient_id, post_id)
  WHERE type = 'comment' AND post_id IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS uq_notif_mention
  ON notifications (actor_id, recipient_id, post_id)
  WHERE type = 'mention' AND post_id IS NOT NULL;

-- Update send_follow_request: upsert notification via the new index
CREATE OR REPLACE FUNCTION send_follow_request(p_target_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO follow_requests (requester_id, target_id, status, created_at)
  VALUES (auth.uid(), p_target_id, 'pending', NOW())
  ON CONFLICT (requester_id, target_id)
  DO UPDATE SET status = 'pending', created_at = NOW();

  -- Upsert: reset read + bump timestamp if request was already sent
  INSERT INTO notifications (recipient_id, actor_id, type, read, created_at)
  VALUES (p_target_id, auth.uid(), 'follow_request', false, NOW())
  ON CONFLICT (actor_id, recipient_id) WHERE type = 'follow_request'
  DO UPDATE SET read = false, created_at = NOW();
END;
$$;

GRANT EXECUTE ON FUNCTION send_follow_request(UUID) TO authenticated;

-- Update notify_on_comment: upsert so repeated comments on the same post
-- collapse into one notification (latest body shown)
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
    INSERT INTO notifications
      (recipient_id, actor_id, type, post_id, body, read, created_at)
    VALUES
      (v_author, NEW.author_id, 'comment', NEW.post_id,
       LEFT(NEW.content, 100), false, NOW())
    ON CONFLICT (actor_id, recipient_id, post_id)
      WHERE type = 'comment' AND post_id IS NOT NULL
    DO UPDATE SET
      body       = LEFT(NEW.content, 100),
      read       = false,
      created_at = NOW();
  END IF;
  RETURN NEW;
END;
$$;

-- Update notify_mentions: upsert to deduplicate same actor→recipient in same post
CREATE OR REPLACE FUNCTION notify_mentions(p_post_id UUID, p_handles TEXT[])
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_handle    TEXT;
  v_recipient UUID;
BEGIN
  FOREACH v_handle IN ARRAY p_handles LOOP
    IF lower(v_handle) = 'anonymous' THEN CONTINUE; END IF;

    SELECT id INTO v_recipient
    FROM profiles
    WHERE handle = lower(v_handle)
    LIMIT 1;

    IF v_recipient IS NULL OR v_recipient = auth.uid() THEN CONTINUE; END IF;

    INSERT INTO notifications
      (recipient_id, actor_id, type, post_id, read, created_at)
    VALUES
      (v_recipient, auth.uid(), 'mention', p_post_id, false, NOW())
    ON CONFLICT (actor_id, recipient_id, post_id)
      WHERE type = 'mention' AND post_id IS NOT NULL
    DO UPDATE SET read = false, created_at = NOW();
  END LOOP;
END;
$$;

GRANT EXECUTE ON FUNCTION notify_mentions(UUID, TEXT[]) TO authenticated;

-- ── 3. Rebuild posts_with_meta ─────────────────────────────────────────────────
-- Drops following_posts_with_meta and notifications_with_actor via CASCADE

DROP VIEW IF EXISTS following_posts_with_meta CASCADE;
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
  -- Edge rank with 1.5× boost for posts by authors the viewer follows
  (
    (
      COALESCE((SELECT AVG(r.value)::float FROM post_ratings r WHERE r.post_id = p.id),0.0)
        * LN(1.0+(SELECT COUNT(*) FROM post_ratings r WHERE r.post_id = p.id)::float)
      + LN(1.0+p.comment_count::float)
      + LN(1.0+(SELECT COUNT(*) FROM saved_posts sp WHERE sp.post_id = p.id)::float)
      + 1.0
    ) /
    POWER(
      GREATEST(EXTRACT(EPOCH FROM (now()-p.created_at))/3600.0+2.0, 0.001),
      1.5
    )
  )::float
  * CASE WHEN EXISTS (
      SELECT 1 FROM follows
      WHERE follower_id = auth.uid() AND following_id = p.author_id
    ) THEN 1.5 ELSE 1.0 END                                                      AS edge_rank,
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
LEFT JOIN categories c ON c.id = p.category_id
WHERE
  -- Hide posts the viewer marked as Not Interested
  NOT EXISTS (
    SELECT 1 FROM hidden_posts hp
    WHERE hp.post_id = p.id AND hp.user_id = auth.uid()
  )
  -- Hide posts the viewer has reported
  AND NOT EXISTS (
    SELECT 1 FROM reports rp
    WHERE rp.post_id = p.id AND rp.reporter_id = auth.uid()
  )
  -- Hide posts from authors the viewer has blocked
  AND NOT EXISTS (
    SELECT 1 FROM blocks bl
    WHERE bl.blocker_id = auth.uid() AND bl.blocked_id = p.author_id
  );

GRANT SELECT ON posts_with_meta TO authenticated, anon;

-- ── 4. Rebuild dependent views ─────────────────────────────────────────────────

CREATE OR REPLACE VIEW following_posts_with_meta AS
SELECT p.* FROM posts_with_meta p
WHERE p.author_id IN (
  SELECT following_id FROM follows WHERE follower_id = auth.uid()
);

GRANT SELECT ON following_posts_with_meta TO authenticated;

DROP VIEW IF EXISTS notifications_with_actor CASCADE;
CREATE OR REPLACE VIEW notifications_with_actor AS
SELECT n.id, n.recipient_id, n.actor_id, n.type, n.post_id, n.body,
       n.read, n.created_at,
       pr.handle     AS actor_handle,
       pr.avatar_url AS actor_avatar_url
FROM notifications n
LEFT JOIN profiles pr ON pr.id = n.actor_id;

GRANT SELECT ON notifications_with_actor TO authenticated;

NOTIFY pgrst, 'reload schema';
