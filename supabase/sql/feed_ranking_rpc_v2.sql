-- =========================================================
-- Feed ranking RPC v2
-- Replaces public.get_ranked_feed with stronger server-side scoring:
-- relationship + recency + engagement + controlled discovery jitter.
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
with followings as (
  select s.subscribed_id
  from public.subscribes s
  where p_user_id is not null
    and s.subscriber_id = p_user_id
),
base as (
  select
    p.*,
    to_jsonb(u.*) as users,
    (p.user_id = p_user_id) as is_self,
    exists (
      select 1 from followings f where f.subscribed_id = p.user_id
    ) as is_following,
    greatest(extract(epoch from (now() - p.created_at)) / 3600.0, 0.0) as age_hours,
    row_number() over (
      partition by p.user_id
      order by p.created_at desc, p.id desc
    ) as author_recent_rank,
    (
      greatest(coalesce(p.like_count, 0), 0) * 1.6
      + greatest(coalesce(p.comment_count, 0), 0) * 2.4
      + greatest(coalesce(p.share_count, 0), 0) * 3.2
    ) as engagement_raw
  from public.posts p
  join public.users u on u.id = p.user_id
  where p.is_deleted = false
),
scored as (
  select
    b.*,
    (
      -- 1) Relationship boost (following + self priority)
      case
        when b.is_self then 0.6
        when b.is_following then 2.1
        else 0.0
      end
      +
      -- 2) Engagement boost (log keeps outliers under control)
      ln(1 + b.engagement_raw)
      +
      -- 3) Recency decay (fresh posts should surface)
      (4.6 * exp(- b.age_hours / 20.0))
      +
      -- 4) Extra freshness bump for very recent posts
      case
        when b.age_hours <= 2 then 0.9
        when b.age_hours <= 8 then 0.45
        when b.age_hours <= 24 then 0.2
        else 0.0
      end
      +
      -- 5) Controlled discovery jitter.
      -- Stable for a 3-hour window per user, avoids identical feed feel.
      (
        (
          (
            hashtextextended(
              b.id::text || coalesce(p_user_id::text, ''),
              floor(extract(epoch from now()) / 10800)::bigint
            ) & 2147483647
          ) % 1000
        )::double precision / 1000.0
      ) * 0.38
      +
      -- 6) Diversity penalty: avoid one author dominating the top feed.
      case
        when b.author_recent_rank = 1 then 0.0
        when b.author_recent_rank = 2 then -0.35
        when b.author_recent_rank = 3 then -0.8
        when b.author_recent_rank = 4 then -1.4
        else -2.2
      end
      +
      -- 7) Additional self-post penalty so own posts don't fill the feed.
      case
        when b.is_self then -1.25
        else 0.0
      end
    )::double precision as rank_score
  from base b
)
select
  s.id,
  s.user_id,
  s.media_type,
  s.caption,
  s.like_count,
  s.share_count,
  s.comment_count,
  s.is_deleted,
  s.location,
  s.created_at,
  s.updated_at,
  s.media_urls,
  s.thumbnail_urls,
  s.users,
  s.rank_score
from scored s
where
  p_cursor_score is null
  or s.rank_score < p_cursor_score
  or (s.rank_score = p_cursor_score and s.created_at < p_cursor_created_at)
  or (
    s.rank_score = p_cursor_score
    and s.created_at = p_cursor_created_at
    and s.id::text < coalesce(p_cursor_id::text, 'ffffffff-ffff-ffff-ffff-ffffffffffff')
  )
order by s.rank_score desc, s.created_at desc, s.id desc
limit greatest(coalesce(p_limit, 20), 1);
$$;

grant execute on function public.get_ranked_feed(uuid, integer, double precision, timestamptz, uuid) to authenticated;

-- =========================================================
-- Recommended indexes for ranked feed performance
-- (safe with your current schema)
-- =========================================================
create index if not exists idx_posts_feed_created_desc
  on public.posts (is_deleted, created_at desc, id desc);

create index if not exists idx_posts_feed_engagement
  on public.posts (
    is_deleted,
    share_count desc,
    comment_count desc,
    like_count desc,
    created_at desc
  );

create index if not exists idx_subscribes_subscriber_subscribed
  on public.subscribes (subscriber_id, subscribed_id);
