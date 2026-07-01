-- ============================================================
-- SilentAlpha Finance Seed — PART 3: Engagement
-- Run AFTER seed_p2_posts.sql in the SAME Supabase session
-- Creates: follows, ratings (leaderboard), comments, polls
-- ============================================================

-- ── PHASE 4: FOLLOWS ─────────────────────────────────────────
-- Each user gains followers according to their tier.
-- Strategy A: "who follows this user" (inbound)
INSERT INTO follows (follower_id, following_id, created_at)
SELECT
  rater.user_id,
  followed.user_id,
  now() - (random() * interval '700 days')
FROM seed_tiers followed
CROSS JOIN LATERAL (
  SELECT st.user_id
  FROM   seed_tiers st
  WHERE  st.user_id != followed.user_id
  ORDER  BY random()
  LIMIT  CASE followed.tier
           WHEN 'W' THEN 70
           WHEN 'Q' THEN 44
           WHEN 'P' THEN 22
           WHEN 'R' THEN 11
           WHEN 'N' THEN  5
           WHEN 'X' THEN  2
           ELSE 3
         END
) rater
ON CONFLICT DO NOTHING;

-- Strategy B: "who each user follows" (outbound, biased toward higher tiers)
INSERT INTO follows (follower_id, following_id, created_at)
SELECT
  t.user_id,
  others.user_id,
  now() - (random() * interval '700 days')
FROM seed_tiers t
CROSS JOIN LATERAL (
  SELECT st.user_id
  FROM   seed_tiers st
  WHERE  st.user_id != t.user_id
  ORDER  BY random()
  LIMIT  CASE t.tier
           WHEN 'W' THEN  8   -- Wolves follow few (selective)
           WHEN 'Q' THEN 14
           WHEN 'P' THEN 20
           WHEN 'R' THEN 30
           WHEN 'N' THEN 40
           WHEN 'X' THEN 18
           ELSE 10
         END
) others
ON CONFLICT DO NOTHING;

-- Sanity check
SELECT 'Follows created' AS step, count(*) FROM follows;

-- ── PHASE 5: RATINGS (drives leaderboard / user_score) ───────
-- user_score = SUM(post_ratings.value) for all ratings on user's posts
-- Badge thresholds: Wolf >=1501 | Quant 501-1500 | Portfolio Pro 201-500
--   Analyst 76-200 | Bull Rider 21-75 | Market Lurker 0-20 | Paper Trader <0
--
-- Target scores per tier:
--   W: ~2500-5000  (35 posts × 28 raters × avg 3.5 → ~3430)
--   Q: ~700-1400   (25 posts × 14 raters × avg 2.5 → ~875)
--   P: ~220-480    (15 posts × 9  raters × avg 2.0 → ~270)
--   R: ~30-180     ( 9 posts × 5  raters × avg 1.0 → ~45)
--   N: ~0-60       ( 6 posts × 3  raters × avg 0.5 → ~9)
--   X: ~-50 to 10  ( 4 posts × 2  raters × avg -1  → ~-8)

INSERT INTO post_ratings (post_id, user_id, value, created_at)
SELECT
  p.id                                          AS post_id,
  rater.user_id,
  GREATEST(-5, LEAST(5,
    CASE st.tier
      WHEN 'W' THEN 3 + floor(random() * 3)::int   -- 3,4,5   avg 4.0
      WHEN 'Q' THEN 2 + floor(random() * 3)::int   -- 2,3,4   avg 3.0
      WHEN 'P' THEN 1 + floor(random() * 3)::int   -- 1,2,3   avg 2.0
      WHEN 'R' THEN     floor(random() * 3)::int   -- 0,1,2   avg 1.0
      WHEN 'N' THEN -1+ floor(random() * 3)::int   -- -1,0,1  avg 0.0
      WHEN 'X' THEN -3+ floor(random() * 5)::int   -- -3…1   avg -1.0
      ELSE 1
    END
  ))                                            AS value,
  p.created_at + (random() * interval '14 days') AS created_at
