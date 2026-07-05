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

// مسیرهای ممکن برای فایل Firebase (Deno در بعضی محیط‌ها به /secrets دسترسی ندارد)
const FIREBASE_CRED_PATHS = [
  '/home/deno/functions/.secrets/firebase-service-account.json',
  '/secrets/firebase-service-account.json',
];

async function getServiceAccountJson(): Promise<string> {
  let key = Deno.env.get('FIREBASE_SERVICE_ACCOUNT_KEY')?.trim();
  if (key) return key;
  const b64 = Deno.env.get('FIREBASE_SERVICE_ACCOUNT_B64')?.trim();
  if (b64) return atob(b64);
  const envPath = Deno.env.get('GOOGLE_APPLICATION_CREDENTIALS');
  const pathsToTry = envPath ? [envPath, ...FIREBASE_CRED_PATHS] : FIREBASE_CRED_PATHS;
  for (const p of pathsToTry) {
    try {
      return await Deno.readTextFile(p);
    } catch (_) {
      continue;
    }
  }
  throw new Error('Firebase creds not found. Set FIREBASE_SERVICE_ACCOUNT_B64 (base64) or FIREBASE_SERVICE_ACCOUNT_KEY in .env');
}

// Get OAuth2 access token for FCM V1 API using proper RSA signing
async function getFCMAccessToken(): Promise<string> {
  const serviceAccountKey = await getServiceAccountJson();
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
  console.log('📤 sendToTopic called with data:', JSON.stringify(data));
  
  // Parse data if it's a string (from database JSON column)
  let parsedData: any = {};
  if (data) {
    if (typeof data === 'string') {
      try {
        parsedData = JSON.parse(data);
        console.log('✅ Parsed string data:', JSON.stringify(parsedData));
      } catch (e) {
        console.error('❌ Error parsing string data:', e);
        parsedData = {};
      }
    } else if (typeof data === 'object' && data !== null) {
      parsedData = data;
      console.log('✅ Using object data directly:', JSON.stringify(parsedData));
    }
    
    // Convert all values to strings (FCM requirement)
    const stringifiedData: any = {};
    for (const key in parsedData) {
      if (parsedData[key] !== undefined && parsedData[key] !== null) {
        stringifiedData[key] = String(parsedData[key]);
      }
    }
    parsedData = stringifiedData;
    console.log('✅ Stringified data:', JSON.stringify(parsedData));
  } else {
    console.log('⚠️ No data provided');
  }

  const message: any = {
    message: {
      topic,
      notification: { title, body },
      android: { priority: 'high' },
      apns: { headers: { 'apns-priority': '10' } },
    },
  };
  
  // Add data if it exists and has properties
  if (parsedData && typeof parsedData === 'object' && Object.keys(parsedData).length > 0) {
    message.message.data = parsedData;
    console.log('✅ Added data to message:', JSON.stringify(message.message.data));
  } else {
    console.log('⚠️ No data to add to message');
  }
  
  console.log('📨 Final FCM message:', JSON.stringify(message));

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

  // Parse data if it's a string (from database JSON column)
  let parsedData: any = {};
  if (data) {
    if (typeof data === 'string') {
      try {
        parsedData = JSON.parse(data);
      } catch {
        parsedData = {};
      }
    } else if (typeof data === 'object' && data !== null) {
      parsedData = data;
    }
  }

  // ارسال جداگانه برای هر token
  for (const token of tokens) {
    try {
      const hasData = parsedData && typeof parsedData === 'object' && Object.keys(parsedData).length > 0;
      
      // فیلتر کردن data payload برای FCM
      let filteredData: any = {};
      if (hasData) {
        // فقط فیلدهای مجاز FCM را نگه دار
        // اضافه کردن فیلدهای مربوط به طراحی نوتیفیکیشن
        const allowedKeys = [
          'type', 
          'route', 
          'conversation_id', 
          'peer_id', 
          'peer_name', 
          'sender_id', 
          'sender_name', 
          'message_id', 
          'receiver_id',
          'background_color', // رنگ پس‌زمینه
          'icon', // آیکون
          'image_url', // آدرس تصویر
        ];
        for (const key of allowedKeys) {
          if (parsedData[key] !== undefined && parsedData[key] !== null) {
            filteredData[key] = String(parsedData[key]);
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
    let projectId = Deno.env.get('FIREBASE_PROJECT_ID')?.trim();
    if (!projectId) {
      try {
        const sa = JSON.parse(await getServiceAccountJson());
        projectId = sa.project_id || 'gymai-9db69';
      } catch {
        projectId = 'gymai-9db69';
      }
    }
    if (!url || !serviceKey) {
      return new Response('Missing SUPABASE_URL or SERVICE_ROLE_KEY', { status: 500 });
    }

    const authHeader = req.headers.get('Authorization') || '';
    const jwt = authHeader.replace('Bearer ', '').trim();
    if (!jwt) return new Response('Unauthorized', { status: 401 });

    const supabase = createClient(url, serviceKey);
    // SERVICE_ROLE_KEY: اجازه تست از سرور (curl) بدون لاگین کاربر
    const isServiceRole = jwt === serviceKey;
    if (!isServiceRole) {
      const { data: { user }, error: userErr } = await supabase.auth.getUser(jwt);
      if (userErr || !user) {
        console.error('getUser failed:', userErr?.message ?? 'no user');
        return new Response('Unauthorized', { status: 401 });
      }
    }

    const accessToken = await getFCMAccessToken();

    let payload: any = {};
    try {
      payload = await req.json();
    } catch (_) {}
    console.log('send-notifications request mode:', payload?.mode ?? '(none)');

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

    // trainer_new_student: اپ نمی‌تواند توکن مربی را بخواند (RLS)، پس سمت سرور می‌خوانیم
    if (payload?.mode === 'trainer_new_student' || payload?.mode === 'trainer_notify') {
      const trainerId = payload.trainer_id as string;
      const title = (payload.title || (payload?.mode === 'trainer_notify' ? 'درخواست برنامه جدید' : 'شاگرد جدید')) as string;
      const body = (payload.body || 'یک کاربر به شاگردان شما اضافه شد.') as string;
      const payloadData = (payload.data && typeof payload.data === 'object') ? payload.data : {};
      if (!trainerId) {
        return new Response(JSON.stringify({ error: 'trainer_id required' }), { status: 400, headers: { 'Content-Type': 'application/json' } });
      }
      let trainerAuthId = trainerId;
      try {
        const { data: row } = await supabase.from('profiles').select('auth_user_id').eq('id', trainerId).maybeSingle();
        if (row?.auth_user_id) trainerAuthId = row.auth_user_id;
      } catch (_) {}

      let notificationCreated = false;
      const notif = payload.notification;
      if (payload?.mode === 'trainer_notify' && notif && typeof notif === 'object') {
        try {
          const targetUserId = (notif.user_id as string) || trainerAuthId;
          const { error: rpcErr } = await supabase.rpc('create_user_notification', {
            p_user_id: targetUserId,
            p_title: (notif.title as string) || title,
            p_message: (notif.message as string) || body,
            p_type: (notif.type as string) || 'payment',
            p_priority: (notif.priority as number) ?? 3,
            p_data: (notif.data as object) ?? payloadData,
            p_action_url: (notif.action_url as string) ?? null,
          });
          if (rpcErr) {
            console.error('create_user_notification error:', rpcErr);
          } else {
            notificationCreated = true;
          }
        } catch (e) {
          console.error('trainer_notify persist error:', e);
        }
      }

      const userIdsToTry = [trainerAuthId];
      if (trainerId !== trainerAuthId) userIdsToTry.push(trainerId);
      const { data: tokensRows, error: tokensErr } = await supabase
        .from('device_tokens')
        .select('token')
        .in('user_id', userIdsToTry)
        .eq('is_push_enabled', true);
      if (tokensErr) {
        console.error('device_tokens query error:', tokensErr);
        return new Response(JSON.stringify({ error: tokensErr.message, notification_created: notificationCreated }), { status: 500, headers: { 'Content-Type': 'application/json' } });
      }
      const tokens = (tokensRows || []).map((t: any) => t.token as string).filter(Boolean);
      console.log(`${payload.mode}: trainerId=${trainerId} trainerAuthId=${trainerAuthId} tokens_found=${tokens.length} notification_created=${notificationCreated}`);
      if (tokens.length > 0) {
        await sendToTokens(accessToken, projectId, tokens, title, body, payloadData);
      }
      return new Response(JSON.stringify({ ok: true, mode: payload.mode, tokens_sent: tokens.length, notification_created: notificationCreated }), {
        headers: { 'Content-Type': 'application/json' },
      });
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
        // Parse data if it's a string (from database JSON column)
        let requestData: any = {};
        if (r.data) {
          if (typeof r.data === 'string') {
            try {
              requestData = JSON.parse(r.data);
            } catch {
              requestData = {};
            }
          } else if (typeof r.data === 'object' && r.data !== null) {
            requestData = r.data;
          }
        }
        
        if (r.target_type === 'topic') {
          const topic = r.topic || 'all';
          await sendToTopic(accessToken, projectId!, topic, r.title, r.body, requestData);
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
            await sendToTokens(accessToken, projectId!, tokens, r.title, r.body, requestData);
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
