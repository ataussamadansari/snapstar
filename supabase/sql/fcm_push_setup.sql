-- FCM push token storage setup for Snapstar.
-- Run this in Supabase SQL editor.

create table if not exists public.user_push_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  token text not null,
  platform text not null default 'android',
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, token)
);

alter table public.user_push_tokens enable row level security;

drop policy if exists "read own push tokens" on public.user_push_tokens;
create policy "read own push tokens"
on public.user_push_tokens
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "insert own push tokens" on public.user_push_tokens;
create policy "insert own push tokens"
on public.user_push_tokens
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "update own push tokens" on public.user_push_tokens;
create policy "update own push tokens"
on public.user_push_tokens
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "delete own push tokens" on public.user_push_tokens;
create policy "delete own push tokens"
on public.user_push_tokens
for delete
to authenticated
using (auth.uid() = user_id);

create or replace function public.upsert_push_token(
  p_token text,
  p_platform text default 'android'
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'auth.uid() is required';
  end if;

  insert into public.user_push_tokens (
    user_id,
    token,
    platform,
    is_active,
    updated_at
  )
  values (
    auth.uid(),
    p_token,
    p_platform,
    true,
    now()
  )
  on conflict (user_id, token)
  do update set
    platform = excluded.platform,
    is_active = true,
    updated_at = now();
end;
$$;

create or replace function public.deactivate_push_token(
  p_token text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'auth.uid() is required';
  end if;

  update public.user_push_tokens
  set
    is_active = false,
    updated_at = now()
  where user_id = auth.uid()
    and token = p_token;
end;
$$;

grant execute on function public.upsert_push_token(text, text) to authenticated;
grant execute on function public.deactivate_push_token(text) to authenticated;
