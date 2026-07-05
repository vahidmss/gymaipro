#!/bin/bash
# Add CORS headers for coach music on dl.gymaipro.ir (fixes Flutter Web / iOS PWA playback).
# Run ON dl server as root.
set -euo pipefail

CONF="/etc/nginx/conf.d/dl-gymaipro-cors.conf"
cat > "$CONF" <<'EOF'
# GymAI Pro — allow browser audio fetch/stream from dl.gymaipro.ir
location ~* ^/coaches_music/.*\.(mp3|m4a|ogg|wav)$ {
    if ($request_method = OPTIONS) {
        add_header Access-Control-Allow-Origin *;
        add_header Access-Control-Allow-Methods "GET, HEAD, OPTIONS";
        add_header Access-Control-Allow-Headers "Range, Content-Type, Authorization, apikey";
        add_header Access-Control-Max-Age 86400;
        return 204;
    }
    add_header Access-Control-Allow-Origin * always;
    add_header Access-Control-Allow-Methods "GET, HEAD, OPTIONS" always;
    add_header Access-Control-Expose-Headers "Content-Length, Content-Range, Accept-Ranges" always;
}
EOF

nginx -t
systemctl reload nginx
echo "Done. Test:"
echo "  curl -I -H 'Origin: https://gymaipro.ir' https://dl.gymaipro.ir/coaches_music/hamed/music_1772137273_35bd3702.mp3"
