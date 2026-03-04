-- Cleanup duplicate / legacy / conflicting DB objects
-- Safe to run multiple times.
-- Run this AFTER:
--   1) instagram_schema_patch_v2.sql
--   2) hashtags_search_feed_ranking.sql
--   3) notification_queue_edge_functions.sql

-- =========================================================
-- 1) Duplicate check constraints / unique constraints
-- =========================================================
alter table if exists public.subscribes drop constraint if exists no_self_subscribe;
alter table if exists public.subscribes drop constraint if exists subscribes_no_self_follow;
-- keep: ck_subscribes_no_self

alter table if exists public.likes drop constraint if exists unique_like;
alter table if exists public.shares drop constraint if exists unique_share;
alter table if exists public.story_views drop constraint if exists unique_story_view;
-- keep canonical unique constraints/indexes from schema patch

-- =========================================================
-- 2) Duplicate indexes (same keys, different names)
-- =========================================================
drop index if exists public.idx_likes_post_user_unique;
drop index if exists public.unique_like;

drop index if exists public.idx_shares_post_user_unique;
drop index if exists public.unique_share;

drop index if exists public.idx_story_views_story_viewer_unique;
drop index if exists public.unique_story_view;

drop index if exists public.idx_subscribes_pair_unique;
drop index if exists public.uq_subscribes_subscriber_subscribed;

drop index if exists public.idx_user_push_tokens_user_token_unique;
drop index if exists public.uq_user_push_tokens_user_token;

drop index if exists public.idx_users_username_search;
-- keep: idx_users_username_trgm

drop index if exists public.idx_posts_caption_search;
-- keep: idx_posts_caption_trgm

drop index if exists public.idx_posts_feed_created;
drop index if exists public.idx_posts_created_at;
-- keep: idx_posts_created

drop index if exists public.idx_posts_user;
drop index if exists public.idx_posts_user_id;
-- keep: idx_posts_user_created

drop index if exists public.idx_stories_expires_at;
-- keep: idx_stories_expiry

drop index if exists public.idx_story_user;
drop index if exists public.idx_stories_user_id;
drop index if exists public.idx_story_user_expiry;
-- keep: idx_stories_user_expiry

drop index if exists public.idx_story_views_story_id;
-- keep: idx_story_views_story_created

drop index if exists public.idx_subscribes_subscriber_id;
drop index if exists public.idx_subscribes_subscribed_id;
-- keep: idx_subscribes_subscriber / idx_subscribes_subscribed

drop index if exists public.idx_comments_post;
drop index if exists public.idx_comments_post_id;
-- keep: idx_comments_post_created

drop index if exists public.idx_messages_conversation_id;
-- keep: idx_messages_conversation_created

drop index if exists public.idx_notifications_user_read;
-- keep: idx_notifications_user_unread + idx_notifications_user_created

-- =========================================================
-- 3) Duplicate / conflicting RLS policies
-- =========================================================
-- keep canonical policies created by latest patch scripts:
-- users_read, users_update_self, posts_read, posts_owner_all, comments_read, comments_owner_all, etc.

-- generic old policies
drop policy if exists "Enable delete for users based on user_id" on public.users;
drop policy if exists "Enable delete for users based on user_id" on public.comments;
drop policy if exists "Enable delete for users based on user_id" on public.subscribes;
drop policy if exists "Enable delete for users based on user_id" on public.posts;
drop policy if exists "Enable insert for authenticated users only" on public.shares;
drop policy if exists "Enable insert for authenticated users only" on public.users;
drop policy if exists "Enable insert for authenticated users only" on public.subscribes;
drop policy if exists "Enable insert for authenticated users only" on public.posts;
drop policy if exists "Enable insert for authenticated users only" on public.comments;
drop policy if exists "Enable insert for users based on user_id" on public.posts;
drop policy if exists "Enable read access for all users" on public.shares;
drop policy if exists "Enable read access for all users" on public.subscribes;
drop policy if exists "Enable read access for all users" on public.comments;
drop policy if exists "Enable read access for all users" on public.posts;
drop policy if exists "Enable read access for all users" on public.users;
drop policy if exists "Enable update for authenticated users only" on public.comments;
drop policy if exists "Enable update for users based on id" on public.users;
drop policy if exists "Policy with table joins" on public.subscribes;

