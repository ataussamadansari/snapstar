-- SnapStar auth and guest-access policies.
-- Apply this in Supabase SQL editor or your migration pipeline.

alter table public.posts enable row level security;
alter table public.comments enable row level security;
alter table public.messages enable row level security;

drop policy if exists "posts_select_all" on public.posts;
create policy "posts_select_all"
on public.posts
for select
to anon, authenticated
using (true);

drop policy if exists "posts_mutation_google_only" on public.posts;
create policy "posts_mutation_google_only"
on public.posts
for all
to authenticated
using (
  auth.uid() = user_id
  and coalesce((auth.jwt() ->> 'is_anonymous')::boolean, false) = false
)
with check (
  auth.uid() = user_id
  and coalesce((auth.jwt() ->> 'is_anonymous')::boolean, false) = false
);

drop policy if exists "comments_select_all" on public.comments;
create policy "comments_select_all"
on public.comments
for select
to anon, authenticated
using (true);

drop policy if exists "comments_mutation_google_only" on public.comments;
create policy "comments_mutation_google_only"
on public.comments
for all
to authenticated
using (
  auth.uid() = user_id
  and coalesce((auth.jwt() ->> 'is_anonymous')::boolean, false) = false
)
with check (
  auth.uid() = user_id
  and coalesce((auth.jwt() ->> 'is_anonymous')::boolean, false) = false
);

drop policy if exists "messages_select_participants" on public.messages;
create policy "messages_select_participants"
on public.messages
for select
to anon, authenticated
using (
  exists (
    select 1
    from public.conversation_participants cp
    where cp.conversation_id = messages.conversation_id
      and cp.user_id = auth.uid()
  )
);

drop policy if exists "messages_insert_google_only" on public.messages;
create policy "messages_insert_google_only"
on public.messages
for insert
to authenticated
with check (
  auth.uid() = sender_id
  and coalesce((auth.jwt() ->> 'is_anonymous')::boolean, false) = false
);

drop policy if exists "messages_update_google_sender_only" on public.messages;
create policy "messages_update_google_sender_only"
on public.messages
for update
to authenticated
using (
  auth.uid() = sender_id
  and coalesce((auth.jwt() ->> 'is_anonymous')::boolean, false) = false
)
with check (
  auth.uid() = sender_id
  and coalesce((auth.jwt() ->> 'is_anonymous')::boolean, false) = false
);

create or replace function public.increment_user_subscribing_count(
  p_user_id uuid
)
returns void
language plpgsql
security definer
set search_path to 'public'
as $function$
begin
  update public.users
  set
    subscribing_count = coalesce(subscribing_count, 0) + 1,
    updated_at = now()
  where id = p_user_id;
end;
$function$;

create or replace function public.decrement_user_subscribing_count(
  p_user_id uuid
)
returns void
language plpgsql
security definer
set search_path to 'public'
as $function$
begin
  update public.users
  set
    subscribing_count = greatest(coalesce(subscribing_count, 0) - 1, 0),
    updated_at = now()
  where id = p_user_id;
end;
$function$;
