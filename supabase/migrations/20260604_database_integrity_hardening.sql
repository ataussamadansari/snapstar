-- SnapStar production integrity hardening.
-- Reconciles denormalized counters before adding constraints and triggers.

begin;

-- Comments are soft-deleted by the Flutter client. Make that behavior explicit.
alter table public.comments
  add column if not exists is_deleted boolean not null default false;

alter table public.posts
  add column if not exists watch_event_count bigint not null default 0,
  add column if not exists skip_count bigint not null default 0;

-- One database row represents one accepted reel-view event.
create table if not exists public.post_watch_events (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.posts(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  session_id text not null,
  watched_seconds numeric not null check (watched_seconds >= 0),
  total_seconds numeric not null check (total_seconds > 0),
  completion_rate numeric not null check (completion_rate >= 0 and completion_rate <= 1),
  skipped boolean not null default false,
  created_at timestamptz not null default now(),
  unique (post_id, user_id, session_id)
);

alter table public.post_watch_events enable row level security;

drop policy if exists post_watch_events_select_self on public.post_watch_events;
create policy post_watch_events_select_self
  on public.post_watch_events
  for select
  to authenticated
  using (user_id = auth.uid());

revoke insert, update, delete on table public.post_watch_events from anon, authenticated;

-- Remove invalid legacy self-follows before enforcing the check constraint.
delete from public.subscribes where subscriber_id = subscribed_id;

-- Remove legacy duplicates before enforcing one-row-per-relation guarantees.
delete from public.likes a
using public.likes b
where a.id > b.id
  and a.post_id = b.post_id
  and a.user_id = b.user_id;

delete from public.shares a
using public.shares b
where a.id > b.id
  and a.post_id = b.post_id
  and a.user_id = b.user_id;

delete from public.subscribes a
using public.subscribes b
where a.id > b.id
  and a.subscriber_id = b.subscriber_id
  and a.subscribed_id = b.subscribed_id;

delete from public.story_views a
using public.story_views b
where a.id > b.id
  and a.story_id = b.story_id
  and a.viewer_id = b.viewer_id;

delete from public.story_likes a
using public.story_likes b
where a.id > b.id
  and a.story_id = b.story_id
  and a.user_id = b.user_id;

delete from public.saved_posts a
using public.saved_posts b
where a.id > b.id
  and a.post_id = b.post_id
  and a.user_id = b.user_id;

delete from public.comment_likes a
using public.comment_likes b
where a.id > b.id
  and a.comment_id = b.comment_id
  and a.user_id = b.user_id;

delete from public.message_reads a
using public.message_reads b
where a.id > b.id
  and a.message_id = b.message_id
  and a.user_id = b.user_id;

delete from public.conversation_participants a
using public.conversation_participants b
where a.id > b.id
  and a.conversation_id = b.conversation_id
  and a.user_id = b.user_id;

create unique index if not exists uq_likes_post_user
  on public.likes (post_id, user_id);
create unique index if not exists uq_shares_post_user
  on public.shares (post_id, user_id);
create unique index if not exists subscribes_unique_pair
  on public.subscribes (subscriber_id, subscribed_id);
create unique index if not exists uq_story_views_story_viewer
  on public.story_views (story_id, viewer_id);
create unique index if not exists story_likes_unique
  on public.story_likes (story_id, user_id);
create unique index if not exists saved_posts_user_post_unique
  on public.saved_posts (user_id, post_id);
create unique index if not exists comment_likes_unique
  on public.comment_likes (comment_id, user_id);
create unique index if not exists message_reads_message_id_user_id_key
  on public.message_reads (message_id, user_id);
create unique index if not exists conversation_participants_conversation_id_user_id_key
  on public.conversation_participants (conversation_id, user_id);

update public.comments c
set parent_id = null
where c.parent_id is not null
  and not exists (
    select 1
    from public.comments parent
    where parent.id = c.parent_id
      and parent.post_id = c.post_id
  );

-- Repair existing counter drift from source-of-truth tables.
update public.users u
set
  posts_count = coalesce((
    select count(*) from public.posts p
    where p.user_id = u.id and p.is_deleted = false
  ), 0),
  subscriber_count = coalesce((
    select count(*) from public.subscribes s
    where s.subscribed_id = u.id
  ), 0),
  subscribing_count = coalesce((
    select count(*) from public.subscribes s
    where s.subscriber_id = u.id
  ), 0);

update public.posts p
set
  like_count = coalesce((
    select count(*) from public.likes l where l.post_id = p.id
  ), 0),
  comment_count = coalesce((
    select count(*) from public.comments c
    where c.post_id = p.id and c.is_deleted = false
  ), 0),
  share_count = coalesce((
    select count(*) from public.shares s where s.post_id = p.id
  ), 0);

update public.stories s
set like_count = coalesce((
  select count(*) from public.story_likes sl where sl.story_id = s.id
), 0);

update public.hashtags h
set usage_count = coalesce((
  select count(*)
  from public.post_hashtags ph
  join public.posts p on p.id = ph.post_id
  where ph.hashtag_id = h.id and p.is_deleted = false
), 0);

update public.conversation_participants
set unread_count = greatest(coalesce(unread_count, 0), 0);

update public.notification_jobs
set
  attempts = greatest(coalesce(attempts, 0), 0),
  status = case
    when status in ('queued', 'processing', 'retry', 'delivered', 'failed') then status
    else 'failed'
  end;

-- Normalize null or negative legacy values before constraints are validated.
update public.users
set
  posts_count = greatest(coalesce(posts_count, 0), 0),
  subscriber_count = greatest(coalesce(subscriber_count, 0), 0),
  subscribing_count = greatest(coalesce(subscribing_count, 0), 0);

update public.posts
set
  like_count = greatest(coalesce(like_count, 0), 0),
  comment_count = greatest(coalesce(comment_count, 0), 0),
  share_count = greatest(coalesce(share_count, 0), 0),
  watch_count = greatest(coalesce(watch_count, 0), 0),
  avg_watch_time_seconds = greatest(coalesce(avg_watch_time_seconds, 0), 0),
  completion_rate = least(greatest(coalesce(completion_rate, 0), 0), 1),
  skip_rate = least(greatest(coalesce(skip_rate, 0), 0), 1);

update public.posts
set
  watch_event_count = greatest(coalesce(watch_event_count, watch_count), watch_count),
  skip_count = greatest(
    coalesce(skip_count, 0),
    round(skip_rate * greatest(watch_count, 0))::bigint,
    0
  );

update public.stories set like_count = greatest(coalesce(like_count, 0), 0);
update public.hashtags set usage_count = greatest(coalesce(usage_count, 0), 0);

alter table public.users
  alter column posts_count set default 0,
  alter column posts_count set not null,
  alter column subscriber_count set default 0,
  alter column subscriber_count set not null,
  alter column subscribing_count set default 0,
  alter column subscribing_count set not null;

alter table public.posts
  alter column like_count set default 0,
  alter column like_count set not null,
  alter column comment_count set default 0,
  alter column comment_count set not null,
  alter column share_count set default 0,
  alter column share_count set not null;

-- Clients may edit content fields, but denormalized counters are database-owned.
revoke update on table public.users from authenticated;
grant update (name, username, email, phone, avatar_url, bio, updated_at)
  on table public.users to authenticated;

revoke update on table public.posts from authenticated;
grant update (caption, location, is_deleted, updated_at)
  on table public.posts to authenticated;

revoke update on table public.stories from authenticated;
grant update (expires_at, media_urls, media_types)
  on table public.stories to authenticated;

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'users_posts_count_nonnegative'
  ) then
    alter table public.users
      add constraint users_posts_count_nonnegative check (posts_count >= 0);
  end if;
  if not exists (
    select 1 from pg_constraint where conname = 'users_subscriber_count_nonnegative'
  ) then
    alter table public.users
      add constraint users_subscriber_count_nonnegative check (subscriber_count >= 0);
  end if;
  if not exists (
    select 1 from pg_constraint where conname = 'users_subscribing_count_nonnegative'
  ) then
    alter table public.users
      add constraint users_subscribing_count_nonnegative check (subscribing_count >= 0);
  end if;
  if not exists (
    select 1 from pg_constraint where conname = 'posts_like_count_nonnegative'
  ) then
    alter table public.posts
      add constraint posts_like_count_nonnegative check (like_count >= 0);
  end if;
  if not exists (
    select 1 from pg_constraint where conname = 'posts_comment_count_nonnegative'
  ) then
    alter table public.posts
      add constraint posts_comment_count_nonnegative check (comment_count >= 0);
  end if;
  if not exists (
    select 1 from pg_constraint where conname = 'posts_share_count_nonnegative'
  ) then
    alter table public.posts
      add constraint posts_share_count_nonnegative check (share_count >= 0);
  end if;
  if not exists (
    select 1 from pg_constraint where conname = 'posts_watch_event_count_nonnegative'
  ) then
    alter table public.posts
      add constraint posts_watch_event_count_nonnegative check (watch_event_count >= 0);
  end if;
  if not exists (
    select 1 from pg_constraint where conname = 'posts_skip_count_nonnegative'
  ) then
    alter table public.posts
      add constraint posts_skip_count_nonnegative check (skip_count >= 0);
  end if;
  if not exists (
    select 1 from pg_constraint where conname = 'stories_like_count_nonnegative'
  ) then
    alter table public.stories
      add constraint stories_like_count_nonnegative check (like_count >= 0);
  end if;
  if not exists (
    select 1 from pg_constraint where conname = 'hashtags_usage_count_nonnegative'
  ) then
    alter table public.hashtags
      add constraint hashtags_usage_count_nonnegative check (usage_count >= 0);
  end if;
  if not exists (
    select 1 from pg_constraint where conname = 'conversation_participants_unread_nonnegative'
  ) then
    alter table public.conversation_participants
      add constraint conversation_participants_unread_nonnegative check (unread_count >= 0);
  end if;
  if not exists (
    select 1 from pg_constraint where conname = 'notification_jobs_attempts_nonnegative'
  ) then
    alter table public.notification_jobs
      add constraint notification_jobs_attempts_nonnegative check (attempts >= 0);
  end if;
  if not exists (
    select 1 from pg_constraint where conname = 'notification_jobs_status_valid'
  ) then
    alter table public.notification_jobs
      add constraint notification_jobs_status_valid
      check (status in ('queued', 'processing', 'retry', 'delivered', 'failed'));
  end if;
  if not exists (
    select 1 from pg_constraint where conname = 'subscribes_no_self_follow'
  ) then
    alter table public.subscribes
      add constraint subscribes_no_self_follow check (subscriber_id <> subscribed_id);
  end if;
