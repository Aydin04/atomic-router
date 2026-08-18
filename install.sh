#!/usr/bin/env bash
# ==============================================================================
# ⚡ AtomicRouter 1-Line Automated Installer & CLI Manager
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
RELEASE_URL="https://github.com/${REPO}/releases/latest/download/atomic-router-linux-x64.tar.gz"

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
echo -e "${BLUE}[1/5] Checking system dependencies (Node.js 22 LTS, tar, curl)...${NC}"
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
echo -e "${BLUE}[2/5] Fetching pre-compiled release from GitHub...${NC}"
mkdir -p "$INSTALL_DIR"
TEMP_TAR="/tmp/atomic-router-pkg.tar.gz"

if curl -sIL "$RELEASE_URL" | grep -qE "HTTP/.* (200|302)"; then
  echo -e "${GREEN}[✓] Downloading pre-built package...${NC}"
  curl -fsSL "$RELEASE_URL" -o "$TEMP_TAR"
  tar -xzf "$TEMP_TAR" -C "$INSTALL_DIR/"
  rm -rf "$TEMP_TAR"
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
echo -e "${BLUE}[3/5] Initializing unique cryptographic configuration...\${NC}"
if [ ! -f "$INSTALL_DIR/.env" ]; then
  if [ -f "$INSTALL_DIR/.env.example" ]; then
    cp "$INSTALL_DIR/.env.example" "$INSTALL_DIR/.env"
  else
    touch "$INSTALL_DIR/.env"
  fi

  # Generate random cryptographic secrets unique per machine
  RAND_SECRET=$(node -e "console.log(require('crypto').randomBytes(32).toString('hex'))")
  RAND_AUTH=$(node -e "console.log(require('crypto').randomBytes(32).toString('hex'))")

  sed -i "s|^JWT_SECRET=.*|JWT_SECRET=$RAND_SECRET|" "$INSTALL_DIR/.env" 2>/dev/null || true
  sed -i "s|^OMNIROUTE_SECRET_KEY=.*|OMNIROUTE_SECRET_KEY=$RAND_SECRET|" "$INSTALL_DIR/.env" 2>/dev/null || true
  sed -i "s|^BETTER_AUTH_SECRET=.*|BETTER_AUTH_SECRET=$RAND_AUTH|" "$INSTALL_DIR/.env" 2>/dev/null || true

  if ! grep -q "PORT=" "$INSTALL_DIR/.env"; then
    echo "PORT=${PORT}" >> "$INSTALL_DIR/.env"
  fi
  echo -e "${GREEN}[✓] Generated unique local encryption keys for this VPS.\${NC}"
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
echo -e "${BLUE}[4/5] Setting up systemd background service...${NC}"
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

# 5. Install Global CLI Command: atomic-router
echo -e "${BLUE}[5/5] Creating global CLI command (/usr/local/bin/atomic-router)...${NC}"
cat << 'CLI_EOF' > /usr/local/bin/atomic-router
#!/usr/bin/env bash
# AtomicRouter Management CLI

INSTALL_DIR="/opt/atomic-router"
REPO="dianrestu/atomic-router"
RELEASE_URL="https://github.com/${REPO}/releases/latest/download/atomic-router-linux-x64.tar.gz"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

case "$1" in
  update|upgrade)
    echo -e "${CYAN}${BOLD}⚡ Updating AtomicRouter to latest version...${NC}"
    if [ "$(id -u)" -ne 0 ]; then
      echo -e "${RED}[ERROR] Please run with sudo: sudo atomic-router update${NC}"
      exit 1
    fi
    TEMP_TAR="/tmp/atomic-router-pkg.tar.gz"
    echo -e "${BLUE}Downloading latest release package...${NC}"
    curl -fsSL "$RELEASE_URL" -o "$TEMP_TAR"
    echo -e "${BLUE}Applying update files...${NC}"
    tar -xzf "$TEMP_TAR" -C "$INSTALL_DIR/"
    rm -rf "$TEMP_TAR"
    echo -e "${BLUE}Restarting service...${NC}"
    systemctl daemon-reload
    systemctl restart atomic-router
    echo -e "${GREEN}${BOLD}🎉 AtomicRouter successfully updated to latest version!${NC}"
    ;;
  restart)
    echo -e "${CYAN}Restarting AtomicRouter service...${NC}"
    systemctl restart atomic-router
    echo -e "${GREEN}[✓] Service restarted.${NC}"
    ;;
  start)
    systemctl start atomic-router
    echo -e "${GREEN}[✓] Service started.${NC}"
    ;;
  stop)
    systemctl stop atomic-router
    echo -e "${YELLOW}[!] Service stopped.${NC}"
    ;;
  status)
    systemctl status atomic-router
    ;;
  logs|log)
    journalctl -u atomic-router -f
    ;;
  version|-v|--version)
    if [ -f "$INSTALL_DIR/package.json" ]; then
      VER=$(node -p "require('$INSTALL_DIR/package.json').version" 2>/dev/null || echo "Unknown")
      echo "⚡ AtomicRouter version: v$VER"
    else
      echo "⚡ AtomicRouter (Active)"
    fi
    ;;
  *)
    echo -e "${CYAN}${BOLD}⚡ AtomicRouter CLI Commands:${NC}"
    echo "  atomic-router update    - Update to latest version (fast 5s update, preserves DB)"
    echo "  atomic-router restart   - Restart service"
    echo "  atomic-router status    - Check service health & status"
    echo "  atomic-router logs      - View live real-time logs"
    echo "  atomic-router start     - Start service"
    echo "  atomic-router stop      - Stop service"
    echo "  atomic-router version   - Show current version"
    ;;
esac
CLI_EOF

chmod +x /usr/local/bin/atomic-router

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
echo -e "  ⚡ ${BOLD}Convenient CLI Commands:${NC}"
echo -e "     • Update to latest:  ${CYAN}sudo atomic-router update${NC}"
echo -e "     • View live logs:    ${CYAN}atomic-router logs${NC}"
echo -e "     • Check status:      ${CYAN}atomic-router status${NC}"
echo -e "     • Restart:           ${CYAN}atomic-router restart${NC}"
echo -e "${CYAN}================================================================${NC}"
