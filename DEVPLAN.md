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