end $$;

-- Relation identity must not be mutable. Delete and insert instead.
create or replace function public.prevent_relation_identity_update()
returns trigger
language plpgsql
set search_path to 'public'
as $$
begin
  raise exception 'Relation identity columns are immutable';
end;
$$;

drop trigger if exists trg_likes_identity_immutable on public.likes;
create trigger trg_likes_identity_immutable
before update of post_id, user_id on public.likes
for each row execute function public.prevent_relation_identity_update();

drop trigger if exists trg_shares_identity_immutable on public.shares;
create trigger trg_shares_identity_immutable
before update of post_id, user_id on public.shares
for each row execute function public.prevent_relation_identity_update();

drop trigger if exists trg_subscribes_identity_immutable on public.subscribes;
create trigger trg_subscribes_identity_immutable
before update of subscriber_id, subscribed_id on public.subscribes
for each row execute function public.prevent_relation_identity_update();

drop trigger if exists trg_story_likes_identity_immutable on public.story_likes;
create trigger trg_story_likes_identity_immutable
before update of story_id, user_id on public.story_likes
for each row execute function public.prevent_relation_identity_update();

drop trigger if exists trg_story_views_identity_immutable on public.story_views;
create trigger trg_story_views_identity_immutable
before update of story_id, viewer_id on public.story_views
for each row execute function public.prevent_relation_identity_update();

