# kde-setup

Recreates this KDE Plasma 6 desktop for one user on another machine. Everything installs into `$HOME` and nothing needs sudo.

## Requirements

- KDE Plasma 6 on Wayland. Tested on Kubuntu 26.04 with Plasma 6.6 and Qt 6.10.
- `git`, `curl`, `python3`, `tar` with xz support, and `qml6-module-qtmultimedia` for the video wallpaper.
- An x86_64 CPU. The kitty, fish and starship binaries are x86_64 builds.

## Install

```sh
git clone <this repo> ~/kde-setup
~/kde-setup/install.sh
```

Then log out and back in once.

The login screen is system wide, so it needs root and a separate script:

```sh
sudo ~/kde-setup/login-screen.sh
```

The script first saves the current Plasma, KWin, kitty and fish config to `~/kde-backup-<date>.tar.gz`. To undo, extract that archive over `~` and log in again.

## What it sets up

| Part | Choice |
| --- | --- |
| Colours | QogirBlack: QogirManjaroDark with the blue greys made neutral black and the teal accent made dark grey |
| Plasma style | Qogir-black, derived the same way from Qogir-manjaro-dark, panels 88% opaque and always translucent |
| Window decoration | Qogir-black (Aurorae) |
| Application style | Breeze |
| Icons | Papirus-Dark, grey folders |
| Fonts | IBM Plex Mono everywhere, JetBrains Mono Nerd Font in kitty |
| Top bar | Kicker menu, Compact Pager (3 desktops), PlasMusic Toolbar, centred CPU, temperature and RAM stats, tray, keyboard layout, clock, show desktop |
| Dock | Floating, centred, icons only, auto-hide |
| Desktop | Calendar, weather and media player on the left of the primary screen, CPU, GPU, RAM and network tiles on the right |
| Wallpaper | Animated MANET loop, 60 fps. Landscape and portrait versions are picked per screen. |
| Lock screen | The same animated landscape loop |
| Login screen | Breeze SDDM theme with a still of the wallpaper, IBM Plex Mono and QogirBlack colours, set by `login-screen.sh` |
| Terminal | kitty with fish and a grey agnoster-style starship prompt. The fish git plugin gives the oh-my-zsh git aliases. |
| File manager (terminal) | yazi with image previews in kitty. `y` opens it and leaves the shell in the last directory. |

kitty is the default terminal, including Ctrl+Alt+T and Dolphin's Open Terminal. The installer does not change the login shell. To make fish the login shell, run:

```sh
echo ~/.local/bin/fish | sudo tee -a /etc/shells
chsh -s ~/.local/bin/fish
```

Port anything machine-specific from `~/.zshrc` or `~/.profile` (PATH entries, exports, functions) to `~/.config/fish/conf.d/local.fish` first, since fish reads neither file.

## Machine-specific values

`install.sh` fills these into `layout.js`:

- **GPU sensor:** the highest numbered `gpu/gpuN` that reports a temperature. With an iGPU and a discrete card this is the discrete card.
- **Desktop widgets:** placed against the left and right edges of screen 0. The portrait wallpaper goes on any screen taller than it is wide.
- **Weather:** Weather Widget 3.0.4 with met.no data. It has no place after install. Open its settings and search for your town.

## Repository

- `CLAUDE.md`: guide for a Claude Code agent that applies this setup, including the checks and pitfalls.
- `install.sh`: the installer. Downloads are pinned to versions and checked against sha256 sums, and git sources are pinned to commits.
- `login-screen.sh`: sets the SDDM login screen. Needs sudo.
- `layout.js`: Plasma shell script for the panels, widgets and wallpaper.
- `assets/`: the modified themes, the whole-number "Text Only" sensor face (`org.local.textint`), IBM Plex Mono, configs and the wallpaper videos.

The scripts are MIT licensed, see `LICENSE`. The assets keep their upstream licenses. The Qogir-derived themes are GPL-3.0 like Qogir-kde, the sensor face is LGPL-2.0-or-later like the KDE face it is based on, and IBM Plex Mono is under the SIL Open Font License.
