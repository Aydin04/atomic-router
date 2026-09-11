#!/sbin/sh
ui_print "****************************************"
ui_print "*        AtomicRouter Daemon           *"
ui_print "*     Magisk / KernelSU / APatch       *"
ui_print "****************************************"

ui_print "- Installing AtomicRouter files..."
mkdir -p /data/adb/atomic-router-data

set_perm_recursive $MODPATH 0 0 0755 0644
set_perm $MODPATH/service.sh 0 0 0755

if [ -f "$MODPATH/bin/node" ]; then
    set_perm $MODPATH/bin/node 0 0 0755
fi

ui_print "- RAM limit configured: 128MB"
ui_print "- Web dashboard port: 20128"
ui_print "- Installed successfully! Reboot to activate."
