-- Notification queue + Edge worker support (FCM fanout + retry).
-- Run after instagram_schema_patch_v2.sql

-- =========================================================
-- Extra columns for job lifecycle visibility
-- =========================================================
alter table public.notification_jobs
  add column if not exists processed_at timestamptz,
  add column if not exists last_response jsonb;

-- =========================================================
-- Enqueue job automatically when notification row is inserted
-- =========================================================
create or replace function public.enqueue_notification_job_from_notification()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.is_deleted is true then
    return new;
  end if;

  insert into public.notification_jobs (
    user_id,
    actor_id,
    type,
    payload,
    status,
    attempts,
    next_attempt_at
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
  );

  return new;
end;
$$;

drop trigger if exists trg_enqueue_notification_job on public.notifications;
create trigger trg_enqueue_notification_job
after insert on public.notifications
for each row
execute function public.enqueue_notification_job_from_notification();

-- =========================================================
-- Claim jobs atomically for worker (uses SKIP LOCKED)
-- =========================================================
create or replace function public.claim_notification_jobs(p_limit integer default 50)
returns setof public.notification_jobs
language plpgsql
security definer
set search_path = public
as $$
begin
  return query
  with picked as (
    select id
    from public.notification_jobs
    where status in ('queued', 'retry')
      and next_attempt_at <= now()
    order by created_at asc
    for update skip locked
    limit greatest(coalesce(p_limit, 50), 1)
  )
  update public.notification_jobs j
  set
    status = 'processing',
    attempts = coalesce(j.attempts, 0) + 1,
    updated_at = now()
  from picked
  where j.id = picked.id
  returning j.*;
end;
$$;

-- =========================================================
-- Mark job completion/retry/failure from worker
-- =========================================================
create or replace function public.complete_notification_job(
  p_job_id uuid,
  p_status text,
  p_last_error text default null,
  p_last_response jsonb default null,
  p_retry_delay_seconds integer default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_delay interval := make_interval(secs => greatest(coalesce(p_retry_delay_seconds, 30), 1));
begin
  if p_status = 'retry' then
    update public.notification_jobs
    set
      status = 'retry',
      last_error = p_last_error,
      last_response = p_last_response,
      next_attempt_at = now() + v_delay,
      updated_at = now()
    where id = p_job_id;
  elsif p_status = 'delivered' then
    update public.notification_jobs
    set
      status = 'delivered',
      last_error = null,
      last_response = p_last_response,
      processed_at = now(),
      updated_at = now()
    where id = p_job_id;
  else
    update public.notification_jobs
    set
      status = 'failed',
      last_error = p_last_error,
      last_response = p_last_response,
      processed_at = now(),
      updated_at = now()
    where id = p_job_id;
  end if;
end;
$$;

-- Service-role worker reads/writes jobs and push tokens.
grant execute on function public.claim_notification_jobs(integer) to service_role;
grant execute on function public.complete_notification_job(uuid, text, text, jsonb, integer) to service_role;
