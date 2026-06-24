# avalanche-colorscheme.ks — Plasma color scheme (deep blue / white / charcoal)
#
# A Plasma "color scheme" is just an INI file (extension .colors) describing the
# colors for every UI role: window backgrounds, text, selection, buttons, the
# window-manager titlebar (the [WM] group), etc. Plasma ships them in
# /usr/share/color-schemes/ and lists them in System Settings > Colors.
#
# Making it the DEFAULT for every new user is a separate step: KDE reads
# system-wide defaults from /etc/xdg/kdeglobals. We install the scheme AND seed
# kdeglobals so a fresh live session already wears it — no clicking required.
#
# Palette (from the Avalanche identity): charcoal bases, white-ish text, an
# alpine deep-blue accent for selection/focus.

%post
SCHEME=/usr/share/color-schemes/AvalancheOS.colors
mkdir -p /usr/share/color-schemes

cat > "$SCHEME" << 'EOF'
[General]
Name=Avalanche OS
ColorScheme=AvalancheOS
shadeSortColumn=true

[ColorEffects:Disabled]
Color=56,62,71
ColorAmount=0
ColorEffect=0
ContrastAmount=0.65
ContrastEffect=1
IntensityAmount=0.1
IntensityEffect=2

[ColorEffects:Inactive]
ChangeSelectionColor=true
Color=27,33,40
ColorAmount=0.025
ColorEffect=2
ContrastAmount=0.1
ContrastEffect=2
Enable=false
IntensityAmount=0
IntensityEffect=0

[Colors:Button]
BackgroundAlternate=35,43,52
BackgroundNormal=42,51,61
DecorationFocus=61,110,158
DecorationHover=94,158,214
ForegroundActive=94,158,214
ForegroundInactive=147,161,172
ForegroundLink=108,179,255
ForegroundNegative=218,68,83
ForegroundNeutral=201,162,39
ForegroundNormal=234,240,244
ForegroundPositive=39,174,96
ForegroundVisited=155,114,196

[Colors:Header]
BackgroundAlternate=27,33,40
BackgroundNormal=35,43,52
DecorationFocus=61,110,158
DecorationHover=94,158,214
ForegroundActive=94,158,214
ForegroundInactive=147,161,172
ForegroundLink=108,179,255
ForegroundNegative=218,68,83
ForegroundNeutral=201,162,39
ForegroundNormal=234,240,244
ForegroundPositive=39,174,96
ForegroundVisited=155,114,196

[Colors:Selection]
BackgroundAlternate=49,90,130
BackgroundNormal=61,110,158
DecorationFocus=61,110,158
DecorationHover=94,158,214
ForegroundActive=234,240,244
ForegroundInactive=200,214,224
ForegroundLink=178,212,255
ForegroundNegative=255,140,150
ForegroundNeutral=232,201,110
ForegroundNormal=255,255,255
ForegroundPositive=140,220,170
ForegroundVisited=200,170,230

[Colors:Tooltip]
BackgroundAlternate=27,33,40
BackgroundNormal=35,43,52
DecorationFocus=61,110,158
DecorationHover=94,158,214
ForegroundActive=94,158,214
ForegroundInactive=147,161,172
ForegroundLink=108,179,255
ForegroundNegative=218,68,83
ForegroundNeutral=201,162,39
ForegroundNormal=234,240,244
ForegroundPositive=39,174,96
ForegroundVisited=155,114,196

[Colors:View]
BackgroundAlternate=27,33,40
BackgroundNormal=22,27,33
DecorationFocus=61,110,158
DecorationHover=94,158,214
ForegroundActive=94,158,214
ForegroundInactive=147,161,172
ForegroundLink=108,179,255
ForegroundNegative=218,68,83
ForegroundNeutral=201,162,39
ForegroundNormal=234,240,244
ForegroundPositive=39,174,96
ForegroundVisited=155,114,196

[Colors:Window]
BackgroundAlternate=35,43,52
BackgroundNormal=27,33,40
DecorationFocus=61,110,158
DecorationHover=94,158,214
ForegroundActive=94,158,214
ForegroundInactive=147,161,172
ForegroundLink=108,179,255
ForegroundNegative=218,68,83
ForegroundNeutral=201,162,39
ForegroundNormal=234,240,244
ForegroundPositive=39,174,96
ForegroundVisited=155,114,196

[WM]
activeBackground=35,43,52
activeBlend=94,158,214
activeForeground=234,240,244
inactiveBackground=27,33,40
inactiveBlend=147,161,172
inactiveForeground=147,161,172
EOF

# Seed the system-wide default. kdeglobals is read from /etc/xdg for every user
# who doesn't have their own ~/.config/kdeglobals yet (i.e. fresh live session).
# We copy the scheme and ensure [General] carries the ColorScheme key so Plasma
# selects it by name on first login.
awk '1; /^\[General\]$/ && !done {print "ColorScheme=AvalancheOS"; done=1}' \
    "$SCHEME" > /etc/xdg/kdeglobals

if grep -q '^ColorScheme=AvalancheOS' /etc/xdg/kdeglobals; then
    echo "AVALANCHE: color scheme installed + set default (AvalancheOS)"
else
    echo "AVALANCHE ERROR: kdeglobals did not get ColorScheme=AvalancheOS"
fi
%end
