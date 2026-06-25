# avalanche-effects.ks — KWin window close animation
#
# Fall Apart effect attempts were unsuccessful (KWin 6 compiles all effects
# into its binary; plugin-path and config-layer approaches don't reliably
# enable it from a kickstart %post).
#
# A custom AvalancheDestroy C++ effect exists in kwin/ but requires rebuilding
# kwin itself. See DEVPLAN.md for the standalone project plan.
#
# This file is intentionally a no-op — effects left at KDE stock defaults.

%post
echo "AVALANCHE: effects — no custom KWin config applied (stock defaults)"
%end
