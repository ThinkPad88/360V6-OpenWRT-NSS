#!/bin/bash
# ============================================================
# 360V6 (qihoo_360v6) ç²¾ç®åºä»¶ èªå®ä¹ç¼è¯èæ¬
# æºç : laipeng668/openwrt-6.x  main-nss åæ¯ (6.12åæ ¸)
# ä¿ç: LuCIç®¡ççé¢ + NSSå é + OpenClash + Auroraä¸»é¢
# ============================================================

set -e

echo "=== å¼å§å è½½èªå®ä¹éç½® ==="

# --- 1. ä¿®æ¹é»è®¤IPåä¸»æºå ---
# é»è®¤IPä¿æ 192.168.1.1
sed -i "s/hostname='.*'/hostname='Openwrt'/g" package/base-files/files/bin/config_generate

# --- 2. ä¿®æ¹åºä»¶çæ¬å· ---
date_version=$(date +"%y.%m.%d")
if [ -f "package/lean/default-settings/files/zzz-default-settings" ]; then
    orig_version=$(cat "package/lean/default-settings/files/zzz-default-settings" | grep DISTRIB_REVISION= | awk -F "'" '{print $2}')
    if [ -n "$orig_version" ]; then
        sed -i "s/${orig_version}/R${date_version}/g" package/lean/default-settings/files/zzz-default-settings
        echo "çæ¬å·å·²ä¿®æ¹ä¸º: R${date_version}"
    fi
fi

# --- 3. ç§»é¤ä¸éè¦çLuCIåºç¨æºç  ---
# PassWall å¨å¥ï¼ä¸OpenClashåè½éå¤ï¼
rm -rf feeds/luci/applications/luci-app-passwall 2>/dev/null || true
rm -rf feeds/luci/applications/luci-app-passwall2 2>/dev/null || true
rm -rf package/passwall-packages 2>/dev/null || true
rm -rf package/luci-app-passwall 2>/dev/null || true
rm -rf package/luci-app-passwall2 2>/dev/null || true

# åç½ç©¿é
rm -rf feeds/luci/applications/luci-app-frpc 2>/dev/null || true
rm -rf feeds/luci/applications/luci-app-frps 2>/dev/null || true
rm -rf feeds/packages/net/frp 2>/dev/null || true

# å¶ä»ä¸å¸¸ç¨åºç¨
rm -rf feeds/luci/applications/luci-app-wechatpush 2>/dev/null || true
rm -rf package/luci-app-wechatpush 2>/dev/null || true
rm -rf feeds/luci/applications/luci-app-appfilter 2>/dev/null || true
rm -rf feeds/packages/net/open-app-filter 2>/dev/null || true
rm -rf package/OpenAppFilter 2>/dev/null || true
rm -rf feeds/luci/applications/luci-app-diskman 2>/dev/null || true
rm -rf feeds/luci/applications/luci-app-hd-idle 2>/dev/null || true
rm -rf feeds/luci/applications/luci-app-samba4 2>/dev/null || true
rm -rf feeds/luci/applications/luci-app-wol 2>/dev/null || true
rm -rf feeds/luci/applications/luci-app-vlmcsd 2>/dev/null || true
rm -rf feeds/luci/applications/luci-app-aria2 2>/dev/null || true
rm -rf feeds/packages/net/ariang 2>/dev/null || true
rm -rf feeds/luci/applications/luci-app-autoreboot 2>/dev/null || true
rm -rf feeds/luci/applications/luci-app-wifischedule 2>/dev/null || true
rm -rf feeds/luci/applications/luci-app-banip 2>/dev/null || true
rm -rf feeds/luci/applications/luci-app-acme 2>/dev/null || true
rm -rf feeds/luci/applications/luci-app-arpbind 2>/dev/null || true
rm -rf feeds/luci/applications/luci-app-usb-printer 2>/dev/null || true
rm -rf feeds/luci/applications/luci-app-watchcat 2>/dev/null || true
rm -rf feeds/luci/applications/luci-app-smartdns 2>/dev/null || true
rm -rf feeds/luci/applications/luci-app-zerotier 2>/dev/null || true
rm -rf feeds/luci/applications/luci-app-cpufreq 2>/dev/null || true
rm -rf package/luci-app-lucky 2>/dev/null || true
rm -rf package/openlist2 2>/dev/null || true
rm -rf package/luci-app-gecoosac 2>/dev/null || true
rm -rf package/luci-app-athena-led 2>/dev/null || true

# --- 4. åé Aurora ä¸»é¢ ---
echo "=== åéAuroraä¸»é¢ ==="
rm -rf feeds/luci/themes/luci-theme-aurora
git clone --depth=1 https://github.com/eamonxg/luci-theme-aurora feeds/luci/themes/luci-theme-aurora

# --- 5. åéææ° OpenClash ---
echo "=== åéææ°OpenClash ==="
rm -rf feeds/luci/applications/luci-app-openclash
git clone --depth=1 https://github.com/vernesong/OpenClash package/luci-app-openclash

# --- 5.5 éæèªå®ä¹ LuCI ä»ªè¡¨ç ---
echo "=== éæèªå®ä¹ LuCI ä»ªè¡¨ç ==="
rm -rf package/luci-app-dashboard
cp -r $GITHUB_WORKSPACE/packages/luci-app-dashboard package/luci-app-dashboard
chmod +x package/luci-app-dashboard/files/www/cgi-bin/dashboard-data
echo "ä»ªè¡¨çåå·²å¤å¶å° package/luci-app-dashboard"

# --- 6. æ·»å  helloworld feed ---
echo 'src-git helloworld https://github.com/fw876/helloworld' >>feeds.conf.default

# --- 7. æ´æ°å¹¶å®è£ feeds ---
echo "=== æ´æ°feeds ==="
./scripts/feeds update -a
./scripts/feeds install -a

# --- 8. è®¾ç½®é»è®¤ç»å½é¡µä¸ºä»ªè¡¨ç ---
echo "=== è®¾ç½®é»è®¤é¦é¡µä¸ºç³»ç»ä»ªè¡¨ç ==="
LUCI_CONFIG="package/feeds/luci/luci-base/root/etc/config/luci"
if [ -f "$LUCI_CONFIG" ]; then
    # å¨ config internal 'main' æ®µä¸­æ·»å  option home
    if ! grep -q "option home" "$LUCI_CONFIG"; then
        sed -i "/config internal 'main'/a\\\toption home '/admin/dashboard'" "$LUCI_CONFIG"
        echo "å·²è®¾ç½®é»è®¤é¦é¡µä¸º /admin/dashboard"
    else
        sed -i "s|option home.*|option home '/admin/dashboard'|" "$LUCI_CONFIG"
        echo "å·²æ´æ°é»è®¤é¦é¡µä¸º /admin/dashboard"
    fi
else
    echo "è­¦å: æªæ¾å° LuCI éç½®æä»¶ $LUCI_CONFIG"
fi

echo "=== èªå®ä¹éç½®å è½½å®æ ==="
