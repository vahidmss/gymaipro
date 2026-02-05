#!/bin/bash
# =============================================================================
# Supabase Self-Host Setup Script (run on Linux server)
# Usage: ./setup_supabase_server.sh [SERVER_IP]
# Example: ./setup_supabase_server.sh 87.248.156.175
# =============================================================================

set -e

SERVER_IP="${1:-87.248.156.175}"
PROJECT_DIR="$HOME/supabase-project"
SUPABASE_REPO_DIR="$HOME/supabase-repo"

echo "=============================================="
echo "Supabase Self-Host Setup"
echo "Server URL will be: http://${SERVER_IP}:8000"
echo "=============================================="

# -----------------------------------------------------------------------------
# 1. Install Docker if not present
# -----------------------------------------------------------------------------
if ! command -v docker &> /dev/null; then
  echo "[1/7] Installing Docker..."
  curl -fsSL https://get.docker.com | sh
  if [ -n "$SUDO_USER" ]; then
    usermod -aG docker "$SUDO_USER" 2>/dev/null || true
  fi
  echo "Docker installed. You may need to log out and back in for group to apply."
else
  echo "[1/7] Docker already installed."
fi

# Prefer "docker compose" (plugin), fallback to "docker-compose" (standalone)
if docker compose version &> /dev/null 2>&1; then
  DOCKER_COMPOSE_CMD="docker compose"
elif command -v docker-compose &> /dev/null && docker-compose version &> /dev/null; then
  DOCKER_COMPOSE_CMD="docker-compose"
else
  echo "Installing Docker Compose plugin..."
  apt-get update -qq && apt-get install -y -qq docker-compose-plugin 2>/dev/null || true
  if docker compose version &> /dev/null; then
    DOCKER_COMPOSE_CMD="docker compose"
  elif command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE_CMD="docker-compose"
  else
    echo "ERROR: Docker Compose not found. Install with: apt-get install -y docker-compose-plugin"
    exit 1
  fi
fi
echo "Using: $DOCKER_COMPOSE_CMD"

# -----------------------------------------------------------------------------
# 2. Clone Supabase (shallow)
# -----------------------------------------------------------------------------
echo "[2/7] Cloning Supabase repository..."
if [ -d "$SUPABASE_REPO_DIR" ]; then
  echo "Repo already exists at $SUPABASE_REPO_DIR, skipping clone."
else
  git clone --depth 1 https://github.com/supabase/supabase "$SUPABASE_REPO_DIR"
fi

# -----------------------------------------------------------------------------
# 3. Create project dir and copy Docker files
# -----------------------------------------------------------------------------
echo "[3/7] Preparing project directory..."
mkdir -p "$PROJECT_DIR"
cp -rf "$SUPABASE_REPO_DIR/docker/"* "$PROJECT_DIR/"
if [ -f "$SUPABASE_REPO_DIR/docker/.env.example" ]; then
  cp "$SUPABASE_REPO_DIR/docker/.env.example" "$PROJECT_DIR/.env"
else
  echo "Warning: .env.example not found. You must create .env manually."
fi

cd "$PROJECT_DIR"

# -----------------------------------------------------------------------------
# 4. Generate keys (if script exists)
# -----------------------------------------------------------------------------
echo "[4/7] Generating API keys and secrets..."
if [ -f "./utils/generate-keys.sh" ]; then
  sh ./utils/generate-keys.sh
else
  echo "generate-keys.sh not found. You must set JWT_SECRET, ANON_KEY, SERVICE_ROLE_KEY, and other secrets in .env manually."
  echo "See: https://supabase.com/docs/guides/self-hosting/docker"
fi

# -----------------------------------------------------------------------------
# 5. Set URL variables and passwords in .env
# -----------------------------------------------------------------------------
echo "[5/7] Configuring URLs and passwords..."

BASE_URL="http://${SERVER_IP}:8000"

# Set public/API URLs (works with sed on both GNU and BSD)
if grep -q '^SUPABASE_PUBLIC_URL=' .env 2>/dev/null; then
  sed -i.bak "s|^SUPABASE_PUBLIC_URL=.*|SUPABASE_PUBLIC_URL=${BASE_URL}|" .env
else
  echo "SUPABASE_PUBLIC_URL=${BASE_URL}" >> .env
fi
if grep -q '^API_EXTERNAL_URL=' .env 2>/dev/null; then
  sed -i.bak "s|^API_EXTERNAL_URL=.*|API_EXTERNAL_URL=${BASE_URL}|" .env
else
  echo "API_EXTERNAL_URL=${BASE_URL}" >> .env
fi
if grep -q '^SITE_URL=' .env 2>/dev/null; then
  sed -i.bak "s|^SITE_URL=.*|SITE_URL=${BASE_URL}|" .env
else
  echo "SITE_URL=${BASE_URL}" >> .env
fi

# Generate a random alphanumeric password for Studio (at least one letter - no special chars per Supabase docs)
DASH_PASS=$(openssl rand -base64 12 | tr -dc 'a-zA-Z0-9' | head -c 16)
if [ -z "$DASH_PASS" ]; then
  DASH_PASS="SupabaseStudio$(date +%s | tail -c 6)"
fi
if grep -q '^DASHBOARD_PASSWORD=' .env 2>/dev/null; then
  sed -i.bak "s|^DASHBOARD_PASSWORD=.*|DASHBOARD_PASSWORD=${DASH_PASS}|" .env
else
  echo "DASHBOARD_PASSWORD=${DASH_PASS}" >> .env
fi

# Strong Postgres password if still default
if grep -q '^POSTGRES_PASSWORD=.*your-super-secret-and-long-postgres-password' .env 2>/dev/null; then
  PG_PASS=$(openssl rand -base64 24 | tr -dc 'a-zA-Z0-9' | head -c 32)
  sed -i.bak "s|^POSTGRES_PASSWORD=.*|POSTGRES_PASSWORD=${PG_PASS}|" .env
fi

# Remove backup files if created by sed
rm -f .env.bak

# -----------------------------------------------------------------------------
# 6. Pull images and start
# -----------------------------------------------------------------------------
echo "[6/7] Pulling Docker images (this may take a few minutes)..."
$DOCKER_COMPOSE_CMD pull

echo "[7/7] Starting Supabase..."
$DOCKER_COMPOSE_CMD up -d

echo ""
echo "=============================================="
echo "Supabase is starting. Wait 1-2 minutes."
echo "=============================================="
echo ""
echo "  Studio (Dashboard):  http://${SERVER_IP}:8000"
echo ""
echo "  Login:"
echo "    Username: supabase  (or value of DASHBOARD_USERNAME in .env)"
echo "    Password: (stored in .env as DASHBOARD_PASSWORD)"
echo ""
echo "  To see Studio password on this server run:"
echo "    grep DASHBOARD_PASSWORD ${PROJECT_DIR}/.env"
echo ""
echo "  To get ANON_KEY for your app .env:"
echo "    grep ANON_KEY ${PROJECT_DIR}/.env"
echo ""
echo "  Check service status:"
echo "    cd ${PROJECT_DIR} && $DOCKER_COMPOSE_CMD ps"
echo ""
echo "  View logs if something fails:"
echo "    $DOCKER_COMPOSE_CMD -f ${PROJECT_DIR}/docker-compose.yml logs -f"
echo ""
echo "=============================================="
