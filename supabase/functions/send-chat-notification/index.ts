// deno-lint-ignore-file no-explicit-any
import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.44.2";

// Get OAuth2 access token for FCM V1 API using proper RSA signing
async function getFCMAccessToken() {
  const serviceAccountKey = Deno.env.get('FIREBASE_SERVICE_ACCOUNT_KEY');
  if (!serviceAccountKey) {
    throw new Error('FIREBASE_SERVICE_ACCOUNT_KEY not set');
  }
  
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
          'receiver_id'
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

    const supabase = createClient(url, serviceKey);

    // دریافت device tokens کاربر گیرنده
    const { data: tokensRows, error: tokensErr } = await supabase
      .from('device_tokens')
      .select('token')
      .eq('user_id', receiver_id)
      .eq('is_push_enabled', true);

    if (tokensErr) {
      console.error('Error fetching device tokens:', tokensErr);
      return new Response('Error fetching device tokens', { status: 500 });
    }

    const tokens = (tokensRows || []).map((t: any) => t.token);
    
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

    // بررسی حضور کاربر در چت
    const { data: presenceData, error: presenceErr } = await supabase
      .from('chat_presence')
      .select('user_id')
      .eq('conversation_id', conversation_id)
      .eq('user_id', receiver_id)
      .eq('is_active', true);

    if (presenceErr) {
      console.error('Error checking chat presence:', presenceErr);
    }

    // اگر کاربر در چت فعال است، نوتیفیکیشن ارسال نکن
    if (presenceData && presenceData.length > 0) {
      console.log(`User ${receiver_id} is active in chat, skipping notification`);
      return new Response(JSON.stringify({ 
        ok: true, 
        message: 'User is active in chat, notification skipped',
        tokens_sent: 0 
      }), {
        headers: { 'Content-Type': 'application/json' }
      });
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