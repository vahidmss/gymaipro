-- Server-side alert state for client crash fingerprints.
-- The table is intentionally inaccessible to client roles.

CREATE TABLE IF NOT EXISTS public.client_crash_alerts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  fingerprint TEXT NOT NULL UNIQUE,
  first_alerted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  last_alerted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  alert_count INTEGER NOT NULL DEFAULT 1,
  last_occurrence_count INTEGER NOT NULL DEFAULT 1,
  last_app_version TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_client_crash_alerts_last_alerted
  ON public.client_crash_alerts (last_alerted_at DESC);

ALTER TABLE public.client_crash_alerts ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON public.client_crash_alerts FROM anon, authenticated;
GRANT ALL ON public.client_crash_alerts TO service_role;

ALTER TABLE public.client_crash_alerts
  DROP CONSTRAINT IF EXISTS client_crash_alerts_counts_positive;

ALTER TABLE public.client_crash_alerts
  ADD CONSTRAINT client_crash_alerts_counts_positive
  CHECK (alert_count > 0 AND last_occurrence_count > 0);
