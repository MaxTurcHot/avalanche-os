# avalanche-apps.ks — Starship prompt, RPM Fusion, apps, and codecs

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

# ── RPM Fusion (free + non-free) ──────────────────────────────────────────────
dnf install -y \
  https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
  https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

# ── Multimedia codecs ─────────────────────────────────────────────────────────
dnf install -y \
  ffmpeg \
  gstreamer1-plugins-ugly \
  gstreamer1-plugins-bad-freeworld \
  gstreamer1-plugins-bad-free \
  gstreamer1-plugin-libav \
  libdvdcss

# ── Steam (RPM Fusion non-free) ───────────────────────────────────────────────
dnf install -y steam

# ── Visual Studio Code (Microsoft repo) ──────────────────────────────────────
rpm --import https://packages.microsoft.com/keys/microsoft.asc
cat << 'EOF' > /etc/yum.repos.d/vscode.repo
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF
dnf install -y code

# ── DBeaver Community (official repo) ─────────────────────────────────────────
cat << 'EOF' > /etc/yum.repos.d/dbeaver.repo
[dbeaver]
name=DBeaver Community
baseurl=https://dbeaver.io/files/rpm/stable/x86_64
enabled=1
gpgcheck=0
EOF
dnf install -y dbeaver-ce

%end
