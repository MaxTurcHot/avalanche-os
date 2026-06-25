# Avalanche OS — Dev Plan / Idea Log

Running list of ideas not yet built. See `CLAUDE.md` for the project's fixed
context and decisions already made. Things here are candidates, not commitments.

---

## Idea: backcountry/snowboarding vocabulary layer

Rename or relabel parts of the system using splitboard / snowboarding terms, so
the language of the distro matches its identity. This is a *naming/wording*
layer — separate from the visual branding (wallpaper, colors, splash).

### Seed examples

| Stock concept        | Avalanche term  |
| -------------------- | --------------- |
| Home (folder)        | **Basecamp**    |
| Downloads (folder)   | **Drop Zone**   |
| Active / Running     | **Shredding**   |
| Error                | **Catch an edge** |

### Where this could surface (to investigate)

- **XDG user dirs** — `~/Downloads`, `~/Documents`, etc. are defined in
  `~/.config/user-dirs.dirs` (seeded from `/etc/xdg/user-dirs.defaults`). The
  *display* name shown in Dolphin can differ from the on-disk path, so we may be
  able to relabel without breaking apps that hardcode `$HOME/Downloads`. Needs
  checking: how Dolphin/Plasma localize these, and whether renaming the actual
  dir vs. just the label is safer.
- **"Home" label** — the Dolphin "Home" place and the Plasma Kickoff entry.
  Likely a `.directory` / Places-panel relabel rather than moving `$HOME`
  (moving the real home dir would break everything — almost certainly label-only).
- **Service/status wording ("Shredding" / "Catch an edge")** — trickier. systemd
  unit states and shell error messages are not meant to be user-reworded and
  doing so globally would be fragile. More realistic homes for this flavor:
  - a custom shell prompt / MOTD that says "Shredding" on success, "Caught an
    edge" on a non-zero exit code,
  - a KRunner or notification skin,
  - splash/boot text,
  rather than overriding real systemd or kernel strings.

### Open questions

- Label-only (safe, cosmetic) vs. real renames (riskier, can break apps)? Lean
  label-only wherever possible so `ID=fedora` software keeps working.
- Localization mechanism: is this a `.desktop`/`.directory` Name= override, a
  custom locale, or per-app config? Different surfaces likely need different
  tricks.
- Keep it tasteful — a few well-placed terms read as charming; renaming
  everything reads as a gimmick and hurts usability.

### Status

Idea only — not started. Fits the "configure"/"brand" layers, after the current
identity + branding pass is verified on a real boot.

---

## Standalone project: AvalancheDestroy KWin effect

Custom window close animation: tiles cascade downward with avalanche physics
(upper tiles carry more kinetic energy, front widens laterally, 600ms, 20px blocks).

### What was built

Source lives in `kwin/avalanchedestroy/` — a full C++ KWin effect derived from
Fall Apart (GPL-2.0-or-later). Physics are implemented and the code compiles
cleanly against kwin-devel 6.7.0 (`cmake + ninja` on the VM).

### The blocker

KWin 6 compiles all effects directly into the kwin binary via
`kwin_add_builtin_effect`. There is no runtime plugin path for compiled effects —
`/usr/lib64/qt6/plugins/kwin/effects/` only contains config UI plugins (.so),
not effect code. Shipping a custom compiled effect requires either:

- Rebuilding kwin itself with the effect patched in, or
- Maintaining a custom kwin RPM (fork + package + update forever)

### Next steps (when prioritized)

1. Fork the kwin SRPM, add `kwin/avalanchedestroy/` as a new builtin plugin,
   patch `src/plugins/CMakeLists.txt` to include it.
2. Build a custom `kwin` RPM on the VM.
3. Host it in a custom Copr repo or embed the RPM in the kickstart.
4. Wire `gen-effects-ks.py` to embed the RPM instead of a .so.

**In the meantime:** Fall Apart with 20px blocks is enabled as a reasonable
placeholder (same tile-fall concept, already built into kwin).
