-- ============================================================
-- SilentAlpha — Fix: Follows + Ratings + Comments
-- Safe to run even if partial data exists (ON CONFLICT DO NOTHING)
-- Polls already done via seed_p3b_polls_fix.sql
-- ============================================================

-- ── FOLLOWS ──────────────────────────────────────────────────

-- Inbound follows (higher-tier users attract more followers)
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

-- Outbound follows (lower-tier users follow more people)
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
           WHEN 'W' THEN  8
           WHEN 'Q' THEN 14
           WHEN 'P' THEN 20
           WHEN 'R' THEN 30
           WHEN 'N' THEN 40
           WHEN 'X' THEN 18
           ELSE 10
         END
) others
ON CONFLICT DO NOTHING;

SELECT 'follows' AS step, count(*) AS total FROM follows;

-- ── RATINGS ──────────────────────────────────────────────────
-- Drives user_score → leaderboard badges
-- W posts: raters give +3 to +5   → high scores → Wolf badge
-- Q posts: +2 to +4               → Quant badge
-- P posts: +1 to +3               → Portfolio Pro / Analyst
-- R posts: 0 to +2                → Bull Rider / Market Lurker
-- N posts: -1 to +1               → near-zero score
-- X posts: -3 to +1               → negative scores → Paper Trader

INSERT INTO post_ratings (post_id, user_id, value, created_at)
SELECT
  p.id   AS post_id,
  rater.user_id,
  GREATEST(-5, LEAST(5,
    CASE st.tier
      WHEN 'W' THEN 3 + floor(random() * 3)::int
      WHEN 'Q' THEN 2 + floor(random() * 3)::int
      WHEN 'P' THEN 1 + floor(random() * 3)::int
      WHEN 'R' THEN     floor(random() * 3)::int
      WHEN 'N' THEN -1+ floor(random() * 3)::int
      WHEN 'X' THEN -3+ floor(random() * 5)::int
      ELSE 1
    END
  )) AS value,
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

SELECT 'post_ratings' AS step, count(*) AS total FROM post_ratings;

-- ── COMMENTS ─────────────────────────────────────────────────
DO $COMMENTS$
DECLARE
  v_post   record;
  v_author uuid;
  v_body   text;
  v_n      int;
  j        int;

  hi_comments text[] := ARRAY[
    'Great analysis! The FII data really supports this thesis. Adding to watchlist.',
    'This is exactly what I was thinking. The sector rotation point is very insightful.',
    'Disagree on the target. At this PE, fundamentals do not fully justify the valuation.',
    'Can you share the source for FY24 PAT numbers? Would like to cross-verify my model.',
    'Been tracking this stock for 6 months. Your analysis aligns perfectly with mine.',
    'What is your SL here? Seems like a volatile level for fresh entry.',
    'Excellent breakdown. The risk-reward math is clean. Watching this closely.',
    'The management quality point is key. Have you read their latest earnings call transcript?',
    'Wait for Q3 results before fresh entry. This might have more downside short term.',
    'RSI divergence is valid but needs volume confirmation before acting on it.',
    'Already in this one since 850. Running a nice profit now thanks to your early call.',
    'Strongly agree on the macro setup. RBI cut will be the primary catalyst here.',
    'Perfect FII/DII data presentation. This is how market education should look.',
    'This promoter has related-party transaction history. Worth checking the AR carefully.',
    'Bookmarked this post. Will revisit in 3 months to track your call accuracy.',
    'The direct vs regular plan math is eye-opening. Shared with 5 friends already.',
    'Do not forget sector headwinds. US recession risk still not fully priced in globally.',
    'Your technical call last month was spot on. Following this one with conviction.',
    'The SME GMP analysis is sharp. Operator exit patterns are exactly as you describe.',
    'The SIP step-up compound math should be taught in every school in India!',
    'Nailed the support zone call from last week. This community is genuinely valuable.',
    'Brilliant valuation framework. The SOTP approach makes complex companies simple.',
    'Started SIP based on your earlier post. Up 11% already. Thank you for sharing!',
    'The emergency fund point is critical. Most investors skip this and regret it badly.',
    'I have been saying this for months! Finally someone with data backing the argument.'
  ];

  med_comments text[] := ARRAY[
    'Good point. I will look into this further before deciding.',
    'Interesting. What is your view on the Q3 outlook for this sector?',
    'Added to my watchlist. Thanks for sharing the analysis.',
    'How long have you been tracking this? My view is slightly different on valuation.',
    'Makes sense. The chart pattern matches your analysis.',
    'Not sure I agree 100% but you raise valid concerns. Watching closely.',
    'What entry price are you targeting? Current levels seem a bit extended to me.',
    'Good catch on the FII data. Most people miss this detail.',
    'Solid post. Keep sharing more like this.',
    'Agreed. I took a small position already based on similar thinking.',
    'What is your 1 year target? Trying to build a conviction case.',
    'The sector comparison is helpful. Had not thought of it this way.',
    'Are you holding through results or booking before?',
    'Good fundamental data. I prefer looking at cash flows over PAT for this sector.',
    'Your consistency in analysis is what I appreciate about this account.',
    'Thanks for breaking this down. Complex topic made simple.',
    'Have you looked at the peer comparison? The relative valuation is interesting.',
    'I was wrong on this one earlier. Your analysis changed my view.',
    'Numbers check out. Strong conviction building here.',
    'Which brokerage do you use for these trades? Curious about execution.'
  ];

  low_comments text[] := ARRAY[
    'Buy kar loon kya?',
    'Target kya hai bhai?',
    'Nifty kb 30000 hoga?',
    'Mujhe bhi batao which stock to buy please',
    'SL matlab kya hota hai? Beginner hun.',
    'Should I buy or sell?',
    'Lol market is going to crash anyway',
    'Great post! Following for more updates',
    'Too complicated for me. Can you simplify?',
    'What is RSI? Please explain simply.',
    'I bought this and it is red now. Help!',
    'Nice! Keep posting such content.',
    'Bookmarked!',
    'When will this recover bro?',
    'Good one!'
  ];

