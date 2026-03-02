-- ============================================
-- CHAT FEATURE - Complete Database Schema
-- ============================================

-- 1. CONVERSATIONS TABLE
-- Stores chat conversations between users
CREATE TABLE IF NOT EXISTS public.conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  last_message_at TIMESTAMPTZ,
  last_message_text TEXT,
  last_message_type TEXT DEFAULT 'text'
);

-- 2. CONVERSATION PARTICIPANTS TABLE
-- Maps users to conversations (supports group chats)
CREATE TABLE IF NOT EXISTS public.conversation_participants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  last_read_at TIMESTAMPTZ,
  unread_count INTEGER NOT NULL DEFAULT 0,
  is_muted BOOLEAN NOT NULL DEFAULT false,
  is_archived BOOLEAN NOT NULL DEFAULT false,
  UNIQUE(conversation_id, user_id)
);

-- 3. MESSAGES TABLE
-- Stores all chat messages
CREATE TABLE IF NOT EXISTS public.messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  message_type TEXT NOT NULL DEFAULT 'text', -- text, image, video, post, reel, story
  message_text TEXT,
  media_url TEXT,
  thumbnail_url TEXT,
  
  -- For shared posts/reels
  shared_post_id UUID REFERENCES public.posts(id) ON DELETE SET NULL,
  shared_post_caption TEXT,
  shared_post_media_url TEXT,
  shared_post_thumbnail_url TEXT,
  shared_post_user_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
  
  is_deleted BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4. MESSAGE READS TABLE
-- Tracks who has read which messages
CREATE TABLE IF NOT EXISTS public.message_reads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  message_id UUID NOT NULL REFERENCES public.messages(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  read_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(message_id, user_id)
);

-- ============================================
-- INDEXES FOR PERFORMANCE
-- ============================================

CREATE INDEX IF NOT EXISTS idx_conversations_updated_at ON public.conversations(updated_at DESC);
CREATE INDEX IF NOT EXISTS idx_conversation_participants_user_id ON public.conversation_participants(user_id);
CREATE INDEX IF NOT EXISTS idx_conversation_participants_conversation_id ON public.conversation_participants(conversation_id);
CREATE INDEX IF NOT EXISTS idx_messages_conversation_id ON public.messages(conversation_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_sender_id ON public.messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_message_reads_message_id ON public.message_reads(message_id);
CREATE INDEX IF NOT EXISTS idx_message_reads_user_id ON public.message_reads(user_id);

-- ============================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================

-- Enable RLS
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversation_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.message_reads ENABLE ROW LEVEL SECURITY;

-- Conversations: Users can only see conversations they're part of
CREATE POLICY "Users can view their conversations"
  ON public.conversations FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.conversation_participants
      WHERE conversation_id = conversations.id
        AND user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update their conversations"
  ON public.conversations FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.conversation_participants
      WHERE conversation_id = conversations.id
        AND user_id = auth.uid()
    )
  );

-- Conversation Participants: Users can view participants of their conversations
-- Fixed to avoid infinite recursion
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

CREATE POLICY "Users can insert conversation participants"
  ON public.conversation_participants FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Users can update their participant record"
  ON public.conversation_participants FOR UPDATE
  USING (user_id = auth.uid());

