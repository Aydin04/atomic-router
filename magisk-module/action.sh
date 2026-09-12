#!/system/bin/sh
# Interactive Control Center CLI for Magisk / KernelSU / APatch Action Button
MODDIR=${0%/*}
DATA_DIR="/data/adb/atomic-router-data"
UI_FLAG="$DATA_DIR/enable_ui"
SYNC_FLAG="$DATA_DIR/enable_sync"
CONFIG_FILE="$DATA_DIR/router_config.env"
mkdir -p "$DATA_DIR"

# Load or init custom config
if [ ! -f "$CONFIG_FILE" ]; then
    cat << 'CFG' > "$CONFIG_FILE"
CUSTOM_RAM_LIMIT=300
AUTO_SHUTDOWN_MINUTES=15
SYNC_MODELS=false
SYNC_ARENA=false
SYNC_PRICING=false
CFG
fi
. "$CONFIG_FILE"

get_process_info() {
    PID=$(cat "$DATA_DIR/atomic.pid" 2>/dev/null)
    if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
        STATUS="RUNNING (PID: $PID)"
        # Read Resident Set Size (RSS) in KB from /proc/<PID>/status
        RSS_KB=$(grep -i VmRSS "/proc/$PID/status" 2>/dev/null | awk '{print $2}')
        if [ -n "$RSS_KB" ]; then
            RSS_MB=$(( RSS_KB / 1024 ))
            MEM_INFO="${RSS_MB} MB RSS"
        else
            MEM_INFO="Measuring..."
        fi
        UPTIME_SEC=$(awk '{print int($1)}' "/proc/uptime" 2>/dev/null)
        START_TIME=$(stat -c %Y "/proc/$PID" 2>/dev/null)
        if [ -n "$START_TIME" ] && [ -n "$UPTIME_SEC" ]; then
            CUR_EPOCH=$(date +%s)
            PROC_UP=$(( CUR_EPOCH - START_TIME ))
            UP_INFO="${PROC_UP}s"
        else
            UP_INFO="Active"
        fi
    else
        STATUS="STOPPED"
        MEM_INFO="0 MB"
        UP_INFO="Off"
    fi

    if [ -f "$UI_FLAG" ]; then
        UI_STATE="ACTIVE (Port 20128 ON)"
    else
        UI_STATE="DORMANT (Ultra-Lite Mode)"
    fi

    if [ -f "$SYNC_FLAG" ]; then
        SYNC_STATE="ENABLED (Manual Sync Armed)"
    else
        SYNC_STATE="DISABLED (Offline / Clean)"
    fi
}

show_menu() {
    get_process_info
    echo ""
    echo "=================================================="
    echo "       ⚡ ATOMIC ROUTER CONTROL CENTER ⚡         "
    echo "=================================================="
    echo " Service Status   : $STATUS"
    echo " Service Uptime   : $UP_INFO"
    echo " Live RAM Usage   : $MEM_INFO (Max Cap: ${CUSTOM_RAM_LIMIT:-300}MB)"
    echo " Web Dashboard    : $UI_STATE"
    echo " Background Sync  : $SYNC_STATE"
    echo " Endpoint Target  : http://127.0.0.1:20128"
    echo "=================================================="
    echo " [1] Toggle Web Dashboard (Open/Close Browser)"
    echo " [2] Trigger On-Demand Model & Provider Sync Now"
    echo " [3] Change Max RAM Limit (Current: ${CUSTOM_RAM_LIMIT:-300}MB)"
    echo " [4] View Live Service Logs (service.log)"
    echo " [5] View App Proxy History (Last 25 Requests)"
    echo " [6] Clear Logs & Temporary Cache"
    echo " [7] Restart AtomicRouter Service"
    echo " [8] Stop Service Completely"
    echo " [0] Exit Control Center"
    echo "=================================================="
    echo -n "Select option [0-8]: "
}

reload_service() {
    PID=$(cat "$DATA_DIR/atomic.pid" 2>/dev/null)
    if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
        echo "[INFO] Reloading AtomicRouter with new parameters..."
        kill -15 "$PID" 2>/dev/null
    fi
}

# Main interactive loop
while true; do
    show_menu
    read -r choice
    case "$choice" in
        1)
            echo ""
            if [ -f "$UI_FLAG" ]; then
                rm -f "$UI_FLAG"
                echo "[-] Web Dashboard DEACTIVATED. Returning to Ultra-Lite mode (~80MB)."
                reload_service
            else
                touch "$UI_FLAG"
                echo "[+] Web Dashboard ACTIVATED!"
                echo "[+] Launching Browser at http://127.0.0.1:20128..."
                reload_service
                sleep 2
                which am >/dev/null 2>&1 && am start -a android.intent.action.VIEW -d "http://127.0.0.1:20128" >/dev/null 2>&1 || true
            fi
            sleep 2
            ;;
        2)
            echo ""
            echo "[+] Arming On-Demand Background Sync..."
            touch "$SYNC_FLAG"
            reload_service
            echo "[+] Sync is now active for this session."
            echo "[+] Models and Arena stats are synchronizing in background..."
            sleep 2
            ;;
        3)
            echo ""
            echo "Current Max RAM limit is: ${CUSTOM_RAM_LIMIT:-300} MB"
            echo -n "Enter new RAM limit in MB (e.g. 200, 300, 400, 500): "
            read -r new_ram
            if [ "$new_ram" -ge 150 ] 2>/dev/null; then
                sed -i "s/CUSTOM_RAM_LIMIT=.*/CUSTOM_RAM_LIMIT=$new_ram/" "$CONFIG_FILE"
                CUSTOM_RAM_LIMIT=$new_ram
                echo "[+] Updated Max RAM Limit to ${CUSTOM_RAM_LIMIT} MB."
                reload_service
            else
                echo "[!] Invalid value. Minimum supported is 150 MB."
            fi
            sleep 2
            ;;
        4)
            echo ""
            echo "--- [ Live Service Logs: Last 35 Lines ] ---"
            tail -n 35 "$DATA_DIR/service.log" 2>/dev/null || echo "No logs yet."
            echo "--------------------------------------------"
            echo "Press ENTER to return to menu..."
            read -r _dummy
            ;;
        5)
            echo ""
            echo "--- [ SQLite / App Proxy Logs Summary ] ---"
            grep -E "proxyLogger|Loaded|Request|POST|GET" "$DATA_DIR/service.log" 2>/dev/null | tail -n 25 || echo "No proxy traffic logged yet."
            echo "-------------------------------------------"
            echo "Press ENTER to return to menu..."
            read -r _dummy
            ;;
        6)
            echo ""
            echo "[+] Clearing service.log and temp cache..."
            rm -f "$DATA_DIR/service.log" "$DATA_DIR/service.log.1" "$DATA_DIR/tmp/*" 2>/dev/null
            touch "$DATA_DIR/service.log"
            echo "[+] Logs cleaned."
            sleep 1
            ;;
        7)
            echo ""
            echo "[+] Restarting AtomicRouter daemon..."
            reload_service
            sleep 2
            ;;
        8)
            echo ""
            rm -f "$UI_FLAG" "$SYNC_FLAG"
            PID=$(cat "$DATA_DIR/atomic.pid" 2>/dev/null)
            if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
                kill -9 "$PID" 2>/dev/null
                rm -f "$DATA_DIR/atomic.pid"
            fi
            echo "[+] AtomicRouter service stopped."
            sleep 2
            ;;
        0|q|exit)
            echo ""
            echo "Bye! AtomicRouter continues running in background."
            break
            ;;
        *)
            echo "Invalid option. Please choose [0-8]."
            sleep 1
            ;;
    esac
done
