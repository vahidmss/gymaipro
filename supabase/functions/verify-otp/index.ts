// verify-otp — same import style as send-notifications (no jsr.io)
import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.44.2'

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Content-Type': 'application/json',
}

const MAX_VERIFY_ATTEMPTS = 8
const VERIFY_WINDOW_MINUTES = 15

type VerifyOtpRequest = {
  phone_number?: string
  code?: string
}

function normalizePhone(phone: string): string {
  let n = phone.replace(/\s+/g, '')
  if (!n.startsWith('0')) n = `0${n}`
  return n
}

function clientIp(req: Request): string {
  return (
    req.headers.get('x-forwarded-for')?.split(',')[0]?.trim() ||
    req.headers.get('x-real-ip') ||
    'unknown'
  )
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors })
  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'method-not-allowed' }), {
      status: 405,
      headers: cors,
    })
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? 'https://api.gymaipro.ir'
    const serviceKey =
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')?.trim() ??
      Deno.env.get('SERVICE_ROLE_KEY')?.trim() ??
      ''
    if (!serviceKey) {
      return new Response(
        JSON.stringify({ error: 'server-misconfig' }),
        { status: 500, headers: cors },
      )
    }

    const body = (await req.json()) as VerifyOtpRequest
    const phone = normalizePhone(body.phone_number?.trim() ?? '')
    const code = body.code?.trim() ?? ''

    if (!/^09\d{9}$/.test(phone) || !/^\d{6}$/.test(code)) {
      return new Response(
        JSON.stringify({ ok: false, message: 'ورودی نامعتبر' }),
        { status: 400, headers: cors },
      )
    }

    const ip = clientIp(req)
    const sb = createClient(supabaseUrl, serviceKey, {
      auth: { persistSession: false },
    })

    const windowStart = new Date(
      Date.now() - VERIFY_WINDOW_MINUTES * 60 * 1000,
    ).toISOString()

    const { count: attemptCount } = await sb
      .from('otp_verify_log')
      .select('id', { count: 'exact', head: true })
      .eq('phone_number', phone)
      .gte('created_at', windowStart)

    if ((attemptCount ?? 0) >= MAX_VERIFY_ATTEMPTS) {
      return new Response(
        JSON.stringify({
          ok: false,
          message: 'تلاش‌های زیاد. چند دقیقه بعد دوباره امتحان کنید.',
        }),
        { status: 429, headers: cors },
      )
    }

    await sb.from('otp_verify_log').insert({
      phone_number: phone,
      ip_address: ip,
    })

    const { data: row, error } = await sb
      .from('otp_codes')
      .select('id')
      .eq('phone_number', phone)
      .eq('code', code)
      .eq('is_used', false)
      .gt('expires_at', new Date().toISOString())
      .maybeSingle()

    if (error) {
      console.error('verify query failed', error.message)
      return new Response(
        JSON.stringify({ ok: false, message: 'خطای سرور' }),
        { status: 500, headers: cors },
      )
    }

    if (!row?.id) {
      return new Response(JSON.stringify({ ok: false }), {
        status: 200,
        headers: cors,
      })
    }

    await sb
      .from('otp_codes')
      .update({
        is_used: true,
        used_at: new Date().toISOString(),
      })
      .eq('id', row.id)

    return new Response(JSON.stringify({ ok: true }), {
      status: 200,
      headers: cors,
    })
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e)
    return new Response(
      JSON.stringify({ error: 'server', message }),
      { status: 500, headers: cors },
    )
  }
})
