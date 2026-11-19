#!/usr/bin/env bash
# Recreate the KDE Plasma 6 setup for the current user. Everything goes into $HOME, no sudo.
# Needs: git curl python3 tar xz qdbus6 kwriteconfig6 kpackagetool6 plasma-apply-*
set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd)"
A="$REPO/assets"
DATA="${XDG_DATA_HOME:-$HOME/.local/share}"
CONF="${XDG_CONFIG_HOME:-$HOME/.config}"
BIN="$HOME/.local/bin"
WORK="$(mktemp -d)"
trap 'rm -r -- "$WORK"' EXIT

KITTY_VER=0.51.0
KITTY_SHA=c285daaf1b699997614939c8d1cd92dd8b99302ff12f18efcc3f69382aa72b1d
FISH_VER=4.9.3
FISH_SHA=8f643d10ad1abb0ef7072764c01ceb5cf61b2d373fda400cf60f0bad69b7e095
STARSHIP_VER=1.27.0
STARSHIP_SHA=10c8eb4cb3b761d9bf59ea828444c2dab36c900b7d69a69e08814b286969df89
YAZI_VER=26.9.1
YAZI_SHA=9b9c39decccf8cb0ff53a7d637d38f8a79d93bbd0099f4ea9c619ef6bb392f5d
NERD_VER=3.5.1
JETBRAINS_SHA=04d5e8f903693f9dd13e16f867e994834e681eb3c72c0d337a770dcda09010cf
WEATHER_VER=3.0.4
WEATHER_SHA=fb4a66c12f7942709e43976a430f0790495073fa09bf2913703a7e61dd93be71

say() { printf '\n== %s\n' "$*"; }

fetch() { # url sha256 dest
	curl -fsSL -o "$3" "$1"
	echo "$2  $3" | sha256sum -c --quiet -
}

clone() { # url commit dir
	git init -q "$3"
	git -C "$3" fetch -q --depth 1 "$1" "$2"
	git -C "$3" checkout -q FETCH_HEAD
}

backup() {
	say "Backing up current KDE config to ~/kde-backup-$(date +%F-%H%M).tar.gz"
	(cd "$HOME" && tar czf "$HOME/kde-backup-$(date +%F-%H%M).tar.gz" --ignore-failed-read \
		.config/plasma-org.kde.plasma.desktop-appletsrc .config/plasmashellrc .config/kdeglobals \
		.config/kwinrc .config/kcminputrc .config/kitty .config/fish .config/starship.toml \
		2>/dev/null) || true
}

themes() {
	say "Themes, decoration and sensor face"
	mkdir -p "$DATA/color-schemes" "$DATA/plasma/desktoptheme" "$DATA/aurorae/themes" "$DATA/ksysguard/sensorfaces"
	cp "$A/color-schemes/QogirBlack.colors" "$DATA/color-schemes/"
	cp -r "$A/desktoptheme/Qogir-black" "$DATA/plasma/desktoptheme/"
	cp -r "$A/aurorae/Qogir-black" "$DATA/aurorae/themes/"
	cp -r "$A/sensorfaces/org.local.textint" "$DATA/ksysguard/sensorfaces/"
}

icons() {
	say "Papirus icons with grey folders"
	clone https://github.com/PapirusDevelopmentTeam/papirus-icon-theme.git 33d971eb2d0c8454bac58246687de78e58f960c8 "$WORK/papirus"
	clone https://github.com/PapirusDevelopmentTeam/papirus-folders.git 0f838ee5679229e3a3e97e3b333c222c9e9615b4 "$WORK/pf"
	mkdir -p "$DATA/icons"
	cp -r "$WORK/papirus/Papirus" "$WORK/papirus/Papirus-Dark" "$DATA/icons/"
	bash "$WORK/pf/papirus-folders" -C grey --theme Papirus-Dark
}

fonts() {
	say "Fonts: IBM Plex Mono, JetBrains Mono Nerd Font"
	mkdir -p "$DATA/fonts/JetBrainsMonoNerd"
	cp -r "$A/fonts/IBMPlexMono" "$DATA/fonts/"
	fetch "https://github.com/ryanoasis/nerd-fonts/releases/download/v$NERD_VER/JetBrainsMono.tar.xz" "$JETBRAINS_SHA" "$WORK/jb.tar.xz"
	tar xJf "$WORK/jb.tar.xz" -C "$DATA/fonts/JetBrainsMonoNerd" --wildcards "JetBrainsMonoNerdFontMono-*.ttf"
	fc-cache -f "$DATA/fonts" >/dev/null
}

