// send-program-sms — پیامک الگویی پس از خرید برنامه مربی (مربی + شاگرد)
import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.44.2'

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Content-Type': 'application/json',
}

type SendProgramSmsRequest = {
  subscription_id?: string
}

function normalizePhone(phone: string): string {
  let n = phone.replace(/\s+/g, '')
  if (!n.startsWith('0') && n.length === 10) n = `0${n}`
  return n
}

function toInternationalPhone(phone: string): string {
  const n = normalizePhone(phone)
  if (n.startsWith('0')) return `98${n.substring(1)}`
  if (!n.startsWith('98')) return `98${n}`
  return n
}

function displayName(row: Record<string, unknown> | null): string {
  if (!row) return 'کاربر'
  const first = String(row.first_name ?? '').trim()
  const last = String(row.last_name ?? '').trim()
  const full = `${first} ${last}`.trim()
  if (full) return full
  const username = String(row.username ?? '').trim()
  if (username) return username
  return 'کاربر'
}

async function sendPatternSms(
  internationalPhone: string,
  bodyId: number,
  parameters: string[],
): Promise<{ ok: boolean; detail?: string }> {
  const baseUrl =
    Deno.env.get('SMS_API_BASE_URL')?.trim() ||
    'https://rest.payamak-panel.com/api/SendSMS/BaseServiceNumber'
  const username = Deno.env.get('SMS_API_USERNAME')?.trim() ?? ''
  const password = Deno.env.get('SMS_API_PASSWORD')?.trim() ?? ''

  if (!username || !password || bodyId <= 0) {
    return { ok: false, detail: 'missing SMS env or bodyId' }
  }

  const form = new URLSearchParams({
    username,
    password,
    to: internationalPhone,
    text: parameters.map((p) => p.trim()).join(';'),
    bodyId: String(bodyId),
  })

  try {
    const res = await fetch(baseUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        Accept: 'application/json',
      },
      body: form.toString(),
    })
    const bodyText = await res.text()
    if (!res.ok) {
      return { ok: false, detail: `http ${res.status}: ${bodyText.slice(0, 200)}` }
    }
    try {
      const data = JSON.parse(bodyText)
      const ok =
        data?.StrRetStatus === '1' ||
        data?.StrRetStatus === 1 ||
        data?.RetStatus === 1 ||
        data?.success === true
      return { ok, detail: ok ? undefined : bodyText.slice(0, 200) }
    } catch {
      return { ok: true }
    }
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e)
    return { ok: false, detail: msg }
  }
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
    const authHeader = req.headers.get('Authorization') ?? ''
    if (!authHeader.startsWith('Bearer ')) {
      return new Response(JSON.stringify({ error: 'unauthorized' }), {
        status: 401,
        headers: cors,
      })
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? 'https://api.gymaipro.ir'
    const anonKey = Deno.env.get('SUPABASE_ANON_KEY')?.trim() ?? ''
    const serviceKey =
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')?.trim() ??
      Deno.env.get('SERVICE_ROLE_KEY')?.trim() ??
      ''

    if (!anonKey || !serviceKey) {
      return new Response(JSON.stringify({ error: 'server-misconfig' }), {
        status: 500,
        headers: cors,
      })
    }

    const userClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
      auth: { persistSession: false },
    })
    const {
      data: { user },
      error: userError,
    } = await userClient.auth.getUser()
    if (userError || !user) {
      return new Response(JSON.stringify({ error: 'unauthorized' }), {
        status: 401,
        headers: cors,
      })
    }

    const body = (await req.json()) as SendProgramSmsRequest
    const subscriptionId = body.subscription_id?.trim() ?? ''
    if (!subscriptionId) {
      return new Response(JSON.stringify({ error: 'missing-subscription-id' }), {
        status: 400,
        headers: cors,
      })
    }

    const sb = createClient(supabaseUrl, serviceKey, {
      auth: { persistSession: false },
    })

    const { data: buyerProfile } = await sb
      .from('profiles')
      .select('id')
      .eq('auth_user_id', user.id)
      .maybeSingle()

    const buyerProfileId = buyerProfile?.id ?? user.id

    const { data: sub, error: subError } = await sb
      .from('trainer_subscriptions')
      .select('id, user_id, trainer_id')
      .eq('id', subscriptionId)
      .maybeSingle()

    if (subError || !sub) {
      return new Response(JSON.stringify({ error: 'subscription-not-found' }), {
        status: 404,
        headers: cors,
      })
    }

    if (sub.user_id !== buyerProfileId && sub.user_id !== user.id) {
      return new Response(JSON.stringify({ error: 'forbidden' }), {
        status: 403,
        headers: cors,
      })
    }

    const coachBodyId = parseInt(
      Deno.env.get('SMS_BODY_ID_TRAINER_PROGRAM_REQUEST')?.trim() ?? '450989',
      10,
    )
    const buyerBodyId = parseInt(
      Deno.env.get('SMS_BODY_ID_USER_PROGRAM_PURCHASE')?.trim() ?? '450988',
      10,
    )

    const { data: trainerProfile } = await sb
      .from('profiles')
      .select('id, phone_number, first_name, last_name, username')
      .eq('id', sub.trainer_id)
      .maybeSingle()

    const { data: athleteProfile } = await sb
      .from('profiles')
      .select('id, phone_number, first_name, last_name, username')
      .eq('id', sub.user_id)
      .maybeSingle()

    const results: Record<string, unknown> = {}

    const trainerPhone = normalizePhone(
      String(trainerProfile?.phone_number ?? ''),
    )
    if (/^09\d{9}$/.test(trainerPhone)) {
      results.coach = await sendPatternSms(
        toInternationalPhone(trainerPhone),
        coachBodyId,
        [displayName(trainerProfile)],
      )
    } else {
      results.coach = { ok: false, detail: 'trainer phone missing' }
    }

    const athletePhone = normalizePhone(
      String(athleteProfile?.phone_number ?? ''),
    )
    if (/^09\d{9}$/.test(athletePhone)) {
      results.buyer = await sendPatternSms(
        toInternationalPhone(athletePhone),
        buyerBodyId,
        [displayName(athleteProfile)],
      )
    } else {
      results.buyer = { ok: false, detail: 'buyer phone missing' }
    }

    const coachOk = (results.coach as { ok?: boolean })?.ok === true
    const buyerOk = (results.buyer as { ok?: boolean })?.ok === true

    return new Response(
      JSON.stringify({
        ok: coachOk || buyerOk,
        coach_sent: coachOk,
        buyer_sent: buyerOk,
        results,
      }),
      { status: 200, headers: cors },
    )
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e)
    return new Response(JSON.stringify({ error: 'server', message }), {
      status: 500,
      headers: cors,
    })
  }
})
