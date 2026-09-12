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

# Launch Standalone Control Center Web UI on isolated port 20129 (<15MB RAM)
if [ -f "$MODDIR/control-center.js" ]; then
    kill $(cat "$DATA_DIR/control_center.pid" 2>/dev/null) 2>/dev/null || true
    DATA_DIR="$DATA_DIR" $NODE_BIN --max-old-space-size=32 "$MODDIR/control-center.js" >> "$LOG_FILE" 2>&1 &
    echo $! > "$DATA_DIR/control_center.pid"
fi

# Dynamic Dual-Mode Architecture:
# 1. Ultra-Lite Mode (Default, ~80MB - 120MB):
#    Runs Core AI Gateway routing, streaming, auto-fallback, and token compression.
#    Web UI is dormant, freeing ~75% memory.
# 2. Dashboard Mode (Triggered via Magisk Action button, ~350MB):
#    Runs full web management interface with auto-off timer.

export UV_THREADPOOL_SIZE=2
UI_FLAG="$DATA_DIR/enable_ui"
SYNC_FLAG="$DATA_DIR/enable_sync"
CONFIG_FILE="$DATA_DIR/router_config.env"

cd "$MODDIR/atomic-router" || exit 1

while true; do
    # Load user config if exists
    [ -f "$CONFIG_FILE" ] && . "$CONFIG_FILE"
    
    # Network Binding: 0.0.0.0 (LAN/WiFi) vs 127.0.0.1 (Localhost only)
    export HOST="${BIND_HOST:-0.0.0.0}"

    # Authentication Control:
    # If REQUIRE_AUTH=true, enforce API key and password protection
    if [ "$REQUIRE_AUTH" = "true" ]; then
        export REQUIRE_API_KEY="true"
        export ROUTER_API_KEY="${CUSTOM_API_KEY:-dsh-local-key}"
        export OMNIROUTE_API_KEY="${CUSTOM_API_KEY:-dsh-local-key}"
        if [ -n "$CUSTOM_ADMIN_PASSWORD" ]; then
            export INITIAL_PASSWORD="$CUSTOM_ADMIN_PASSWORD"
        fi
    else
        export REQUIRE_API_KEY="false"
        export ROUTER_API_KEY="dsh-local-key"
        export OMNIROUTE_API_KEY="dsh-local-key"
        unset INITIAL_PASSWORD
    fi

    # Check sync state
    if [ -f "$SYNC_FLAG" ]; then
        export ARENA_ELO_SYNC_ENABLED=true
        export PRICING_SYNC_ENABLED=true
        export MODELS_DEV_SYNC_ENABLED=1
        export OPENROUTER_STATS_SYNC_ENABLED=true
    else
        export ARENA_ELO_SYNC_ENABLED=false
        export PRICING_SYNC_ENABLED=false
        export MODELS_DEV_SYNC_ENABLED=0
        export OPENROUTER_STATS_SYNC_ENABLED=false
    fi

    # Logging control:
    # When disable_internal_logs is active (or by default in Ultra-Lite mode),
    # suppress internal request call logs & file logging to save RAM and flash storage wear.
    LOG_FLAG="$DATA_DIR/enable_internal_logs"
    if [ -f "$LOG_FLAG" ]; then
        export APP_LOG_LEVEL="info"
        export APP_LOG_TO_FILE="true"
        export CALL_LOGS_TABLE_MAX_ROWS=1000
        export PROXY_LOGS_TABLE_MAX_ROWS=1000
    else
        export APP_LOG_LEVEL="warn"
        export APP_LOG_TO_FILE="false"
        export CALL_LOG_RETENTION_DAYS=1
        export CALL_LOG_MAX_ENTRIES=100
        export CALL_LOGS_TABLE_MAX_ROWS=200
        export PROXY_LOGS_TABLE_MAX_ROWS=200
        export CALL_LOG_PIPELINE_MAX_SIZE_KB=32
    fi

    if [ -f "$UI_FLAG" ]; then
        MODE="Dashboard (Full Web UI)"
        RAM_LIMIT=${CUSTOM_RAM_LIMIT:-450}
        [ "$RAM_LIMIT" -lt 350 ] && RAM_LIMIT=350
        export NEXT_MANUAL_SIG_HANDLE=true
        V8_FLAGS="--max-old-space-size=$RAM_LIMIT --optimize-for-size"
    else
        MODE="Ultra-Lite (Gateway Core Only)"
        RAM_LIMIT=${CUSTOM_RAM_LIMIT:-280}
        V8_FLAGS="--max-old-space-size=$RAM_LIMIT --optimize-for-size"
    fi

    echo "[INFO] Launching AtomicRouter in $MODE mode (RAM Limit: ${RAM_LIMIT}MB)..."
    START_TIME=$(date +%s)
    
    $NODE_BIN $V8_FLAGS server.js &
    ROUTER_PID=$!
    echo "$ROUTER_PID" > "$DATA_DIR/atomic.pid"
    echo "[INFO] AtomicRouter running with PID: $ROUTER_PID"

    # Protect AtomicRouter from Android Low Memory Killer (LMK)
    if [ -f "/proc/$ROUTER_PID/oom_score_adj" ]; then
        echo -700 > "/proc/$ROUTER_PID/oom_score_adj" 2>/dev/null
    fi

    wait $ROUTER_PID
    EXIT_CODE=$?
    rm -f "$DATA_DIR/atomic.pid"
    UPTIME=$(( $(date +%s) - START_TIME ))
    echo "[INFO] AtomicRouter stopped (Exit code: $EXIT_CODE, Uptime: ${UPTIME}s)"

    # Short delay before rebooting daemon
    sleep 1
done
