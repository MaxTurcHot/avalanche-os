# avalanche-identity.ks — Layer 1: system identity
#
# Rebrands the HUMAN-FACING OS name to "Avalanche OS" while leaving the
# MACHINE-READABLE identity (ID=fedora, VERSION_ID) untouched, so dnf, repos,
# and "am I on Fedora?" scripts keep working correctly.
#
# /etc/os-release is a symlink to /usr/lib/os-release (the real file, owned by
# the fedora-release package). We rewrite the real backing file so every reader
# — login screen, neofetch, GRUB, About dialog — reports Avalanche OS.
#
# NOTE (update fragility): a future `dnf update` of fedora-release could
# overwrite /usr/lib/os-release back to stock. For a live spin built fresh each
# time this is fine; the "proper" long-term fix is shipping our own *-release
# RPM. Documented here so it's a known, deliberate trade-off — not a surprise.

%post
# os-release is just shell-style KEY=value lines, so we can source it to reuse
# Fedora's real VERSION_ID / PLATFORM_ID / CPE_NAME instead of hardcoding them.
. /usr/lib/os-release

cat > /usr/lib/os-release << EOF
NAME="Avalanche OS"
VERSION="${VERSION_ID} (KDE Plasma)"
ID=fedora
VERSION_ID=${VERSION_ID}
PLATFORM_ID="${PLATFORM_ID}"
PRETTY_NAME="Avalanche OS ${VERSION_ID} (KDE Plasma)"
ANSI_COLOR="0;38;2;70;98;122"
LOGO=avalanche-logo-icon
CPE_NAME="${CPE_NAME}"
DEFAULT_HOSTNAME="avalanche"
HOME_URL="https://example.com/avalanche-os/"
DOCUMENTATION_URL="https://example.com/avalanche-os/"
SUPPORT_URL="https://example.com/avalanche-os/"
BUG_REPORT_URL="https://example.com/avalanche-os/"
AVALANCHE_BASE="Fedora Linux ${VERSION_ID}"
VARIANT="KDE Plasma"
VARIANT_ID=kde
EOF

echo "AVALANCHE: identity set ->"
grep -E '^(NAME|PRETTY_NAME|ID|VERSION_ID)=' /usr/lib/os-release
%end
