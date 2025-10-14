// deno-lint-ignore-file no-explicit-any
import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.44.2";

type BroadcastRequest = {
  id: string;
  target_type: 'topic' | 'inactive_7d';
  topic: string | null;
  title: string;
  body: string;
  data: any;
};

// Get OAuth2 access token for FCM V1 API using proper RSA signing
async function getFCMAccessToken(): Promise<string> {
  const serviceAccountKey = Deno.env.get('FIREBASE_SERVICE_ACCOUNT_KEY');
  if (!serviceAccountKey) {
    throw new Error('FIREBASE_SERVICE_ACCOUNT_KEY not set');
  }

  const serviceAccount = JSON.parse(serviceAccountKey);
  const now = Math.floor(Date.now() / 1000);

  const header = {
    alg: 'RS256',
    typ: 'JWT',
    kid: serviceAccount.private_key_id,
  };
  const payload = {
    iss: serviceAccount.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    exp: now + 3600,
    iat: now,
  };

  // Base64url encode helper
  const b64url = (input: string) => btoa(input).replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_');

  // Import private key from PEM
  const privateKeyPem: string = serviceAccount.private_key;
  const pemContents = privateKeyPem
    .replace(/-----BEGIN PRIVATE KEY-----/, '')
    .replace(/-----END PRIVATE KEY-----/, '')
    .replace(/\s/g, '');
  const binaryDer = Uint8Array.from(atob(pemContents), (c) => c.charCodeAt(0));
  const privateKey = await crypto.subtle.importKey(
    'pkcs8',
    binaryDer,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  );

  const encodedHeader = b64url(JSON.stringify(header));
  const encodedPayload = b64url(JSON.stringify(payload));
  const signatureInput = `${encodedHeader}.${encodedPayload}`;
  const signatureBuffer = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    privateKey,
    new TextEncoder().encode(signatureInput),
  );
  const signature = b64url(String.fromCharCode(...new Uint8Array(signatureBuffer)));
  const jwt = `${signatureInput}.${signature}`;

  const tokenResponse = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }),
  });

  const tokenData = await tokenResponse.json();
  if (tokenData?.access_token) return tokenData.access_token as string;
  throw new Error(`Failed to get access token: ${JSON.stringify(tokenData)}`);
}

async function sendToTopic(accessToken: string, projectId: string, topic: string, title: string, body: string, data: any) {
  // include data only if it has properties
  const hasData = data && typeof data === 'object' && Object.keys(data).length > 0;
  const message: any = {
    message: {
      topic,
      notification: { title, body },
      android: { priority: 'high' },
      apns: { headers: { 'apns-priority': '10' } },
    },
  };
  if (hasData) message.message.data = data;

  const res = await fetch(`https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${accessToken}`,
    },
    body: JSON.stringify(message),
  });

  if (!res.ok) {
    const errorText = await res.text();
    throw new Error(`FCM V1 topic send failed: ${errorText}`);
  }

  const result = await res.json();
  console.log('FCM V1 response:', result);
}

async function sendToTokens(accessToken: string, projectId: string, tokens: string[], title: string, body: string, data: any) {
  if (tokens.length === 0) return;

  // ارسال جداگانه برای هر token
  for (const token of tokens) {
    try {
      const hasData = data && typeof data === 'object' && Object.keys(data).length > 0;
      
      // فیلتر کردن data payload برای FCM
      let filteredData: any = {};
      if (hasData) {
        // فقط فیلدهای مجاز FCM را نگه دار
        const allowedKeys = ['type', 'route', 'conversation_id', 'peer_id', 'peer_name', 'sender_id', 'sender_name', 'message_id', 'receiver_id'];
        for (const key of allowedKeys) {
          if (data[key] !== undefined) {
            filteredData[key] = String(data[key]);
          }
        }
      }
      
      const message: any = {
        message: {
          token: token, // استفاده از token به جای tokens
          notification: { title, body }, // اضافه کردن notification field برای background
          android: { 
            priority: 'high',
          },
          apns: { 
            headers: { 'apns-priority': '10' },
            payload: {
              aps: {
                sound: 'default',
                badge: 1,
                alert: {
                  title: title,
                  body: body,
                },
              },
            },
          },
        },
      };
      // اضافه کردن title و body به data
      const finalData = {
        ...filteredData,
        title: title,
        body: body,
      };
      message.message.data = finalData;

      const res = await fetch(`https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${accessToken}`,
        },
        body: JSON.stringify(message),
      });

      if (!res.ok) {
        const errorText = await res.text();
        console.error(`FCM V1 token send failed for ${token.substring(0, 20)}...: ${errorText}`);
      } else {
        const result = await res.json();
        console.log(`FCM V1 token sent successfully: ${token.substring(0, 20)}...`);
      }
    } catch (error) {
      console.error(`Error sending to token ${token.substring(0, 20)}...:`, error);
    }
  }
}

