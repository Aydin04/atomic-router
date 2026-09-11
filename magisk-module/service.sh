#!/system/bin/sh
# AtomicRouter background service with RAM and OOM restrictions
MODDIR=${0%/*}

# Wait until device boot is completed
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 3
done

# Environment Setup
export MODDIR
export DATA_DIR="/data/adb/atomic-router-data"
export LOG_FILE="/data/adb/atomic-router-data/service.log"
mkdir -p "$DATA_DIR"
mkdir -p "$DATA_DIR/tmp"

exec >> "$LOG_FILE" 2>&1
echo "=== Starting AtomicRouter Service at $(date) ==="

# Check for node runtime
NODE_BIN=""
if [ -x "$MODDIR/bin/node" ]; then
    NODE_BIN="$MODDIR/bin/node"
elif [ -x "/data/data/com.termux/files/usr/bin/node" ]; then
    NODE_BIN="/data/data/com.termux/files/usr/bin/node"
elif which node >/dev/null 2>&1; then
    NODE_BIN="$(which node)"
fi

if [ -z "$NODE_BIN" ]; then
    echo "[ERROR] Node.js binary not found! Please ensure Node is available or Termux is installed."
    exit 1
fi

echo "[INFO] Using Node binary: $NODE_BIN"

# Runtime Environment Variables
export PORT=20128
export HOST="0.0.0.0"
export REQUIRE_API_KEY="false"
export ROUTER_API_KEY="dsh-local-key"
export OMNIROUTE_API_KEY="dsh-local-key"
export HOME="$DATA_DIR"
export TMPDIR="$DATA_DIR/tmp"
export PATH="$MODDIR/bin:/system/bin:/system/xbin:$PATH"

# Auto-configure CDP endpoint for Android Chrome
# Chrome on Android listens on local abstract socket @chrome_devtools_remote
# Forward tcp:9222 -> localabstract:chrome_devtools_remote if adb/socat available
if which socat >/dev/null 2>&1; then
    socat TCP-LISTEN:9222,fork,bind=127.0.0.1 ABSTRACT-CONNECT:chrome_devtools_remote &
fi
export CHROME_CDP_ENDPOINT="http://127.0.0.1:9222"

# Run AtomicRouter with strict RAM limiter (--max-old-space-size=128)
cd "$MODDIR/atomic-router" || exit 1

# Start in background
$NODE_BIN --max-old-space-size=128 server.js &
ROUTER_PID=$!

echo "[INFO] AtomicRouter started with PID: $ROUTER_PID (RAM Limit: 128MB)"

# Apply OOM protection & cgroup limits to avoid eating excessive phone RAM
if [ -f "/proc/$ROUTER_PID/oom_score_adj" ]; then
    echo 200 > "/proc/$ROUTER_PID/oom_score_adj" 2>/dev/null
fi

wait $ROUTER_PID
echo "=== AtomicRouter exited with code $? ==="