-- Messages: Users can only see messages in their conversations
CREATE POLICY "Users can view messages in their conversations"
  ON public.messages FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.conversation_participants
      WHERE conversation_id = messages.conversation_id
        AND user_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert messages in their conversations"
  ON public.messages FOR INSERT
  WITH CHECK (
    sender_id = auth.uid() AND
    EXISTS (
      SELECT 1 FROM public.conversation_participants
      WHERE conversation_id = messages.conversation_id
        AND user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update their own messages"
  ON public.messages FOR UPDATE
  USING (sender_id = auth.uid());

-- Message Reads: Users can manage their own read receipts
CREATE POLICY "Users can view message reads"
  ON public.message_reads FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.messages m
      JOIN public.conversation_participants cp ON m.conversation_id = cp.conversation_id
      WHERE m.id = message_reads.message_id
        AND cp.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert their own read receipts"
  ON public.message_reads FOR INSERT
  WITH CHECK (user_id = auth.uid());

-- ============================================
-- FUNCTIONS
-- ============================================

-- Function: Get or create conversation between two users
CREATE OR REPLACE FUNCTION get_or_create_conversation(
  p_other_user_id UUID
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_current_user_id UUID;
  v_conversation_id UUID;
BEGIN
  v_current_user_id := auth.uid();
  
  IF v_current_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;
  
  IF v_current_user_id = p_other_user_id THEN
    RAISE EXCEPTION 'Cannot create conversation with yourself';
  END IF;
  
  -- Check if conversation already exists
  SELECT cp1.conversation_id INTO v_conversation_id
  FROM conversation_participants cp1
  JOIN conversation_participants cp2 ON cp1.conversation_id = cp2.conversation_id
  WHERE cp1.user_id = v_current_user_id
    AND cp2.user_id = p_other_user_id
    AND (
      SELECT COUNT(*) FROM conversation_participants
      WHERE conversation_id = cp1.conversation_id
    ) = 2
  LIMIT 1;
  
  -- If conversation exists, return it
  IF v_conversation_id IS NOT NULL THEN
    RETURN v_conversation_id;
  END IF;
  
  -- Create new conversation
  INSERT INTO conversations (created_at, updated_at)
  VALUES (NOW(), NOW())
  RETURNING id INTO v_conversation_id;
  
  -- Add both participants
  INSERT INTO conversation_participants (conversation_id, user_id, joined_at)
  VALUES 
    (v_conversation_id, v_current_user_id, NOW()),
    (v_conversation_id, p_other_user_id, NOW());
  
  RETURN v_conversation_id;
END;
$$;

-- Function: Send message
CREATE OR REPLACE FUNCTION send_message(
  p_conversation_id UUID,
  p_message_type TEXT,
  p_message_text TEXT DEFAULT NULL,
  p_media_url TEXT DEFAULT NULL,
  p_thumbnail_url TEXT DEFAULT NULL,
  p_shared_post_id UUID DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_current_user_id UUID;
  v_message_id UUID;
  v_shared_post_caption TEXT;
  v_shared_post_media_url TEXT;
  v_shared_post_thumbnail_url TEXT;
  v_shared_post_user_id UUID;
BEGIN
  v_current_user_id := auth.uid();
  
  IF v_current_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;
  
  -- Verify user is participant
  IF NOT EXISTS (
    SELECT 1 FROM conversation_participants
    WHERE conversation_id = p_conversation_id
      AND user_id = v_current_user_id
  ) THEN
    RAISE EXCEPTION 'Not a participant of this conversation';
  END IF;
  
  -- Get shared post details if applicable
  IF p_shared_post_id IS NOT NULL THEN
    SELECT caption, media_urls[1], thumbnail_urls[1], user_id
    INTO v_shared_post_caption, v_shared_post_media_url, v_shared_post_thumbnail_url, v_shared_post_user_id
    FROM posts
    WHERE id = p_shared_post_id;
  END IF;
  
  -- Insert message
  INSERT INTO messages (
    conversation_id,
    sender_id,
    message_type,
    message_text,
    media_url,
    thumbnail_url,
    shared_post_id,
    shared_post_caption,
    shared_post_media_url,
    shared_post_thumbnail_url,
    shared_post_user_id,
    created_at
  )
  VALUES (
    p_conversation_id,
    v_current_user_id,
    p_message_type,
    p_message_text,
    p_media_url,
    p_thumbnail_url,
    p_shared_post_id,
    v_shared_post_caption,
    v_shared_post_media_url,
    v_shared_post_thumbnail_url,
    v_shared_post_user_id,
    NOW()
  )
  RETURNING id INTO v_message_id;
  
  -- Update conversation
  UPDATE conversations
  SET 
    updated_at = NOW(),
    last_message_at = NOW(),
    last_message_text = COALESCE(p_message_text, p_message_type),
    last_message_type = p_message_type
  WHERE id = p_conversation_id;
  
  -- Increment unread count for other participants
  UPDATE conversation_participants
  SET unread_count = unread_count + 1
  WHERE conversation_id = p_conversation_id
    AND user_id != v_current_user_id;
  
  RETURN v_message_id;
END;
$$;

-- Function: Mark messages as read
CREATE OR REPLACE FUNCTION mark_messages_read(
  p_conversation_id UUID,
  p_up_to_message_id UUID DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_current_user_id UUID;
BEGIN
  v_current_user_id := auth.uid();
  
  IF v_current_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;
  
  -- Insert read receipts for unread messages
  INSERT INTO message_reads (message_id, user_id, read_at)
  SELECT m.id, v_current_user_id, NOW()
  FROM messages m
  WHERE m.conversation_id = p_conversation_id
    AND m.sender_id != v_current_user_id
    AND (p_up_to_message_id IS NULL OR m.created_at <= (
      SELECT created_at FROM messages WHERE id = p_up_to_message_id
    ))
    AND NOT EXISTS (
      SELECT 1 FROM message_reads
      WHERE message_id = m.id AND user_id = v_current_user_id
    )
  ON CONFLICT (message_id, user_id) DO NOTHING;
  
  -- Update participant record
  UPDATE conversation_participants
  SET 
    last_read_at = NOW(),
    unread_count = 0
  WHERE conversation_id = p_conversation_id
    AND user_id = v_current_user_id;
END;
$$;

-- ============================================
-- TRIGGERS
-- ============================================

-- Trigger: Update conversation timestamp when message is sent
CREATE OR REPLACE FUNCTION update_conversation_on_message()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE conversations
  SET 
    updated_at = NEW.created_at,
    last_message_at = NEW.created_at,
    last_message_text = COALESCE(NEW.message_text, NEW.message_type),
    last_message_type = NEW.message_type
  WHERE id = NEW.conversation_id;
  
  RETURN NEW;
END;
$$;

CREATE TRIGGER trigger_update_conversation_on_message
  AFTER INSERT ON messages
  FOR EACH ROW
  EXECUTE FUNCTION update_conversation_on_message();

-- Trigger: Increment unread count when message is sent
CREATE OR REPLACE FUNCTION increment_unread_count()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE conversation_participants
  SET unread_count = unread_count + 1
  WHERE conversation_id = NEW.conversation_id
    AND user_id != NEW.sender_id;
  
  RETURN NEW;
END;
$$;

CREATE TRIGGER trigger_increment_unread_count
  AFTER INSERT ON messages
  FOR EACH ROW
  EXECUTE FUNCTION increment_unread_count();

-- ============================================
-- REALTIME PUBLICATION
-- ============================================

-- Enable realtime for chat tables
ALTER PUBLICATION supabase_realtime ADD TABLE conversations;
ALTER PUBLICATION supabase_realtime ADD TABLE conversation_participants;
ALTER PUBLICATION supabase_realtime ADD TABLE messages;
ALTER PUBLICATION supabase_realtime ADD TABLE message_reads;

-- Grant necessary permissions
GRANT SELECT, INSERT, UPDATE ON public.conversations TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.conversation_participants TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.messages TO authenticated;
GRANT SELECT, INSERT ON public.message_reads TO authenticated;

-- ============================================
-- HELPER VIEWS
-- ============================================

-- View: Conversations with participant details
CREATE OR REPLACE VIEW conversation_list AS
SELECT 
  c.id,
  c.created_at,
  c.updated_at,
  c.last_message_at,
  c.last_message_text,
  c.last_message_type,
  cp.user_id AS current_user_id,
  cp.unread_count,
  cp.is_muted,
  cp.is_archived,
  cp.last_read_at,
  -- Other participant details (for 1-on-1 chats)
  (
    SELECT json_agg(json_build_object(
      'id', u.id,
      'username', u.username,
      'name', u.name,
      'avatar_url', u.avatar_url
    ))
    FROM conversation_participants cp2
    JOIN users u ON cp2.user_id = u.id
    WHERE cp2.conversation_id = c.id
      AND cp2.user_id != cp.user_id
  ) AS other_participants
FROM conversations c
JOIN conversation_participants cp ON c.id = cp.conversation_id
WHERE cp.user_id = auth.uid()
ORDER BY c.updated_at DESC;

COMMENT ON TABLE conversations IS 'Stores chat conversations';
COMMENT ON TABLE conversation_participants IS 'Maps users to conversations';
COMMENT ON TABLE messages IS 'Stores all chat messages';
COMMENT ON TABLE message_reads IS 'Tracks message read receipts';
