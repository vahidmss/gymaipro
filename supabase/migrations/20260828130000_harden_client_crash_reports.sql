-- Harden client crash reports with safe diagnostics and occurrence aggregation.
-- Existing rows remain valid; the client continues to work if this migration
-- has not been deployed yet because upload failures are queued locally.

ALTER TABLE public.client_crash_reports
  ADD COLUMN IF NOT EXISTS error_type TEXT,
  ADD COLUMN IF NOT EXISTS is_fatal BOOLEAN NOT NULL DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS session_id TEXT,
  ADD COLUMN IF NOT EXISTS context JSONB NOT NULL DEFAULT '{}'::jsonb,
  ADD COLUMN IF NOT EXISTS last_seen_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  ADD COLUMN IF NOT EXISTS occurrence_count INTEGER NOT NULL DEFAULT 1;

CREATE INDEX IF NOT EXISTS idx_client_crash_reports_last_seen
  ON public.client_crash_reports (last_seen_at DESC);

CREATE INDEX IF NOT EXISTS idx_client_crash_reports_fatal
  ON public.client_crash_reports (is_fatal, created_at DESC);

ALTER TABLE public.client_crash_reports
  DROP CONSTRAINT IF EXISTS client_crash_reports_occurrence_count_positive;

ALTER TABLE public.client_crash_reports
  ADD CONSTRAINT client_crash_reports_occurrence_count_positive
  CHECK (occurrence_count > 0);

COMMENT ON TABLE public.client_crash_reports IS
  'Client error events. Payloads must be sanitized; raw secrets and phone numbers are forbidden.';