drop trigger if exists trg_saved_posts_identity_immutable on public.saved_posts;
create trigger trg_saved_posts_identity_immutable
before update of post_id, user_id on public.saved_posts
for each row execute function public.prevent_relation_identity_update();

drop trigger if exists trg_comment_likes_identity_immutable on public.comment_likes;
create trigger trg_comment_likes_identity_immutable
before update of comment_id, user_id on public.comment_likes
for each row execute function public.prevent_relation_identity_update();

-- A reply must belong to the same post as its parent comment.
create or replace function public.validate_comment_parent()
returns trigger
language plpgsql
set search_path to 'public'
as $$
begin
  if new.parent_id is not null and not exists (
    select 1
    from public.comments parent
    where parent.id = new.parent_id
      and parent.post_id = new.post_id
  ) then
    raise exception 'Parent comment must belong to the same post';
  end if;
  return new;
end;
$$;

drop trigger if exists trg_validate_comment_parent on public.comments;
create trigger trg_validate_comment_parent
before insert or update of parent_id, post_id on public.comments
for each row execute function public.validate_comment_parent();

-- Atomic denormalized counters.
create or replace function public.trg_update_post_like_count()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  if tg_op = 'INSERT' then
    update public.posts
    set like_count = like_count + 1
    where id = new.post_id;
    return new;
  end if;

  update public.posts
  set like_count = greatest(like_count - 1, 0)
  where id = old.post_id;
  return old;
