# macOS-on-KDE — Arch Linux dotfiles

Turns a stock **Arch Linux + KDE Plasma 6** install into a macOS-style desktop in one run:

- **WhiteSur** global theme (Big Sur look) — Plasma theme, colours, Kvantum widgets, Aurorae window decorations
- **Top menu bar**: Apple launcher · global application menu · system tray · clock
- **Floating bottom dock**: icons-only task manager, content-width and centred (the macOS dock)
- **Left-aligned traffic-light window buttons** (close/minimise/maximise on the left) for both KWin and GTK apps
- **WhiteSur icons + cursors + GTK/libadwaita theme + wallpaper**
- **SDDM** login screen themed to match
- **SF Pro** font if available on the AUR, otherwise **Inter** as a close free fallback

Everything is driven by one script and is safe to re-run.

## Requirements

- Arch Linux (or an Arch derivative using `pacman`)
- KDE Plasma 6 already installed and running (`plasma-desktop`, `plasma-workspace`)
- Internet access (clones the WhiteSur repos, installs packages)
- A normal user account with `sudo` (do **not** run as root)
- Optional: an AUR helper (`paru`/`yay`) for SF Pro fonts and Plank

## Usage

```bash
cd dotfiles
chmod +x install.sh scripts/*.sh
./install.sh --conky
```

Then **log out and back in** (or reboot) so SDDM, the global menu and GTK apps pick everything up cleanly.

### Options

| Flag        | Effect                                                            |
|-------------|-------------------------------------------------------------------|
| `--dark`    | Use the dark WhiteSur variant                                     |
| `--light`   | Use the light variant (default)                                   |
| `--no-aur`  | Skip AUR packages (SF Pro, Plank); use Inter + native dock        |
| `--plank`   | Also install Plank (a magnifying dock) — **X11 sessions only**    |

## What it does, stage by stage

| Stage | Script               | Action |
|-------|----------------------|--------|
| 00 | `00-preflight.sh`  | Detect session (X11/Wayland), Plasma version, AUR helper; keep sudo alive |
| 01 | `01-packages.sh`   | `pacman` deps: kvantum, appmenu-gtk-module, build tools |
| 02 | `02-fonts.sh`      | SF Pro via AUR, else Inter |
| 03 | `03-themes.sh`     | Clone + build WhiteSur (kde/icon/cursor/gtk/wallpaper) from source |
| 04 | `04-apply-theme.sh`| Apply look-and-feel, Kvantum, window buttons, fonts, GTK, SDDM |
| 05 | `05-panels.sh`     | Build top bar + floating dock + wallpaper via Plasma scripting |
| 06 | `06-plank.sh`      | *(optional)* Plank dock on X11 |

## Dock: native vs Plank

Plasma 6 defaults to **Wayland**, where **Plank does not run**. The default here is a
**native floating Plasma panel** with an icons-only task manager — it gives the centred,
content-width macOS dock and works on both Wayland and X11.

If you are on **X11** and want the macOS magnification effect, run with `--plank`, then
remove the native bottom dock (right-click the dock → *Remove Panel*) so you don't have two.

## Reverting

Before changing anything, stage 04 copies your existing KDE config to:

```
~/.config/.macos-kde-backup-YYYYMMDD-HHMMSS/
```

To roll back the theme/config and panels:

```bash
cp -rf ~/.config/.macos-kde-backup-*/. ~/.config/
# reset panels to Plasma defaults:
rm -f ~/.config/plasma-org.kde.plasma.desktop-appletsrc
# then restart Plasma (log out/in), and in System Settings pick the Breeze global theme
```

SDDM: remove `/etc/sddm.conf.d/10-macos-kde-theme.conf`.

## Notes / caveats

- The **global application menu** only shows menus for apps that export them. GTK apps need
  `appmenu-gtk-module` (installed by stage 01) and a relog; a few Qt/Electron apps never export a menu.
- WhiteSur upstream (vinceliuice) is what everything is built from; if an `install.sh` flag ever
  changes upstream, stages 03/04 fall back to the plain `./install.sh` and set components directly.
- Tested against Plasma 6. On Plasma 5 the theme installs but the panel-scripting property names
  (`floating`, `lengthMode`) are ignored gracefully.

## Credits

Theme set: [vinceliuice/WhiteSur](https://github.com/vinceliuice) (GPL-3.0). This repo only
automates fetching, building and applying it.
