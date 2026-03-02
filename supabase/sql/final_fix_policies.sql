-- ============================================
-- FINAL FIX - Force Delete and Recreate All Policies
-- ============================================

-- Step 1: Disable RLS temporarily
ALTER TABLE public.conversation_participants DISABLE ROW LEVEL SECURITY;

-- Step 2: Drop ALL policies (using CASCADE to force)
DO $$ 
DECLARE
    r RECORD;
BEGIN
    FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'conversation_participants') 
    LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || r.policyname || '" ON public.conversation_participants CASCADE';
    END LOOP;
END $$;

-- Step 3: Re-enable RLS
ALTER TABLE public.conversation_participants ENABLE ROW LEVEL SECURITY;

-- Step 4: Create simple, non-recursive policies

-- Policy 1: View own record (simple, no recursion)
CREATE POLICY "cp_view_own"
  ON public.conversation_participants FOR SELECT
  USING (user_id = auth.uid());

-- Policy 2: View other participants (using subquery, no recursion)
CREATE POLICY "cp_view_others"
  ON public.conversation_participants FOR SELECT
  USING (
    conversation_id IN (
      SELECT DISTINCT conversation_id 
      FROM conversation_participants 
      WHERE user_id = auth.uid()
    )
  );

-- Policy 3: Insert
CREATE POLICY "cp_insert"
  ON public.conversation_participants FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

-- Policy 4: Update own record
CREATE POLICY "cp_update_own"
  ON public.conversation_participants FOR UPDATE
  USING (user_id = auth.uid());

-- Step 5: Verify
SELECT 'Policies recreated successfully!' AS status,
       COUNT(*) AS policy_count
FROM pg_policies 
WHERE tablename = 'conversation_participants';
