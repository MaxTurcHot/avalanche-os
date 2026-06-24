# avalanche-grub.ks — bootloader identity
#
# GRUB_DISTRIBUTOR is the string GRUB uses to label menu entries, e.g.
# "Avalanche OS (6.x.x ...)" instead of "Fedora Linux (...)". It lives in
# /etc/default/grub, which is the *input* to grub config generation.
#
# IMPORTANT nuance worth understanding for a LIVE spin:
#   - The boot menu of the *live ISO itself* is built by lorax/livemedia-creator
#     from its own templates, NOT from this file — so this won't rebrand the
#     "boot the live image" menu you first see.
#   - This DOES rebrand the GRUB menu of an *installed* system after someone
#     runs the Anaconda installer from the live session, because Anaconda
#     regenerates grub.cfg using /etc/default/grub.
# So this is the correct, conventional place to set it; just don't expect the
# live ISO's own menu to change from it.

%post
GRUBDEF=/etc/default/grub

if [ -f "$GRUBDEF" ]; then
    # Replace an existing GRUB_DISTRIBUTOR line if present, else append one.
    if grep -q '^GRUB_DISTRIBUTOR=' "$GRUBDEF"; then
        sed -i 's/^GRUB_DISTRIBUTOR=.*/GRUB_DISTRIBUTOR="Avalanche OS"/' "$GRUBDEF"
    else
        echo 'GRUB_DISTRIBUTOR="Avalanche OS"' >> "$GRUBDEF"
    fi
else
    # No file yet (can happen on some images) — create a minimal one.
    echo 'GRUB_DISTRIBUTOR="Avalanche OS"' > "$GRUBDEF"
fi

echo "AVALANCHE: GRUB_DISTRIBUTOR ->"
grep '^GRUB_DISTRIBUTOR=' "$GRUBDEF"
%end
