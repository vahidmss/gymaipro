// deno-lint-ignore-file no-explicit-any
import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.44.2";

// Get service account JSON: B64 از .env (همان‌طور که deploy-firebase-gymai تنظیم می‌کند)
const FIREBASE_CRED_PATHS = [
  '/home/deno/functions/.secrets/firebase-service-account.json',
  '/secrets/firebase-service-account.json',
];
async function getServiceAccountJson(): Promise<string> {
  const b64 = Deno.env.get('FIREBASE_SERVICE_ACCOUNT_B64')?.trim();
  if (b64) return atob(b64);
  const key = Deno.env.get('FIREBASE_SERVICE_ACCOUNT_KEY')?.trim();
  if (key) return key;
  const credPath = Deno.env.get('GOOGLE_APPLICATION_CREDENTIALS');
  const pathsToTry = credPath ? [credPath, ...FIREBASE_CRED_PATHS] : FIREBASE_CRED_PATHS;
  for (const p of pathsToTry) {
    try {
      return await Deno.readTextFile(p);
    } catch (_) {
      continue;
    }
  }
  throw new Error(
    'Firebase creds not found. On server: run set-firebase-in-env.sh then docker compose stop functions && docker rm -f supabase-edge-functions && docker compose up -d functions'
  );
}

// Get OAuth2 access token for FCM V1 API using proper RSA signing
async function getFCMAccessToken() {
  const serviceAccountKey = await getServiceAccountJson();
  const serviceAccount = JSON.parse(serviceAccountKey);
  const now = Math.floor(Date.now() / 1000);
  
  const header = {
    alg: 'RS256',
    typ: 'JWT',
    kid: serviceAccount.private_key_id
  };
  
  const payload = {
    iss: serviceAccount.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    exp: now + 3600,
    iat: now
  };

  // Base64url encode helper
  const b64url = (input: string) => btoa(input).replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_');

  // Import private key from PEM
  const privateKeyPem = serviceAccount.private_key;
  const pemContents = privateKeyPem
    .replace(/-----BEGIN PRIVATE KEY-----/, '')
    .replace(/-----END PRIVATE KEY-----/, '')
    .replace(/\s/g, '');
  
  const binaryDer = Uint8Array.from(atob(pemContents), (c) => c.charCodeAt(0));
  const privateKey = await crypto.subtle.importKey(
    'pkcs8',
    binaryDer,
    {
      name: 'RSASSA-PKCS1-v1_5',
      hash: 'SHA-256'
    },
    false,
    ['sign']
  );

  const encodedHeader = b64url(JSON.stringify(header));
  const encodedPayload = b64url(JSON.stringify(payload));
  const signatureInput = `${encodedHeader}.${encodedPayload}`;
  
  const signatureBuffer = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    privateKey,
    new TextEncoder().encode(signatureInput)
  );
  
  const signature = b64url(String.fromCharCode(...new Uint8Array(signatureBuffer)));
  const jwt = `${signatureInput}.${signature}`;

  const tokenResponse = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded'
    },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt
    })
  });

  const tokenData = await tokenResponse.json();
  if (tokenData?.access_token) return tokenData.access_token;
  throw new Error(`Failed to get access token: ${JSON.stringify(tokenData)}`);
}

