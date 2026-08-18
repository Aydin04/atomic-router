#!/usr/bin/env bash
# ==============================================================================
# ⚡ AtomicRouter 1-Line Automated Installer
# Pure Streamlined Universal AI Gateway Fork of OmniRoute
# Optimized for 512MB - 1GB Low-Spec VPS
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
REPO_URL="https://github.com/dianrestu/atomic-router.git"

echo -e "${CYAN}${BOLD}"
echo "================================================================"
echo "   ⚡ AtomicRouter | Ultra-Lightweight Universal AI Gateway"
echo "   (Pure Gateway Fork of OmniRoute - 330+ Providers & Combos)"
echo "================================================================"
echo -e "${NC}"

# Check root privilege
if [ "$(id -u)" -ne 0 ]; then
  echo -e "${RED}[ERROR] Please run this script as root or with sudo.${NC}"
  exit 1
fi

# 1. Check RAM and automatically setup Swap if RAM < 1.5GB
TOTAL_RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
TOTAL_RAM_MB=$((TOTAL_RAM_KB / 1024))
TOTAL_SWAP_KB=$(grep SwapTotal /proc/meminfo | awk '{print $2}')

echo -e "${BLUE}[1/6] Checking system memory... (Detected: ${TOTAL_RAM_MB} MB RAM)${NC}"

if [ "$TOTAL_RAM_MB" -lt 1500 ] && [ "$TOTAL_SWAP_KB" -lt 500000 ]; then
  echo -e "${YELLOW}[!] Low memory detected (${TOTAL_RAM_MB} MB). Setting up 1.5 GB Swap to prevent Out-Of-Memory during build...${NC}"
  if [ ! -f /swapfile_atomic ]; then
    fallocate -l 1536M /swapfile_atomic 2>/dev/null || dd if=/dev/zero of=/swapfile_atomic bs=1M count=1536
    chmod 600 /swapfile_atomic
    mkswap /swapfile_atomic >/dev/null 2>&1
    swapon /swapfile_atomic 2>/dev/null || true
    echo -e "${GREEN}[✓] 1.5 GB Swap active.${NC}"
  fi
fi

# 2. Install essential packages & Node.js 22 LTS if missing
echo -e "${BLUE}[2/6] Checking dependencies (Node.js, Git, curl)...${NC}"
if ! command -v git &>/dev/null || ! command -v curl &>/dev/null; then
  echo -e "${YELLOW}Installing git and curl...${NC}"
  apt-get update -y && apt-get install -y git curl build-essential || yum install -y git curl gcc-c++ make
fi

if ! command -v node &>/dev/null || [ "$(node -v | cut -d'.' -f1 | tr -d 'v')" -lt 20 ]; then
  echo -e "${YELLOW}Installing Node.js 22 LTS...${NC}"
  curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
  apt-get install -y nodejs || yum install -y nodejs
fi

echo -e "${GREEN}[✓] Node.js $(node -v) and npm $(npm -v) installed.${NC}"

# 3. Clone or update repository
echo -e "${BLUE}[3/6] Setting up AtomicRouter source at ${INSTALL_DIR}...${NC}"
if [ -d "$INSTALL_DIR/.git" ]; then
  echo -e "${YELLOW}Updating existing installation...${NC}"
  cd "$INSTALL_DIR"
  git fetch origin main || true
  git reset --hard origin/main || true
else
  mkdir -p "$INSTALL_DIR"
  git clone --depth=1 "$REPO_URL" "$INSTALL_DIR"
  cd "$INSTALL_DIR"
fi

# 4. Install dependencies with memory limit
echo -e "${BLUE}[4/6] Installing dependencies (Capped memory mode for low-spec VPS)...${NC}"
export NODE_OPTIONS="--max-old-space-size=450"
npm install --no-audit --no-fund

# 5. Build optimized standalone gateway
echo -e "${BLUE}[5/6] Building production gateway...${NC}"
if [ ! -f "$INSTALL_DIR/.env" ]; then
  if [ -f "$INSTALL_DIR/.env.example" ]; then
    cp "$INSTALL_DIR/.env.example" "$INSTALL_DIR/.env"
  else
    echo "PORT=${PORT}" > "$INSTALL_DIR/.env"
  fi
fi

npm run build

# 6. Configure Systemd Service
echo -e "${BLUE}[6/6] Configuring systemd background service...${NC}"
cat << 'SERVICE_EOF' > /etc/systemd/system/atomic-router.service
[Unit]
Description=AtomicRouter Universal AI Gateway Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/atomic-router
Environment=NODE_ENV=production
Environment=PORT=20128
Environment=NODE_OPTIONS="--max-old-space-size=450"
ExecStart=/usr/bin/npm start
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

# Fetch public / local IP
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