end;
$$;

create or replace function public.trg_update_post_comment_count()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  if tg_op = 'INSERT' and new.is_deleted = false then
    update public.posts set comment_count = comment_count + 1 where id = new.post_id;
  elsif tg_op = 'DELETE' and old.is_deleted = false then
    update public.posts set comment_count = greatest(comment_count - 1, 0) where id = old.post_id;
  elsif tg_op = 'UPDATE' and old.is_deleted is distinct from new.is_deleted then
    update public.posts
    set comment_count = greatest(
      comment_count + case when new.is_deleted then -1 else 1 end,
      0
    )
    where id = new.post_id;
  end if;
  return coalesce(new, old);
end;
$$;

drop trigger if exists trg_comments_counter on public.comments;
create trigger trg_comments_counter
after insert or delete or update of is_deleted on public.comments
for each row execute function public.trg_update_post_comment_count();

create or replace function public.trg_update_post_share_count()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  if tg_op = 'INSERT' then
    update public.posts set share_count = share_count + 1 where id = new.post_id;
    return new;
  end if;

  update public.posts set share_count = greatest(share_count - 1, 0) where id = old.post_id;
  return old;
end;
$$;

drop trigger if exists trg_shares_counter on public.shares;
create trigger trg_shares_counter
after insert or delete on public.shares
for each row execute function public.trg_update_post_share_count();

create or replace function public.trg_update_user_posts_count()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  if tg_op = 'INSERT' and new.is_deleted = false then
    update public.users set posts_count = posts_count + 1 where id = new.user_id;
  elsif tg_op = 'DELETE' and old.is_deleted = false then
    update public.users set posts_count = greatest(posts_count - 1, 0) where id = old.user_id;
  elsif tg_op = 'UPDATE' then
    if old.user_id <> new.user_id then
      if old.is_deleted = false then
        update public.users set posts_count = greatest(posts_count - 1, 0) where id = old.user_id;
      end if;
      if new.is_deleted = false then
        update public.users set posts_count = posts_count + 1 where id = new.user_id;
      end if;
    elsif old.is_deleted is distinct from new.is_deleted then
      update public.users
      set posts_count = greatest(
        posts_count + case when new.is_deleted then -1 else 1 end,
        0
      )
      where id = new.user_id;
    end if;
  end if;
  return coalesce(new, old);
end;
$$;

drop trigger if exists trg_posts_counter on public.posts;
create trigger trg_posts_counter
after insert or delete or update of user_id, is_deleted on public.posts
for each row execute function public.trg_update_user_posts_count();

create or replace function public.sync_story_like_count()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  if tg_op = 'INSERT' then
    update public.stories set like_count = like_count + 1 where id = new.story_id;
    return new;
  end if;

  update public.stories set like_count = greatest(like_count - 1, 0) where id = old.story_id;
  return old;
