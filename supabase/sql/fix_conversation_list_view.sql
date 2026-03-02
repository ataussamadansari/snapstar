-- ============================================
-- FIX CONVERSATION_LIST VIEW
-- ============================================
-- This fixes the null values issue in other_participants

-- Drop the old view
DROP VIEW IF EXISTS conversation_list;

-- Recreate with proper null handling
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
  -- Use COALESCE to return empty array instead of null
  COALESCE(
    (
      SELECT json_agg(json_build_object(
        'id', u.id,
        'username', COALESCE(u.username, ''),
        'name', COALESCE(u.name, ''),
        'email', COALESCE(u.email, ''),
        'avatar_url', u.avatar_url,
        'bio', u.bio,
        'role', u.role,
        'posts_count', COALESCE(u.posts_count, 0),
        'subscriber_count', COALESCE(u.subscriber_count, 0),
        'subscribing_count', COALESCE(u.subscribing_count, 0),
        'created_at', u.created_at,
        'updated_at', u.updated_at
      ))
      FROM conversation_participants cp2
      JOIN users u ON cp2.user_id = u.id
      WHERE cp2.conversation_id = c.id
        AND cp2.user_id != cp.user_id
    ),
    '[]'::json
  ) AS other_participants
FROM conversations c
JOIN conversation_participants cp ON c.id = cp.conversation_id
ORDER BY c.updated_at DESC;

-- Grant permissions
GRANT SELECT ON conversation_list TO authenticated;

SELECT 'Conversation list view fixed!' AS status;
