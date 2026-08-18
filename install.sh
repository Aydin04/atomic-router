#!/usr/bin/env bash
# ==============================================================================
# ⚡ AtomicRouter 1-Line Automated Installer
# Pure Streamlined Universal AI Gateway Fork of OmniRoute
# Optimized for 512MB - 1GB Low-Spec VPS (Instant Pre-Built Deployment)
# ==============================================================================

set -e

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

INSTALL_DIR="${INSTALL_DIR:-/opt/atomic-router}"
PORT="${PORT:-20128}"
REPO="dianrestu/atomic-router"
RELEASE_TAG="${RELEASE_TAG:-v1.0.0}"
RELEASE_URL="https://github.com/${REPO}/releases/download/${RELEASE_TAG}/atomic-router-linux-x64.tar.gz"

echo -e "${CYAN}${BOLD}"
echo "================================================================"
echo "   ⚡ AtomicRouter | Ultra-Lightweight Universal AI Gateway"
echo "   (Pre-Compiled Standalone Release - Fast 30s Install)"
echo "================================================================"
echo -e "${NC}"

# Check root privilege
if [ "$(id -u)" -ne 0 ]; then
  echo -e "${RED}[ERROR] Please run this script as root or with sudo.${NC}"
  exit 1
fi

# 1. Install Node.js 22 LTS, curl, and tar if missing
echo -e "${BLUE}[1/4] Checking system dependencies (Node.js 22 LTS, tar, curl)...${NC}"
if ! command -v curl &>/dev/null || ! command -v tar &>/dev/null; then
  apt-get update -y && apt-get install -y curl tar || yum install -y curl tar
fi

if ! command -v node &>/dev/null || [ "$(node -v | cut -d'.' -f1 | tr -d 'v')" -lt 20 ]; then
  echo -e "${YELLOW}Installing Node.js 22 LTS...${NC}"
  curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
  apt-get install -y nodejs || yum install -y nodejs
fi

echo -e "${GREEN}[✓] Node.js $(node -v) ready.${NC}"

# 2. Download and extract pre-compiled release (No heavy compile on VPS!)
echo -e "${BLUE}[2/4] Fetching pre-compiled release from GitHub...${NC}"
mkdir -p "$INSTALL_DIR"
TEMP_TAR="/tmp/atomic-router-pkg.tar.gz"

if curl -sIL "$RELEASE_URL" | grep -qE "HTTP/.* (200|302)"; then
  echo -e "${GREEN}[✓] Downloading pre-built package...${NC}"
  curl -fsSL "$RELEASE_URL" -o "$TEMP_TAR"
  tar -xzf "$TEMP_TAR" -C /tmp/
  cp -r /tmp/atomic-router/* "$INSTALL_DIR/"
  rm -rf /tmp/atomic-router "$TEMP_TAR"
else
  echo -e "${YELLOW}[!] Pre-built release tarball not found, cloning repository directly...${NC}"
  if [ -d "$INSTALL_DIR/.git" ]; then
    cd "$INSTALL_DIR" && git pull || true
  else
    git clone --depth=1 "https://github.com/${REPO}.git" "$INSTALL_DIR"
  fi
fi

cd "$INSTALL_DIR"

# 3. Setup configuration & dependencies
echo -e "${BLUE}[3/4] Initializing configuration and dependencies...${NC}"
if [ ! -f "$INSTALL_DIR/.env" ]; then
  if [ -f "$INSTALL_DIR/.env.example" ]; then
    cp "$INSTALL_DIR/.env.example" "$INSTALL_DIR/.env"
  else
    echo "PORT=${PORT}" > "$INSTALL_DIR/.env"
  fi
fi

# Determine start command
START_CMD="$(which npm) start"
if [ -f "$INSTALL_DIR/server.js" ]; then
  START_CMD="$(which node) server.js"
else
  export NODE_OPTIONS="--max-old-space-size=450"
  npm install --omit=dev --no-audit --no-fund 2>/dev/null || npm install --no-audit --no-fund
fi

# 4. Setup Systemd Service
echo -e "${BLUE}[4/4] Setting up systemd background service...${NC}"
cat << SERVICE_EOF > /etc/systemd/system/atomic-router.service
[Unit]
Description=AtomicRouter Universal AI Gateway Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=${INSTALL_DIR}
Environment=NODE_ENV=production
Environment=PORT=${PORT}
Environment=NODE_OPTIONS="--max-old-space-size=450"
ExecStart=${START_CMD}
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
SERVICE_EOF

systemctl daemon-reload
systemctl enable atomic-router
systemctl restart atomic-router

# Fetch public IP
SERVER_IP=$(curl -s -4 ifconfig.me || curl -s -4 api.ipify.org || hostname -I | awk '{print $1}')

echo -e "${GREEN}${BOLD}"
echo "================================================================"
echo "   🎉 AtomicRouter Successfully Installed and Running!"
echo "================================================================"
echo -e "${NC}"
echo -e "  🌐 ${BOLD}Dashboard URL:${NC}      http://${SERVER_IP}:${PORT}"
echo -e "  🤖 ${BOLD}OpenAI Endpoint:${NC}    http://${SERVER_IP}:${PORT}/v1/chat/completions"
echo -e "  📊 ${BOLD}Models Endpoint:${NC}    http://${SERVER_IP}:${PORT}/v1/models"
echo ""
echo -e "  ⚙️  ${BOLD}Service Status:${NC}     systemctl status atomic-router"
echo -e "  📝 ${BOLD}View Logs:${NC}          journalctl -u atomic-router -f"
echo -e "  🔄 ${BOLD}Restart:${NC}            systemctl restart atomic-router"
echo -e "${CYAN}================================================================${NC}"
