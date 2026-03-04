import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.8";

type QueueJob = {
  id: string;
  user_id: string;
  actor_id: string | null;
  type: string;
  payload: Record<string, unknown> | null;
  attempts: number;
};

type FcmLegacyResult = {
  ok: boolean;
  permanentFailure: boolean;
  error?: string;
  response?: unknown;
};

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const FCM_SERVER_KEY = Deno.env.get("FCM_SERVER_KEY") ?? "";
const QUEUE_WORKER_SECRET = Deno.env.get("QUEUE_WORKER_SECRET") ?? "";
const DEFAULT_BATCH_SIZE = 50;
const MAX_ATTEMPTS = 6;

if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
  throw new Error("Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY env");
}

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
  auth: { persistSession: false, autoRefreshToken: false },
});

serve(async (req) => {
  if (req.method !== "POST") {
    return json(405, { error: "Only POST allowed" });
  }

  if (QUEUE_WORKER_SECRET) {
    const incoming = req.headers.get("x-queue-secret");
    if (!incoming || incoming !== QUEUE_WORKER_SECRET) {
      return json(401, { error: "Unauthorized queue secret" });
    }
  }

  if (!FCM_SERVER_KEY) {
    return json(500, { error: "Missing FCM_SERVER_KEY env" });
  }

  let limit = DEFAULT_BATCH_SIZE;
  try {
    const body = await req.json().catch(() => ({}));
    if (typeof body?.limit === "number") {
      limit = Math.max(1, Math.min(200, Math.floor(body.limit)));
    }
  } catch (_) {}

  const { data: jobs, error: claimError } = await supabase.rpc(
    "claim_notification_jobs",
    { p_limit: limit },
  );

  if (claimError) {
    return json(500, {
      error: "Failed to claim jobs",
      details: claimError.message,
    });
  }

  const queueJobs = (jobs ?? []) as QueueJob[];
  if (queueJobs.length === 0) {
    return json(200, { claimed: 0, delivered: 0, retried: 0, failed: 0 });
  }

  let delivered = 0;
  let retried = 0;
  let failed = 0;

  for (const job of queueJobs) {
    const result = await processJob(job);
    if (result.status === "delivered") delivered++;
    else if (result.status === "retry") retried++;
    else failed++;
  }

  return json(200, {
    claimed: queueJobs.length,
    delivered,
    retried,
    failed,
  });
});

async function processJob(
  job: QueueJob,
): Promise<{ status: "delivered" | "retry" | "failed" }> {
  const payload = job.payload ?? {};
  const title = asString(payload["title"]) || "Snapstar";
  const message = asString(payload["message"]) || "You have a new notification";
  const route = asString(payload["route"]) || "/notifications";

  const { data: tokens, error: tokenError } = await supabase
    .from("user_push_tokens")
    .select("token, platform")
    .eq("user_id", job.user_id)
    .eq("is_active", true);

  if (tokenError) {
    await markRetryOrFail(job, `token fetch failed: ${tokenError.message}`, {
      step: "fetch_tokens",
    });
    return { status: job.attempts >= MAX_ATTEMPTS ? "failed" : "retry" };
  }

  if (!tokens || tokens.length === 0) {
    await completeJob(job.id, "delivered", null, {
      step: "no_tokens",
      detail: "No active user push token",
    });
    return { status: "delivered" };
  }

  let atLeastOneDelivered = false;
  let transientFailures = 0;
  const tokenResponses: unknown[] = [];

  for (const tokenRow of tokens) {
    const token = asString(tokenRow.token);
    if (!token) continue;

    const sendResult = await sendLegacyFcm({
      token,
      title,
      body: message,
      data: {
        route,
        type: asString(payload["type"]) ?? job.type,
        notification_id: asString(payload["notification_id"]) ?? "",
        post_id: asString(payload["post_id"]) ?? "",
      },
    });

    tokenResponses.push({ token, ...sendResult });

    if (sendResult.ok) {
      atLeastOneDelivered = true;
      continue;
    }

    if (sendResult.permanentFailure) {
      await supabase
        .from("user_push_tokens")
        .update({ is_active: false, updated_at: new Date().toISOString() })
        .eq("user_id", job.user_id)
        .eq("token", token);
    } else {
      transientFailures++;
    }
  }

  if (atLeastOneDelivered) {
    await completeJob(job.id, "delivered", null, {
      step: "fanout",
      token_responses: tokenResponses,
    });
    return { status: "delivered" };
  }

  if (job.attempts >= MAX_ATTEMPTS) {
    await completeJob(
      job.id,
      "failed",
      "Max attempts reached without successful token delivery",
      { step: "fanout", token_responses: tokenResponses },
    );
    return { status: "failed" };
  }

  const reason = transientFailures > 0
    ? "Transient FCM errors, retrying"
    : "No successful FCM response";

  await markRetryOrFail(job, reason, {
    step: "fanout",
    token_responses: tokenResponses,
  });
  return { status: "retry" };
}

async function markRetryOrFail(
  job: QueueJob,
  errorMessage: string,
  lastResponse: Record<string, unknown>,
) {
  if (job.attempts >= MAX_ATTEMPTS) {
    await completeJob(job.id, "failed", errorMessage, lastResponse);
    return;
  }

  const retryDelaySeconds = Math.min(30 * 2 ** Math.max(job.attempts - 1, 0), 3600);
  await completeJob(job.id, "retry", errorMessage, lastResponse, retryDelaySeconds);
}

async function completeJob(
  jobId: string,
  status: "delivered" | "retry" | "failed",
  errorMessage: string | null,
  response: Record<string, unknown>,
  retryDelaySeconds?: number,
) {
  await supabase.rpc("complete_notification_job", {
    p_job_id: jobId,
    p_status: status,
    p_last_error: errorMessage,
    p_last_response: response,
    p_retry_delay_seconds: retryDelaySeconds ?? null,
  });
}

async function sendLegacyFcm(args: {
  token: string;
  title: string;
  body: string;
  data: Record<string, string>;
}): Promise<FcmLegacyResult> {
  try {
    const response = await fetch("https://fcm.googleapis.com/fcm/send", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `key=${FCM_SERVER_KEY}`,
      },
      body: JSON.stringify({
        to: args.token,
        priority: "high",
        notification: {
          title: args.title,
          body: args.body,
        },
        data: args.data,
      }),
    });

    const parsed = await response.json().catch(() => ({}));
    if (!response.ok) {
      return {
        ok: false,
        permanentFailure: response.status === 400 || response.status === 401 || response.status === 403,
        error: `FCM HTTP ${response.status}`,
        response: parsed,
      };
    }

    const result = Array.isArray((parsed as any)?.results)
      ? (parsed as any).results[0]
      : undefined;

    if ((parsed as any)?.success >= 1 || result?.message_id) {
      return { ok: true, permanentFailure: false, response: parsed };
    }

    const err = asString(result?.error) ?? "Unknown FCM error";
    const permanentTokenErrors = new Set([
      "InvalidRegistration",
      "NotRegistered",
      "MismatchSenderId",
    ]);

    return {
      ok: false,
      permanentFailure: permanentTokenErrors.has(err),
      error: err,
      response: parsed,
    };
  } catch (error) {
    return {
      ok: false,
      permanentFailure: false,
      error: String(error),
    };
  }
}

function asString(value: unknown): string | null {
  if (typeof value !== "string") return null;
  const v = value.trim();
  return v.length > 0 ? v : null;
}

function json(status: number, body: Record<string, unknown>) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
