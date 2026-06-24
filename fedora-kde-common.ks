
%packages
# install env-group to resolve RhBug:1891500
@^kde-desktop-environment

@firefox
@kde-apps
@kde-media

# ── Avalanche: dropped groups ─────────────────────────────────────────────────
-@kde-pim
-@libreoffice

# ── Rescued from @kde-pim ─────────────────────────────────────────────────────
kleopatra

# ── Replaces LibreOffice ──────────────────────────────────────────────────────
kate

# ── @kde-apps exclusions ──────────────────────────────────────────────────────
-keditbookmarks
-kmahjongg
-kmines
-kmouth
-kpat
-neochat
-qrca
-skanpage

# ── @kde-media exclusions ─────────────────────────────────────────────────────
-digikam
-dragon
-elisa-player
-k3b
-kamera
-kamoso
-kolourpaint

# ── Avalanche: added apps ─────────────────────────────────────────────────────
btop
mariadb
mariadb-server
nextcloud-client
flatpak

fedora-release-kde

# drop tracker stuff pulled in by gtk3 (pagureio:fedora-kde/SIG#124)
-tracker-miners
-tracker

# Not needed on desktops. See: https://pagure.io/fedora-kde/SIG/issue/566
-mariadb-server-utils

# proj-data-* are optional country-specific geodata weak deps pulled in by
# Marble/PROJ. They total ~1 GB and are not needed for a desktop spin.
-proj-data-ar
-proj-data-at
-proj-data-au
-proj-data-be
-proj-data-br
-proj-data-ca
-proj-data-ch
-proj-data-cz
-proj-data-de
-proj-data-dk
-proj-data-es
-proj-data-eur
-proj-data-fi
-proj-data-fo
-proj-data-fr
-proj-data-hu
-proj-data-is
-proj-data-jp
-proj-data-lv
-proj-data-mx
-proj-data-nc
-proj-data-nl
-proj-data-no
-proj-data-nz
-proj-data-pl
-proj-data-pt
-proj-data-se
-proj-data-sk
-proj-data-uk
-proj-data-us
-proj-data-za

### The KDE-Desktop

# fedora-specific packages
plasma-welcome-fedora

### fixes

# minimal localization support - allows installing the kde-l10n-* packages
kde-l10n

# Additional packages that are not default in kde-* groups, but useful
fuse
mediawriter

# Required for the Avalanche Plymouth theme (uses the script module)
plymouth-plugin-script

%end
