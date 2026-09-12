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
if [ -f "$MODDIR/control-center.cjs" ]; then
    kill $(cat "$DATA_DIR/control_center.pid" 2>/dev/null) 2>/dev/null || true
    DATA_DIR="$DATA_DIR" $NODE_BIN --max-old-space-size=32 "$MODDIR/control-center.cjs" >> "$LOG_FILE" 2>&1 &
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
        MODE="Dashboard (Full Web UI Active)"
        TARGET_MAX_RAM=${CUSTOM_RAM_LIMIT:-450}
        [ "$TARGET_MAX_RAM" -lt 350 ] && TARGET_MAX_RAM=350
        export OMNIROUTE_ENABLE_LIVE_WS=1
        export OMNIROUTE_DISABLE_BACKGROUND_SERVICES=0
    else
        # Ultra-Lite Core Mode: Core AI router runs 24/7 with low RAM ceiling
        # Heavy schedulers, live WS daemon (port 20132), and intensive workers are suppressed!
        MODE="Ultra-Lite Core (AI Gateway 24/7, Web UI Dormant)"
        TARGET_MAX_RAM=${CUSTOM_RAM_LIMIT:-300}
        export OMNIROUTE_ENABLE_LIVE_WS=0
        export OMNIROUTE_DISABLE_BACKGROUND_SERVICES=1
        export OMNIROUTE_DISABLE_CREDENTIAL_HEALTH_CHECK=1
        export CLOUD_SYNC_ENABLED=false
    fi

    # 1. Uncap memory during initialization/booting to prevent startup OOM!
    # V8 is given ample breathing room (1024MB) while compiling Next.js AST, SQLite, routes, and modules.
    BOOT_RAM_LIMIT=1024
    export NEXT_MANUAL_SIG_HANDLE=true
    V8_FLAGS="--max-old-space-size=$BOOT_RAM_LIMIT --max-semi-space-size=2 --optimize-for-size"

    echo "[INFO] Launching AtomicRouter in $MODE mode (Boot Cap: ${BOOT_RAM_LIMIT}MB, Target Limit: ${TARGET_MAX_RAM}MB)..."
    START_TIME=$(date +%s)
    
    $NODE_BIN $V8_FLAGS server.js &
    ROUTER_PID=$!
    echo "$ROUTER_PID" > "$DATA_DIR/atomic.pid"
    echo "[INFO] AtomicRouter running with PID: $ROUTER_PID"

    # Protect AtomicRouter from Android Low Memory Killer (LMK)
    if [ -f "/proc/$ROUTER_PID/oom_score_adj" ]; then
        echo -700 > "/proc/$ROUTER_PID/oom_score_adj" 2>/dev/null
    fi

    # 2. Dynamic Memory Stabilizer & Auto-Lock Background Monitor
    # Allows server to boot freely without OOM, then monitors when RSS stabilizes
    (
        BOOT_SETTLE_COUNT=0
        LAST_RSS=0
        
        # Wait up to 60s for boot phase to complete
        for i in $(seq 1 30); do
            sleep 2
            [ ! -d "/proc/$ROUTER_PID" ] && exit 0
            
            # Read current VmRSS
            CUR_RSS_KB=$(grep -i 'VmRSS:' "/proc/$ROUTER_PID/status" 2>/dev/null | awk '{print $2}')
            [ -z "$CUR_RSS_KB" ] && continue
            CUR_RSS_MB=$((CUR_RSS_KB / 1024))
            
            # Check if RSS delta is small (< 10MB variation over 3 consecutive checks)
            DIFF=$((CUR_RSS_MB - LAST_RSS))
            [ $DIFF -lt 0 ] && DIFF=$(( -DIFF ))
            
            if [ $DIFF -le 10 ] && [ $CUR_RSS_MB -ge 40 ]; then
                BOOT_SETTLE_COUNT=$((BOOT_SETTLE_COUNT + 1))
            else
                BOOT_SETTLE_COUNT=0
            fi
            LAST_RSS=$CUR_RSS_MB
            
            # If server stabilized for 3 checks (6s) or after 25 iterations (50s)
            if [ $BOOT_SETTLE_COUNT -ge 3 ] || [ $i -eq 25 ]; then
                # Calculate auto-locked ceiling: always slightly above actual stable RSS (+ 35MB buffer)
                FINAL_LOCK_MB=$((CUR_RSS_MB + 35))
                
                # If user set a higher manual RAM limit, allow up to user limit
                if [ -n "$TARGET_MAX_RAM" ] && [ "$TARGET_MAX_RAM" -gt "$FINAL_LOCK_MB" ]; then
                    FINAL_LOCK_MB=$TARGET_MAX_RAM
                fi
                
                echo "[INFO] Boot phase finished! Stable RSS: ${CUR_RSS_MB}MB. Auto-locking RAM target: ${FINAL_LOCK_MB}MB." >> "$LOG_FILE"
                echo "$FINAL_LOCK_MB" > "$DATA_DIR/locked_ram_limit"
                break
            fi
        done
        
        # Continuous Memory Watchdog:
        # If process ever climbs too high above lock target, trigger gentle V8 GC via signal or trim
        while [ -d "/proc/$ROUTER_PID" ]; do
            sleep 10
            CUR_RSS_KB=$(grep -i 'VmRSS:' "/proc/$ROUTER_PID/status" 2>/dev/null | awk '{print $2}')
            [ -z "$CUR_RSS_KB" ] && continue
            CUR_RSS_MB=$((CUR_RSS_KB / 1024))
            LOCK_VAL=$(cat "$DATA_DIR/locked_ram_limit" 2>/dev/null || echo "$FINAL_LOCK_MB")
            if [ -n "$LOCK_VAL" ] && [ "$CUR_RSS_MB" -gt "$((LOCK_VAL + 50))" ]; then
                # Notify kernel to compact/reclaim process memory
                echo 1 > "/proc/sys/vm/compact_memory" 2>/dev/null || true
            fi
        done
    ) &
    WATCHDOG_PID=$!

    wait $ROUTER_PID
    EXIT_CODE=$?
    kill $WATCHDOG_PID 2>/dev/null || true
    rm -f "$DATA_DIR/atomic.pid" "$DATA_DIR/locked_ram_limit"
    UPTIME=$(( $(date +%s) - START_TIME ))
    echo "[INFO] AtomicRouter stopped (Exit code: $EXIT_CODE, Uptime: ${UPTIME}s)"

    # Short delay before rebooting daemon loop
    sleep 1
done
