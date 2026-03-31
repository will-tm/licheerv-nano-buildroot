#!/bin/sh
# Fix AIC8800 driver for Linux 6.19+ kernel API changes
DIR="$1"
cd "$DIR" || exit 1

FDRV=aic8800_fdrv
BSP=aic8800_bsp

# 1. Timer API
find . -name '*.c' -o -name '*.h' | xargs sed -i \
    -e 's/from_timer(\([^,]*\), *\([^,]*\), *\([^)]*\))/timer_container_of(\1, \2, \3)/g' \
    -e 's/\bdel_timer_sync\b/timer_delete_sync/g'
find . -name '*.c' | xargs sed -i 's/\bdel_timer\b(/timer_delete(/g'

# 2. in_irq() -> in_hardirq()
find . -name '*.c' | xargs sed -i 's/\bin_irq()/in_hardirq()/g'

# 3. Remove MODULE_IMPORT_NS(VFS_internal...)
find . -name '*.c' | xargs sed -i '/MODULE_IMPORT_NS.*VFS_internal/d'

# 4. Add missing #include <linux/vmalloc.h>
grep -q 'vmalloc.h' $BSP/aic8800d80n_compat.c || \
    sed -i '/#include/a #include <linux/vmalloc.h>' $BSP/aic8800d80n_compat.c

# 5. cfg80211_rx_spurious_frame: add link_id=-1 parameter
sed -i 's/cfg80211_rx_spurious_frame(\([^,]*\), *\([^,]*\), *GFP_ATOMIC)/cfg80211_rx_spurious_frame(\1, \2, -1, GFP_ATOMIC)/g' $FDRV/rwnx_rx.c

# 6. cfg80211_rx_unexpected_4addr_frame: add link_id=-1 before GFP_ATOMIC
# Match the line with sta->mac_addr, GFP_ATOMIC that follows the function call
sed -i '/cfg80211_rx_unexpected_4addr_frame/,/GFP_ATOMIC/{s/sta->mac_addr, GFP_ATOMIC/sta->mac_addr, -1, GFP_ATOMIC/}' $FDRV/rwnx_rx.c

# 7. set_monitor_channel: added struct net_device *dev parameter
sed -i 's/^static int rwnx_cfg80211_set_monitor_channel(struct wiphy \*wiphy,$/static int rwnx_cfg80211_set_monitor_channel(struct wiphy *wiphy, struct net_device *dev,/' $FDRV/rwnx_main.c
# Fix internal callers - add NULL for dev parameter
sed -i 's/rwnx_cfg80211_set_monitor_channel(wiphy, chandef)/rwnx_cfg80211_set_monitor_channel(wiphy, NULL, chandef)/g' $FDRV/rwnx_main.c
sed -i 's/rwnx_cfg80211_set_monitor_channel(wiphy, NULL)/rwnx_cfg80211_set_monitor_channel(wiphy, NULL, NULL)/g' $FDRV/rwnx_main.c

# 8. set_wiphy_params: added int radio_idx parameter
sed -i 's/^static int rwnx_cfg80211_set_wiphy_params(struct wiphy \*wiphy, u32 changed)/static int rwnx_cfg80211_set_wiphy_params(struct wiphy *wiphy, int radio_idx, u32 changed)/' $FDRV/rwnx_main.c

# 9. set_tx_power: added int radio_idx parameter (line after function name, before enum)
sed -i '/^static int rwnx_cfg80211_set_tx_power/,/^{/{
    s/enum nl80211_tx_power_setting/int radio_idx, enum nl80211_tx_power_setting/
}' $FDRV/rwnx_main.c

# 10. get_tx_power: replace the whole function signature block
# Old: (wiphy, wdev, int *mbm) with #if guards
# New: (wiphy, wdev, radio_idx, link_id, int *mbm)
sed -i '/^static int rwnx_cfg80211_get_tx_power/,/^{/{
    /struct wireless_dev \*wdev,/d
    /#if.*KERNEL_VERSION(3, 8, 0)/d
    /#endif/d
    s/int \*mbm)/struct wireless_dev *wdev, int radio_idx, unsigned int link_id, int *mbm)/
}' $FDRV/rwnx_main.c
# Remove the old compat wdev declaration inside the function
sed -i '/^    #if LINUX_VERSION_CODE < KERNEL_VERSION(3, 8, 0)/{N;N;d}' $FDRV/rwnx_main.c

# 11. wakeup_source_create/add/remove/destroy removed - use register/unregister
sed -i 's/#include <linux\/pm_wakeirq.h>/#include <linux\/pm_wakeup.h>/' $FDRV/rwnx_wakelock.c
cat > /tmp/aic8800_wakelock_fix.py << 'PYEOF'
import re, sys
with open(sys.argv[1]) as f: s = f.read()
# Replace rwnx_wakeup_init to use wakeup_source_register
s = re.sub(
    r'struct wakeup_source \*rwnx_wakeup_init\(const char \*name\)\n\{[^}]+\}',
    'struct wakeup_source *rwnx_wakeup_init(const char *name)\n{\n\treturn wakeup_source_register(NULL, name);\n}',
    s)
# Replace rwnx_wakeup_deinit to use wakeup_source_unregister
s = re.sub(
    r'void rwnx_wakeup_deinit\(struct wakeup_source \*ws\)\n\{[^}]+\}',
    'void rwnx_wakeup_deinit(struct wakeup_source *ws)\n{\n\tif (ws && ws->active)\n\t\t__pm_relax(ws);\n\twakeup_source_unregister(ws);\n}',
    s)
with open(sys.argv[1], 'w') as f: f.write(s)
PYEOF
python3 /tmp/aic8800_wakelock_fix.py $FDRV/rwnx_wakelock.c

echo "AIC8800 v6.19 compat fixes applied"
