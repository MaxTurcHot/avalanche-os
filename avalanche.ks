# avalanche.ks — Avalanche OS kickstart
# Fedora KDE Plasma respin; backcountry / splitboard touring theme.
#
# All Avalanche branding layers are added below.

%include fedora-live-kde.ks

# Safety net: ignore any packages/groups that don't exist in the configured repos.
%packages --ignoremissing
%end

# ── Plymouth boot splash ──────────────────────────────────────────────────────
# Generated fragment: theme files + the three boot frames, embedded and verified.
# Regenerate with: python3 scripts/gen-bootsplash-ks.py
%include avalanche-bootsplash.ks
