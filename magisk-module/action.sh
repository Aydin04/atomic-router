#!/system/bin/sh
# Magisk / KernelSU / APatch Action Trigger for AtomicRouter
MODDIR=${0%/*}
DATA_DIR="/data/adb/atomic-router-data"
UI_FLAG="$DATA_DIR/enable_ui"
AUTO_SHUTDOWN_MINUTES=10

show_toast() {
    local msg="$1"
    if which am >/dev/null 2>&1; then
        am start -a android.intent.action.MAIN -e toast "$msg" >/dev/null 2>&1 || true
    fi
    echo "[Action] $msg"
}

open_dashboard() {
    if which am >/dev/null 2>&1; then
        am start -a android.intent.action.VIEW -d "http://127.0.0.1:20128" >/dev/null 2>&1 || true
    fi
}

mkdir -p "$DATA_DIR"

if [ -f "$UI_FLAG" ]; then
    # Currently ON -> Turn OFF (Switch to Ultra-Lite mode)
    rm -f "$UI_FLAG"
    rm -f "$DATA_DIR/ui_timer.pid"
    
    # Signal service.sh to reload in Lite mode
    PID=$(cat "$DATA_DIR/atomic.pid" 2>/dev/null)
    if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
        kill -15 "$PID" 2>/dev/null
    fi
    show_toast "Atomic Dashboard: OFF (Ultra-Lite Mode ~80MB)"
else
    # Currently OFF -> Turn ON (Activate Dashboard & Auto-Shutdown Timer)
    touch "$UI_FLAG"
    
    # Signal service.sh to reload with Dashboard enabled
    PID=$(cat "$DATA_DIR/atomic.pid" 2>/dev/null)
    if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
        kill -15 "$PID" 2>/dev/null
    fi
    
    # Open dashboard in browser
    sleep 2
    open_dashboard
    show_toast "Atomic Dashboard: ON (Auto-off in ${AUTO_SHUTDOWN_MINUTES}m)"
    
    # Launch background auto-shutdown watchdog timer
    (
        sleep $(( AUTO_SHUTDOWN_MINUTES * 60 ))
        if [ -f "$UI_FLAG" ]; then
            rm -f "$UI_FLAG"
            PID_CUR=$(cat "$DATA_DIR/atomic.pid" 2>/dev/null)
            if [ -n "$PID_CUR" ] && kill -0 "$PID_CUR" 2>/dev/null; then
                kill -15 "$PID_CUR" 2>/dev/null
            fi
            echo "[Auto-Shutdown] Dashboard auto-closed after ${AUTO_SHUTDOWN_MINUTES}m idle." >> "$DATA_DIR/service.log"
        fi
    ) &
    echo $! > "$DATA_DIR/ui_timer.pid"
fi
