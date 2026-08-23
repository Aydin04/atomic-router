#!/usr/bin/env bash
# ==============================================================================
# ⚡ AtomicRouter 1-Line Universal Installer (Linux, macOS, Raspberry Pi, Termux)
# ==============================================================================

set -e

# Color definitions
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
CYAN="\033[0;36m"
BOLD="\033[1m"
NC="\033[0m"

REPO="Aydin04/atomic-router"
PORT="${PORT:-20128}"
OS="$(uname -s)"
ARCH="$(uname -m)"

echo -e "${CYAN}${BOLD}"
echo "================================================================"
echo "   ⚡ AtomicRouter | Ultra-Lightweight Universal AI Gateway"
echo "   (Pre-Compiled Standalone Release - Universal 1-Line Installer)"
echo "================================================================"
echo -e "${NC}"

# Detect Environment: Termux, macOS, or standard Linux
IS_TERMUX=false
IS_MACOS=false

if [ -n "$PREFIX" ] && [[ "$PREFIX" == *"com.termux"* ]]; then
  IS_TERMUX=true
  INSTALL_DIR="${INSTALL_DIR:-$HOME/.atomic-router}"
elif [ "$OS" = "Darwin" ]; then
  IS_MACOS=true
  INSTALL_DIR="${INSTALL_DIR:-$HOME/.atomic-router}"
else
  INSTALL_DIR="${INSTALL_DIR:-/opt/atomic-router}"
  if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}[ERROR] Please run with sudo on Linux: curl -fsSL https://raw.githubusercontent.com/$REPO/main/install.sh | sudo bash${NC}"
    exit 1
  fi
fi

# 1. Dependency checks
echo -e "${BLUE}[1/5] Checking environment and dependencies...${NC}"

if [ "$IS_TERMUX" = true ]; then
  echo -e "${YELLOW}Detected Android Termux environment.${NC}"
  pkg update -y && pkg install -y nodejs-lts curl tar
elif [ "$IS_MACOS" = true ]; then
  echo -e "${YELLOW}Detected macOS ($ARCH).${NC}"
  if ! command -v node &>/dev/null; then
    if command -v brew &>/dev/null; then
      brew install node@22
    else
      echo -e "${RED}[ERROR] Please install Node.js 20+ from https://nodejs.org/ or via Homebrew.${NC}"
      exit 1
    fi
  fi
else
  if ! command -v curl &>/dev/null || ! command -v tar &>/dev/null; then
    apt-get update -y && apt-get install -y curl tar || yum install -y curl tar || apk add curl tar
  fi
  if ! command -v node &>/dev/null || [ "$(node -v | cut -d"." -f1 | tr -d "v")" -lt 20 ]; then
    echo -e "${YELLOW}Installing Node.js 22 LTS...${NC}"
    curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
    apt-get install -y nodejs || yum install -y nodejs || apk add nodejs
  fi
fi

echo -e "${GREEN}[✓] Node.js $(node -v) ready.${NC}"

# 2. Determine download package URL
RELEASE_URL="https://github.com/${REPO}/releases/latest/download/atomic-router-linux-x64.tar.gz"
if [ "$IS_MACOS" = true ]; then
  RELEASE_URL="https://github.com/${REPO}/releases/latest/download/atomic-router-macos-universal.tar.gz"
fi

echo -e "${BLUE}[2/5] Fetching pre-compiled release from GitHub...${NC}"
mkdir -p "$INSTALL_DIR"
TEMP_TAR="/tmp/atomic-router-pkg.tar.gz"
[ "$IS_TERMUX" = true ] && TEMP_TAR="$PREFIX/tmp/atomic-router-pkg.tar.gz"

echo -e "${GREEN}[✓] Downloading pre-built package...${NC}"
if ! curl -fsSL "$RELEASE_URL" -o "$TEMP_TAR" 2>/dev/null; then
  echo -e "${YELLOW}[!] Retrying with tag fallback...${NC}"
  FALLBACK_URL="https://github.com/${REPO}/releases/download/v3.8.50/atomic-router-linux-x64.tar.gz"
  [ "$IS_MACOS" = true ] && FALLBACK_URL="https://github.com/${REPO}/releases/download/v3.8.50/atomic-router-macos-universal.tar.gz"
  curl -fsSL "$FALLBACK_URL" -o "$TEMP_TAR"
fi

echo -e "${BLUE}Extracting bundle into $INSTALL_DIR...${NC}"
tar -xzf "$TEMP_TAR" -C "$INSTALL_DIR/"
rm -rf "$TEMP_TAR"

cd "$INSTALL_DIR"

# 3. Setup configuration
echo -e "${BLUE}[3/5] Initializing unique cryptographic configuration...${NC}"
if [ ! -f "$INSTALL_DIR/.env" ]; then
  if [ -f "$INSTALL_DIR/.env.example" ]; then
    cp "$INSTALL_DIR/.env.example" "$INSTALL_DIR/.env"
  else
    touch "$INSTALL_DIR/.env"
  fi

  RAND_SECRET=$(node -e "console.log(require("crypto").randomBytes(32).toString("hex"))" 2>/dev/null || echo "atomic_secret_$(date +%s)")
  RAND_AUTH=$(node -e "console.log(require("crypto").randomBytes(32).toString("hex"))" 2>/dev/null || echo "atomic_auth_$(date +%s)")

  sed -i "s|^JWT_SECRET=.*|JWT_SECRET=$RAND_SECRET|" "$INSTALL_DIR/.env" 2>/dev/null || true
  sed -i "s|^OMNIROUTE_SECRET_KEY=.*|OMNIROUTE_SECRET_KEY=$RAND_SECRET|" "$INSTALL_DIR/.env" 2>/dev/null || true
  sed -i "s|^BETTER_AUTH_SECRET=.*|BETTER_AUTH_SECRET=$RAND_AUTH|" "$INSTALL_DIR/.env" 2>/dev/null || true

  if ! grep -q "PORT=" "$INSTALL_DIR/.env"; then
    echo "PORT=${PORT}" >> "$INSTALL_DIR/.env"
  fi
  echo -e "${GREEN}[✓] Generated unique local encryption keys.${NC}"
