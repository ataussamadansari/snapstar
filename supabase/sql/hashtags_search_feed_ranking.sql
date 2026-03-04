-- Hashtags + search RPC + ranked feed RPC
-- Run after instagram_schema_patch_v2.sql

-- =========================================================
-- 1) Hashtag schema
-- =========================================================
create table if not exists public.hashtags (
  id bigserial primary key,
  tag text not null unique,
  usage_count integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.post_hashtags (
  post_id uuid not null references public.posts(id) on delete cascade,
  hashtag_id bigint not null references public.hashtags(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (post_id, hashtag_id)
);

create index if not exists idx_hashtags_tag_trgm
  on public.hashtags using gin (tag gin_trgm_ops);

create index if not exists idx_post_hashtags_hashtag_post
  on public.post_hashtags (hashtag_id, post_id);

create index if not exists idx_post_hashtags_post
  on public.post_hashtags (post_id);

-- =========================================================
-- 2) hashtag extraction + sync helpers
-- =========================================================
create or replace function public.extract_hashtags(p_caption text)
returns text[]
language plpgsql
immutable
as $$
declare
  v_match text[];
  v_tag text;
  v_tags text[] := '{}';
begin
  if p_caption is null or length(trim(p_caption)) = 0 then
    return v_tags;
  end if;

  for v_match in
    select regexp_matches(lower(p_caption), '#([a-z0-9_]{1,50})', 'g')
  loop
    v_tag := trim(v_match[1]);
    if v_tag is not null and v_tag <> '' then
      if not (v_tag = any(v_tags)) then
        v_tags := array_append(v_tags, v_tag);
      end if;
    end if;
  end loop;

  return v_tags;
end;
$$;

create or replace function public.sync_post_hashtags(
  p_post_id uuid,
  p_caption text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_new_tags text[] := public.extract_hashtags(p_caption);
begin
  if v_new_tags is null then
    v_new_tags := '{}';
  end if;

  -- remove old links
  delete from public.post_hashtags
  where post_id = p_post_id;

  -- if post is deleted, do not map hashtags
  if exists (
    select 1 from public.posts p
    where p.id = p_post_id and p.is_deleted = true
  ) then
    update public.hashtags h
    set usage_count = coalesce(src.cnt, 0), updated_at = now()
    from (
      select ph.hashtag_id, count(*)::int as cnt
      from public.post_hashtags ph
      join public.posts p on p.id = ph.post_id and p.is_deleted = false
      group by ph.hashtag_id
    ) src
    where h.id = src.hashtag_id;

    update public.hashtags
    set usage_count = 0, updated_at = now()
    where id not in (
      select distinct hashtag_id from public.post_hashtags
    );

    return;
  end if;

  if array_length(v_new_tags, 1) is null then
    -- no hashtags, just recalc counts
    update public.hashtags h
    set usage_count = coalesce(src.cnt, 0), updated_at = now()
    from (
      select ph.hashtag_id, count(*)::int as cnt
      from public.post_hashtags ph
      join public.posts p on p.id = ph.post_id and p.is_deleted = false
      group by ph.hashtag_id
    ) src
    where h.id = src.hashtag_id;

    update public.hashtags
    set usage_count = 0, updated_at = now()
    where id not in (
      select distinct hashtag_id from public.post_hashtags
    );

    return;
  end if;

  -- upsert hashtag rows
  insert into public.hashtags (tag, usage_count)
  select unnest(v_new_tags), 0
  on conflict (tag) do nothing;

  -- map post -> hashtags
  insert into public.post_hashtags (post_id, hashtag_id)
  select p_post_id, h.id
  from public.hashtags h
  where h.tag = any(v_new_tags)
  on conflict do nothing;

  -- refresh usage counts
  update public.hashtags h
  set usage_count = coalesce(src.cnt, 0), updated_at = now()
  from (
    select ph.hashtag_id, count(*)::int as cnt
    from public.post_hashtags ph
    join public.posts p on p.id = ph.post_id and p.is_deleted = false
    group by ph.hashtag_id
  ) src
  where h.id = src.hashtag_id;

  update public.hashtags
  set usage_count = 0, updated_at = now()
  where id not in (
    select distinct hashtag_id from public.post_hashtags
  );
end;
$$;

create or replace function public.trg_sync_post_hashtags()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.sync_post_hashtags(new.id, new.caption);
  return new;
end;
$$;

drop trigger if exists trg_posts_sync_hashtags on public.posts;
create trigger trg_posts_sync_hashtags
after insert or update of caption, is_deleted on public.posts
for each row
execute function public.trg_sync_post_hashtags();

-- =========================================================
-- 3) Search RPCs
-- =========================================================
create or replace function public.search_posts_with_hashtags(
  p_query text,
  p_limit integer default 30,
  p_offset integer default 0
)
returns table (
  id uuid,
  user_id uuid,
  media_type varchar,
  caption text,
  like_count integer,
  share_count integer,
  comment_count integer,
  is_deleted boolean,
  location text,
  created_at timestamptz,
  updated_at timestamptz,
  media_urls text[],
  thumbnail_urls text[],
  users jsonb,
  match_score double precision
)
language sql
stable
as $$
with q as (
  select
    lower(trim(coalesce(p_query, ''))) as term,
    lower(replace(trim(coalesce(p_query, '')), '#', '')) as term_tag
)
select
  p.id,
  p.user_id,
  p.media_type,
  p.caption,
  p.like_count,
  p.share_count,
  p.comment_count,
  p.is_deleted,
  p.location,
  p.created_at,
  p.updated_at,
  p.media_urls,
  p.thumbnail_urls,
  to_jsonb(u.*) as users,
  (
    case
      when lower(coalesce(p.caption, '')) like ('%' || q.term || '%') then 2.0
      else 0.0
    end
    +
    case
      when exists (
        select 1
        from public.post_hashtags ph
        join public.hashtags h on h.id = ph.hashtag_id
        where ph.post_id = p.id
          and h.tag like (q.term_tag || '%')
      ) then 3.0
      else 0.0
    end
  )::double precision as match_score
from public.posts p
join public.users u on u.id = p.user_id
cross join q
where p.is_deleted = false
  and (
    lower(coalesce(p.caption, '')) like ('%' || q.term || '%')
    or exists (
      select 1
      from public.post_hashtags ph
      join public.hashtags h on h.id = ph.hashtag_id
      where ph.post_id = p.id
        and h.tag like (q.term_tag || '%')
    )
    or (q.term like '#%' and exists (
      select 1
      from public.post_hashtags ph
      join public.hashtags h on h.id = ph.hashtag_id
      where ph.post_id = p.id
        and h.tag = q.term_tag
    ))
  )
order by match_score desc, p.created_at desc, p.id desc
limit greatest(coalesce(p_limit, 30), 1)
offset greatest(coalesce(p_offset, 0), 0);
$$;

create or replace function public.search_hashtags(
  p_query text,
  p_limit integer default 20
)
returns table (
  tag text,
  usage_count integer,
  post_count integer
)
language sql
stable
as $$
with q as (
  select lower(replace(trim(coalesce(p_query, '')), '#', '')) as term
)
select
  h.tag,
  h.usage_count,
  coalesce(ph_cnt.post_count, 0)::int as post_count
from public.hashtags h
cross join q
left join (
  select ph.hashtag_id, count(*)::int as post_count
  from public.post_hashtags ph
  join public.posts p on p.id = ph.post_id and p.is_deleted = false
  group by ph.hashtag_id
) ph_cnt on ph_cnt.hashtag_id = h.id
where q.term <> ''
  and h.tag like (q.term || '%')
order by
  case when h.tag = q.term then 0 else 1 end,
  coalesce(ph_cnt.post_count, 0) desc,
  h.usage_count desc,
  h.tag asc
limit greatest(coalesce(p_limit, 20), 1);
$$;

-- =========================================================
-- 4) Ranked feed RPC (engagement + recency + relationship)
-- =========================================================
create or replace function public.get_ranked_feed(
  p_user_id uuid default auth.uid(),
  p_limit integer default 20,
  p_cursor_score double precision default null,
  p_cursor_created_at timestamptz default null,
  p_cursor_id uuid default null
)
returns table (
  id uuid,
  user_id uuid,
  media_type varchar,
  caption text,
  like_count integer,
  share_count integer,
  comment_count integer,
  is_deleted boolean,
  location text,
  created_at timestamptz,
  updated_at timestamptz,
  media_urls text[],
  thumbnail_urls text[],
  users jsonb,
  rank_score double precision
)
language sql
stable
as $$
with ranked as (
  select
    p.*,
    to_jsonb(u.*) as users,
    (
      -- Relationship boost
      case
        when p.user_id = p_user_id then 5.0
        when exists (
          select 1
          from public.subscribes s
          where s.subscriber_id = p_user_id
            and s.subscribed_id = p.user_id
        ) then 3.0
        else 0.0
      end
      +
      -- Engagement score
      ln(1 + greatest(coalesce(p.like_count, 0), 0) * 2
            + greatest(coalesce(p.comment_count, 0), 0) * 3
            + greatest(coalesce(p.share_count, 0), 0) * 4)
      +
      -- Recency decay (recent posts boosted)
      (6.0 * exp(- greatest(extract(epoch from (now() - p.created_at)) / 3600.0, 0) / 36.0))
    )::double precision as rank_score
  from public.posts p
  join public.users u on u.id = p.user_id
  where p.is_deleted = false
)
select
  r.id, r.user_id, r.media_type, r.caption, r.like_count, r.share_count,
  r.comment_count, r.is_deleted, r.location, r.created_at, r.updated_at,
  r.media_urls, r.thumbnail_urls, r.users, r.rank_score
from ranked r
where
  p_cursor_score is null
  or r.rank_score < p_cursor_score
  or (r.rank_score = p_cursor_score and r.created_at < p_cursor_created_at)
  or (
    r.rank_score = p_cursor_score
    and r.created_at = p_cursor_created_at
    and r.id::text < coalesce(p_cursor_id::text, 'ffffffff-ffff-ffff-ffff-ffffffffffff')
  )
order by r.rank_score desc, r.created_at desc, r.id desc
limit greatest(coalesce(p_limit, 20), 1);
$$;

grant execute on function public.search_posts_with_hashtags(text, integer, integer) to authenticated;
grant execute on function public.search_hashtags(text, integer) to authenticated;
grant execute on function public.get_ranked_feed(uuid, integer, double precision, timestamptz, uuid) to authenticated;

-- =========================================================
-- 5) RLS for hashtag tables
-- =========================================================
alter table public.hashtags enable row level security;
alter table public.post_hashtags enable row level security;

drop policy if exists hashtags_read on public.hashtags;
create policy hashtags_read on public.hashtags
for select to authenticated
using (true);

drop policy if exists post_hashtags_read on public.post_hashtags;
create policy post_hashtags_read on public.post_hashtags
for select to authenticated
using (true);
