## Process Notification Queue (Edge Function)

### Required secrets

Set these in Supabase project secrets:

- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`
- `FCM_SERVER_KEY`
- `QUEUE_WORKER_SECRET` (optional but recommended)

### Deploy

```bash
supabase functions deploy process-notification-queue --no-verify-jwt
```

### Manual invoke

```bash
curl -X POST \
  "https://<PROJECT_REF>.functions.supabase.co/process-notification-queue" \
  -H "Content-Type: application/json" \
  -H "x-queue-secret: <QUEUE_WORKER_SECRET>" \
  -d '{"limit":50}'
```

### DB setup order

1. Run `supabase/sql/instagram_schema_patch_v2.sql`
2. Run `supabase/sql/notification_queue_edge_functions.sql`
3. Run `supabase/sql/notification_queue_cron_setup.sql` (after replacing placeholders)
