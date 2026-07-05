// CORS-safe audio proxy for Flutter Web / PWA (HTML audio cannot send custom headers).
import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type, range',
  'Access-Control-Allow-Methods': 'GET, HEAD, OPTIONS',
  'Access-Control-Expose-Headers': 'Content-Length, Content-Range, Accept-Ranges',
}

const DEFAULT_ALLOWED = [
  'dl.gymaipro.ir',
  'gymaipro.ir',
  'www.gymaipro.ir',
  'api.gymaipro.ir',
]

function allowedHosts(): Set<string> {
  const raw = Deno.env.get('MEDIA_PROXY_ALLOWED_HOSTS')?.trim()
  const list = raw
    ? raw.split(',').map((h) => h.trim().toLowerCase()).filter(Boolean)
    : DEFAULT_ALLOWED
  return new Set(list)
}

function isAllowedUrl(raw: string, hosts: Set<string>): URL | null {
  try {
    const parsed = new URL(raw)
    if (parsed.protocol !== 'https:' && parsed.protocol !== 'http:') return null
    const host = parsed.hostname.toLowerCase()
    if (!hosts.has(host)) return null
    return parsed
  } catch {
    return null
  }
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: cors })
  }

  if (req.method !== 'GET' && req.method !== 'HEAD') {
    return new Response('method-not-allowed', { status: 405, headers: cors })
  }

  const targetRaw = new URL(req.url).searchParams.get('url')?.trim()
  if (!targetRaw) {
    return new Response('missing url', { status: 400, headers: cors })
  }

  const target = isAllowedUrl(targetRaw, allowedHosts())
  if (!target) {
    return new Response('url not allowed', { status: 403, headers: cors })
  }

  try {
    const upstreamHeaders: Record<string, string> = {}
    const range = req.headers.get('range')
    if (range) upstreamHeaders['Range'] = range

    const upstream = await fetch(target.toString(), {
      method: req.method,
      headers: upstreamHeaders,
    })

    const outHeaders: Record<string, string> = { ...cors }
    const pass = ['content-type', 'content-length', 'content-range', 'accept-ranges']
    for (const key of pass) {
      const v = upstream.headers.get(key)
      if (v) outHeaders[key] = v
    }
    if (!outHeaders['content-type']) {
      outHeaders['content-type'] = 'audio/mpeg'
    }

    return new Response(req.method === 'HEAD' ? null : upstream.body, {
      status: upstream.status,
      headers: outHeaders,
    })
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e)
    return new Response(`proxy error: ${message}`, { status: 502, headers: cors })
  }
})
