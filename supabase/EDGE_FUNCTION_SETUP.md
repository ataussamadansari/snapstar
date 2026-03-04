## Edge Function Setup (FCM Queue Worker)

### Edge Function name
- `process-notification-queue`

### Folder location
- `supabase/functions/process-notification-queue/index.ts`

### SQL run order
1. `supabase/sql/instagram_schema_patch_v2.sql`
2. `supabase/sql/hashtags_search_feed_ranking.sql`
3. `supabase/sql/notification_queue_edge_functions.sql`
4. `supabase/sql/notification_queue_cron_setup.sql`

### Before running cron SQL
`notification_queue_cron_setup.sql` me ye 2 placeholders replace karo:
- `<PROJECT_REF>`
- `<QUEUE_WORKER_SECRET>`

### Deploy commands
```bash
supabase secrets set --project-ref <PROJECT_REF> SUPABASE_URL="https://<PROJECT_REF>.supabase.co"
supabase secrets set --project-ref <PROJECT_REF> SUPABASE_SERVICE_ROLE_KEY="<SERVICE_ROLE_KEY>"
supabase secrets set --project-ref <PROJECT_REF> FCM_SERVER_KEY="<FIREBASE_LEGACY_SERVER_KEY>"
supabase secrets set --project-ref <PROJECT_REF> QUEUE_WORKER_SECRET="<RANDOM_LONG_SECRET>"

supabase functions deploy process-notification-queue --project-ref <PROJECT_REF> --no-verify-jwt
```

### Quick test
```bash
curl -X POST "https://<PROJECT_REF>.functions.supabase.co/process-notification-queue" \
  -H "Content-Type: application/json" \
  -H "x-queue-secret: <QUEUE_WORKER_SECRET>" \
  -d '{"limit":50}'
```
