/**
 * Relay رایگان OpenAI روی Cloudflare Workers (خارج از ایران).
 * سرور Supabase ایران به این Worker می‌زند؛ Worker به api.openai.com وصل می‌شود.
 *
 * Secrets در Cloudflare: OPENAI_API_KEY, RELAY_SECRET
 */

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'content-type, x-relay-secret',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders })
    }

    if (request.method !== 'POST') {
      return new Response(JSON.stringify({ error: 'method-not-allowed' }), {
        status: 405,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const relaySecret = env.RELAY_SECRET?.trim()
    const apiKey = env.OPENAI_API_KEY?.trim()
    if (!relaySecret || !apiKey) {
      return new Response(
        JSON.stringify({ error: { message: 'Worker secrets not configured' } }),
        { status: 500, headers: { 'Content-Type': 'application/json' } },
      )
    }

    const incoming = request.headers.get('X-Relay-Secret')?.trim()
    if (!incoming || incoming !== relaySecret) {
      return new Response(JSON.stringify({ error: { message: 'Unauthorized' } }), {
        status: 401,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    const url = new URL(request.url)
    const path = url.pathname.startsWith('/v1/') ? url.pathname : '/v1/chat/completions'
    const openaiUrl = `https://api.openai.com${path}${url.search}`

    const openaiRes = await fetch(openaiUrl, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${apiKey}`,
        'Content-Type': request.headers.get('Content-Type') ?? 'application/json',
      },
      body: request.body,
    })

    return new Response(openaiRes.body, {
      status: openaiRes.status,
      headers: {
        'Content-Type': openaiRes.headers.get('Content-Type') ?? 'application/json',
        ...corsHeaders,
      },
    })
  },
}

interface Env {
  OPENAI_API_KEY: string
  RELAY_SECRET: string
}
