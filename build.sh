#!/usr/bin/env bash
set -euo pipefail

# Fedora release to build against. Match this to a current stable release.
RELEASEVER="${1:-44}"
RESULTDIR="/var/lmc"
VOLID="AvalancheOS-${RELEASEVER}"
KS="fedora-live-kde.ks"

echo "==> Building Avalanche OS (Fedora ${RELEASEVER} base)"
echo "    Kickstart : ${KS}"
echo "    Output    : ${RESULTDIR}"
echo ""

# livemedia-creator must run as root
if [[ $EUID -ne 0 ]]; then
  echo "ERROR: run with sudo"
  exit 1
fi

mkdir -p "${RESULTDIR}"

sudo livemedia-creator \
  --ks "${KS}" \
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
