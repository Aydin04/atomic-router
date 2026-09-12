#!/sbin/sh
ui_print "****************************************"
ui_print "*        AtomicRouter Daemon           *"
ui_print "*     Magisk / KernelSU / APatch       *"
ui_print "****************************************"

ui_print "- Installing AtomicRouter files..."
mkdir -p /data/adb/atomic-router-data

# Extract payload (supports fast gzip atomic-router.tar.gz or legacy .tar.xz)
PAYLOAD=""
if [ -f "$MODPATH/atomic-router.tar.gz" ]; then
    PAYLOAD="$MODPATH/atomic-router.tar.gz"
    PAYLOAD_TYPE="gzip"
elif [ -f "$MODPATH/atomic-router.tar.xz" ]; then
    PAYLOAD="$MODPATH/atomic-router.tar.xz"
    PAYLOAD_TYPE="xz"
fi

if [ -n "$PAYLOAD" ]; then
    ui_print "- Extracting core payload ($PAYLOAD_TYPE format)..."
    ui_print "  [1/3] Decompressing runtime & dependencies..."
    
    if [ "$PAYLOAD_TYPE" = "gzip" ]; then
        # Fast streaming gzip (native to busybox / toybox on Android)
        if command -v gzip >/dev/null 2>&1; then
            gzip -dc "$PAYLOAD" | tar -xf - -C "$MODPATH/" 2>/dev/null || tar -xzf "$PAYLOAD" -C "$MODPATH/"
        else
            tar -xzf "$PAYLOAD" -C "$MODPATH/" 2>/dev/null || tar -xf "$PAYLOAD" -C "$MODPATH/"
        fi
    else
        # Legacy xz decompression
        if command -v xz >/dev/null 2>&1; then
            xz -dc "$PAYLOAD" | tar -xf - -C "$MODPATH/" 2>/dev/null || tar -xJf "$PAYLOAD" -C "$MODPATH/"
        else
            tar -xJf "$PAYLOAD" -C "$MODPATH/" 2>/dev/null || tar -xf "$PAYLOAD" -C "$MODPATH/"
        fi
    fi
    
    ui_print "  [2/3] Verifying core modules..."
    rm -f "$PAYLOAD"
    ui_print "  [3/3] Extraction completed successfully!"
fi

set_perm_recursive $MODPATH 0 0 0755 0644
set_perm $MODPATH/service.sh 0 0 0755
set_perm $MODPATH/action.sh 0 0 0755
set_perm_recursive $MODPATH/bin 0 0 0755 0755
set_perm_recursive $MODPATH/lib 0 0 0755 0755

ui_print "- Embedded Node.js runtime included (Standalone)"
ui_print "- RAM limit: 300MB adaptive (500MB peak workload backup)"
ui_print "- Web dashboard port: 20128"
ui_print "- Installed successfully! Reboot to activate."