-- duplicate named variants
drop policy if exists comments_owner_write on public.comments;
drop policy if exists comments_public_read on public.comments;
drop policy if exists likes_owner_write on public.likes;
drop policy if exists likes_public_read on public.likes;
drop policy if exists posts_owner_write on public.posts;
drop policy if exists posts_public_read on public.posts;
drop policy if exists shares_owner_write on public.shares;
drop policy if exists shares_public_read on public.shares;
drop policy if exists subscribes_owner_write on public.subscribes;
drop policy if exists subscribes_public_read on public.subscribes;
drop policy if exists users_public_read on public.users;
drop policy if exists users_self_update on public.users;
drop policy if exists stories_owner_write on public.stories;
drop policy if exists stories_read_active on public.stories;
drop policy if exists story_views_insert_self on public.story_views;
drop policy if exists story_views_select on public.story_views;
drop policy if exists notifications_owner_read on public.notifications;
drop policy if exists notifications_select_own on public.notifications;
drop policy if exists notifications_update_own on public.notifications;

-- legacy push-token policies when owner_all exists
drop policy if exists "read own push tokens" on public.user_push_tokens;
drop policy if exists "insert own push tokens" on public.user_push_tokens;
drop policy if exists "update own push tokens" on public.user_push_tokens;
drop policy if exists "delete own push tokens" on public.user_push_tokens;

-- risky notification insert policy (conflicts with server-side queue model)
drop policy if exists notifications_insert_actor on public.notifications;

-- =========================================================
-- 4) Duplicate/legacy triggers
-- =========================================================
-- keep latest counter triggers:
-- trg_likes_counter, trg_comments_counter, trg_subscribes_counter
drop trigger if exists trg_increment_like on public.likes;
drop trigger if exists trg_decrement_like on public.likes;
drop trigger if exists trg_increment_comment on public.comments;
drop trigger if exists trg_decrement_comment on public.comments;
drop trigger if exists trg_increment_subscribe on public.subscribes;
drop trigger if exists trg_decrement_subscribe on public.subscribes;
drop trigger if exists trg_increment_share on public.shares;
drop trigger if exists trg_decrement_share on public.shares;
drop trigger if exists trg_increment_posts on public.posts;
drop trigger if exists trg_decrement_posts on public.posts;

-- keep only one updated_at trigger per table (set_row_updated_at)
drop trigger if exists trg_users_set_updated_at on public.users;
drop trigger if exists trg_posts_set_updated_at on public.posts;
drop trigger if exists trg_comments_set_updated_at on public.comments;
drop trigger if exists trg_notifications_set_updated_at on public.notifications;
drop trigger if exists trg_messages_set_updated_at on public.messages;
drop trigger if exists trg_subscribes_set_updated_at on public.subscribes;
drop trigger if exists trg_user_push_tokens_set_updated_at on public.user_push_tokens;

-- avoid double-notification (app service already creates notifications)
drop trigger if exists trg_notify_like_insert on public.likes;
drop trigger if exists trg_notify_comment_insert on public.comments;
drop trigger if exists trg_notify_subscribe_insert on public.subscribes;
drop trigger if exists trg_notify_subscribe_delete on public.subscribes;

-- =========================================================
-- 5) Legacy helper functions that become unused after trigger cleanup
-- =========================================================
drop function if exists public.increment_like_count();
drop function if exists public.decrement_like_count();
drop function if exists public.increment_comment_count();
drop function if exists public.decrement_comment_count();
drop function if exists public.increment_subscribe_count();
drop function if exists public.decrement_subscribe_count();
drop function if exists public.increment_share_count();
drop function if exists public.decrement_share_count();
drop function if exists public.increment_posts_count();
drop function if exists public.decrement_posts_count();

drop function if exists public.set_updated_at();
drop function if exists public.set_notifications_updated_at();

-- optional old story cleanup fn (keep cleanup_expired_stories)
drop function if exists public.delete_expired_stories();
