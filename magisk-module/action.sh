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
BIND_HOST=0.0.0.0
REQUIRE_AUTH=false
CUSTOM_API_KEY=dsh-local-key
CUSTOM_ADMIN_PASSWORD=admin
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

    LOG_FLAG="$DATA_DIR/enable_internal_logs"
    if [ -f "$LOG_FLAG" ]; then
        LOG_STATE="ENABLED (Full App/Request Logs)"
    else
        LOG_STATE="DISABLED (Silent / Low-RAM Mode)"
    fi

    TARGET_HOST="${BIND_HOST:-0.0.0.0}"
    if [ "$REQUIRE_AUTH" = "true" ]; then
        AUTH_STATE="ENABLED (Key: ${CUSTOM_API_KEY:-dsh-local-key})"
    else
        AUTH_STATE="DISABLED (Open / No Auth)"
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
    echo " Network Binding  : $TARGET_HOST:20128"
    echo " API Key Auth     : $AUTH_STATE"
    echo " Web Dashboard    : $UI_STATE"
    echo " Background Sync  : $SYNC_STATE"
    echo " Internal Logging : $LOG_STATE"
    echo "=================================================="
    echo " [1] Toggle Web Dashboard (Open/Close Browser)"
    echo " [2] Toggle API Key & Password Protection"
    echo " [3] Toggle Network Binding (Localhost vs All/WiFi)"
    echo " [4] Trigger On-Demand Model & Provider Sync Now"
    echo " [5] Change Max RAM Limit (Current: ${CUSTOM_RAM_LIMIT:-300}MB)"
    echo " [6] Read service.log (Tail / Full / Follow)"
    echo " [7] Toggle Internal Router Logging (Silent vs Detailed)"
    echo " [8] Configure Custom API Key & Admin Password"
    echo " [9] Clear Logs & Temporary Cache"
    echo " [10] Restart AtomicRouter Service"
    echo " [11] Stop Service Completely"
    echo " [0] Exit Control Center"
    echo "=================================================="
    echo -n "Select option [0-11]: "
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
            if [ "$REQUIRE_AUTH" = "true" ]; then
                sed -i "s/REQUIRE_AUTH=.*/REQUIRE_AUTH=false/" "$CONFIG_FILE"
                REQUIRE_AUTH=false
                echo "[-] API Key & Password protection DISABLED (Anonymous access allowed)."
            else
                sed -i "s/REQUIRE_AUTH=.*/REQUIRE_AUTH=true/" "$CONFIG_FILE"
                REQUIRE_AUTH=true
                echo "[+] API Key & Password protection ENABLED!"
                echo "    Active Key : ${CUSTOM_API_KEY:-dsh-local-key}"
                echo "    Admin Pass : ${CUSTOM_ADMIN_PASSWORD:-admin}"
            fi
            reload_service
            sleep 2
            ;;
        3)
            echo ""
            if [ "$BIND_HOST" = "127.0.0.1" ]; then
                sed -i "s/BIND_HOST=.*/BIND_HOST=0.0.0.0/" "$CONFIG_FILE"
                BIND_HOST=0.0.0.0
                echo "[+] Network Binding set to: 0.0.0.0 (Accessible via LAN / WiFi / Hotspot)."
            else
                sed -i "s/BIND_HOST=.*/BIND_HOST=127.0.0.1/" "$CONFIG_FILE"
                BIND_HOST=127.0.0.1
                echo "[-] Network Binding set to: 127.0.0.1 (Localhost only, secure on public WiFi)."
            fi
            reload_service
            sleep 2
            ;;
        4)
            echo ""
            echo "[+] Arming On-Demand Background Sync..."
            touch "$SYNC_FLAG"
            reload_service
            echo "[+] Sync is now active for this session."
            echo "[+] Models and Arena stats are synchronizing in background..."
            sleep 2
            ;;
        5)
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
        6)
            echo ""
            echo "--- [ Read service.log ] ---"
            echo "File path: $DATA_DIR/service.log"
            if [ -f "$DATA_DIR/service.log" ]; then
                LOG_SIZE=$(wc -c < "$DATA_DIR/service.log" 2>/dev/null || echo 0)
                echo "File size: $(( LOG_SIZE / 1024 )) KB"
            fi
            echo "----------------------------"
            echo " [1] View last 50 lines (Quick Tail)"
            echo " [2] View last 150 lines"
            echo " [3] View entire log file (cat)"
            echo " [4] Live follow log stream (tail -f, Ctrl+C to stop)"
            echo " [0] Return to main menu"
            echo -n "Choose [0-4]: "
            read -r log_choice
            echo ""
            case "$log_choice" in
                1)
                    echo "--- Last 50 Lines ---"
                    tail -n 50 "$DATA_DIR/service.log" 2>/dev/null || echo "No logs found."
                    ;;
                2)
                    echo "--- Last 150 Lines ---"
                    tail -n 150 "$DATA_DIR/service.log" 2>/dev/null || echo "No logs found."
                    ;;
                3)
                    echo "--- Entire service.log ---"
                    cat "$DATA_DIR/service.log" 2>/dev/null || echo "No logs found."
                    ;;
                4)
                    echo "--- Following live service.log (Press Ctrl+C to return) ---"
                    tail -f -n 25 "$DATA_DIR/service.log" 2>/dev/null
                    ;;
                *)
                    ;;
            esac
            echo "--------------------------------------------"
            echo "Press ENTER to return to menu..."
            read -r _dummy
            ;;
        7)
            echo ""
            LOG_FLAG="$DATA_DIR/enable_internal_logs"
            if [ -f "$LOG_FLAG" ]; then
                rm -f "$LOG_FLAG"
                echo "[-] Atomic internal logging DISABLED (Silent mode: warn only, no file logging, minimum memory/flash writes)."
            else
                touch "$LOG_FLAG"
                echo "[+] Atomic internal logging ENABLED (Detailed mode: info level, call logs enabled)."
            fi
            reload_service
            sleep 2
            ;;
        8)
            echo ""
            echo "--- [ Configure API Key & Password ] ---"
            echo "Current API Key   : ${CUSTOM_API_KEY:-dsh-local-key}"
            echo "Current Admin Pass: ${CUSTOM_ADMIN_PASSWORD:-admin}"
            echo ""
            echo -n "Enter new API Key (leave empty to keep current): "
            read -r new_key
            if [ -n "$new_key" ]; then
                sed -i "s/CUSTOM_API_KEY=.*/CUSTOM_API_KEY=$new_key/" "$CONFIG_FILE"
                CUSTOM_API_KEY="$new_key"
                echo "[+] API Key updated."
            fi
            echo -n "Enter new Admin Password (leave empty to keep current): "
            read -r new_pass
            if [ -n "$new_pass" ]; then
                sed -i "s/CUSTOM_ADMIN_PASSWORD=.*/CUSTOM_ADMIN_PASSWORD=$new_pass/" "$CONFIG_FILE"
                CUSTOM_ADMIN_PASSWORD="$new_pass"
                echo "[+] Admin Password updated."
            fi
            reload_service
            sleep 2
            ;;
        9)
            echo ""
            echo "[+] Clearing service.log and temp cache..."
            rm -f "$DATA_DIR/service.log" "$DATA_DIR/service.log.1" "$DATA_DIR/tmp/*" 2>/dev/null
            touch "$DATA_DIR/service.log"
            echo "[+] Logs cleaned."
            sleep 1
            ;;
        10)
            echo ""
            echo "[+] Restarting AtomicRouter daemon..."
            reload_service
            sleep 2
            ;;
        11)
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
            echo "Invalid option. Please choose [0-11]."
            sleep 1
            ;;
    esac
done