end;
$$;

create or replace function public.trg_update_subscribe_counts()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  if tg_op = 'INSERT' then
    update public.users
    set subscriber_count = subscriber_count + 1
    where id = new.subscribed_id;

    update public.users
    set subscribing_count = subscribing_count + 1
    where id = new.subscriber_id;
    return new;
  end if;

  update public.users
  set subscriber_count = greatest(subscriber_count - 1, 0)
  where id = old.subscribed_id;

  update public.users
  set subscribing_count = greatest(subscribing_count - 1, 0)
  where id = old.subscriber_id;
  return old;
end;
$$;

create or replace function public.increment_unread_count()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  update public.conversation_participants
  set unread_count = unread_count + 1
  where conversation_id = new.conversation_id
    and user_id <> new.sender_id;
  return new;
end;
$$;

create or replace function public.trg_recalculate_post_engagement_score()
returns trigger
language plpgsql
set search_path to 'public'
as $$
begin
  new.engagement_score :=
    coalesce(new.like_count, 0)::double precision
    + coalesce(new.comment_count, 0)::double precision * 2.0
    + coalesce(new.share_count, 0)::double precision * 2.5;
  return new;
end;
$$;

drop trigger if exists trg_posts_engagement_score on public.posts;
create trigger trg_posts_engagement_score
before insert or update of like_count, comment_count, share_count on public.posts
for each row execute function public.trg_recalculate_post_engagement_score();

update public.posts
set engagement_score =
  like_count::double precision
  + comment_count::double precision * 2.0
  + share_count::double precision * 2.5;

-- Counter updates must not rebuild hashtag links or search documents.
drop trigger if exists trg_posts_sync_hashtags on public.posts;
create trigger trg_posts_sync_hashtags
after insert or update of caption, is_deleted on public.posts
for each row execute function public.trg_sync_post_hashtags();

drop trigger if exists trg_refresh_post_search_from_posts on public.posts;
create trigger trg_refresh_post_search_from_posts
after insert or update of caption, location, is_deleted, user_id on public.posts
for each row execute function public.trg_refresh_post_search_from_posts();

-- Idempotent share recording. One user contributes at most one share per post.
create or replace function public.record_post_share(p_post_id uuid)
returns boolean
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_user_id uuid := auth.uid();
  v_rows integer;
begin
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;
  if not exists (
    select 1 from public.posts p where p.id = p_post_id and p.is_deleted = false
  ) then
    return false;
  end if;

  insert into public.shares (user_id, post_id)
  values (v_user_id, p_post_id)
  on conflict (post_id, user_id) do nothing;

  get diagnostics v_rows = row_count;
  return v_rows > 0;
end;
$$;

grant execute on function public.record_post_share(uuid) to authenticated;

-- Count a shared-post message as a share, without allowing duplicate rows.
create or replace function public.trg_record_shared_post_message()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  if new.shared_post_id is not null then
    insert into public.shares (user_id, post_id)
    values (new.sender_id, new.shared_post_id)
    on conflict (post_id, user_id) do nothing;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_record_shared_post_message on public.messages;
create trigger trg_record_shared_post_message
after insert on public.messages
for each row execute function public.trg_record_shared_post_message();

-- Idempotent reel analytics. A post/user/session can be accepted only once.
create or replace function public.record_post_watch_event(
  p_post_id uuid,
  p_session_id text,
  p_watched_seconds double precision,
  p_total_seconds double precision
)
returns boolean
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_user_id uuid := auth.uid();
  v_completion numeric;
  v_skipped boolean;
  v_rows integer;
