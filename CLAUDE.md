# Avalanche OS — Project Context

## What this is

A custom Fedora KDE Plasma respin (spin), built for fun with no fixed deadline
and no required deliverable. The point of the project is the build process
itself — learning kickstart files, Lorax/livemedia-creator, and KDE
customization — as much as the final ISO.

**"Avalanche OS"** is the project name.

## Theme & identity

Backcountry / splitboard touring aesthetic, inspired by Maxime's own hobbies:
splitboarding, powder snowboarding, and renting a cottage at **Massif du Sud**.

- **Mood:** alpine, early-morning, low-light backcountry — not bright
  resort/ski branding.
- **Palette:** deep blue, white, charcoal.
- **Boot splash idea:** visual nod to a skin track or a "transition" moment
  (skins peeling off a board).
- **Possible touches (not committed yet):** Plasma widget pulling
  snow/avalanche conditions for Massif du Sud, MOTD or terminal banner with
  snow-report flavor, custom GRUB/Plymouth theme.

Branding is a first-class part of this project, not an afterthought — treat
visual identity work (icons, splash, color scheme) with the same care as the
FEA Model Manager (FEA:MM) visual identity work.

## Technical approach

**Base:** Fedora KDE Plasma Spin, customized via a **kickstart file (.ks)**.

**Build tooling:** `livemedia-creator` / Lorax to turn the kickstart into a
bootable ISO.

**Package manager:** Stock `dnf`, pointed at normal Fedora repos. No custom
package manager — this was deliberately decided against (see "Decisions
already made" below).

**Build environment:** A VM (QEMU) is the intended build/test environment, to
allow safe iteration and easy snapshotting/reverting when builds break.

### Planned customization layers (in order)

1. **Strip down** — `%packages` exclusions to remove cruft that sneaks into
   KDE spins (e.g. stray GNOME apps), trim unused default services.
2. **Configure** — `%packages` inclusions for preferred apps/dev tools,
   `%post` scripts for dotfiles/configs/KDE settings, repo setup (e.g. RPM
   Fusion if codecs/extra software are wanted).
3. **Brand** — custom wallpaper, Plasma theme/color scheme, Plymouth boot
   splash, GRUB theme, `/etc/os-release` and `/etc/fedora-release` identity.

### Milestone 0 (do this first)

Before any customization: build a **bare, unmodified Fedora KDE kickstart**
successfully into a bootable ISO. This proves the toolchain works end-to-end
and gives a known-good baseline to diff against once things break later (they
will — that's normal and expected, not a sign something's wrong).

## Decisions already made (don't re-litigate without new info)

- **Not building from LFS/Buildroot/Yocto.** Seriously considered LFS for the
  "build everything by hand" learning experience, but ruled it out once it
  became clear the actual goals (KDE Plasma look, dnf workflow, Fedora
  ecosystem) would mean reconstructing things Fedora already does well.
  Respin was the better-fit project for the stated goals.
- **No custom/from-scratch package manager.** Considered and rejected for the
  same reason — dnf already does exactly what was wanted (dependency
  resolution, repos, simple install/remove).
- **Not Python-tooling-focused.** A Python-dev-focused spin angle (pyenv,
  Jupyter, Dolphin "create venv here" actions, etc.) was explored in detail
  but didn't click as the project's identity. Some of those QoL ideas (Dolphin
  service-menu actions, KRunner shortcuts) could still be borrowed later as
  generic "nice things to add," but they are not the theme.
- **Theme is backcountry/splitboard, not engineering-tool-focused.** An
  "engineer's daily driver" angle (FreeCAD/KiCad/FEA:MM-pinned) was considered
  and explicitly set aside in favor of the personal/hobby theme. FEA:MM may
  still get pinned/installed as a practical nicety, but it isn't the spin's
  identity.

## Working style / what good help looks like here

- This is a hobby project pursued for fun — prioritize the experience of
  building over the fastest path to a "finished" result. Don't optimize away
  the parts of the process that are themselves the point.
- It's fine and expected for builds to fail repeatedly during kickstart
  iteration. Treat that as normal debugging, not a red flag.
- Visual/branding polish matters as much as functional correctness — Maxime
  cares about coherent design systems (see prior FEA:MM SVG/icon/logo work).
- No fixed scope or deadline. It's fine to keep iterating indefinitely.

### Teach as you go (important)

Maxime is learning how to build a Linux distribution through this project — the
learning is a primary goal, not a side effect. So **explain the work like a
teacher explaining to a student**:

- Before (or while) running a command or editing a file, say *what* it does and
  *why* we're doing it this way — in plain language, not jargon dumps.
- When a new concept comes up (kickstart directive, `dracut`, Plymouth,
  initramfs, squashfs, `%post`, etc.), give a short, concrete explanation of
  what it is and how it fits the bigger picture before moving on.
- Mention alternatives we *didn't* take and why, when it aids understanding.
- When something breaks, walk through the diagnosis out loud — the debugging
  reasoning is itself a lesson.
- Favour understanding over speed. A working result the user doesn't understand
  is a worse outcome here than a slower one they do.

## Open questions / not yet decided

- Exact wallpaper/icon set and Plasma color scheme.
- Whether to build the Massif du Sud snow-report widget, and what data
  source it would use (Maxime has an existing snowboarding/powder website —
  worth checking if it already has usable data/feed).
- Whether RPM Fusion / extra codec repos get enabled by default.
- Specific app/dev-tool list for the "configure" layer.
