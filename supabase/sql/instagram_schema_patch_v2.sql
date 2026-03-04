-- Instagram-like hardening patch for existing Snapstar schema.
-- Apply on staging first, then production.

create extension if not exists pg_trgm;

-- =========================================================
-- 1) Fix dangerous defaults (important)
-- =========================================================
alter table public.comments alter column post_id drop default;
alter table public.comments alter column parent_id drop default;
alter table public.likes alter column post_id drop default;
alter table public.shares alter column post_id drop default;
alter table public.subscribes alter column subscribed_id drop default;

-- =========================================================
-- 2) Data integrity guards
-- =========================================================
create unique index if not exists uq_likes_post_user
  on public.likes(post_id, user_id);

create unique index if not exists uq_shares_post_user
  on public.shares(post_id, user_id);

create unique index if not exists uq_story_views_story_viewer
  on public.story_views(story_id, viewer_id);

create unique index if not exists uq_subscribes_subscriber_subscribed
  on public.subscribes(subscriber_id, subscribed_id);

create unique index if not exists uq_conversation_participants
  on public.conversation_participants(conversation_id, user_id);

create unique index if not exists uq_message_reads_message_user
  on public.message_reads(message_id, user_id);

alter table public.subscribes
  drop constraint if exists ck_subscribes_no_self;
alter table public.subscribes
  add constraint ck_subscribes_no_self
  check (subscriber_id <> subscribed_id);

alter table public.posts
  drop constraint if exists ck_posts_media_type;
alter table public.posts
  add constraint ck_posts_media_type
  check (media_type is null or media_type in ('image', 'video'));

alter table public.stories
  drop constraint if exists ck_stories_media_len_match;
alter table public.stories
  add constraint ck_stories_media_len_match
  check (cardinality(media_urls) = cardinality(media_types));

-- =========================================================
-- 3) Performance indexes
-- =========================================================
create index if not exists idx_posts_created
  on public.posts(created_at desc, id desc)
  where is_deleted = false;

create index if not exists idx_posts_user_created
  on public.posts(user_id, created_at desc, id desc)
  where is_deleted = false;

create index if not exists idx_posts_video_created
  on public.posts(created_at desc, id desc)
  where is_deleted = false and media_type = 'video';

create index if not exists idx_comments_post_created
  on public.comments(post_id, created_at desc, id desc);

create index if not exists idx_likes_post_created
  on public.likes(post_id, created_at desc, id desc);

create index if not exists idx_stories_user_expiry
  on public.stories(user_id, expires_at desc, created_at desc);

create index if not exists idx_story_views_story_created
  on public.story_views(story_id, created_at desc, id desc);

create index if not exists idx_subscribes_subscriber
  on public.subscribes(subscriber_id, created_at desc);

create index if not exists idx_subscribes_subscribed
  on public.subscribes(subscribed_id, created_at desc);

create index if not exists idx_notifications_user_created
  on public.notifications(user_id, created_at desc, id desc)
  where is_deleted = false;

create index if not exists idx_notifications_user_unread
  on public.notifications(user_id, is_read, created_at desc)
  where is_deleted = false;

create index if not exists idx_messages_conversation_created
  on public.messages(conversation_id, created_at desc, id desc)
  where is_deleted = false;

create index if not exists idx_messages_sender_created
  on public.messages(sender_id, created_at desc);

create index if not exists idx_users_username_trgm
  on public.users using gin (username gin_trgm_ops);

create index if not exists idx_posts_caption_trgm
  on public.posts using gin (caption gin_trgm_ops)
  where is_deleted = false;

create index if not exists idx_user_push_tokens_active
  on public.user_push_tokens(user_id, is_active, updated_at desc);

create unique index if not exists uq_user_push_tokens_user_token
  on public.user_push_tokens(user_id, token);

-- =========================================================
-- 4) updated_at auto-maintenance
-- =========================================================
create or replace function public.set_row_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_users_updated_at on public.users;
create trigger trg_users_updated_at
before update on public.users
for each row execute function public.set_row_updated_at();

drop trigger if exists trg_posts_updated_at on public.posts;
create trigger trg_posts_updated_at
before update on public.posts
for each row execute function public.set_row_updated_at();

drop trigger if exists trg_comments_updated_at on public.comments;
create trigger trg_comments_updated_at
before update on public.comments
for each row execute function public.set_row_updated_at();

drop trigger if exists trg_notifications_updated_at on public.notifications;
create trigger trg_notifications_updated_at
before update on public.notifications
for each row execute function public.set_row_updated_at();

drop trigger if exists trg_messages_updated_at on public.messages;
create trigger trg_messages_updated_at
before update on public.messages
for each row execute function public.set_row_updated_at();