plasmoids() {
	say "Widgets and video wallpaper plugin"
	clone https://github.com/ccatterina/plasmusic-toolbar.git 0e78da10095e5a9089494cd874129ee5062a5a8d "$WORK/plasmusic"
	clone https://github.com/tilorenz/compact_pager.git 548d704aceb609eae4d327e92ae49f624291ac46 "$WORK/pager"
	clone https://github.com/luisbocanegra/plasma-smart-video-wallpaper-reborn.git 74f6fd5eb8f98aeacfe8bbf5ad3b3b1f1ba74021 "$WORK/svw"
	kpackagetool6 -t Plasma/Applet -u "$WORK/plasmusic/src" >/dev/null 2>&1 || kpackagetool6 -t Plasma/Applet -i "$WORK/plasmusic/src"
	kpackagetool6 -t Plasma/Applet -u "$WORK/pager/package" >/dev/null 2>&1 || kpackagetool6 -t Plasma/Applet -i "$WORK/pager/package"
	kpackagetool6 -t Plasma/Wallpaper -u "$WORK/svw/package" >/dev/null 2>&1 || kpackagetool6 -t Plasma/Wallpaper -i "$WORK/svw/package"
	# Weather Widget uses met.no, which covers small Swedish towns the stock widget lacks
	fetch "https://github.com/blackadderkate/weather-widget-2/releases/download/V$WEATHER_VER/weather-widget-$WEATHER_VER.plasmoid" "$WEATHER_SHA" "$WORK/weather.plasmoid"
	kpackagetool6 -t Plasma/Applet -u "$WORK/weather.plasmoid" >/dev/null 2>&1 || kpackagetool6 -t Plasma/Applet -i "$WORK/weather.plasmoid"
	mkdir -p "$DATA/wallpapers/manet"
	cp "$A/wallpaper/"*.mp4 "$A/wallpaper/"*.jpg "$DATA/wallpapers/manet/"
	mkdir -p "$BIN" "$DATA/applications"
	install -m 755 "$A/bin/wallpaper-toggle" "$BIN/"
	cat > "$DATA/applications/wallpaper-toggle.desktop" <<-EOF
		[Desktop Entry]
		Type=Application
		Name=Toggle Wallpaper Animation
		Comment=Switch between the animated wallpaper and a still image
		Icon=media-playback-pause
		Exec=$BIN/wallpaper-toggle
		Categories=Settings;DesktopSettings;
	EOF
}

terminal() {
	say "kitty, fish, starship, yazi"
	mkdir -p "$BIN" "$HOME/.local/kitty.app" "$DATA/applications" "$CONF/kitty" "$CONF/fish/conf.d" "$CONF/fish/functions" "$CONF/fish/completions"
	fetch "https://github.com/kovidgoyal/kitty/releases/download/v$KITTY_VER/kitty-$KITTY_VER-x86_64.txz" "$KITTY_SHA" "$WORK/kitty.txz"
	fetch "https://github.com/fish-shell/fish-shell/releases/download/$FISH_VER/fish-$FISH_VER-linux-x86_64.tar.xz" "$FISH_SHA" "$WORK/fish.tar.xz"
	fetch "https://github.com/starship/starship/releases/download/v$STARSHIP_VER/starship-x86_64-unknown-linux-musl.tar.gz" "$STARSHIP_SHA" "$WORK/starship.tar.gz"
	tar xJf "$WORK/kitty.txz" -C "$HOME/.local/kitty.app"
	tar xJf "$WORK/fish.tar.xz" -C "$BIN" fish
	tar xzf "$WORK/starship.tar.gz" -C "$BIN" starship
	fetch "https://github.com/sxyazi/yazi/releases/download/v$YAZI_VER/yazi-x86_64-unknown-linux-musl.zip" "$YAZI_SHA" "$WORK/yazi.zip"
	python3 -I -m zipfile -e "$WORK/yazi.zip" "$WORK/yazi"
	install -m 755 "$WORK/yazi/yazi-x86_64-unknown-linux-musl/yazi" "$WORK/yazi/yazi-x86_64-unknown-linux-musl/ya" "$BIN/"
	ln -sf "$HOME/.local/kitty.app/bin/kitty" "$HOME/.local/kitty.app/bin/kitten" "$BIN/"
	for f in kitty.desktop kitty-open.desktop; do
		sed "s|Icon=kitty|Icon=$HOME/.local/kitty.app/share/icons/hicolor/256x256/apps/kitty.png|; s|Exec=kitty|Exec=$HOME/.local/kitty.app/bin/kitty|" \
			"$HOME/.local/kitty.app/share/applications/$f" > "$DATA/applications/$f"
	done
	sed -i '/^\[Desktop Entry\]/a X-KDE-Shortcuts=Ctrl+Alt+T' "$DATA/applications/kitty.desktop"
	# kitty does not expand ~ in the shell option
	sed "s|@HOME@|$HOME|" "$A/kitty/kitty.conf" > "$CONF/kitty/kitty.conf"
	cp "$A/fish/config.fish" "$CONF/fish/"
	cp "$A/fish/functions/"*.fish "$CONF/fish/functions/"
	cp "$WORK/yazi/yazi-x86_64-unknown-linux-musl/completions/yazi.fish" "$CONF/fish/completions/"
	cp "$A/starship.toml" "$CONF/"
	clone https://github.com/jhillyerd/plugin-git.git 85d692987aabbb4018d1c38d528b7a154d6aae3f "$WORK/plugin-git"
	cp "$WORK/plugin-git/conf.d/"*.fish "$CONF/fish/conf.d/"
	cp "$WORK/plugin-git/functions/"*.fish "$CONF/fish/functions/"
}

