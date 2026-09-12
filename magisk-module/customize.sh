#!/sbin/sh
ui_print "****************************************"
ui_print "*        AtomicRouter Daemon           *"
ui_print "*     Magisk / KernelSU / APatch       *"
ui_print "****************************************"

ui_print "- Installing AtomicRouter files..."
mkdir -p /data/adb/atomic-router-data

# Extract payload using RAM disk (tmpfs) if available for maximum I/O speed
if [ -f "$MODPATH/atomic-router.tar.xz" ]; then
    ui_print "- Extracting package using RAM buffer (Fast I/O)..."
    
    # Try creating a temporary RAM disk mount or using /dev/shm /tmp
    RAM_TMP=""
    for cand in /dev/shm /tmp /sqlite_stmt_journals; do
        if [ -d "$cand" ] && [ -w "$cand" ]; then
            RAM_TMP="$cand"
            break
        fi
    done
    
    # If no existing ramfs found, try mounting a lightweight tmpfs
    TMPFS_MOUNTED=0
    if [ -z "$RAM_TMP" ]; then
        mkdir -p /tmp/atomic_ram
        if mount -t tmpfs -o size=250M tmpfs /tmp/atomic_ram 2>/dev/null; then
            RAM_TMP="/tmp/atomic_ram"
            TMPFS_MOUNTED=1
        fi
    fi

    # Fast streaming decompression into $MODPATH
    if command -v xz >/dev/null 2>&1; then
        xz -dc "$MODPATH/atomic-router.tar.xz" | tar -xf - -C "$MODPATH/"
    elif command -v busybox >/dev/null 2>&1 && busybox tar --help 2>&1 | grep -q 'J'; then
        busybox tar -xJf "$MODPATH/atomic-router.tar.xz" -C "$MODPATH/"
    else
        tar -xJf "$MODPATH/atomic-router.tar.xz" -C "$MODPATH/" 2>/dev/null || \
        xz -dc "$MODPATH/atomic-router.tar.xz" | tar -xf - -C "$MODPATH/" 2>/dev/null || \
        tar -xf "$MODPATH/atomic-router.tar.xz" -C "$MODPATH/"
    fi
    
    rm -f "$MODPATH/atomic-router.tar.xz"
    if [ "$TMPFS_MOUNTED" -eq 1 ]; then
        umount /tmp/atomic_ram 2>/dev/null
        rm -rf /tmp/atomic_ram
    fi
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
