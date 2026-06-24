# avalanche-apps.ks — Starship prompt, Flathub, and firstboot Flatpak installer
# RPM packages for this layer live in fedora-kde-common.ks

%packages
%end

%post
# ── Starship bash prompt ───────────────────────────────────────────────────────
curl -sS https://starship.rs/install.sh | sh -s -- --yes

cat << 'EOF' > /etc/profile.d/starship.sh
eval "$(starship init bash)"
EOF

mkdir -p /etc/skel/.config
cat << 'EOF' > /etc/skel/.config/starship.toml
# Avalanche OS — minimalist alpine prompt
format = """
$directory\
$git_branch\
$git_status\
$character\
"""

add_newline = false

[directory]
style = "bold white"
format = "[$path]($style) "
truncation_length = 3
truncation_symbol = "…/"

[git_branch]
symbol = "❄ "
style = "bold #38bdf8"
format = "on [$symbol$branch]($style) "

[git_status]
style = "bold #ef4444"
format = "([$all_status$ahead_behind]($style) )"

[character]
success_symbol = "[❯](bold #2563eb)"
error_symbol = "[caught edge ❯](bold #ef4444)"
EOF

# ── Flathub remote ────────────────────────────────────────────────────────────
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# ── Firstboot Flatpak installer ───────────────────────────────────────────────
cat << 'EOF' > /usr/local/bin/avalanche-flatpak-setup.sh
#!/bin/bash
flatpak install -y flathub \
  com.valvesoftware.Steam \
  com.visualstudio.code \
  io.dbeaver.DBeaverCommunity \
  com.bambulab.BambuStudio

rm -f /etc/avalanche-flatpak-setup.pending
systemctl disable avalanche-flatpak-setup.service
EOF
chmod +x /usr/local/bin/avalanche-flatpak-setup.sh

cat << 'EOF' > /etc/systemd/system/avalanche-flatpak-setup.service
[Unit]
Description=Avalanche OS — install Flatpak apps on first boot
After=network-online.target
Wants=network-online.target
ConditionPathExists=/etc/avalanche-flatpak-setup.pending

[Service]
Type=oneshot
ExecStart=/usr/local/bin/avalanche-flatpak-setup.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

touch /etc/avalanche-flatpak-setup.pending
systemctl enable avalanche-flatpak-setup.service
%end
