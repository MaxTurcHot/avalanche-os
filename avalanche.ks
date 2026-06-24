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

# Generated fragment: logo icon + default wallpaper, base64-embedded + verified.
# Regenerate with: python3 scripts/gen-branding-ks.py
%include avalanche-branding.ks

# ── Plymouth boot splash ──────────────────────────────────────────────────────
# Generated fragment: theme files + the three boot frames, embedded and verified.
# Regenerate with: python3 scripts/gen-bootsplash-ks.py
%include avalanche-bootsplash.ks