settings() {
	say "Look and feel settings"
	plasma-apply-colorscheme QogirBlack
	plasma-apply-desktoptheme Qogir-black
	plasma-apply-cursortheme breeze_cursors || true
	"$(find /usr/lib* -path '*libexec/plasma-changeicons' -print -quit)" Papirus-Dark
	kwriteconfig6 --file kdeglobals --group KDE --key widgetStyle Breeze
	kwriteconfig6 --file kwinrc --group Plugins --key shakecursorEnabled false
	kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key library org.kde.kwin.aurorae
	kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key theme __aurorae__svg__Qogir-black
	local f="IBM Plex Mono"
	for k in font menuFont toolBarFont fixed; do
		kwriteconfig6 --file kdeglobals --group General --key "$k" "$f,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
	done
	kwriteconfig6 --file kdeglobals --group General --key smallestReadableFont "$f,8,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
	kwriteconfig6 --file kdeglobals --group WM --key activeFont "$f,10,-1,5,600,0,0,0,0,0,0,0,0,0,0,1"
	kwriteconfig6 --file kdeglobals --group General --key TerminalApplication "$HOME/.local/kitty.app/bin/kitty"
	kwriteconfig6 --file kdeglobals --group General --key TerminalService kitty.desktop
	# Ctrl+Alt+T comes from Konsole's desktop entry, so it has to be taken off Konsole first
	kwriteconfig6 --file kglobalshortcutsrc --group services --group org.kde.konsole.desktop --key _launch none
	kwriteconfig6 --file kglobalshortcutsrc --group services --group kitty.desktop --key _launch "Ctrl+Alt+T"
	local svw=luisbocanegra.smart.video.wallpaper.reborn
	kwriteconfig6 --file kscreenlockerrc --group Greeter --key WallpaperPlugin "$svw"
	kwriteconfig6 --file kscreenlockerrc --group Greeter --group Wallpaper --group "$svw" --group General --key FillMode 2
	kwriteconfig6 --file kscreenlockerrc --group Greeter --group Wallpaper --group "$svw" --group General --key VideoUrls \
		"[{\"filename\": \"file://$DATA/wallpapers/manet/manet_wallpaper.mp4\", \"enabled\": true, \"duration\": 0, \"customDuration\": 0, \"playbackRate\": 0.0, \"alternativePlaybackRate\": 0.0, \"loop\": true, \"dayNightCycleAssignment\": 0}]"
	local vdm=(org.kde.KWin /VirtualDesktopManager)
	while [ "$(qdbus6 "${vdm[@]}" org.freedesktop.DBus.Properties.Get org.kde.KWin.VirtualDesktopManager count)" -lt 3 ]; do
		n=$(qdbus6 "${vdm[@]}" org.freedesktop.DBus.Properties.Get org.kde.KWin.VirtualDesktopManager count)
		qdbus6 "${vdm[@]}" org.kde.KWin.VirtualDesktopManager.createDesktop "$n" "$((n + 1))"
	done
	qdbus6 org.kde.KWin /KWin reconfigure
}

# Highest numbered GPU that reports a temperature, the discrete card on a desktop with an iGPU.
gpu_sensor() {
	busctl --user call org.kde.ksystemstats1 /org/kde/ksystemstats1 org.kde.ksystemstats1 allSensors \
		| grep -oE '"gpu/gpu[0-9]+/temperature"' | tr -d '"' | sort -V | tail -1 | sed 's|/temperature||' \
		| grep . || echo gpu/all
}

layout() {
	say "Panels, dock, wallpaper and desktop widgets"
	local js="$WORK/layout.js" out
	sed "s|@HOME@|$HOME|; s|@GPU@|$(gpu_sensor)|" "$REPO/layout.js" > "$js"
	out="$(qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$(cat "$js")")"
	# Plasma ignores widget geometry set from scripts, so the column is written to the config offline.
	kquitapp6 plasmashell
	sleep 2
	grep '^GEOMETRY ' <<<"$out" | while read -r _ id res geo; do
		kwriteconfig6 --file plasma-org.kde.plasma.desktop-appletsrc --group Containments --group "$id" --key "ItemGeometries-$res" "$geo"
		kwriteconfig6 --file plasma-org.kde.plasma.desktop-appletsrc --group Containments --group "$id" --key ItemGeometriesHorizontal "$geo"
	done
	# translucent instead of adaptive, which turns opaque next to maximized windows
	for p in $(grep '^PANELS ' <<<"$out" | cut -d' ' -f2-); do
		kwriteconfig6 --file plasmashellrc --group PlasmaViews --group "Panel $p" --key panelOpacity 2
	done
	kstart plasmashell >/dev/null 2>&1 &
	disown
}

backup
themes
icons
fonts
plasmoids
terminal
settings
layout
say "Done. Log out and back in once so every app picks up fonts and icons."
