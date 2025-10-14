// supabase/functions/wallet-topup-confirm/index.ts
import 'jsr:@supabase/functions-js/edge-runtime.d.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-signature',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Content-Type': 'application/json',
}

const textEncoder = new TextEncoder()

async function hmacSha256Hex(secret: string, payload: string) {
  const key = await crypto.subtle.importKey(
    'raw',
    textEncoder.encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign']
  )
  const sig = await crypto.subtle.sign('HMAC', key, textEncoder.encode(payload))
  return Array.from(new Uint8Array(sig)).map(b => b.toString(16).padStart(2, '0')).join('')
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors })
  if (req.method !== 'POST') return new Response(JSON.stringify({ error: 'method-not-allowed' }), { status: 405, headers: cors })

  try {
    const signature = req.headers.get('x-signature') || ''
    const secret = Deno.env.get('GYM_TOPUP_SECRET')
    const SUPABASE_URL = Deno.env.get('SUPABASE_URL') || 'https://oaztoennovtcfcxvnswa.supabase.co'
    const SERVICE_ROLE_ENV = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || ''
    const authHeader = req.headers.get('authorization') || req.headers.get('Authorization') || ''
    const bearer = authHeader.startsWith('Bearer ') ? authHeader.substring('Bearer '.length).trim() : ''
    const apiKeyHeader = req.headers.get('apikey') || ''
    const supabaseKey = SERVICE_ROLE_ENV || bearer || apiKeyHeader

    if (!secret || !supabaseKey) {
      return new Response(
        JSON.stringify({ error: 'server-misconfig', detail: { missingSecret: !secret, missingSupabaseKey: !supabaseKey } }),
        { status: 500, headers: cors },
      )
    }

    // بدنهٔ خام را بگیر تا ترتیب کلیدها حفظ شود (برای HMAC)
    const rawBody = await req.text()
    let body = JSON.parse(rawBody) as {
      session_id: string
      gateway: 'zibal' | string
      gateway_ref?: string
    }

    if (!body?.session_id || !body?.gateway || !body?.gateway_ref) {
      return new Response(JSON.stringify({ error: 'missing-fields' }), { status: 400, headers: cors })
    }

    // verify HMAC روی بدنهٔ خام
    const expectedHex = await hmacSha256Hex(secret, rawBody)
    if (signature !== expectedHex) {
      return new Response(JSON.stringify({ error: 'bad-signature' }), { status: 403, headers: cors })
    }

    const sb = createClient(SUPABASE_URL, supabaseKey, { auth: { persistSession: false } })

    // فراخوانی RPC اتمیک (واحد پیش‌فرض: تومان IRT)
    const { data, error } = await sb.rpc('wallet_topup_apply_v2', {
      p_session_id: body.session_id,
      p_gateway: body.gateway,
      p_gateway_ref: body.gateway_ref,
      p_units: 'IRT',
    })

    if (error) {
      return new Response(
        JSON.stringify({ error: 'apply-failed', detail: error.message }),
        { status: 500, headers: cors },
      )
    }

    return new Response(JSON.stringify({ ok: true, result: data ?? null }), { status: 200, headers: cors })

  } catch (e) {
    return new Response(JSON.stringify({ error: 'server', detail: String(e) }), { status: 500, headers: cors })
  }
})
