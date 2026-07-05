-- migration_v22: Keep trending_hashtags materialized view fresh
--
-- migration_v20 turned trending_hashtags into a materialized view for
-- performance, and left a manual "REFRESH MATERIALIZED VIEW" comment
-- suggesting a pg_cron job — but that job was never actually scheduled.
-- The view has been frozen at its initial deploy-time snapshot ever since,
-- so Explore's "Trending Topics" goes stale (and eventually shows hashtags
-- with zero current matching posts). Schedule the refresh for real.

CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Drop any stale schedule from a previous manual attempt, then (re)schedule.
SELECT cron.unschedule(jobid)
FROM cron.job
WHERE jobname = 'refresh-trending-hashtags';

SELECT cron.schedule(
  'refresh-trending-hashtags',
  '*/10 * * * *',
  'SELECT public.refresh_trending_hashtags();'
);

-- Bring the view up to date immediately rather than waiting for the
-- first scheduled tick.
REFRESH MATERIALIZED VIEW public.trending_hashtags;