FROM posts p
JOIN seed_tiers st ON st.user_id = p.author_id
CROSS JOIN LATERAL (
  SELECT st2.user_id
  FROM   seed_tiers st2
  WHERE  st2.user_id != p.author_id
  ORDER  BY random()
  LIMIT  CASE st.tier
           WHEN 'W' THEN 28
           WHEN 'Q' THEN 14
           WHEN 'P' THEN  9
           WHEN 'R' THEN  5
           WHEN 'N' THEN  3
           WHEN 'X' THEN  2
           ELSE 2
         END
) rater
ON CONFLICT (post_id, user_id) DO NOTHING;

-- Sanity check: top 15 user scores (should be W/Q tier at top)
SELECT
  p.handle,
  t.tier,
  COALESCE(SUM(pr.value), 0) AS computed_score
FROM profiles p
JOIN seed_tiers t ON t.user_id = p.id
LEFT JOIN posts po ON po.author_id = p.id
LEFT JOIN post_ratings pr ON pr.post_id = po.id
GROUP BY p.handle, t.tier
ORDER BY computed_score DESC
LIMIT 15;

-- ── PHASE 6: COMMENTS (~600 comments) ────────────────────────
DO $COMMENTS$
DECLARE
  v_post   record;
  v_author uuid;
  v_content text;
  v_n      int;
  j        int;

  hi_comments text[] := ARRAY[
    'Great analysis! The FII data really supports this thesis. Adding to watchlist.',
    'This is exactly what I was thinking. The sector rotation point is very insightful.',
    'Disagree on the target. At this PE, fundamentals don''t fully justify the valuation.',
    'Can you share the source for FY24 PAT numbers? Would like to cross-verify my model.',
    'Been tracking this stock for 6 months. Your analysis aligns perfectly with mine.',
    'What''s your SL here? Seems like a volatile level for fresh entry.',
    'Excellent breakdown. The risk:reward math is clean. Watching this closely.',
    'The management quality point is key. Have you read their latest earnings call transcript?',
    'Wait for Q3 results before fresh entry. This might have more downside short term.',
    'RSI divergence is valid but needs volume confirmation before acting on it.',
    'Already in this one since ₹850. Running a nice profit now thanks to your early call.',
    'Strongly agree on the macro setup. RBI cut will be the primary catalyst here.',
    'Perfect FII/DII data presentation. This is how market education should look.',
    'This promoter has related-party transaction history. Worth checking AR more carefully.',
    'Bookmarked this post. Will revisit in 3 months to track your call accuracy.',
    'The direct vs regular plan math is eye-opening. Shared with 5 friends already.',
    'Don''t forget sector headwinds. US recession risk still not fully priced in globally.',
    'Your technical call last month was spot on. Following this one with conviction.',
    'The SME GMP analysis is sharp. Operator exit patterns are exactly as you describe.',
    'The SIP step-up compound math should be taught in every school in India!',
    'Nailed the support zone call from last week. This community is genuinely valuable.',
    'Brilliant valuation framework. The SOTP approach makes complex companies simple.',
    'I''ve been saying this for months! Finally someone with data backing the argument.',
    'Started SIP based on your earlier post. Up 11% already. Thank you for sharing!',
    'The emergency fund point is critical. Most investors skip this and regret it badly.'
  ];

  med_comments text[] := ARRAY[
    'Good point. I''ll look into this further before deciding.',
    'Interesting. What''s your view on the Q3 outlook for this sector?',
    'Added to my watchlist. Thanks for sharing the analysis.',
    'How long have you been tracking this? My view is slightly different on valuation.',
    'Makes sense. The chart pattern matches your analysis.',
    'Not sure I agree 100% but you raise valid concerns. Watching closely.',
    'What entry price are you targeting? Current levels seem a bit extended to me.',
    'Good catch on the FII data. Most people miss this detail.',
    'Solid post. Keep sharing more like this.',
    'Agreed. I took a small position already based on similar thinking.',
    'What''s your 1 year target? Trying to build a conviction case.',
    'The sector comparison is helpful. Hadn''t thought of it this way.',
    'Are you holding through results or booking before?',
    'Good fundamental data. I prefer looking at cash flows over PAT for this sector.',
    'Your consistency in analysis is what I appreciate about this account.',
    'Which brokerage do you use for these trades? Curious about execution.',
    'Thanks for breaking this down. Complex topic made simple.',
    'Have you looked at the peer comparison? The relative valuation is interesting.',
    'I was wrong on this one earlier. Your analysis changed my view.',
    'Numbers check out. Strong conviction building here.'
  ];

  low_comments text[] := ARRAY[
    'Buy kar loon kya? 😂',
    'Target kya hai bhai?',
    'Nifty kb 30000 hoga? 🚀',
    'Mujhe bhi batao which stock to buy please',
    'SL matlab kya hota hai? Beginner hun.',
    'Should I buy or sell? 🤔',
    'Lol market is going to crash anyway 😅',
    'Great post! Following for more updates 👍',
    'Too complicated for me. Can you simplify?',
    'What is RSI? Please explain simply.',
    'I bought this and it''s red now. Help!',
    'Nice! Keep posting such content.',
    '❤️❤️❤️',
    'Bookmarked!',
    'When will this recover bro?'
  ];