begin
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;
  if p_total_seconds <= 0 or p_watched_seconds < 0 or nullif(trim(p_session_id), '') is null then
    return false;
  end if;
  if not exists (
    select 1 from public.posts p where p.id = p_post_id and p.is_deleted = false
  ) then
    return false;
  end if;

  v_completion := least(greatest(p_watched_seconds / p_total_seconds, 0), 1);
  v_skipped := p_watched_seconds < 3 and v_completion < 0.20;

  -- Skips update skip_rate but do not increment watch_count.
  insert into public.post_watch_events (
    post_id, user_id, session_id, watched_seconds, total_seconds,
    completion_rate, skipped
  )
  values (
    p_post_id, v_user_id, p_session_id, p_watched_seconds, p_total_seconds,
    v_completion, v_skipped
  )
  on conflict (post_id, user_id, session_id) do nothing;

  get diagnostics v_rows = row_count;
  if v_rows = 0 then
    return false;
  end if;

  if v_skipped then
    update public.posts
    set
      watch_event_count = watch_event_count + 1,
      skip_count = skip_count + 1,
      skip_rate = round(
        (skip_count + 1)::numeric / (watch_event_count + 1),
        4
      ),
      updated_at = now()
    where id = p_post_id and is_deleted = false;
  else
    update public.posts
    set
      avg_watch_time_seconds = round(
        ((avg_watch_time_seconds * watch_count) + p_watched_seconds::numeric) /
        (watch_count + 1),
        2
      ),
      completion_rate = round(
        ((completion_rate * watch_count) + v_completion) /
        (watch_count + 1),
        4
      ),
      watch_event_count = watch_event_count + 1,
      skip_rate = round(
        skip_count::numeric / (watch_event_count + 1),
        4
      ),
      watch_count = watch_count + 1,
      updated_at = now()
    where id = p_post_id and is_deleted = false;
  end if;

  return true;
end;
$$;

grant execute on function public.record_post_watch_event(uuid, text, double precision, double precision)
  to authenticated;

revoke execute on function public.increment_post_watch_count(uuid)
  from public, anon, authenticated;
revoke execute on function public.update_post_watch_metrics(uuid, double precision, double precision)
  from public, anon, authenticated;

do $$
declare
  v_signature regprocedure;
begin
  for v_signature in
    select p.oid::regprocedure
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname = any (array[
        'increment_post_like_count',
        'decrement_post_like_count',
        'increment_post_comment_count',
        'decrement_post_comment_count',
        'increment_user_subscriber_count',
        'decrement_user_subscriber_count',
        'increment_user_subscribing_count',
        'decrement_user_subscribing_count',
        'increment_hashtag_usage'
      ])
  loop
    execute format(
      'revoke execute on function %s from public, anon, authenticated',
      v_signature
    );
  end loop;
end $$;

-- Serialize direct-conversation creation for the same user pair.
create or replace function public.get_or_create_conversation(p_other_user_id uuid)
returns uuid
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_current_user_id uuid := auth.uid();
  v_conversation_id uuid;
  v_pair_key text;
begin
  if v_current_user_id is null then
    raise exception 'Not authenticated';
  end if;
  if v_current_user_id = p_other_user_id then
    raise exception 'Cannot create conversation with yourself';
  end if;
  if not exists (select 1 from public.users where id = p_other_user_id) then
    raise exception 'User not found';
  end if;

  v_pair_key := least(v_current_user_id::text, p_other_user_id::text)
    || ':' || greatest(v_current_user_id::text, p_other_user_id::text);
  perform pg_advisory_xact_lock(hashtextextended(v_pair_key, 0));

  select cp1.conversation_id into v_conversation_id
  from public.conversation_participants cp1
  join public.conversation_participants cp2
    on cp2.conversation_id = cp1.conversation_id
  where cp1.user_id = v_current_user_id
    and cp2.user_id = p_other_user_id
    and (
      select count(*)
      from public.conversation_participants cp
      where cp.conversation_id = cp1.conversation_id
    ) = 2
  limit 1;

  if v_conversation_id is not null then
    return v_conversation_id;
  end if;

  insert into public.conversations default values
  returning id into v_conversation_id;

  insert into public.conversation_participants (conversation_id, user_id)
  values
    (v_conversation_id, v_current_user_id),
    (v_conversation_id, p_other_user_id);

  return v_conversation_id;
end;
$$;

-- Read receipts are idempotent and unread_count reflects remaining unread rows.
create or replace function public.mark_messages_read(
  p_conversation_id uuid,
  p_up_to_message_id uuid default null
)
returns void
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_current_user_id uuid := auth.uid();
  v_up_to_created_at timestamptz;
