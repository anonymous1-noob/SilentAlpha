-- Add author_score to posts_with_meta so badges can be shown on post cards.
-- Anonymous posts expose NULL score (identity protection).

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
  CASE WHEN COALESCE(p.is_anonymous,false) AND p.author_id != auth.uid()
       THEN NULL
       ELSE COALESCE(
         (SELECT SUM(r2.value)::int
          FROM post_ratings r2
          JOIN posts p2 ON p2.id = r2.post_id
          WHERE p2.author_id = p.author_id), 0
       )
  END                                                                             AS author_score,
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
    POWER(
      GREATEST(EXTRACT(EPOCH FROM (now()-p.created_at))/3600.0+2.0, 0.001),
      1.5
    )
  )::float                                                                        AS edge_rank,
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

CREATE OR REPLACE VIEW following_posts_with_meta AS
SELECT p.* FROM posts_with_meta p
WHERE p.author_id IN (
  SELECT following_id FROM follows WHERE follower_id = auth.uid()
);

GRANT SELECT ON following_posts_with_meta TO authenticated;
