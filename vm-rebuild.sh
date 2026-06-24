#!/usr/bin/env bash
# vm-rebuild.sh — VM build-box helper for the laptop+VM workflow.
#
# Workflow:
#   1. Edit + commit + push from the LAPTOP (with AI).
#   2. On the VM, run the one-liner:
#          cd ~/avalanche-os && git pull && ./vm-rebuild.sh
#      (git pull is in the one-liner, not here, so the *latest* version of this
#      script is the one that runs.)
#
# This script: builds the ISO (via sudo build.sh, ~40 min) then serves /var/lmc
# over HTTP so the laptop can wget the result. The build stays --no-virt because
# this is a disposable VM — the rootful installer never touches the laptop.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

PORT="${PORT:-8080}"
RESULTDIR="/var/lmc"

echo "==> HEAD is $(git rev-parse --short HEAD): $(git log -1 --pretty=%s)"

# Clear stale state left by previous failed builds.
sudo rm -f /run/anaconda.pid /run/user/0/anaconda.pid /run/user/"$(id -u)"/anaconda.pid
sudo rm -rf /var/tmp/dnf.package.cache

echo "==> Building AvalancheDestroy KWin effect…"
sudo dnf install -y cmake ninja-build kwin-devel extra-cmake-modules \
    qt6-qtbase-devel kf6-kconfigwidgets-devel kf6-kconfig-devel 2>&1 | tail -3
EFFECT_DIR="$SCRIPT_DIR/kwin/avalanchedestroy"
BUILD_DIR="$EFFECT_DIR/build"
rm -rf "$BUILD_DIR" && mkdir -p "$BUILD_DIR"
(cd "$BUILD_DIR" && cmake .. -GNinja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr 2>&1 | tail -5 && ninja 2>&1)
python3 "$SCRIPT_DIR/scripts/gen-effects-ks.py"
echo "==> AvalancheDestroy built and embedded into avalanche-effects.ks"

echo "==> Building Avalanche OS (this takes ~40 min)…"
sudo ./build.sh

ISO="$(ls -1 "${RESULTDIR}"/*.iso 2>/dev/null | head -1 || true)"
if [ -z "${ISO}" ]; then
  echo "ERROR: no ISO produced — check the build output above." >&2
  exit 1
fi

# Ensure the download port is reachable (no-op if already allowed).
sudo firewall-cmd --add-port="${PORT}/tcp" >/dev/null 2>&1 || true

IP="$(ip -4 -o addr show scope global | awk '{print $4}' | cut -d/ -f1 | head -1)"
echo ""
echo "==> Build done: ${ISO} ($(du -h "${ISO}" | cut -f1))"
echo "==> Serving ${RESULTDIR} on :${PORT}. On the laptop, run:"
echo ""
echo "        wget -c http://${IP}:${PORT}/$(basename "${ISO}")"
echo ""
echo "    Ctrl+C here to stop the server once the download finishes."
echo ""
exec python3 -m http.server "${PORT}" --bind 0.0.0.0 --directory "${RESULTDIR}"
