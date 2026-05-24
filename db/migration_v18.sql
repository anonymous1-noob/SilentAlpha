-- =====================================================
-- SilentAlpha Migration v18
-- Server-enforce admin authorization boundaries
--
-- Gaps closed:
--   1. profiles_update WITH CHECK — prevents any authenticated
--      user from self-escalating their role column.
--   2. reports admin RLS — adds SELECT/UPDATE policies so
--      getModerationQueue and resolveReport actually work for
--      admins (previously returned empty / silently failed).
--   3. set_user_role   SECURITY DEFINER — role changes go through
--      a server function that re-checks admin status.
--   4. set_post_pinned SECURITY DEFINER — pin/unpin goes through
--      a server function; prevents authors self-pinning their posts.
--   5. resolve_report  SECURITY DEFINER — report resolution goes
--      through a server function that enforces admin-only access.
-- =====================================================

-- ── 1. profiles_update: add WITH CHECK to block role self-escalation ──────────
DROP POLICY IF EXISTS "profiles_update" ON profiles;
CREATE POLICY "profiles_update" ON profiles
  FOR UPDATE
  USING (
    auth.uid() = id
    OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  )
  WITH CHECK (
    -- Admins can update any field on any profile
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    OR (
      -- Non-admins may update their own profile but cannot change their role
      auth.uid() = id
      AND role = (SELECT p.role FROM profiles p WHERE p.id = auth.uid())
    )
  );

-- ── 2. reports: add admin SELECT + UPDATE policies ────────────────────────────
DROP POLICY IF EXISTS "Reporters can view own"   ON reports;
DROP POLICY IF EXISTS "reports_select"           ON reports;
DROP POLICY IF EXISTS "reports_update"           ON reports;

CREATE POLICY "reports_select" ON reports FOR SELECT USING (
  auth.uid() = reporter_id
  OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);

CREATE POLICY "reports_update" ON reports FOR UPDATE USING (
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);

-- ── 3. set_user_role ──────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION set_user_role(p_user_id uuid, p_role text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin') THEN
    RAISE EXCEPTION 'unauthorized';
  END IF;
  UPDATE profiles SET role = p_role WHERE id = p_user_id;
END;
$$;

GRANT EXECUTE ON FUNCTION set_user_role(uuid, text) TO authenticated;

-- ── 4. set_post_pinned ────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION set_post_pinned(p_post_id uuid, p_pinned boolean)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin') THEN
    RAISE EXCEPTION 'unauthorized';
  END IF;
  UPDATE posts SET is_pinned = p_pinned WHERE id = p_post_id;
END;
$$;

GRANT EXECUTE ON FUNCTION set_post_pinned(uuid, boolean) TO authenticated;

-- ── 5. resolve_report ─────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION resolve_report(p_report_id uuid, p_action text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin') THEN
    RAISE EXCEPTION 'unauthorized';
  END IF;
  UPDATE reports SET status = p_action WHERE id = p_report_id;
END;
$$;

GRANT EXECUTE ON FUNCTION resolve_report(uuid, text) TO authenticated;

-- Reload PostgREST schema cache
NOTIFY pgrst, 'reload schema';
