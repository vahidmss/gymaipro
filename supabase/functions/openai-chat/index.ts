// openai-chat proxy — same import style as send-notifications (no jsr.io)
import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.44.2'

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Content-Type': 'application/json',
}

type ChatRequest = {
  model?: string
  messages: Array<{ role: string; content: string }>
  temperature?: number
  max_tokens?: number
  response_format?: { type: string }
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
    const openaiKey = Deno.env.get('OPENAI_API_KEY')?.trim()
    if (!openaiKey) {
      return new Response(
        JSON.stringify({
          error: {
            message:
              'OPENAI_API_KEY روی سرور تنظیم نشده است. در secrets سرور مقداردهی کنید.',
          },
        }),
        { status: 500, headers: cors },
      )
    }

    const authHeader =
      req.headers.get('authorization') ?? req.headers.get('Authorization') ?? ''
    if (!authHeader.startsWith('Bearer ')) {
      return new Response(
        JSON.stringify({ error: { message: 'ورود به حساب الزامی است' } }),
        { status: 401, headers: cors },
      )
    }

    const supabaseUrl =
      Deno.env.get('SUPABASE_URL') ?? 'https://api.gymaipro.ir'
    const supabaseAnon =
      Deno.env.get('SUPABASE_ANON_KEY') ?? Deno.env.get('ANON_KEY') ?? ''

    if (!supabaseAnon) {
      return new Response(
        JSON.stringify({ error: { message: 'پیکربندی سرور ناقص است' } }),
        { status: 500, headers: cors },
      )
    }

    const jwt = authHeader.slice('Bearer '.length).trim()
    const supabase = createClient(supabaseUrl, supabaseAnon, {
      auth: { persistSession: false },
    })

    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser(jwt)
    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: { message: 'نشست کاربر معتبر نیست' } }),
        { status: 401, headers: cors },
      )
    }

    const body = (await req.json()) as ChatRequest
    if (!body?.messages?.length) {
      return new Response(
        JSON.stringify({ error: { message: 'messages الزامی است' } }),
        { status: 400, headers: cors },
      )
    }

    const openaiBody: Record<string, unknown> = {
      model: body.model ?? 'gpt-4o-mini',
      messages: body.messages,
      temperature: body.temperature ?? 0.7,
      max_tokens: body.max_tokens ?? 1000,
    }
    if (body.response_format) {
      openaiBody.response_format = body.response_format
    }

    // سقف توکن — درخواست‌های سنگین باعث timeout گیت‌وی (504) می‌شوند
    const maxTokens = Math.min(Math.max(body.max_tokens ?? 1000, 64), 4096)
    openaiBody.max_tokens = maxTokens

    const model = (body.model ?? 'gpt-4o-mini').trim()
    openaiBody.model = model

    const controller = new AbortController()
    const openaiTimeoutMs = 50_000
    const timeoutId = setTimeout(() => controller.abort(), openaiTimeoutMs)

    const relayBase = Deno.env.get('OPENAI_RELAY_URL')?.trim().replace(/\/$/, '')
    const relaySecret = Deno.env.get('OPENAI_RELAY_SECRET')?.trim()
    const useRelay = Boolean(relayBase && relaySecret)

    const aiBase =
      Deno.env.get('AI_API_BASE_URL')?.trim().replace(/\/$/, '') ||
      Deno.env.get('OPENAI_BASE_URL')?.trim().replace(/\/$/, '') ||
      'https://api.openai.com'

    const openaiUrl = useRelay
      ? `${relayBase}/v1/chat/completions`
      : `${aiBase}/v1/chat/completions`

    const openaiHeaders: Record<string, string> = {
      'Content-Type': 'application/json',
    }
    if (useRelay) {
      openaiHeaders['X-Relay-Secret'] = relaySecret!
    } else {
      openaiHeaders['Authorization'] = `Bearer ${openaiKey}`
    }

    let openaiRes: Response
    try {
      openaiRes = await fetch(openaiUrl, {
        method: 'POST',
        headers: openaiHeaders,
        body: JSON.stringify(openaiBody),
        signal: controller.signal,
      })
    } catch (fetchErr) {
      const aborted =
        fetchErr instanceof Error && fetchErr.name === 'AbortError'
      return new Response(
        JSON.stringify({
          error: {
            message: aborted
              ? `OpenAI پاسخ نداد (${openaiTimeoutMs / 1000}s). احتمالاً سرور به api.openai.com دسترسی کند ندارد یا مدل/پرامپت خیلی سنگین است.`
              : `خطا در اتصال به OpenAI: ${fetchErr instanceof Error ? fetchErr.message : String(fetchErr)}`,
          },
        }),
        { status: aborted ? 504 : 502, headers: cors },
      )
    } finally {
      clearTimeout(timeoutId)
    }

    const text = await openaiRes.text()
    return new Response(text, {
      status: openaiRes.status,
      headers: cors,
    })
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e)
    return new Response(
      JSON.stringify({ error: { message: `خطای سرور: ${message}` } }),
      { status: 500, headers: cors },
    )
  }
})