BEGIN
  -- For Wolf/Quant posts: 8-14 comments each
  FOR v_post IN
    SELECT p.id, p.author_id, p.created_at
    FROM   posts p
    JOIN   seed_tiers st ON st.user_id = p.author_id
    WHERE  st.tier IN ('W','Q')
    ORDER  BY random()
    LIMIT  350
  LOOP
    v_n := 8 + floor(random()*7)::int;
    FOR j IN 1..v_n LOOP
      SELECT user_id INTO v_author
      FROM   seed_tiers
      WHERE  user_id != v_post.author_id
      ORDER  BY random() LIMIT 1;

      v_content := hi_comments[1 + floor(random()*25)::int];

      INSERT INTO comments (post_id, author_id, content, created_at)
      VALUES (
        v_post.id, v_author, v_content,
        v_post.created_at + (random() * interval '7 days')
      );
    END LOOP;
  END LOOP;

  -- For Pro/Regular posts: 2-5 comments each
  FOR v_post IN
    SELECT p.id, p.author_id, p.created_at
    FROM   posts p
    JOIN   seed_tiers st ON st.user_id = p.author_id
    WHERE  st.tier IN ('P','R')
    ORDER  BY random()
    LIMIT  200
  LOOP
    v_n := 2 + floor(random()*4)::int;
    FOR j IN 1..v_n LOOP
      SELECT user_id INTO v_author
      FROM   seed_tiers
      WHERE  user_id != v_post.author_id
      ORDER  BY random() LIMIT 1;

      -- Mix hi + med comments for these posts
      IF random() < 0.4 THEN
        v_content := hi_comments[1 + floor(random()*25)::int];
      ELSE
        v_content := med_comments[1 + floor(random()*20)::int];
      END IF;

      INSERT INTO comments (post_id, author_id, content, created_at)
      VALUES (
        v_post.id, v_author, v_content,
        v_post.created_at + (random() * interval '7 days')
      );
    END LOOP;
  END LOOP;

  -- For Novice/Random posts: 0-2 comments
  FOR v_post IN
    SELECT p.id, p.author_id, p.created_at
    FROM   posts p
    JOIN   seed_tiers st ON st.user_id = p.author_id
    WHERE  st.tier IN ('N','X')
    ORDER  BY random()
    LIMIT  80
  LOOP
    v_n := floor(random()*3)::int;   -- 0, 1, or 2
    FOR j IN 1..v_n LOOP
      SELECT user_id INTO v_author
      FROM   seed_tiers
      WHERE  user_id != v_post.author_id
      ORDER  BY random() LIMIT 1;

      v_content := low_comments[1 + floor(random()*15)::int];

      INSERT INTO comments (post_id, author_id, content, created_at)
      VALUES (
        v_post.id, v_author, v_content,
        v_post.created_at + (random() * interval '5 days')
      );
    END LOOP;
  END LOOP;

END $COMMENTS$;

SELECT 'Comments created' AS step, count(*) FROM comments;

