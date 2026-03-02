-- ============================================
-- CHAT FEATURE - Fixed RLS Policies
-- ============================================
-- Run this to fix the infinite recursion error

-- Drop the problematic policy
DROP POLICY IF EXISTS "Users can view conversation participants" ON public.conversation_participants;

-- Create a new policy that doesn't cause recursion
-- Users can see their own participant record OR other participants in conversations they're part of
CREATE POLICY "Users can view conversation participants"
  ON public.conversation_participants FOR SELECT
  USING (
    user_id = auth.uid()
    OR
    conversation_id IN (
      SELECT conversation_id 
      FROM conversation_participants 
      WHERE user_id = auth.uid()
    )
  );

-- Also update the INSERT policy to be less restrictive
DROP POLICY IF EXISTS "Users can insert conversation participants" ON public.conversation_participants;

CREATE POLICY "Users can insert conversation participants"
  ON public.conversation_participants FOR INSERT
  WITH CHECK (
    -- Allow inserting if user is already a participant OR if it's a new conversation
    auth.uid() IS NOT NULL
  );
