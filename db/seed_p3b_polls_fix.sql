-- ============================================================
-- SilentAlpha — Fix: Polls only (run after seed_p3_engagement.sql)
-- Follows + ratings already completed. This adds the 12 polls.
-- ============================================================

-- Store poll definitions in a real table (avoids 2D array slicing bug)
DROP TABLE IF EXISTS _poll_defs;
CREATE TEMP TABLE _poll_defs (
  k    int,
  q    text,
  op1  text,
  op2  text,
  op3  text,
  op4  text
);

INSERT INTO _poll_defs VALUES
(1,  'Which sector will outperform Nifty 50 in the next 6 months?',
     'IT & Technology', 'Banking & Finance', 'Pharma & Healthcare', 'Auto & EV'),
(2,  'What is your current equity allocation?',
     'Less than 50%', '50-70%', '70-90%', 'More than 90%'),
(3,  'Where will Nifty 50 be by December 2025?',
     'Below 22,000', '22,000 to 24,000', '24,000 to 27,000', 'Above 27,000'),
(4,  'Best performing MF category in your portfolio this year?',
     'Large Cap / Index', 'Mid Cap Active', 'Small Cap Active', 'Flexi Cap / Hybrid'),
(5,  'How do you react when your portfolio falls 15%?',
     'Panic and sell everything', 'Hold and do nothing', 'Buy more on the dip', 'Review thesis then decide'),
(6,  'Which IPO strategy do you follow?',
     'Apply for listing gains only', 'Apply and hold 6-12 months', 'Skip all IPOs', 'Only profitable companies'),
(7,  'Do you prefer active or passive MF investing?',
     'Active funds beat index', 'Passive index funds only', 'Mix of both', 'Direct stocks only'),
(8,  'What is your biggest investment mistake?',
     'Selling too early', 'Buying on FOMO or tips', 'Not starting SIP early enough', 'Over-trading or F&O losses'),
(9,  'Where will you invest a 1 lakh windfall today?',
     'Nifty 50 Index Fund lump sum', 'SIP in Mid/Small Cap over 6 months', 'Direct stocks I have researched', 'Fixed Deposit for safety'),
(10, 'How often do you check your portfolio?',
     'Multiple times a day', 'Once a day', 'Weekly', 'Monthly or less'),
(11, 'Nifty 50 PE is above 22x. Your view?',
     'Overvalued - reduce equity', 'Fairly valued - stay invested', 'India premium justified - add more', 'I track earnings not PE'),
(12, 'What is your primary investment goal?',
     'Retire early before 50', 'Children education fund', 'Buy a house', 'Long-term wealth creation');

-- Create polls using the temp table rows
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

    -- Pick a Wolf/Quant/Pro post that doesn't already have a poll
    SELECT p.id INTO v_post_id
    FROM   posts p
    JOIN   public.seed_tiers st ON st.user_id = p.author_id
    WHERE  st.tier IN ('W','Q','P')
      AND  NOT EXISTS (SELECT 1 FROM polls WHERE post_id = p.id)
    ORDER  BY random()
    LIMIT  1;

    IF v_post_id IS NULL THEN
      RAISE NOTICE 'No eligible post found for poll %, skipping', pd.k;
      CONTINUE;
    END IF;

    INSERT INTO polls (post_id, question, options, deadline)
    VALUES (
      v_post_id,
      pd.q,
      ARRAY[pd.op1, pd.op2, pd.op3, pd.op4],
      now() + interval '30 days'
    )
    RETURNING id INTO v_poll_id;

    -- Add 25-60 random votes
    v_n := 25 + floor(random() * 36)::int;
    FOR j IN 1..v_n LOOP
      SELECT user_id INTO v_voter
      FROM   public.seed_tiers
      ORDER  BY random()
      LIMIT  1;

      v_opt := floor(random() * 4)::int;

      INSERT INTO poll_votes (poll_id, user_id, option_index, created_at)
      VALUES (
        v_poll_id, v_voter, v_opt,
        now() - (random() * interval '20 days')
      )
      ON CONFLICT (poll_id, user_id) DO NOTHING;
    END LOOP;

  END LOOP;
END $POLLS$;

DROP TABLE IF EXISTS _poll_defs;

-- Final counts
SELECT 'polls'      AS entity, count(*)::text AS count FROM polls
UNION ALL
SELECT 'poll_votes', count(*)::text FROM poll_votes;
