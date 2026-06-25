# avalanche-console.ks — console / terminal identity + live snow report
#
#   /etc/issue  — pre-login TTY banner. Supports agetty escapes (\S, \r, \l).
#   /etc/motd   — post-login banner, printed by PAM after login.
#
#   /usr/local/bin/avalanche-snow  — live snow conditions fetcher.
#     Reads resort IDs from ~/.config/avalanche/resorts (user override) or
#     /etc/avalanche/resorts (system default). Fetches PI data from the
#     wheretosnow API; caches results 30 min so terminal opens stay fast.
#
#   /etc/skel/.bashrc.d/avalanche-snow.sh  — hook that calls the snow report
#     once per login session. Works for both login and non-login interactive
#     shells (Konsole default is non-login — /etc/profile.d/ alone is not enough).

%post
# ── /etc/issue ────────────────────────────────────────────────────────────────
cat > /etc/issue << 'EOF'

   Avalanche OS  —  \S
   backcountry / splitboard touring spin

   kernel \r  on  \m   (\l)

EOF

cat > /etc/issue.net << 'EOF'

   Avalanche OS — backcountry / splitboard touring spin

EOF

# ── /etc/motd ─────────────────────────────────────────────────────────────────
cat > /etc/motd << 'EOF'

  ▲  Avalanche OS
     Skin up. Transition. Drop in.

EOF

# ── Avalanche preferences: system default resort list ─────────────────────────
# /etc/avalanche/resorts is the system-wide resort list (one ID per line).
# Users override with ~/.config/avalanche/resorts — same format.
# IDs match the wheretosnow API (e.g. "massif-du-sud").
mkdir -p /etc/avalanche
cat > /etc/avalanche/resorts << 'EOF'
# Avalanche OS — default resort watch list
# One resort ID per line. IDs from https://turcserv.duckdns.org/wheretosnow/
# Users can override with ~/.config/avalanche/resorts
massif-du-sud
EOF

# ── Snow conditions script ─────────────────────────────────────────────────────
# Self-contained Python 3 script. Uses only stdlib (urllib, json, pathlib).
# Caches results 30 min; subsequent terminal opens are instant.
cat > /usr/local/bin/avalanche-snow << 'PYEOF'
#!/usr/bin/env python3
"""Avalanche OS — live snow conditions report.

Reads resort IDs from ~/.config/avalanche/resorts (user) or
/etc/avalanche/resorts (system default). Fetches PI data from the
wheretosnow API and prints a brief table. Results cached for 30 min.
"""
import json
import os
import time
import urllib.request
from pathlib import Path

API = "https://turcserv.duckdns.org/wheretosnow/api"
CACHE_TTL = 1800  # 30 minutes


def find_resorts_file():
    user_cfg = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config"))
    user_file = user_cfg / "avalanche" / "resorts"
    if user_file.exists():
        return user_file
    sys_file = Path("/etc/avalanche/resorts")
    if sys_file.exists():
        return sys_file
    return None


def read_resorts(path):
    return [
        line.strip()
        for line in path.read_text().splitlines()
        if line.strip() and not line.lstrip().startswith("#")
    ]


def fetch_json(url, timeout=3):
    try:
        with urllib.request.urlopen(url, timeout=timeout) as resp:
            return json.loads(resp.read())
    except Exception:
        return None


def get_cache_path():
    cache_home = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache"))
    return cache_home / "avalanche" / "snow-report.json"


def print_report(data, cached=False):
    tag = "  (cached)" if cached else ""
    print(f"\n  ▲  Snow conditions{tag}")
    print("  " + "─" * 54)
    for r in data:
        name    = (r.get("name") or r.get("id", "?"))[:28]
        pi      = r.get("pi", 0)
        s24     = r.get("snow24h")
        depth   = r.get("depth")
        s24_s   = f"{s24:.1f}cm"   if s24   is not None else "  —  "
        depth_s = f"{depth:.0f}cm" if depth is not None else "  —  "
        print(f"  {name:<28}  PI={pi:>3}   24h {s24_s:>7}   base {depth_s:>6}")
    print()


def main():
    rf = find_resorts_file()
    if not rf:
        return

    resorts = read_resorts(rf)
    if not resorts:
        return

    cp = get_cache_path()

    # Serve from cache if fresh
    if cp.exists():
        try:
            if time.time() - cp.stat().st_mtime < CACHE_TTL:
                cached_data = json.loads(cp.read_text())
                if cached_data:
                    print_report(cached_data, cached=True)
                    return
        except Exception:
            pass

    # Live fetch
    results = []
    for resort_id in resorts:
        d = fetch_json(f"{API}/resort-snow-detail?id={resort_id}")
        if not d:
            continue
        pi    = round(d.get("pi_state", {}).get("current_pi", 0))
        s24   = d.get("last_24h_cm")
        depth = d.get("snow_depth_cm")
        name  = d.get("name") or resort_id
        results.append({"id": resort_id, "name": name, "pi": pi,
                        "snow24h": s24, "depth": depth})

    if results:
        print_report(results)
        try:
            cp.parent.mkdir(parents=True, exist_ok=True)
            cp.write_text(json.dumps(results))
        except Exception:
            pass


if __name__ == "__main__":
    main()
PYEOF

chmod +x /usr/local/bin/avalanche-snow

# ── bashrc.d hook : show snow once per login session ──────────────────────────
# ~/.bashrc.d/ is sourced by the default Fedora .bashrc for every interactive
# shell. We use a stamp file in XDG_RUNTIME_DIR (per-session tmpfs on systemd)
# so the report shows once when you first open a terminal, not on every tab.
mkdir -p /etc/skel/.bashrc.d
cat > /etc/skel/.bashrc.d/avalanche-snow.sh << 'EOF'
# Avalanche OS — snow conditions on first terminal of each login session
if [[ $- == *i* ]] && command -v avalanche-snow &>/dev/null; then
    _SNOW_STAMP="${XDG_RUNTIME_DIR:-/tmp/user-$UID}/avalanche-snow-shown"
    _SNOW_LAST=$(stat -c %Y "$_SNOW_STAMP" 2>/dev/null || echo 0)
    if (( $(date +%s) - _SNOW_LAST > 1800 )); then
        avalanche-snow 2>/dev/null
        touch "$_SNOW_STAMP" 2>/dev/null
    fi
    unset _SNOW_STAMP _SNOW_LAST
fi
EOF

echo "AVALANCHE: console identity, snow report, and preferences system installed"
%end
