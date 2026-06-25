# avalanche-effects.ks — KWin window close animation
#
# Uses the built-in Fall Apart effect (tiles fall with gravity on window close).
# 20px block size gives a powder-snow texture vs the default 40px.
#
# Note: a custom AvalancheDestroy C++ effect exists in kwin/ but requires
# rebuilding kwin itself (KWin 6 compiles all effects into the binary).
# See DEVPLAN.md for the standalone project plan.

%post

mkdir -p /etc/xdg/kdedefaults

cat >> /etc/xdg/kdedefaults/kwinrc << 'TXTEOF'

[Plugins]
kwin4_effect_fallapartEnabled=true

[Effect-fallapart]
BlockSize=40
TXTEOF

echo "AVALANCHE: Fall Apart close animation enabled"

%end
