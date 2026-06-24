#!/usr/bin/env bash
set -euo pipefail

# Fedora release to build against. Match this to a current stable release.
RELEASEVER="${1:-44}"
RESULTDIR="/var/lmc"
VOLID="AvalancheOS-${RELEASEVER}"
KS="avalanche.ks"

# Resolve the project root regardless of where the script is called from.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Building Avalanche OS (Fedora ${RELEASEVER} base)"
echo "    Kickstart : ${KS}"
echo "    Output    : ${RESULTDIR}"
echo ""

# livemedia-creator must run as root
if [[ $EUID -ne 0 ]]; then
  echo "ERROR: run with sudo"
  exit 1
fi

# Regenerate the Plymouth bootsplash fragment from the current PNG frames +
# script, so the embedded (and round-trip-verified) assets are always fresh.
python3 "${SCRIPT_DIR}/scripts/gen-bootsplash-ks.py"
echo ""

# livemedia-creator requires the results dir to not exist — it creates it itself.
rm -rf "${RESULTDIR}"

# Flatten all %include directives into a single self-contained kickstart so
# anaconda never needs to resolve relative paths at runtime.
FLAT_KS="/tmp/avalanche-flat.ks"
rm -f "${FLAT_KS}"
ksflatten --config "${SCRIPT_DIR}/${KS}" --output "${FLAT_KS}"
echo "==> Flattened kickstart → ${FLAT_KS}"
echo ""

livemedia-creator \
  --ks "${FLAT_KS}" \
  --no-virt \
  --resultdir "${RESULTDIR}" \
  --project "Avalanche OS" \
  --make-iso \
  --volid "${VOLID}" \
  --iso-only \
  --releasever "${RELEASEVER}"

echo ""
echo "==> Done. ISO at: ${RESULTDIR}/"
ls -lh "${RESULTDIR}"/*.iso 2>/dev/null || echo "(no .iso found — check logs above)"