// ارسال نوتیفیکیشن چت به token های خاص
async function sendChatNotification(accessToken: string, projectId: string, tokens: string[], title: string, body: string, data: any) {
  if (tokens.length === 0) return;

  for (const token of tokens) {
    try {
      const hasData = data && typeof data === 'object' && Object.keys(data).length > 0;
      
      let filteredData: any = {};
      if (hasData) {
        // فقط فیلدهای مجاز برای چت
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
          'buyer_user_id',
          'event'
        ];
        
        for (const key of allowedKeys) {
          if (data[key] !== undefined) {
            filteredData[key] = String(data[key]);
          }
        }
      }
      
      const message: any = {
        message: {
          token: token,
          notification: { title, body }, // مهم: notification field برای background
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
      return new Response('Missing SUPABASE_URL or SERVICE_ROLE_KEY', {
        status: 500
      });
    }

    // دریافت payload
    let payload = {};
    try {
      payload = await req.json();
    } catch (_) {
      return new Response('Invalid JSON payload', { status: 400 });
    }

    const supabase = createClient(url, serviceKey);

    // trainer_new_student: اگر درخواست به send-chat-notification رسید (مثلاً مسیریابی اشتباه)، همین‌جا هم هندل می‌کنیم
    if (payload?.mode === 'trainer_new_student') {
      const trainerId = payload.trainer_id as string;
      const title = (payload.title || 'شاگرد جدید') as string;
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
      const userIdsToTry = [trainerAuthId];
      if (trainerId !== trainerAuthId) userIdsToTry.push(trainerId);
      const { data: tokensRows, error: tokensErr } = await supabase
        .from('device_tokens')
        .select('token')
        .in('user_id', userIdsToTry)
        .eq('is_push_enabled', true);
      if (tokensErr) {
        console.error('trainer_new_student device_tokens error:', tokensErr);
        return new Response(JSON.stringify({ error: tokensErr.message }), { status: 500, headers: { 'Content-Type': 'application/json' } });
      }
      const tokens = (tokensRows || []).map((t: any) => t.token as string).filter(Boolean);
      console.log(`trainer_new_student: trainerId=${trainerId} tokens_found=${tokens.length}`);
      if (tokens.length > 0) {
        const accessToken = await getFCMAccessToken();
        await sendChatNotification(accessToken, projectId, tokens, title, body, payloadData);
      }
      return new Response(JSON.stringify({ ok: true, mode: 'trainer_new_student', tokens_sent: tokens.length }), {
        headers: { 'Content-Type': 'application/json' },
      });
    }

    const {
      receiver_id,
      sender_id,
      sender_name,
      message,
      conversation_id,
      message_id
    } = payload as any;

    if (!receiver_id || !sender_id || !message) {
      return new Response('Missing required fields: receiver_id, sender_id, message', {
        status: 400
      });
    }

    // device_tokens.user_id = auth.uid()؛ resolve profile id به auth_user_id
    let receiverAuthId = receiver_id;
    try {
      const { data: row } = await supabase.from('profiles').select('auth_user_id').eq('id', receiver_id).maybeSingle();
      if (row?.auth_user_id) receiverAuthId = row.auth_user_id;
    } catch (_) {}
    const receiverIdsToTry = [receiverAuthId];
    if (receiver_id !== receiverAuthId) receiverIdsToTry.push(receiver_id);

    // دریافت device tokens کاربر گیرنده
    const { data: tokensRows, error: tokensErr } = await supabase
      .from('device_tokens')
      .select('token')
      .in('user_id', receiverIdsToTry)
      .eq('is_push_enabled', true);

    if (tokensErr) {
      console.error('Error fetching device tokens:', tokensErr);
      return new Response('Error fetching device tokens', { status: 500 });
    }

    const tokens = (tokensRows || []).map((t: any) => t.token);
    console.log(`send-chat: receiver_id=${receiver_id} receiverAuthId=${receiverAuthId} tokens_found=${tokens.length}`);

    if (tokens.length === 0) {
      console.log(`No device tokens found for user ${receiver_id}`);
      return new Response(JSON.stringify({ 
        ok: true, 
        message: 'No device tokens found',
        tokens_sent: 0 
      }), {
        headers: { 'Content-Type': 'application/json' }
      });
    }

    // بررسی حضور کاربر در چت (با threshold 45 ثانیه)
    // اگر کاربر در 45 ثانیه گذشته در چت فعال بوده، نوتیفیکیشن ارسال نمی‌کنیم
    if (conversation_id) {
      try {
        const cutoffTime = new Date(Date.now() - 45 * 1000).toISOString();
        const { data: presenceData, error: presenceErr } = await supabase
          .from('chat_presence')
          .select('id')
          .eq('conversation_id', conversation_id)
          .eq('user_id', receiver_id)
          .eq('is_active', true)
          .gt('last_seen', cutoffTime)
          .maybeSingle();

        if (presenceErr) {
          console.error('Error checking chat presence:', presenceErr);
        }

        // اگر کاربر در چت فعال است، نوتیفیکیشن ارسال نکن
        if (presenceData) {
          console.log(`✅ User ${receiver_id} is active in chat (last_seen: ${presenceData}), skipping notification`);
          return new Response(JSON.stringify({ 
            ok: true, 
            message: 'User is active in chat, notification skipped',
            tokens_sent: 0 
          }), {
            headers: { 'Content-Type': 'application/json' }
          });
        } else {
          console.log(`ℹ️ User ${receiver_id} is not active in chat, proceeding with notification`);
        }
      } catch (presenceCheckError) {
        console.error('Error in presence check:', presenceCheckError);
        // در صورت خطا، ادامه می‌دهیم و نوتیفیکیشن را ارسال می‌کنیم
      }
    }

    // بررسی تنظیمات اعلان‌های کاربر گیرنده
    console.log(`🔍 Checking notification settings for user: ${receiver_id}`);
    const { data: userSettings, error: settingsErr } = await supabase
      .from('user_notification_settings')
      .select('chat_notifications')
      .eq('user_id', receiver_id)
      .single();

    if (settingsErr) {
      console.error('❌ Error checking user notification settings:', settingsErr);
      console.log('📋 Settings error details:', JSON.stringify(settingsErr));
    } else {
      console.log('✅ User settings found:', JSON.stringify(userSettings));
    }

    // اگر اعلان‌های چت برای کاربر غیرفعال است، نوتیفیکیشن ارسال نکن
    if (userSettings && userSettings.chat_notifications === false) {
      console.log(`🚫 Chat notifications disabled for user ${receiver_id}, skipping notification`);
      return new Response(JSON.stringify({ 
        ok: true, 
        message: 'Chat notifications disabled for user, notification skipped',
        tokens_sent: 0 
      }), {
        headers: { 'Content-Type': 'application/json' }
      });
    } else if (userSettings) {
      console.log(`✅ Chat notifications enabled for user ${receiver_id}, proceeding with notification`);
    } else {
      console.log(`⚠️ No settings found for user ${receiver_id}, proceeding with notification (default behavior)`);
    }

    // دریافت access token
    const accessToken = await getFCMAccessToken();

    // آماده کردن data payload
    const notificationData = {
      type: 'chat_message',
      route: '/chat',
      conversation_id: conversation_id || '',
      peer_id: sender_id,
      peer_name: sender_name || 'کاربر',
      sender_id: sender_id,
      sender_name: sender_name || 'کاربر',
      message_id: message_id || '',
      receiver_id: receiver_id,
    };

    const title = `پیام جدید از ${sender_name || 'کاربر'}`;
    const body = message;

    // ارسال نوتیفیکیشن
    await sendChatNotification(
      accessToken,
      projectId,
      tokens,
      title,
      body,
      notificationData
    );

    // ذخیره نوتیفیکیشن در جدول notifications
    const { error: notificationErr } = await supabase
      .from('notifications')
      .insert({
        user_id: receiver_id,
        title: title,
        message: body,
        type: 'message',
        data: {
          conversation_id: conversation_id || '',
          sender_id: sender_id,
          sender_name: sender_name || 'کاربر',
          message_id: message_id || '',
          peer_id: sender_id,
          peer_name: sender_name || 'کاربر'
        },
        priority: 3,
        is_read: false
      });

    if (notificationErr) {
      console.error('Error saving notification to database:', notificationErr);
      // ادامه می‌دهیم حتی اگر ذخیره نوتیفیکیشن در دیتابیس با خطا مواجه شود
    } else {
      console.log(`Notification saved to database for user ${receiver_id}`);
    }

    console.log(`Chat notification sent to ${tokens.length} devices for user ${receiver_id}`);

    return new Response(JSON.stringify({ 
      ok: true, 
      tokens_sent: tokens.length,
      receiver_id,
      sender_id 
    }), {
      headers: { 'Content-Type': 'application/json' }
    });

  } catch (e) {
    console.error('Chat notification function error:', e);
    return new Response(`Error: ${e}`, { status: 500 });
  }
});