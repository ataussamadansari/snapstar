-- ============================================
-- DROP ALL POLICIES AND RECREATE - Final Fix
-- ============================================

-- Step 1: Drop ALL existing policies (sabhi possible names)
DROP POLICY IF EXISTS "Users can view conversation participants" ON public.conversation_participants;
DROP POLICY IF EXISTS "Users can view their own participant record" ON public.conversation_participants;
DROP POLICY IF EXISTS "Users can view other participants" ON public.conversation_participants;
DROP POLICY IF EXISTS "Users can insert conversation participants" ON public.conversation_participants;
DROP POLICY IF EXISTS "Users can update their participant record" ON public.conversation_participants;

-- Step 2: Create ONLY 2 simple policies

-- Policy 1: Users can see their own record
CREATE POLICY "view_own_participant"
  ON public.conversation_participants FOR SELECT
  USING (user_id = auth.uid());

-- Policy 2: Users can see other participants in their conversations
CREATE POLICY "view_conversation_participants"
  ON public.conversation_participants FOR SELECT
  USING (
    conversation_id IN (
      SELECT DISTINCT conversation_id 
      FROM conversation_participants 
      WHERE user_id = auth.uid()
    )
  );

-- Policy 3: Allow inserting
CREATE POLICY "insert_participants"
  ON public.conversation_participants FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

-- Policy 4: Allow updating own record
CREATE POLICY "update_own_participant"
  ON public.conversation_participants FOR UPDATE
  USING (user_id = auth.uid());

SELECT 'All policies recreated successfully!' AS status;
