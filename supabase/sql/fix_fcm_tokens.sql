-- Fix FCM token management
-- This script helps manage FCM tokens properly

-- 1. Add unique constraint to prevent duplicate active tokens per user/platform
-- First, deactivate duplicate tokens (keep only the most recent one per user/platform)
UPDATE user_push_tokens upt1
SET is_active = false
WHERE is_active = true
  AND EXISTS (
    SELECT 1
    FROM user_push_tokens upt2
    WHERE upt2.user_id = upt1.user_id
      AND upt2.platform = upt1.platform
      AND upt2.is_active = true
      AND upt2.created_at > upt1.created_at
  );

-- 2. Create or replace the upsert_push_token function
CREATE OR REPLACE FUNCTION upsert_push_token(
  p_token TEXT,
  p_platform TEXT DEFAULT 'android'
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID;
BEGIN
  -- Get current user ID
  v_user_id := auth.uid();
  
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- Deactivate all other tokens for this user on this platform
  UPDATE user_push_tokens
  SET is_active = false,
      updated_at = NOW()
  WHERE user_id = v_user_id
    AND platform = p_platform
    AND token != p_token;

  -- Insert or update the current token
  INSERT INTO user_push_tokens (
    user_id,
    token,
    platform,
    is_active,
    created_at,
    updated_at
  )
  VALUES (
    v_user_id,
    p_token,
    p_platform,
    true,
    NOW(),
    NOW()
  )
  ON CONFLICT (user_id, token)
  DO UPDATE SET
    is_active = true,
    platform = p_platform,
    updated_at = NOW();
END;
$$;

-- 3. Create or replace the deactivate_push_token function
CREATE OR REPLACE FUNCTION deactivate_push_token(
  p_token TEXT
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID;
BEGIN
  -- Get current user ID
  v_user_id := auth.uid();
  
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- Deactivate the token
  UPDATE user_push_tokens
  SET is_active = false,
      updated_at = NOW()
  WHERE user_id = v_user_id
    AND token = p_token;
END;
$$;

-- 4. Add unique constraint if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'user_push_tokens_user_id_token_key'
  ) THEN
    ALTER TABLE user_push_tokens
    ADD CONSTRAINT user_push_tokens_user_id_token_key
    UNIQUE (user_id, token);
  END IF;
END $$;

-- 5. Create index for better performance
CREATE INDEX IF NOT EXISTS idx_user_push_tokens_user_platform_active
ON user_push_tokens (user_id, platform, is_active)
WHERE is_active = true;

-- 6. Clean up old inactive tokens (optional - keeps last 30 days)
-- Uncomment if you want to automatically clean up old tokens
-- DELETE FROM user_push_tokens
-- WHERE is_active = false
--   AND updated_at < NOW() - INTERVAL '30 days';