drop trigger if exists trg_subscribes_updated_at on public.subscribes;
create trigger trg_subscribes_updated_at
before update on public.subscribes
for each row execute function public.set_row_updated_at();

drop trigger if exists trg_user_push_tokens_updated_at on public.user_push_tokens;
create trigger trg_user_push_tokens_updated_at
before update on public.user_push_tokens
for each row execute function public.set_row_updated_at();

-- =========================================================
-- 5) Counter triggers (authoritative counters)
-- =========================================================
create or replace function public.trg_update_post_like_count()
returns trigger
language plpgsql
as $$
begin
  if tg_op = 'INSERT' then
    update public.posts
      set like_count = coalesce(like_count, 0) + 1
      where id = new.post_id;
    return new;
  elsif tg_op = 'DELETE' then
    update public.posts
      set like_count = greatest(coalesce(like_count, 0) - 1, 0)
      where id = old.post_id;
    return old;
  end if;
  return null;
end;
$$;

drop trigger if exists trg_likes_counter on public.likes;
create trigger trg_likes_counter
after insert or delete on public.likes
for each row execute function public.trg_update_post_like_count();

create or replace function public.trg_update_post_comment_count()
returns trigger
language plpgsql
as $$
begin
  if tg_op = 'INSERT' then
    update public.posts
      set comment_count = coalesce(comment_count, 0) + 1
      where id = new.post_id;
    return new;
  elsif tg_op = 'DELETE' then
    update public.posts
      set comment_count = greatest(coalesce(comment_count, 0) - 1, 0)
      where id = old.post_id;
    return old;
  end if;
  return null;
end;
$$;

drop trigger if exists trg_comments_counter on public.comments;
create trigger trg_comments_counter
after insert or delete on public.comments
for each row execute function public.trg_update_post_comment_count();

create or replace function public.trg_update_subscribe_counts()
returns trigger
language plpgsql
as $$
begin
  if tg_op = 'INSERT' then
    update public.users
      set subscriber_count = coalesce(subscriber_count, 0) + 1
      where id = new.subscribed_id;

    update public.users
      set subscribing_count = coalesce(subscribing_count, 0) + 1
      where id = new.subscriber_id;

    return new;
  elsif tg_op = 'DELETE' then
    update public.users
      set subscriber_count = greatest(coalesce(subscriber_count, 0) - 1, 0)
      where id = old.subscribed_id;

    update public.users
      set subscribing_count = greatest(coalesce(subscribing_count, 0) - 1, 0)
      where id = old.subscriber_id;

    return old;
  end if;
  return null;
end;
$$;

drop trigger if exists trg_subscribes_counter on public.subscribes;
create trigger trg_subscribes_counter
after insert or delete on public.subscribes
for each row execute function public.trg_update_subscribe_counts();

-- =========================================================
-- 6) Realtime publication safety
-- =========================================================
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'posts'
  ) then
    alter publication supabase_realtime add table public.posts;
  end if;
end $$;

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'comments'
  ) then
    alter publication supabase_realtime add table public.comments;
  end if;
end $$;

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'likes'
  ) then
    alter publication supabase_realtime add table public.likes;
  end if;
end $$;

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'notifications'
  ) then
    alter publication supabase_realtime add table public.notifications;
  end if;
end $$;

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'messages'
  ) then
    alter publication supabase_realtime add table public.messages;
  end if;
end $$;

-- =========================================================
-- 7) Background jobs support
-- =========================================================
create table if not exists public.notification_jobs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  actor_id uuid references public.users(id) on delete set null,
  type text not null,
  payload jsonb not null default '{}'::jsonb,
  status text not null default 'queued',
  attempts integer not null default 0,
  next_attempt_at timestamptz not null default now(),
  last_error text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_notification_jobs_queue
  on public.notification_jobs(status, next_attempt_at, created_at);

create table if not exists public.rate_limits (
  id bigserial primary key,
  user_id uuid,
  ip inet,
  action text not null,
  bucket_start timestamptz not null,
  count integer not null default 1,
  created_at timestamptz not null default now(),
  unique(user_id, action, bucket_start),
  unique(ip, action, bucket_start)
);

create index if not exists idx_rate_limits_action_bucket
  on public.rate_limits(action, bucket_start desc);

create or replace function public.cleanup_expired_stories()
returns integer
language plpgsql
security definer
as $$
declare
  v_deleted integer := 0;
begin
  delete from public.story_views sv
  using public.stories s
  where sv.story_id = s.id
    and s.expires_at < now() - interval '2 days';

  with gone as (
    delete from public.stories
    where expires_at < now() - interval '2 days'
    returning 1
  )
  select count(*) into v_deleted from gone;

  return v_deleted;
end;
$$;

