#!/usr/bin/env bash
# Give the SDDM login screen the same look: Breeze theme, night wallpaper still, IBM Plex Mono
# and QogirBlack colours. Run with sudo. SDDM runs before login, so it can only use files
# installed system wide.
set -euo pipefail

[ "$(id -u)" -eq 0 ] || { echo "run with sudo: sudo $0" >&2; exit 1; }

REPO="$(cd "$(dirname "$0")" && pwd)"
BG=/usr/share/wallpapers/kde-setup-login.jpg
THEME=/usr/share/sddm/themes/breeze
CONF=/etc/sddm.conf.d/kde_settings.conf
SDDM_HOME="$(getent passwd sddm | cut -d: -f6)"

fc-list : family | grep -qx "IBM Plex Mono" || echo "IBM Plex Mono is not installed system wide; the login screen will fall back (apt install fonts-ibm-plex)" >&2

install -m 644 "$REPO/assets/login/background.jpg" "$BG"

cat > "$THEME/theme.conf.user" <<EOF
[General]
type=image
background=$BG
showClock=true
fontSize=10
EOF

kwriteconfig6 --file "$CONF" --group Theme --key Current breeze
kwriteconfig6 --file "$CONF" --group Theme --key Font "IBM Plex Mono,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
kwriteconfig6 --file "$CONF" --group Theme --key CursorTheme breeze_cursors

# The greeter reads its colours from the sddm user's kdeglobals. A colour scheme file has the
# same format, so it can be used as is.
install -d -o sddm -g sddm -m 755 "$SDDM_HOME/.config"
install -o sddm -g sddm -m 644 "$REPO/assets/color-schemes/QogirBlack.colors" "$SDDM_HOME/.config/kdeglobals"

echo "Login screen updated. It shows from the next logout."
