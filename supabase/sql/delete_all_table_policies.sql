-- ============================================
-- DELETE ALL POLICIES FROM ALL TABLES
-- ============================================
-- WARNING: This will remove ALL RLS policies from ALL tables
-- Use with caution - this is for testing only!

-- Disable RLS on all tables
ALTER TABLE public.users DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.posts DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.comments DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.likes DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.shares DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.stories DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.story_views DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscribes DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_push_tokens DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversations DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversation_participants DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.message_reads DISABLE ROW LEVEL SECURITY;

-- Delete all policies from all tables
DO $$ 
DECLARE
    r RECORD;
BEGIN
    -- Loop through all tables and drop their policies
    FOR r IN (
        SELECT DISTINCT tablename 
        FROM pg_policies 
        WHERE schemaname = 'public'
    ) 
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS ALL ON public.%I CASCADE', r.tablename);
        
        -- Also drop individual policies
        FOR r IN (
            SELECT policyname, tablename 
            FROM pg_policies 
            WHERE schemaname = 'public' AND tablename = r.tablename
        ) 
        LOOP
            EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I CASCADE', r.policyname, r.tablename);
        END LOOP;
    END LOOP;
END $$;

-- Verify all policies deleted
SELECT 
    tablename,
    COUNT(*) as remaining_policies
FROM pg_policies 
WHERE schemaname = 'public'
GROUP BY tablename
ORDER BY tablename;

SELECT 'All policies deleted from all tables! RLS is now DISABLED.' AS status;