begin
  if v_current_user_id is null then
    raise exception 'Not authenticated';
  end if;
  if not exists (
    select 1
    from public.conversation_participants cp
    where cp.conversation_id = p_conversation_id
      and cp.user_id = v_current_user_id
  ) then
    raise exception 'Not a participant of this conversation';
  end if;

  if p_up_to_message_id is not null then
    select m.created_at into v_up_to_created_at
    from public.messages m
    where m.id = p_up_to_message_id
      and m.conversation_id = p_conversation_id;
    if v_up_to_created_at is null then
      raise exception 'Message does not belong to conversation';
    end if;
  end if;

  insert into public.message_reads (message_id, user_id, read_at)
  select m.id, v_current_user_id, now()
  from public.messages m
  where m.conversation_id = p_conversation_id
    and m.sender_id <> v_current_user_id
    and m.is_deleted = false
    and (v_up_to_created_at is null or m.created_at <= v_up_to_created_at)
  on conflict (message_id, user_id) do nothing;

  update public.conversation_participants cp
  set
    last_read_at = now(),
    unread_count = (
      select count(*)::integer
      from public.messages m
      where m.conversation_id = p_conversation_id
        and m.sender_id <> v_current_user_id
        and m.is_deleted = false
        and not exists (
          select 1
          from public.message_reads mr
          where mr.message_id = m.id
            and mr.user_id = v_current_user_id
        )
    )
  where cp.conversation_id = p_conversation_id
    and cp.user_id = v_current_user_id;
end;
$$;

-- Expired stories with likes must still be removable.
create or replace function public.cleanup_expired_stories()
returns integer
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_deleted integer := 0;
begin
  delete from public.story_likes sl
  using public.stories s
  where sl.story_id = s.id
    and s.expires_at < now() - interval '2 days';

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

create or replace function public.search_hashtags(
  p_query text,
  p_limit integer default 20
)
returns table(tag text, usage_count integer, post_count integer)
language sql
stable
set search_path to 'public'
as $$
  with q as (
    select lower(replace(trim(coalesce(p_query, '')), '#', '')) as term
  ),
  matched as (
    select
      h.id,
      h.tag,
      h.usage_count,
      case when h.tag = q.term then 0 else 1 end as match_order
    from public.hashtags h
    cross join q
    where q.term <> ''
      and h.tag like (q.term || '%')
    order by
      match_order,
      h.usage_count desc,
      h.tag asc
    limit greatest(coalesce(p_limit, 20), 1)
  )
  select
    m.tag,
    m.usage_count,
    count(p.id)::integer as post_count
  from matched m
  left join public.post_hashtags ph on ph.hashtag_id = m.id
  left join public.posts p on p.id = ph.post_id and p.is_deleted = false
  group by m.id, m.tag, m.usage_count, m.match_order
  order by m.match_order, post_count desc, m.usage_count desc, m.tag asc;
$$;

-- Prevent duplicate notification jobs for the same notification row.
delete from public.notification_jobs j
using public.notification_jobs duplicate
where j.id > duplicate.id
  and j.payload ? 'notification_id'
  and duplicate.payload ? 'notification_id'
  and j.payload ->> 'notification_id' = duplicate.payload ->> 'notification_id';

create unique index if not exists uq_notification_jobs_notification_id
  on public.notification_jobs ((payload ->> 'notification_id'))
  where payload ? 'notification_id';

create or replace function public.trg_guard_notification_insert()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  if new.user_id is null or (new.actor_id is not null and new.actor_id = new.user_id) then
    return null;
  end if;

  perform pg_advisory_xact_lock(
    hashtextextended(
      concat_ws(':', new.user_id::text, coalesce(new.actor_id::text, ''),
        coalesce(new.post_id::text, ''), coalesce(new.type, 'activity')),
      0
    )
  );

  if exists (
    select 1
    from public.notifications n
    where n.user_id = new.user_id
      and n.actor_id is not distinct from new.actor_id
      and n.post_id is not distinct from new.post_id
      and n.type = coalesce(new.type, 'activity')
      and n.is_deleted = false
      and n.created_at >= now() - interval '30 seconds'
  ) then
    return null;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_guard_notification_insert on public.notifications;
