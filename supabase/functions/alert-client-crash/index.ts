import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.44.2'

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Content-Type': 'application/json',
}

const DEFAULT_THRESHOLD = 3
const DEFAULT_WINDOW_MINUTES = 10
const DEFAULT_COOLDOWN_MINUTES = 30

type CrashAlertRequest = {
  fingerprint?: string
}

function json(body: Record<string, unknown>, status = 200): Response {
  return new Response(JSON.stringify(body), { status, headers: cors })
}

function positiveInt(value: string | undefined, fallback: number): number {
  const parsed = Number.parseInt(value?.trim() ?? '', 10)
  return Number.isFinite(parsed) && parsed > 0 ? parsed : fallback
}

function normalizePhone(phone: string): string {
  let normalized = phone.replace(/\s+/g, '')
  if (!normalized.startsWith('0') && normalized.length === 10) {
    normalized = `0${normalized}`
  }
  return normalized
}

function toInternationalPhone(phone: string): string {
  const normalized = normalizePhone(phone)
  return normalized.startsWith('0')
    ? `98${normalized.substring(1)}`
    : normalized.startsWith('98')
      ? normalized
      : `98${normalized}`
}

async function sendAlertSms(
  fingerprint: string,
  occurrenceCount: number,
  appVersion: string,
): Promise<boolean> {
  const phone = normalizePhone(Deno.env.get('OPS_ALERT_PHONE')?.trim() ?? '')
  const username = Deno.env.get('SMS_API_USERNAME')?.trim() ?? ''
  const password = Deno.env.get('SMS_API_PASSWORD')?.trim() ?? ''
  const baseUrl =
    Deno.env.get('SMS_API_BASE_URL')?.trim() ||
    'https://rest.payamak-panel.com/api/SendSMS/BaseServiceNumber'
  const bodyId = positiveInt(
    Deno.env.get('SMS_BODY_ID_CRASH_ALERT'),
    0,
  )

  if (!/^09\d{9}$/.test(phone) || !username || !password || bodyId <= 0) {
    console.error('Crash alert SMS is not configured')
    return false
  }

  const params = [
    fingerprint.substring(0, 12),
    String(occurrenceCount),
    appVersion || 'unknown',
  ]
  const form = new URLSearchParams({
    username,
    password,
    to: toInternationalPhone(phone),
    text: params.join(';'),
    bodyId: String(bodyId),
  })

  try {
    const response = await fetch(baseUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        Accept: 'application/json',
      },
      body: form.toString(),
    })
    const text = await response.text()
    if (!response.ok) {
      console.error('Crash alert SMS HTTP failure', response.status)
      return false
    }
    try {
      const data = JSON.parse(text)
      return (
        data?.StrRetStatus === '1' ||
        data?.StrRetStatus === 1 ||
        data?.RetStatus === '1' ||
        data?.RetStatus === 1 ||
        data?.success === true ||
        data?.status === 'success' ||
        data?.status === 200
      )
    } catch {
      return text.trim().length > 0
    }
  } catch (error) {
    console.error('Crash alert SMS network failure', error)
    return false
  }
}

serve(async (request) => {
  if (request.method === 'OPTIONS') return new Response('ok', { headers: cors })
  if (request.method !== 'POST') return json({ error: 'method-not-allowed' }, 405)

  try {
    const authorization = request.headers.get('Authorization') ?? ''
    if (!authorization.startsWith('Bearer ')) return json({ error: 'unauthorized' }, 401)

    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? 'https://api.gymaipro.ir'
    const anonKey = Deno.env.get('SUPABASE_ANON_KEY')?.trim() ?? ''
    const serviceKey =
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')?.trim() ??
      Deno.env.get('SERVICE_ROLE_KEY')?.trim() ?? ''
    if (!anonKey || !serviceKey) return json({ error: 'server-misconfig' }, 500)

    const userClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authorization } },
      auth: { persistSession: false },
    })
    const { data: authData, error: authError } = await userClient.auth.getUser()
    if (authError || !authData.user) return json({ error: 'unauthorized' }, 401)

    const body = (await request.json()) as CrashAlertRequest
    const fingerprint = body.fingerprint?.trim() ?? ''
    if (!/^[a-f0-9]{64}$/i.test(fingerprint)) {
      return json({ error: 'invalid-fingerprint' }, 400)
    }

    const admin = createClient(supabaseUrl, serviceKey, {
      auth: { persistSession: false },
    })
    const windowMinutes = positiveInt(
      Deno.env.get('CRASH_ALERT_WINDOW_MINUTES'),
      DEFAULT_WINDOW_MINUTES,
    )
    const threshold = positiveInt(
      Deno.env.get('CRASH_ALERT_THRESHOLD'),
      DEFAULT_THRESHOLD,
    )
    const cooldownMinutes = positiveInt(
      Deno.env.get('CRASH_ALERT_COOLDOWN_MINUTES'),
      DEFAULT_COOLDOWN_MINUTES,
    )
    const since = new Date(Date.now() - windowMinutes * 60_000).toISOString()

    const { count, error: countError } = await admin
      .from('client_crash_reports')
      .select('id', { count: 'exact', head: true })
      .eq('fingerprint', fingerprint)
      .gte('created_at', since)
    if (countError) return json({ error: 'count-failed' }, 500)

    const occurrenceCount = count ?? 0
    if (occurrenceCount < threshold) {
      return json({ ok: true, alerted: false, occurrence_count: occurrenceCount })
    }

    const { data: previous, error: previousError } = await admin
      .from('client_crash_alerts')
      .select('id, last_alerted_at, alert_count')
      .eq('fingerprint', fingerprint)
      .maybeSingle()
    if (previousError) return json({ error: 'alert-state-read-failed' }, 500)

    const lastAlerted = previous?.last_alerted_at
      ? Date.parse(previous.last_alerted_at)
      : 0
    if (lastAlerted > Date.now() - cooldownMinutes * 60_000) {
      return json({ ok: true, alerted: false, suppressed: true, occurrence_count: occurrenceCount })
    }

    const { data: latest } = await admin
      .from('client_crash_reports')
      .select('app_version')
      .eq('fingerprint', fingerprint)
      .order('created_at', { ascending: false })
      .limit(1)
      .maybeSingle()

    const sent = await sendAlertSms(
      fingerprint,
      occurrenceCount,
      String(latest?.app_version ?? ''),
    )
    if (!sent) return json({ ok: false, alerted: false, sms_failed: true }, 502)

    const now = new Date().toISOString()
    const { error: stateError } = await admin.from('client_crash_alerts').upsert(
      {
        fingerprint,
        first_alerted_at: previous?.last_alerted_at ?? now,
        last_alerted_at: now,
        alert_count: (previous?.alert_count ?? 0) + 1,
        last_occurrence_count: occurrenceCount,
        last_app_version: String(latest?.app_version ?? ''),
      },
      { onConflict: 'fingerprint' },
    )
    if (stateError) return json({ error: 'alert-state-write-failed' }, 500)

    return json({ ok: true, alerted: true, occurrence_count: occurrenceCount })
  } catch (error) {
    console.error('Crash alert function failed', error)
    return json({ error: 'server' }, 500)
  }
})