-- ── PHASE 7: POLLS (12 polls + votes) ────────────────────────
-- Store poll definitions in a table to avoid 2D array slicing issues
DROP TABLE IF EXISTS _poll_defs;
CREATE TEMP TABLE _poll_defs (
  k int, q text, op1 text, op2 text, op3 text, op4 text
);
INSERT INTO _poll_defs VALUES
(1,'Which sector will outperform Nifty 50 in the next 6 months?','IT & Technology','Banking & Finance','Pharma & Healthcare','Auto & EV'),
(2,'What is your current equity allocation?','Less than 50%','50-70%','70-90%','More than 90%'),
(3,'Where will Nifty 50 be by December 2025?','Below 22,000','22,000 to 24,000','24,000 to 27,000','Above 27,000'),
(4,'Best performing MF category in your portfolio this year?','Large Cap / Index','Mid Cap Active','Small Cap Active','Flexi Cap / Hybrid'),
(5,'How do you react when your portfolio falls 15%?','Panic and sell everything','Hold and do nothing','Buy more on the dip','Review thesis then decide'),
(6,'Which IPO strategy do you follow?','Apply for listing gains only','Apply and hold 6-12 months','Skip all IPOs','Only profitable companies'),
(7,'Do you prefer active or passive MF investing?','Active funds beat index','Passive index funds only','Mix of both','Direct stocks only'),
(8,'What is your biggest investment mistake?','Selling too early','Buying on FOMO or tips','Not starting SIP early enough','Over-trading or F&O losses'),
(9,'Where will you invest a 1 lakh windfall today?','Nifty 50 Index Fund lump sum','SIP in Mid/Small Cap over 6 months','Direct stocks I have researched','Fixed Deposit for safety'),
(10,'How often do you check your portfolio?','Multiple times a day','Once a day','Weekly','Monthly or less'),
(11,'Nifty 50 PE is above 22x. Your view?','Overvalued - reduce equity','Fairly valued - stay invested','India premium justified - add more','I track earnings not PE'),
(12,'What is your primary investment goal?','Retire early before 50','Children education fund','Buy a house','Long-term wealth creation');

DO $POLLS$
DECLARE
  pd        record;
  v_post_id uuid;
  v_poll_id uuid;
  v_voter   uuid;
  v_opt     int;
  v_n       int;
  j         int;
BEGIN
  FOR pd IN SELECT * FROM _poll_defs ORDER BY k LOOP
    SELECT p.id INTO v_post_id
    FROM   posts p
    JOIN   public.seed_tiers st ON st.user_id = p.author_id
    WHERE  st.tier IN ('W','Q','P')
      AND  NOT EXISTS (SELECT 1 FROM polls WHERE post_id = p.id)
    ORDER  BY random() LIMIT 1;

    IF v_post_id IS NULL THEN CONTINUE; END IF;

    INSERT INTO polls (post_id, question, options, deadline)
    VALUES (v_post_id, pd.q, ARRAY[pd.op1,pd.op2,pd.op3,pd.op4], now() + interval '30 days')
    RETURNING id INTO v_poll_id;

    v_n := 25 + floor(random()*36)::int;
    FOR j IN 1..v_n LOOP
      SELECT user_id INTO v_voter FROM public.seed_tiers ORDER BY random() LIMIT 1;
      v_opt := floor(random()*4)::int;
      INSERT INTO poll_votes (poll_id, user_id, option_index, created_at)
      VALUES (v_poll_id, v_voter, v_opt, now() - (random() * interval '20 days'))
      ON CONFLICT (poll_id, user_id) DO NOTHING;
    END LOOP;
  END LOOP;
END $POLLS$;

DROP TABLE IF EXISTS _poll_defs;

-- ── FINAL SANITY CHECK ────────────────────────────────────────
SELECT 'posts'        AS entity, count(*)::text AS count FROM posts
UNION ALL
SELECT 'follows',       count(*)::text FROM follows
UNION ALL
SELECT 'post_ratings',  count(*)::text FROM post_ratings
UNION ALL
SELECT 'comments',      count(*)::text FROM comments
UNION ALL
SELECT 'polls',         count(*)::text FROM polls
UNION ALL
SELECT 'poll_votes',    count(*)::text FROM poll_votes
UNION ALL
SELECT 'profiles',      count(*)::text FROM profiles;

-- Top 10 leaderboard preview
SELECT
  p.handle,
  t.tier,
  COALESCE(SUM(pr.value), 0)            AS user_score,
  COUNT(DISTINCT po.id)                 AS post_count,
  (SELECT count(*) FROM follows WHERE following_id = p.id) AS followers
FROM profiles p
JOIN seed_tiers t ON t.user_id = p.id
LEFT JOIN posts po ON po.author_id = p.id
LEFT JOIN post_ratings pr ON pr.post_id = po.id
GROUP BY p.handle, t.tier, p.id
ORDER BY user_score DESC
LIMIT 10;
