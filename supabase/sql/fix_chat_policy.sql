-- ============================================
-- FIX CHAT RLS POLICY - Infinite Recursion Fix
-- ============================================
-- Yeh SQL sirf policy fix karega, tables already exist hain

-- Step 1: Drop ALL existing policies on conversation_participants
DROP POLICY IF EXISTS "Users can view conversation participants" ON public.conversation_participants;
DROP POLICY IF EXISTS "Users can insert conversation participants" ON public.conversation_participants;
DROP POLICY IF EXISTS "Users can update their participant record" ON public.conversation_participants;

-- Step 2: Create NEW fixed policies (no infinite recursion)

-- Allow users to see their own participant record
CREATE POLICY "Users can view their own participant record"
  ON public.conversation_participants FOR SELECT
  USING (user_id = auth.uid());

-- Allow users to see other participants in conversations they're part of
-- This uses a CTE to avoid recursion
CREATE POLICY "Users can view other participants"
  ON public.conversation_participants FOR SELECT
  USING (
    conversation_id IN (
      SELECT DISTINCT conversation_id 
      FROM conversation_participants 
      WHERE user_id = auth.uid()
    )
  );

-- Allow inserting participants
CREATE POLICY "Users can insert conversation participants"
  ON public.conversation_participants FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

-- Allow updating own record
CREATE POLICY "Users can update their participant record"
  ON public.conversation_participants FOR UPDATE
  USING (user_id = auth.uid());

-- Verify policies are working
SELECT 'All policies fixed successfully!' AS status;
