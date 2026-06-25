# avalanche.ks — Avalanche OS kickstart
# Fedora KDE Plasma respin; backcountry / splitboard touring theme.
#
# All Avalanche branding layers are added below.

%include fedora-live-kde.ks

# Safety net: ignore any packages/groups that don't exist in the configured repos.
%packages --ignoremissing
%end

# ── Layer 1: system identity ──────────────────────────────────────────────────
# Rebrands os-release to "Avalanche OS" (keeps ID=fedora under the hood).
%include avalanche-identity.ks

# Console/terminal banners (issue, motd) and bootloader label (GRUB_DISTRIBUTOR).
%include avalanche-console.ks
%include avalanche-grub.ks

# ── Layer 3: branding ─────────────────────────────────────────────────────────
# Plasma color scheme (deep blue / white / charcoal) set as the default.
%include avalanche-colorscheme.ks

# Generated fragment: logo icon + default wallpaper + Look-and-Feel global theme
# and the /etc/xdg/kdedefaults cascade that makes it the system default.
# Regenerate with: python3 scripts/gen-branding-ks.py
%include avalanche-branding.ks

# Live-session safety net: seed the liveuser's kdedefaults so the theme applies
# on the live ISO too (must come after avalanche-branding.ks).
%include avalanche-livesys.ks

# ── Plymouth boot splash ──────────────────────────────────────────────────────
# Generated fragment: theme files + the three boot frames, embedded and verified.
# Regenerate with: python3 scripts/gen-bootsplash-ks.py
%include avalanche-bootsplash.ks

# ── Apps: Starship, RPM Fusion, Steam, VS Code, DBeaver, codecs, Firefox bookmarks
%include avalanche-apps.ks

# ── Snow Watch Plasma widget (wheretosnow API) ────────────────────────────────
%include avalanche-widget.ks

# ── KWin effects (no-op — stock KDE defaults) ────────────────────────────────
# Custom AvalancheDestroy C++ effect is in kwin/ — see DEVPLAN.md.
# Requires rebuilding kwin itself (KWin 6 compiles all effects into binary).
%include avalanche-effects.ks