fi

# 4. Service configuration (Linux systemd vs Termux/macOS)
if [ "$IS_TERMUX" = false ] && [ "$IS_MACOS" = false ] && command -v systemctl &>/dev/null; then
  echo -e "${BLUE}[4/5] Setting up systemd background service...${NC}"
  NODE_BIN="$(which node)"
  cat << SERVICE_EOF > /etc/systemd/system/atomic-router.service
[Unit]
Description=AtomicRouter Universal AI Gateway Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$INSTALL_DIR
Environment=NODE_ENV=production
Environment=PORT=$PORT
ExecStart=$NODE_BIN server.js
Restart=always
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
SERVICE_EOF

  systemctl daemon-reload
  systemctl enable atomic-router
  systemctl restart atomic-router
else
  echo -e "${BLUE}[4/5] Non-systemd environment (macOS / Termux) detected.${NC}"
fi

# 5. Create CLI helper
echo -e "${BLUE}[5/5] Creating global CLI command...${NC}"
CLI_BIN="/usr/local/bin/atomic-router"
[ "$IS_TERMUX" = true ] && CLI_BIN="$PREFIX/bin/atomic-router"

cat << CLISCRIPT > "$CLI_BIN"
#!/usr/bin/env bash
INSTALL_DIR_TARGET="$INSTALL_DIR"
REPO="Aydin04/atomic-router"
OS="\$(uname -s)"
URL="https://github.com/\${REPO}/releases/latest/download/atomic-router-linux-x64.tar.gz"
[ "\$OS" = "Darwin" ] && URL="https://github.com/\${REPO}/releases/latest/download/atomic-router-macos-universal.tar.gz"

case "\$1" in
  update|upgrade)
    echo "⚡ Updating AtomicRouter..."
    TEMP="/tmp/atomic-router-pkg.tar.gz"
    curl -fsSL "\$URL" -o "\$TEMP" || curl -fsSL "https://github.com/\${REPO}/releases/download/v3.8.50/atomic-router-linux-x64.tar.gz" -o "\$TEMP"
    tar -xzf "\$TEMP" -C "\$INSTALL_DIR_TARGET/"
    rm -rf "\$TEMP"
    if command -v systemctl &>/dev/null; then
      systemctl restart atomic-router
    fi
    echo "🎉 AtomicRouter successfully updated!"
    ;;
  start)
    cd "\$INSTALL_DIR_TARGET" && node server.js
    ;;
  restart)
    command -v systemctl &>/dev/null && systemctl restart atomic-router || (cd "\$INSTALL_DIR_TARGET" && node server.js)
    ;;
  status)
    command -v systemctl &>/dev/null && systemctl status atomic-router || curl -s http://localhost:20128/api/health
    ;;
  logs|log)
    command -v journalctl &>/dev/null && journalctl -u atomic-router -f || echo "Check terminal output"
    ;;
  *)
    echo "⚡ AtomicRouter CLI: update | start | restart | status | logs"
    ;;
esac
CLISCRIPT

chmod +x "$CLI_BIN"

IP_ADDR="localhost"
if command -v hostname &>/dev/null; then
  IP_ADDR=$(hostname -I 2>/dev/null | awk "{print \$1}" || echo "localhost")
fi

echo ""
echo -e "${GREEN}${BOLD}================================================================${NC}"
echo -e "${GREEN}${BOLD}   🎉 AtomicRouter Successfully Installed and Ready!${NC}"
echo -e "${GREEN}${BOLD}================================================================${NC}"
echo ""
echo -e "  🌐 ${BOLD}Dashboard URL:${NC}      http://${IP_ADDR}:${PORT}"
echo -e "  🤖 ${BOLD}OpenAI Endpoint:${NC}    http://${IP_ADDR}:${PORT}/v1/chat/completions"
echo -e "  📊 ${BOLD}Models Endpoint:${NC}    http://${IP_ADDR}:${PORT}/v1/models"
echo -e "  🔑 ${BOLD}Default Password:${NC}   CHANGEME"
echo ""
echo -e "  ⚡ ${BOLD}Convenient CLI Commands:${NC}"
echo -e "     • Update to latest:  ${CYAN}atomic-router update${NC}"
echo -e "     • View live logs:    ${CYAN}atomic-router logs${NC}"
echo -e "     • Check status:      ${CYAN}atomic-router status${NC}"
echo -e "     • Start manually:    ${CYAN}atomic-router start${NC}"
echo -e "${GREEN}${BOLD}================================================================${NC}"

if [ "$IS_TERMUX" = true ] || [ "$IS_MACOS" = true ]; then
  echo -e "${YELLOW}Starting AtomicRouter Gateway server in background...${NC}"
  (cd "$INSTALL_DIR" && nohup node server.js >/dev/null 2>&1 &) || true
fi
