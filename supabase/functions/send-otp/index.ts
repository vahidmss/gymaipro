// send-otp — same import style as send-notifications (no jsr.io)
import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.44.2'

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Content-Type': 'application/json',
}

const MAX_SENDS_PER_PHONE_HOUR = 5
const MAX_SENDS_PER_IP_HOUR = 30

type SendOtpRequest = {
  phone_number?: string
}

function normalizePhone(phone: string): string {
  let n = phone.replace(/\s+/g, '')
  if (!n.startsWith('0')) n = `0${n}`
  return n
}

function toInternationalPhone(phone: string): string {
  if (phone.startsWith('0')) return `98${phone.substring(1)}`
  if (!phone.startsWith('98')) return `98${phone}`
  return phone
}

function generateOtp(): string {
  const n = crypto.getRandomValues(new Uint32Array(1))[0]! % 900000
  return String(100000 + n)
}

function clientIp(req: Request): string {
  return (
    req.headers.get('x-forwarded-for')?.split(',')[0]?.trim() ||
    req.headers.get('x-real-ip') ||
    'unknown'
  )
}

async function sendSms(
  internationalPhone: string,
  code: string,
): Promise<{ ok: boolean; detail?: string }> {
  const baseUrl =
    Deno.env.get('SMS_API_BASE_URL')?.trim() ||
    'https://rest.payamak-panel.com/api/SendSMS/BaseServiceNumber'
  const username = Deno.env.get('SMS_API_USERNAME')?.trim() ?? ''
  const password = Deno.env.get('SMS_API_PASSWORD')?.trim() ?? ''
  const bodyIdRaw = Deno.env.get('SMS_API_BODY_ID')?.trim() ?? '0'
  const bodyId = parseInt(bodyIdRaw, 10)

  if (!username || !password || !bodyId) {
    console.error('SMS credentials missing in functions container')
    return { ok: false, detail: 'missing SMS env in container' }
  }

  // Payamak pattern (bodyId): text = variable(s) only, not full free text
  const message = bodyId > 0 ? code : `کد تایید شما: ${code}\nGymAI Pro`
  const form = new URLSearchParams({
    username,
    password,
    to: internationalPhone,
    text: message,
    bodyId: String(bodyId),
  })

  let res: Response
  try {
    res = await fetch(baseUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        Accept: 'application/json',
      },
      body: form.toString(),
    })
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e)
    console.error('SMS fetch failed', msg)
    return { ok: false, detail: `network: ${msg}` }
  }

  const bodyText = await res.text()
  if (!res.ok) {
    console.error('SMS HTTP error', res.status, bodyText)
    return { ok: false, detail: `http ${res.status}: ${bodyText.slice(0, 200)}` }
  }

  try {
    const data = JSON.parse(bodyText)
    const ok =
      data?.StrRetStatus === '1' ||
      data?.StrRetStatus === 1 ||
      data?.RetStatus === 1 ||
      data?.RetStatus === '1' ||
      data?.success === true ||
      data?.status === 'success' ||
      data?.status === 200
    if (!ok) {
      console.error('SMS API rejected', bodyText)
      return {
        ok: false,
        detail: `api RetStatus=${data?.RetStatus} StrRetStatus=${data?.StrRetStatus} Value=${data?.Value ?? ''}`,
      }
    }
    return { ok: true }
  } catch {
    console.log('SMS non-JSON 200', bodyText.slice(0, 200))
    return { ok: bodyText.length > 0, detail: bodyText.slice(0, 120) }
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
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? 'https://api.gymaipro.ir'
    const serviceKey =
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')?.trim() ??
      Deno.env.get('SERVICE_ROLE_KEY')?.trim() ??
      ''
    if (!serviceKey) {
      return new Response(
        JSON.stringify({
          error: 'server-misconfig',
          message: 'SUPABASE_SERVICE_ROLE_KEY روی سرور تنظیم نشده است',
        }),
        { status: 500, headers: cors },
      )
    }

    const body = (await req.json()) as SendOtpRequest
    const rawPhone = body.phone_number?.trim() ?? ''
    if (!/^09\d{9}$/.test(normalizePhone(rawPhone))) {
      return new Response(
        JSON.stringify({
          error: 'invalid-phone',
          message: 'شماره موبایل معتبر نیست',
        }),
        { status: 400, headers: cors },
      )
    }

    const phone = normalizePhone(rawPhone)
    const ip = clientIp(req)
    const sb = createClient(supabaseUrl, serviceKey, {
      auth: { persistSession: false },
    })

    const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000).toISOString()

    const { count: phoneCount } = await sb
      .from('otp_send_log')
      .select('id', { count: 'exact', head: true })
      .eq('phone_number', phone)
      .gte('created_at', oneHourAgo)

    if ((phoneCount ?? 0) >= MAX_SENDS_PER_PHONE_HOUR) {
      return new Response(
        JSON.stringify({
          error: 'rate-limit',
          message: 'تعداد درخواست OTP بیش از حد مجاز است. کمی بعد تلاش کنید.',
        }),
        { status: 429, headers: cors },
      )
    }

    if (ip !== 'unknown') {
      const { count: ipCount } = await sb
        .from('otp_send_log')
        .select('id', { count: 'exact', head: true })
        .eq('ip_address', ip)
        .gte('created_at', oneHourAgo)

      if ((ipCount ?? 0) >= MAX_SENDS_PER_IP_HOUR) {
        return new Response(
          JSON.stringify({
            error: 'rate-limit',
            message: 'درخواست‌های زیاد از این شبکه. بعداً تلاش کنید.',
          }),
          { status: 429, headers: cors },
        )
      }
    }

    const code = generateOtp()
    const expiresAt = new Date(Date.now() + 2 * 60 * 1000).toISOString()

    const { error: insertError } = await sb.from('otp_codes').insert({
      phone_number: phone,
      code,
      expires_at: expiresAt,
      is_used: false,
    })

    if (insertError) {
      console.error('otp_codes insert failed', insertError.message)
      return new Response(
        JSON.stringify({
          error: 'save-failed',
          message: 'خطا در ذخیره کد تایید',
        }),
        { status: 500, headers: cors },
      )
    }

    await sb.from('otp_send_log').insert({
      phone_number: phone,
      ip_address: ip,
    })

    const smsResult = await sendSms(toInternationalPhone(phone), code)

    return new Response(
      JSON.stringify({
        ok: true,
        sms_sent: smsResult.ok,
        message: smsResult.ok
          ? 'کد تایید ارسال شد'
          : 'کد ثبت شد اما ارسال پیامک ناموفق بود',
        ...(smsResult.ok ? {} : { sms_detail: smsResult.detail }),
      }),
      { status: 200, headers: cors },
    )
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e)
    return new Response(
      JSON.stringify({ error: 'server', message }),
      { status: 500, headers: cors },
    )
  }
})
