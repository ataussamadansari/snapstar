-- ============================================
-- DELETE ALL CHAT TABLE POLICIES
-- ============================================

-- Disable RLS temporarily
ALTER TABLE public.conversations DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversation_participants DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.message_reads DISABLE ROW LEVEL SECURITY;

-- Delete all policies from conversations
DO $$ 
DECLARE
    r RECORD;
BEGIN
    FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'conversations') 
    LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || r.policyname || '" ON public.conversations CASCADE';
    END LOOP;
END $$;

-- Delete all policies from conversation_participants
DO $$ 
DECLARE
    r RECORD;
BEGIN
    FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'conversation_participants') 
    LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || r.policyname || '" ON public.conversation_participants CASCADE';
    END LOOP;
END $$;

-- Delete all policies from messages
DO $$ 
DECLARE
    r RECORD;
BEGIN
    FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'messages') 
    LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || r.policyname || '" ON public.messages CASCADE';
    END LOOP;
END $$;

-- Delete all policies from message_reads
DO $$ 
DECLARE
    r RECORD;
BEGIN
    FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'message_reads') 
    LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || r.policyname || '" ON public.message_reads CASCADE';
    END LOOP;
END $$;

-- Verify all policies deleted
SELECT 
    'conversations' as table_name,
    COUNT(*) as remaining_policies
FROM pg_policies 
WHERE tablename = 'conversations'
UNION ALL
SELECT 
    'conversation_participants',
    COUNT(*)
FROM pg_policies 
WHERE tablename = 'conversation_participants'
UNION ALL
SELECT 
    'messages',
    COUNT(*)
FROM pg_policies 
WHERE tablename = 'messages'
UNION ALL
SELECT 
    'message_reads',
    COUNT(*)
FROM pg_policies 
WHERE tablename = 'message_reads';

SELECT 'All chat policies deleted! RLS is now DISABLED for all chat tables.' AS status;
