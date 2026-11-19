# Agent guide: apply this setup

This file is for a Claude Code agent asked to set up this KDE Plasma desktop on a new machine. Human documentation is in `README.md`.

## Goal

Make the current user's desktop match this repo: QogirBlack theme, top bar, floating dock, desktop widgets, MANET video wallpaper, kitty with fish and starship, and yazi. Everything installs into `$HOME`. Only the optional steps at the end need sudo or a password.

## Before running anything

1. Confirm the session is KDE Plasma 6 on Wayland: `plasmashell --version` and `echo $XDG_SESSION_TYPE`.
2. Confirm the tools exist: `git curl python3 tar xz fc-cache qdbus6 kwriteconfig6 kpackagetool6 plasma-apply-colorscheme busctl`.
3. Confirm `qml6-module-qtmultimedia` is installed (`dpkg -l qml6-module-qtmultimedia` on Debian or Ubuntu). Without it the video wallpaper stays black. If it is missing, ask the user to install it with sudo.
4. Tell the user that `install.sh` removes all existing panels and desktop widgets and replaces them. It saves a backup first (`~/kde-backup-<date>.tar.gz`). Get a yes before running it.

## Run

```sh
./install.sh
```

The script runs these steps in order: `backup`, `themes`, `icons`, `fonts`, `plasmoids`, `terminal`, `settings`, `layout`. Each prints a `==` header. Downloads are checked against sha256 sums and git sources are pinned to commits. A checksum failure means the upstream file changed. Stop and report it. Do not update the sum without the user's approval.

## Verify

- Take a screenshot with `spectacle -b -n -f -o <file>` and look at it.
- The top bar should show the menu, pager `1 2 3`, the music title, centred `CPU`, temperature and `RAM` stats, the tray, the clock and a show-desktop button.
- The dock is auto-hidden at the bottom. The desktop shows calendar, weather and media player on the left, and four stat tiles on the right, unless windows cover them.
- Panels and widgets can be listed with `qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript '<js>'`, for example `panels().forEach(p => print(p.id + " " + p.widgets().map(w => w.type) + "\n"))`.
- Run `kitty` to check that the font is JetBrains Mono Nerd Font and that fish starts with the powerline prompt.

## Ask the user

- **Weather location.** The weather widget has no place after install. Ask for the town and set it in the widget settings, or write the `places` key the way `layout.js` writes the units. Do not commit a location to this repo.
- **Login shell.** Only kitty starts fish. To make fish the login shell, the user runs the two commands in `README.md`. Both need a password. First port PATH entries, exports and functions from `~/.zshrc` or `~/.profile` to `~/.config/fish/conf.d/local.fish`, since fish reads neither file. That file is machine-specific and stays out of the repo.
- **Login screen.** `install.sh` does not touch SDDM. Ask the user to run `sudo ./login-screen.sh`, which needs their password. It copies a background to `/usr/share/wallpapers`, writes `theme.conf.user` in the Breeze SDDM theme, sets the theme, font and cursor in `/etc/sddm.conf.d/kde_settings.conf`, and gives the sddm user the QogirBlack colours.
- **Optional yazi extras.** These need sudo: `sudo apt install ffmpegthumbnailer fd-find fzf zoxide`.

## Pitfalls already met

- **Plasma rewrites its config when it exits.** Widget order (`AppletOrder`) and desktop widget positions (`ItemGeometries-<W>x<H>`) do not stick when set from a running shell script. Stop Plasma with `kquitapp6 plasmashell`, write them with `kwriteconfig6`, then start it again with `kstart plasmashell`.
- **ItemGeometries lives in the containment group** `[Containments][<id>]`, not in its `[General]` subgroup.
- **Widgets have minimum sizes.** A smaller geometry is overridden and the widget moves. The media player needs at least 368 px height, and a stat tile with two legend rows needs 192.
- **Never delete a font file that running apps use.** Plasma keeps a stale glyph cache and its text renders scrambled, with each letter shifted by one. If it happens, run `fc-cache -r` and restart plasmashell.
- **kitty does not expand `~`** in its `shell` option. The installer writes the full path.
- **The GPU sensor id differs per machine.** `install.sh` picks the highest numbered `gpu/gpuN` with a temperature sensor. Check the GPU tile shows data. If not, list sensors with `busctl --user call org.kde.ksystemstats1 /org/kde/ksystemstats1 org.kde.ksystemstats1 allSensors`.
- **papirus-folders resolves home from the passwd entry**, not `$HOME`. Keep this in mind when testing with a fake home.

## Undo

Extract the backup over the home directory and log out and back in:

```sh
tar xzf ~/kde-backup-<date>.tar.gz -C ~
```

## Changing the repo

- Commit messages are short, imperative and formal, with no AI attribution lines.
- Keep personal data out: no names, locations, home paths or employer names in files or commit messages. Use `@HOME@` style placeholders that `install.sh` fills in.
