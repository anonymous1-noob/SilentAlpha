-- Close notification spoofing vulnerability.
--
-- The "System can insert notifs" policy used WITH CHECK (true), letting
-- any authenticated client insert notifications with an arbitrary actor_id.
--
-- Fix:
--   1. Add send_follow_request() SECURITY DEFINER RPC — replaces the two
--      client-side inserts in requestFollow() (follow_requests + notification).
--   2. Add notify_mentions() SECURITY DEFINER RPC — replaces the client-side
--      mention notification loop in createMentionNotifications().
--   3. Drop the permissive INSERT policy. SECURITY DEFINER functions bypass
--      RLS entirely, so all existing DB triggers (notify_on_comment,
--      notify_on_follow, notify_on_rating) and RPCs (accept_follow_request,
--      reject_follow_request) continue to work without any INSERT policy.

-- ── 1. send_follow_request ────────────────────────────────────────────────────
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

  -- actor_id is always the caller — server-enforced, not client-supplied
  INSERT INTO notifications (recipient_id, actor_id, type, read, created_at)
  VALUES (p_target_id, auth.uid(), 'follow_request', false, NOW());
END;
$$;

GRANT EXECUTE ON FUNCTION send_follow_request(UUID) TO authenticated;

-- ── 2. notify_mentions ────────────────────────────────────────────────────────
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

    INSERT INTO notifications (recipient_id, actor_id, type, post_id, read, created_at)
    VALUES (v_recipient, auth.uid(), 'mention', p_post_id, false, NOW());
  END LOOP;
END;
$$;

GRANT EXECUTE ON FUNCTION notify_mentions(UUID, TEXT[]) TO authenticated;

-- ── 3. Drop the permissive INSERT policy ──────────────────────────────────────
DROP POLICY IF EXISTS "System can insert notifs" ON notifications;