-- =========================================================
-- 8) RLS baseline
-- =========================================================
alter table public.users enable row level security;
alter table public.posts enable row level security;
alter table public.comments enable row level security;
alter table public.likes enable row level security;
alter table public.shares enable row level security;
alter table public.stories enable row level security;
alter table public.story_views enable row level security;
alter table public.subscribes enable row level security;
alter table public.notifications enable row level security;
alter table public.user_push_tokens enable row level security;
alter table public.conversations enable row level security;
alter table public.conversation_participants enable row level security;
alter table public.messages enable row level security;
alter table public.message_reads enable row level security;

drop policy if exists users_read on public.users;
create policy users_read on public.users
for select to authenticated
using (true);

drop policy if exists users_update_self on public.users;
create policy users_update_self on public.users
for update to authenticated
using (id = auth.uid())
with check (id = auth.uid());

drop policy if exists posts_read on public.posts;
create policy posts_read on public.posts
for select to authenticated
using (is_deleted = false);

drop policy if exists posts_owner_all on public.posts;
create policy posts_owner_all on public.posts
for all to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

drop policy if exists comments_read on public.comments;
create policy comments_read on public.comments
for select to authenticated
using (true);

drop policy if exists comments_owner_all on public.comments;
create policy comments_owner_all on public.comments
for all to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

drop policy if exists likes_read on public.likes;
create policy likes_read on public.likes
for select to authenticated
using (true);

drop policy if exists likes_owner_all on public.likes;
create policy likes_owner_all on public.likes
for all to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

drop policy if exists shares_read on public.shares;
create policy shares_read on public.shares
for select to authenticated
using (true);

drop policy if exists shares_owner_all on public.shares;
create policy shares_owner_all on public.shares
for all to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

drop policy if exists stories_read_active on public.stories;
create policy stories_read_active on public.stories
for select to authenticated
using (expires_at > now());

drop policy if exists stories_owner_all on public.stories;
create policy stories_owner_all on public.stories
for all to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

drop policy if exists story_views_select on public.story_views;
create policy story_views_select on public.story_views
for select to authenticated
using (
  viewer_id = auth.uid()
  or exists (
    select 1 from public.stories s
    where s.id = story_views.story_id and s.user_id = auth.uid()
  )
);

drop policy if exists story_views_insert on public.story_views;
create policy story_views_insert on public.story_views
for insert to authenticated
with check (viewer_id = auth.uid());

drop policy if exists subscribes_read on public.subscribes;
create policy subscribes_read on public.subscribes
for select to authenticated
using (true);

drop policy if exists subscribes_owner_all on public.subscribes;
create policy subscribes_owner_all on public.subscribes
for all to authenticated
using (subscriber_id = auth.uid())
with check (subscriber_id = auth.uid());

drop policy if exists notifications_owner_select on public.notifications;
create policy notifications_owner_select on public.notifications
for select to authenticated
using (user_id = auth.uid());

drop policy if exists notifications_owner_update on public.notifications;
create policy notifications_owner_update on public.notifications
for update to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

drop policy if exists user_push_tokens_owner_all on public.user_push_tokens;
create policy user_push_tokens_owner_all on public.user_push_tokens
for all to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

drop policy if exists conversation_participants_select on public.conversation_participants;
create policy conversation_participants_select on public.conversation_participants
for select to authenticated
using (user_id = auth.uid());

drop policy if exists conversation_participants_update_self on public.conversation_participants;
create policy conversation_participants_update_self on public.conversation_participants
for update to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

drop policy if exists conversations_select_member on public.conversations;
create policy conversations_select_member on public.conversations
for select to authenticated
using (
  exists (
    select 1 from public.conversation_participants cp
    where cp.conversation_id = conversations.id
      and cp.user_id = auth.uid()
  )
);

drop policy if exists messages_select_member on public.messages;
create policy messages_select_member on public.messages
for select to authenticated
using (
  exists (
    select 1 from public.conversation_participants cp
    where cp.conversation_id = messages.conversation_id
      and cp.user_id = auth.uid()
  )
);

drop policy if exists messages_insert_member on public.messages;
create policy messages_insert_member on public.messages
for insert to authenticated
with check (
  sender_id = auth.uid()
  and exists (
    select 1 from public.conversation_participants cp
    where cp.conversation_id = messages.conversation_id
      and cp.user_id = auth.uid()
  )
);

drop policy if exists messages_update_sender on public.messages;
create policy messages_update_sender on public.messages
for update to authenticated
using (sender_id = auth.uid())
with check (sender_id = auth.uid());

drop policy if exists message_reads_select_self on public.message_reads;
create policy message_reads_select_self on public.message_reads
for select to authenticated
using (user_id = auth.uid());

drop policy if exists message_reads_insert_self on public.message_reads;
create policy message_reads_insert_self on public.message_reads
for insert to authenticated
with check (user_id = auth.uid());
