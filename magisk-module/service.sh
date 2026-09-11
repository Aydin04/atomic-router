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
export LD_LIBRARY_PATH="$MODDIR/lib:$LD_LIBRARY_PATH"

# Auto-configure CDP endpoint for Android Chrome
# Chrome on Android listens on local abstract socket @chrome_devtools_remote
# Forward tcp:9222 -> localabstract:chrome_devtools_remote if adb/socat available
if which socat >/dev/null 2>&1; then
    socat TCP-LISTEN:9222,fork,bind=127.0.0.1 ABSTRACT-CONNECT:chrome_devtools_remote &
fi
export CHROME_CDP_ENDPOINT="http://127.0.0.1:9222"

# Dynamic RAM Limiter Loop:
# Default: 300MB. If OOM crash occurs (code 137 / heap out of memory),
# fallback temporarily to 500MB, then recover back to 300MB.
CURRENT_RAM_LIMIT=300
cd "$MODDIR/atomic-router" || exit 1

while true; do
    echo "[INFO] Launching AtomicRouter (Target RAM Limit: ${CURRENT_RAM_LIMIT}MB)..."
    START_TIME=$(date +%s)
    
    $NODE_BIN --max-old-space-size=$CURRENT_RAM_LIMIT server.js &
    ROUTER_PID=$!
    echo "[INFO] AtomicRouter running with PID: $ROUTER_PID"

    # Apply OOM protection
    if [ -f "/proc/$ROUTER_PID/oom_score_adj" ]; then
        echo 200 > "/proc/$ROUTER_PID/oom_score_adj" 2>/dev/null
    fi

    wait $ROUTER_PID
    EXIT_CODE=$?
    UPTIME=$(( $(date +%s) - START_TIME ))
    echo "[WARN] AtomicRouter stopped (Exit code: $EXIT_CODE, Uptime: ${UPTIME}s)"

    # If crashed quickly or exit code 137 (SIGKILL/OOM), elevate limit to 500MB backup
    if [ $EXIT_CODE -eq 137 ] || [ $UPTIME -lt 15 ]; then
        if [ $CURRENT_RAM_LIMIT -lt 500 ]; then
            echo "[ALERT] Possible OOM or heavy workload detected! Elevating RAM limit to backup 500MB..."
            CURRENT_RAM_LIMIT=500
        else
            echo "[WARN] Crashed at 500MB, resting 5s before restart..."
            sleep 5
            CURRENT_RAM_LIMIT=300
        fi
    else
        # If ran stably for more than 60s, automatically revert back to 300MB target
        if [ $UPTIME -gt 60 ]; then
            echo "[INFO] Process ran stably. Ensuring standard 300MB RAM limit."
            CURRENT_RAM_LIMIT=300
        fi
        sleep 2
    fi
done