create trigger trg_guard_notification_insert
before insert on public.notifications
for each row execute function public.trg_guard_notification_insert();

create or replace function public.enqueue_notification_job_from_notification()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  if new.is_deleted is true or (new.actor_id is not null and new.actor_id = new.user_id) then
    return new;
  end if;

  insert into public.notification_jobs (
    user_id, actor_id, type, payload, status, attempts, next_attempt_at
  )
  values (
    new.user_id,
    new.actor_id,
    coalesce(new.type, 'activity'),
    jsonb_build_object(
      'notification_id', new.id,
      'title', coalesce(new.title, 'Snapstar'),
      'message', coalesce(new.message, ''),
      'type', coalesce(new.type, 'activity'),
      'post_id', new.post_id,
      'route', '/notifications'
    ),
    'queued',
    0,
    now()
  )
  on conflict do nothing;

  return new;
end;
$$;

create or replace function public.claim_notification_jobs(p_limit integer default 50)
returns setof public.notification_jobs
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  return query
  with picked as (
    select id
    from public.notification_jobs
    where attempts < 10
      and (
        (status in ('queued', 'retry') and next_attempt_at <= now())
        or (status = 'processing' and updated_at < now() - interval '5 minutes')
      )
    order by created_at asc
    for update skip locked
    limit greatest(coalesce(p_limit, 50), 1)
  )
  update public.notification_jobs j
  set
    status = 'processing',
    attempts = j.attempts + 1,
    updated_at = now()
  from picked
  where j.id = picked.id
  returning j.*;
end;
$$;

create or replace function public.create_notification(
  p_user_id uuid,
  p_actor_id uuid,
  p_type text,
  p_message text,
  p_title text default null,
  p_post_id uuid default null
)
returns uuid
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_id uuid;
begin
  if p_user_id is null or (p_actor_id is not null and p_actor_id = p_user_id) then
    return null;
  end if;

  perform pg_advisory_xact_lock(
    hashtextextended(
      concat_ws(':', p_user_id::text, coalesce(p_actor_id::text, ''),
        coalesce(p_post_id::text, ''), coalesce(p_type, 'activity')),
      0
    )
  );

  -- Collapse retries or rapid taps into one notification.
  select n.id into v_id
  from public.notifications n
  where n.user_id = p_user_id
    and n.actor_id is not distinct from p_actor_id
    and n.post_id is not distinct from p_post_id
    and n.type = coalesce(p_type, 'activity')
    and n.is_deleted = false
    and n.created_at >= now() - interval '30 seconds'
  order by n.created_at desc
  limit 1;

  if v_id is not null then
    return v_id;
  end if;

  insert into public.notifications (
    user_id, actor_id, post_id, type, title, message, is_read, is_deleted
  )
  values (
    p_user_id, p_actor_id, p_post_id, coalesce(p_type, 'activity'),
    p_title, p_message, false, false
  )
  returning id into v_id;

  return v_id;
end;
$$;

-- Query-support indexes not already covered by primary/unique indexes.
create index if not exists idx_comments_parent_id
  on public.comments (parent_id)
  where parent_id is not null;

create index if not exists idx_comments_post_active_created
  on public.comments (post_id, created_at asc, id asc)
  where is_deleted = false;

create index if not exists idx_post_watch_events_post_created
  on public.post_watch_events (post_id, created_at desc);

create index if not exists idx_post_watch_events_user_created
  on public.post_watch_events (user_id, created_at desc);

create index if not exists idx_notification_jobs_processing
  on public.notification_jobs (updated_at)
  where status = 'processing';

create index if not exists idx_notifications_actor_created
  on public.notifications (actor_id, created_at desc)
  where actor_id is not null;

create index if not exists idx_notifications_post_created
  on public.notifications (post_id, created_at desc)
  where post_id is not null;

create index if not exists idx_hashtags_tag_pattern
  on public.hashtags (tag text_pattern_ops);

commit;
