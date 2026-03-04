-- Schedule Edge worker every minute (requires pg_cron + pg_net).
-- Replace placeholders before running:
--   <PROJECT_REF>, <QUEUE_WORKER_SECRET>

create extension if not exists pg_cron;
create extension if not exists pg_net;

-- Optional: remove old schedule if already exists
do $$
declare
  v_job_id bigint;
begin
  select jobid into v_job_id
  from cron.job
  where jobname = 'process_notification_queue'
  limit 1;

  if v_job_id is not null then
    perform cron.unschedule(v_job_id);
  end if;
end $$;

select
  cron.schedule(
    'process_notification_queue',
    '* * * * *',
    $$
      select
        net.http_post(
          url := 'https://<PROJECT_REF>.functions.supabase.co/process-notification-queue',
          headers := jsonb_build_object(
            'Content-Type', 'application/json',
            'x-queue-secret', '<QUEUE_WORKER_SECRET>'
          ),
          body := jsonb_build_object('limit', 75)
        );
    $$
  );
