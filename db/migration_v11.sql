-- Accept/reject follow requests via security-definer functions,
-- bypassing RLS on the follows table entirely for these operations.

-- Drop and recreate the accept policy cleanly in case v10 was partial
DROP POLICY IF EXISTS "follows: accept follow_request" ON follows;

-- Function: accept a follow request
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

  INSERT INTO notifications (recipient_id, actor_id, type, read, created_at)
  VALUES (p_requester_id, auth.uid(), 'follow', false, NOW())
  ON CONFLICT DO NOTHING;
END;
$$;

-- Function: reject a follow request
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
END;
$$;

-- Grant execute to authenticated users
GRANT EXECUTE ON FUNCTION accept_follow_request(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION reject_follow_request(UUID) TO authenticated;
