# avalanche-livesys.ks — live-session safety net for KDE theming
#
# WHY THIS EXISTS
# The real fix is the /etc/xdg/kdedefaults/ cascade written by
# avalanche-branding.ks: it makes org.avalanche.desktop the system-default
# global theme, which Plasma applies to any fresh user on first login. This
# fragment is belt-and-suspenders for the LIVE session specifically.
#
# HOW THE LIVE SESSION IS SET UP (learned from the livesys-scripts package):
#   - /usr/libexec/livesys/livesys-main runs once, at first boot, AS ROOT,
#     before the graphical session exists.
#   - It creates the `liveuser`, sources the KDE session script
#     (/usr/libexec/livesys/sessions.d/livesys-kde, which writes assorted
#     /home/liveuser/.config/* files), then sources this extension file if
#     present: /var/lib/livesys/livesys-session-extra
#   - Afterwards it does `chown -R liveuser:liveuser /home/liveuser` and
#     `restorecon`, so anything we drop in /home/liveuser gets the right
#     owner + SELinux context automatically.
#
# Because this runs BEFORE any Plasma/D-Bus session, we CANNOT use
# plasma-apply-lookandfeel/colorscheme/wallpaperimage (they need a running
# session bus). Instead we seed the user's kdedefaults cascade directly —
# exactly the pattern livesys-kde itself uses for kwinrc/baloofilerc/etc. We
# just copy the system defaults we already installed into the live user's
# config, guaranteeing the live desktop wears the Avalanche theme.

%post
# Append our seeding logic to the livesys extension point. Single-quoted heredoc
# so nothing here is expanded now — it runs later, at live boot, as root.
cat >> /var/lib/livesys/livesys-session-extra << 'LIVEEOF'

# --- Avalanche OS: seed the live user's default global theme --------------
# Mirror the system kdedefaults cascade into the live user's config so the
# Avalanche look-and-feel + color scheme + wallpaper apply on first login.
if [ -d /home/liveuser ] && [ -f /etc/xdg/kdedefaults/package ]; then
    mkdir -p /home/liveuser/.config/kdedefaults
    for f in package kdeglobals plasmarc kwinrc; do
        [ -f "/etc/xdg/kdedefaults/$f" ] &&
            cp -f "/etc/xdg/kdedefaults/$f" "/home/liveuser/.config/kdedefaults/$f"
    done
fi
# --- end Avalanche OS ------------------------------------------------------
LIVEEOF

echo "AVALANCHE: livesys theming seed appended to livesys-session-extra"
%end
