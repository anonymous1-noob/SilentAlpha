-- Fix: accept/reject follow request RPCs now also delete the
-- follow_request notification so it doesn't reappear on reload.

CREATE OR REPLACE FUNCTION accept_follow_request(p_requester_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO follows (follower_id, following_id, created_at)
  VALUES (p_requester_id, auth.uid(), NOW())
  ON CONFLICT DO NOTHING;

  UPDATE follow_requests
  SET status = 'accepted'
  WHERE requester_id = p_requester_id
    AND target_id = auth.uid();

  -- Notify the requester that their request was accepted
  INSERT INTO notifications (recipient_id, actor_id, type, read, created_at)
  VALUES (p_requester_id, auth.uid(), 'follow', false, NOW())
  ON CONFLICT DO NOTHING;

  -- Remove the follow_request notification from the acceptor's inbox
  DELETE FROM notifications
  WHERE recipient_id = auth.uid()
    AND actor_id     = p_requester_id
    AND type         = 'follow_request';
END;
$$;

CREATE OR REPLACE FUNCTION reject_follow_request(p_requester_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE follow_requests
  SET status = 'rejected'
  WHERE requester_id = p_requester_id
    AND target_id = auth.uid();

  -- Remove the follow_request notification from the rejector's inbox
  DELETE FROM notifications
  WHERE recipient_id = auth.uid()
    AND actor_id     = p_requester_id
    AND type         = 'follow_request';
END;
$$;

GRANT EXECUTE ON FUNCTION accept_follow_request(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION reject_follow_request(UUID) TO authenticated;