BEGIN
  -- Wolf/Quant posts: 8-14 comments
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
      SELECT user_id INTO v_author FROM seed_tiers
      WHERE user_id != v_post.author_id ORDER BY random() LIMIT 1;
      v_body := hi_comments[1 + floor(random()*25)::int];
      INSERT INTO comments (post_id, author_id, content, created_at)
      VALUES (v_post.id, v_author, v_body,
              v_post.created_at + (random() * interval '7 days'));
    END LOOP;
  END LOOP;

  -- Pro/Regular posts: 2-5 comments
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
      SELECT user_id INTO v_author FROM seed_tiers
      WHERE user_id != v_post.author_id ORDER BY random() LIMIT 1;
      IF random() < 0.4 THEN
        v_body := hi_comments[1 + floor(random()*25)::int];
      ELSE
        v_body := med_comments[1 + floor(random()*20)::int];
      END IF;
      INSERT INTO comments (post_id, author_id, content, created_at)
      VALUES (v_post.id, v_author, v_body,
              v_post.created_at + (random() * interval '7 days'));
    END LOOP;
  END LOOP;

  -- Novice/Random posts: 0-2 comments
  FOR v_post IN
    SELECT p.id, p.author_id, p.created_at
    FROM   posts p
    JOIN   seed_tiers st ON st.user_id = p.author_id
    WHERE  st.tier IN ('N','X')
    ORDER  BY random()
    LIMIT  80
  LOOP
    v_n := floor(random()*3)::int;
    FOR j IN 1..v_n LOOP
      SELECT user_id INTO v_author FROM seed_tiers
      WHERE user_id != v_post.author_id ORDER BY random() LIMIT 1;
      v_body := low_comments[1 + floor(random()*15)::int];
      INSERT INTO comments (post_id, author_id, content, created_at)
      VALUES (v_post.id, v_author, v_body,
              v_post.created_at + (random() * interval '5 days'));
    END LOOP;
  END LOOP;
END $COMMENTS$;

SELECT 'comments' AS step, count(*) AS total FROM comments;

-- ── FINAL LEADERBOARD PREVIEW ────────────────────────────────
SELECT
  p.handle,
  t.tier,
  COALESCE(SUM(pr.value), 0)                          AS user_score,
  COUNT(DISTINCT po.id)                               AS posts,
  (SELECT count(*) FROM follows WHERE following_id = p.id) AS followers
FROM profiles p
JOIN seed_tiers t ON t.user_id = p.id
LEFT JOIN posts po ON po.author_id = p.id
LEFT JOIN post_ratings pr ON pr.post_id = po.id
GROUP BY p.handle, t.tier, p.id
ORDER BY user_score DESC
LIMIT 15;