serve(async (req) => {
  try {
    const url = Deno.env.get('SUPABASE_URL');
    const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
    const projectId = Deno.env.get('FIREBASE_PROJECT_ID') || 'gymai-9db69';
    if (!url || !serviceKey) {
      return new Response('Missing SUPABASE_URL or SERVICE_ROLE_KEY', { status: 500 });
    }

    const authHeader = req.headers.get('Authorization') || '';
    const jwt = authHeader.replace('Bearer ', '');
    if (!jwt) return new Response('Unauthorized', { status: 401 });

    const supabase = createClient(url, serviceKey, {
      global: { headers: { Authorization: `Bearer ${jwt}` } },
    });

    const { data: { user }, error: userErr } = await supabase.auth.getUser();
    if (userErr || !user) return new Response('Unauthorized', { status: 401 });

    const accessToken = await getFCMAccessToken();

    let payload: any = {};
    try {
      payload = await req.json();
    } catch (_) {}

    // Direct mode: send immediately without queue
    if (payload?.mode === 'direct') {
      // Normalize/parse data if string
      let payloadData: any = {};
      if (typeof payload.data === 'string') {
        try { payloadData = JSON.parse(payload.data); } catch { payloadData = {}; }
      } else if (payload.data && typeof payload.data === 'object') {
        payloadData = payload.data;
      }
      if (payload.target_type === 'topic') {
        const topic = (payload.topic || 'all') as string;
        await sendToTopic(accessToken, projectId, topic, payload.title, payload.body, payloadData);
        return new Response(JSON.stringify({ ok: true, mode: 'direct', target_type: 'topic' }), {
          headers: { 'Content-Type': 'application/json' },
        });
      } else if (payload.target_type === 'inactive_7d') {
        const { data: inactive, error: inactiveErr } = await supabase
          .from('inactive_users_7d')
          .select('user_id');
        if (inactiveErr) throw inactiveErr;
        const userIds = (inactive || []).map((x: any) => x.user_id);
        if (userIds.length > 0) {
          const { data: tokensRows, error: tokensErr } = await supabase
            .from('device_tokens')
            .select('token')
            .in('user_id', userIds)
            .eq('is_push_enabled', true);
          if (tokensErr) throw tokensErr;
          const tokens = (tokensRows || []).map((t: any) => t.token as string);
          await sendToTokens(accessToken, projectId, tokens, payload.title, payload.body, payloadData);
        }
        return new Response(JSON.stringify({ ok: true, mode: 'direct', target_type: 'inactive_7d' }), {
          headers: { 'Content-Type': 'application/json' },
        });
      } else if (payload.target_type === 'device_tokens') {
        const tokens = payload.tokens || [];
        if (tokens.length > 0) {
          await sendToTokens(accessToken, projectId, tokens, payload.title, payload.body, payloadData);
        }
        return new Response(JSON.stringify({ ok: true, mode: 'direct', target_type: 'device_tokens' }), {
          headers: { 'Content-Type': 'application/json' },
        });
      }
    }

    // Fallback: process queued requests
    const { data: requests, error: reqErr } = await supabase
      .from('notification_broadcast_requests')
      .select('*')
      .eq('status', 'queued')
      .order('created_at', { ascending: true })
      .limit(10);
    if (reqErr) throw reqErr;

    let processed = 0;
    for (const r of (requests as BroadcastRequest[])) {
      try {
        if (r.target_type === 'topic') {
          const topic = r.topic || 'all';
          await sendToTopic(accessToken, projectId!, topic, r.title, r.body, r.data);
        } else if (r.target_type === 'inactive_7d') {
          const { data: inactive, error: inactiveErr } = await supabase
            .from('inactive_users_7d')
            .select('user_id');
          if (inactiveErr) throw inactiveErr;
          const userIds = (inactive || []).map((x: any) => x.user_id);
          if (userIds.length > 0) {
            const { data: tokensRows, error: tokensErr } = await supabase
              .from('device_tokens')
              .select('token')
              .in('user_id', userIds)
              .eq('is_push_enabled', true);
            if (tokensErr) throw tokensErr;
            const tokens = (tokensRows || []).map((t: any) => t.token as string);
            await sendToTokens(accessToken, projectId!, tokens, r.title, r.body, r.data);
          }
        }
        await supabase
          .from('notification_broadcast_requests')
          .update({ status: 'sent', processed_at: new Date().toISOString() })
          .eq('id', r.id);
        processed++;
      } catch (e) {
        console.error('Error processing request:', e);
        await supabase
          .from('notification_broadcast_requests')
          .update({ status: 'failed', processed_at: new Date().toISOString() })
          .eq('id', r.id);
      }
    }

    return new Response(JSON.stringify({ processed, mode: 'queue' }), {
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (e) {
    console.error('Function error:', e);
    return new Response(`Error: ${e}`, { status: 500 });
  }
});


