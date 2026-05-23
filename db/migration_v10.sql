-- SilentAlpha Migration v10
-- Fix follow approval: add RLS policy allowing the follow target to
-- insert a follows row on behalf of the requester when accepting a request.

CREATE POLICY "follows: accept follow_request" ON follows
  FOR INSERT WITH CHECK (
    following_id = auth.uid() AND
    EXISTS (
      SELECT 1 FROM follow_requests
      WHERE requester_id = follower_id
        AND target_id = auth.uid()
        AND status = 'pending'
    )
  );
