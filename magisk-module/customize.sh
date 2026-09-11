#!/sbin/sh
ui_print "****************************************"
ui_print "*        AtomicRouter Daemon           *"
ui_print "*     Magisk / KernelSU / APatch       *"
ui_print "****************************************"

ui_print "- Installing AtomicRouter files..."
mkdir -p /data/adb/atomic-router-data

# Extract ultra-compressed tar.xz payload if present
if [ -f "$MODPATH/atomic-router.tar.xz" ]; then
    ui_print "- Extracting ultra-compressed package (tar.xz)..."
    tar -xJf "$MODPATH/atomic-router.tar.xz" -C "$MODPATH/" 2>/dev/null || \
    xz -dc "$MODPATH/atomic-router.tar.xz" | tar -xf - -C "$MODPATH/" 2>/dev/null || \
    busybox tar -xJf "$MODPATH/atomic-router.tar.xz" -C "$MODPATH/"
    rm -f "$MODPATH/atomic-router.tar.xz"
fi

set_perm_recursive $MODPATH 0 0 0755 0644
set_perm $MODPATH/service.sh 0 0 0755
set_perm_recursive $MODPATH/bin 0 0 0755 0755
set_perm_recursive $MODPATH/lib 0 0 0755 0755

ui_print "- Embedded Node.js runtime included (Standalone)"
ui_print "- RAM limit: 300MB adaptive (500MB peak workload backup)"
ui_print "- Web dashboard port: 20128"
ui_print "- Installed successfully! Reboot to activate."
