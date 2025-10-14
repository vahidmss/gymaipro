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

// FCM V1 API endpoint
const FCM_V1_ENDPOINT = 'https://fcm.googleapis.com/v1/projects/YOUR_PROJECT_ID/messages:send';

// Get OAuth2 access token for FCM V1 API
async function getFCMAccessToken(): Promise<string> {
  const serviceAccountKey = Deno.env.get('FIREBASE_SERVICE_ACCOUNT_KEY');
  if (!serviceAccountKey) {
    throw new Error('FIREBASE_SERVICE_ACCOUNT_KEY not set');
  }

  const serviceAccount = JSON.parse(serviceAccountKey);
  const now = Math.floor(Date.now() / 1000);
  
  // Create JWT for Google OAuth2
  const header = {
    alg: 'RS256',
    typ: 'JWT'
  };
  
  const payload = {
    iss: serviceAccount.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    exp: now + 3600,
    iat: now
  };

  // Sign JWT (simplified - in production use proper JWT library)
  const jwt = btoa(JSON.stringify(header)) + '.' + btoa(JSON.stringify(payload)) + '.signature';
  
  const tokenResponse = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }),
  });

  if (!tokenResponse.ok) {
    throw new Error(`Failed to get access token: ${await tokenResponse.text()}`);
  }

  const tokenData = await tokenResponse.json();
  return tokenData.access_token;
}

async function sendToTopic(accessToken: string, projectId: string, topic: string, title: string, body: string, data: any) {
  const message = {
    message: {
      topic: topic,
      notification: {
        title: title,
        body: body,
      },
      data: data,
      android: {
        priority: 'high',
        notification: {
          priority: 'high',
        },
      },
      apns: {
        payload: {
          aps: {
            content_available: true,
          },
        },
      },
    },
  };

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

  // FCM V1 supports up to 500 tokens per request
  const batchSize = 500;
  for (let i = 0; i < tokens.length; i += batchSize) {
    const batch = tokens.slice(i, i + batchSize);
    
    const message = {
      message: {
        notification: {
          title: title,
          body: body,
        },
        data: data,
        android: {
          priority: 'high',
          notification: {
            priority: 'high',
          },
        },
        apns: {
          payload: {
            aps: {
              content_available: true,
            },
          },
        },
        tokens: batch,
      },
    };

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
      throw new Error(`FCM V1 tokens send failed: ${errorText}`);
    }

    const result = await res.json();
    console.log('FCM V1 batch response:', result);
  }
}

function chunk<T>(arr: T[], size: number): T[][] {
  const out: T[][] = [];
  for (let i = 0; i < arr.length; i += size) out.push(arr.slice(i, i + size));
  return out;
}

serve(async (req) => {
  try {
    const url = Deno.env.get('SUPABASE_URL');
    const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
    const projectId = Deno.env.get('FIREBASE_PROJECT_ID');
    
    if (!url || !serviceKey || !projectId) {
      return new Response('Missing SUPABASE_URL or SERVICE_ROLE_KEY or FIREBASE_PROJECT_ID', { status: 500 });
    }

    // AuthN: require a logged-in user; optional: check admin flag from profiles
    const authHeader = req.headers.get('Authorization') || '';
    const jwt = authHeader.replace('Bearer ', '');
    if (!jwt) return new Response('Unauthorized', { status: 401 });

    const supabase = createClient(url, serviceKey, {
      global: { headers: { Authorization: `Bearer ${jwt}` } },
    });

    // Check role (optional). Expect profiles.role in ('admin','trainer')
    const {
      data: { user },
      error: userErr,
    } = await supabase.auth.getUser();
    if (userErr || !user) return new Response('Unauthorized', { status: 401 });

    const { data: profile } = await supabase
      .from('profiles')
      .select('role')
      .eq('id', user.id)
      .maybeSingle();
    const role = (profile?.role ?? '').toString();
    if (!['admin', 'trainer'].includes(role)) {
      return new Response('Forbidden', { status: 403 });
    }

    // Get FCM access token
    const accessToken = await getFCMAccessToken();

    // Fetch queued requests
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
          await sendToTopic(accessToken, projectId, topic, r.title, r.body, r.data);
        } else if (r.target_type === 'inactive_7d') {
          // Two-step: get inactive user ids, then their tokens
          const { data: inactive, error: inactiveErr } = await supabase
            .from('inactive_users_7d')
            .select('user_id');
          if (inactiveErr) throw inactiveErr;
          const userIds = (inactive || []).map((x: any) => x.user_id);
          if (userIds.length === 0) {
            // Nothing to send
          } else {
            const { data: tokensRows, error: tokensErr } = await supabase
              .from('device_tokens')
              .select('token')
              .in('user_id', userIds)
              .eq('is_push_enabled', true);
            if (tokensErr) throw tokensErr;
            const tokens = (tokensRows || []).map((t: any) => t.token as string);
            await sendToTokens(accessToken, projectId, tokens, r.title, r.body, r.data);
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

    return new Response(JSON.stringify({ processed }), {
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (e) {
    console.error('Function error:', e);
    return new Response(`Error: ${e}`, { status: 500 });
  }
});


