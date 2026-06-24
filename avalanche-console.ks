# avalanche-console.ks — console / terminal identity
#
# Two distinct things get branded here:
#
#   /etc/issue  — the banner agetty prints on a TEXT virtual console (TTY)
#                 BEFORE you log in. You only see this on a tty (Ctrl+Alt+F3),
#                 not on the graphical SDDM login. Supports backslash escapes
#                 that agetty expands at display time (\S = OS name from
#                 os-release, \r = kernel release, \l = tty line, \t = time).
#
#   /etc/motd   — "message of the day", printed by PAM AFTER a successful
#                 login shell starts. Seen when you open a Konsole that runs a
#                 login shell, or when you SSH in. Plain text, no escapes.
#
# Both are tiny, text-only, and can't break the boot — lowest-risk branding.

%post
# ── /etc/issue : pre-login TTY banner ─────────────────────────────────────────
# \S pulls PRETTY_NAME straight from the os-release we rebranded in Layer 1,
# so this automatically says "Avalanche OS ..." without hardcoding it here.
cat > /etc/issue << 'EOF'

   Avalanche OS  —  \S
   backcountry / splitboard touring spin

   kernel \r  on  \m   (\l)

EOF

# issue.net is the same idea but for network logins (telnet/ssh banners that
# honour it). Keep it text-only — escape codes aren't expanded over the net.
cat > /etc/issue.net << 'EOF'

   Avalanche OS — backcountry / splitboard touring spin

EOF

# ── /etc/motd : post-login banner ─────────────────────────────────────────────
cat > /etc/motd << 'EOF'

  ▲  Avalanche OS
     Skin up. Transition. Drop in.

     This is a Fedora KDE respin built for fun. Stock dnf, normal Fedora
     repos — everything you know about Fedora still applies underneath.

EOF

echo "AVALANCHE: console identity set (issue / issue.net / motd)"
%end
