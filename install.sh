#!/usr/bin/env bash
#
# macOS-on-KDE for Arch Linux — single-shot installer
# =====================================================
# Transforms a stock Arch Linux + KDE Plasma 6 desktop into a macOS-style
# environment: WhiteSur global theme, Kvantum widgets, macOS window buttons
# (left-aligned), a top menu-bar panel and a floating bottom dock.
#
#   Usage:   ./install.sh            # full install + apply
#            ./install.sh --no-aur   # skip AUR packages (fonts, plank)
#            ./install.sh --dark     # use the dark WhiteSur variant
#            ./install.sh --plank    # also install Plank (X11 sessions only)
#            ./install.sh --conky    # also install the macOS Conky widget
#
# Run ONCE as your normal user (NOT root). It will call sudo only for pacman.
# Every file it touches in ~/.config is backed up first (see 99-apply.sh).
#
set -euo pipefail

# ---------------------------------------------------------------------------
# Resolve paths and load the shared helper library
# ---------------------------------------------------------------------------
export DOTFILES_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export SCRIPTS="$DOTFILES_ROOT/scripts"
# shellcheck source=scripts/lib.sh
source "$SCRIPTS/lib.sh"

# ---------------------------------------------------------------------------
# Option parsing
# ---------------------------------------------------------------------------
export WS_VARIANT="light"     # light | dark
export WANT_AUR=1             # install AUR packages (fonts etc.)
export WANT_PLANK=0           # install Plank dock (X11 only)
export WANT_CONKY=0           # install the macOS-style Conky desktop widget

for arg in "$@"; do
    case "$arg" in
        --dark)    WS_VARIANT="dark" ;;
        --light)   WS_VARIANT="light" ;;
        --no-aur)  WANT_AUR=0 ;;
        --plank)   WANT_PLANK=1 ;;
        --conky)   WANT_CONKY=1 ;;
        -h|--help) sed -n '2,24p' "$0"; exit 0 ;;
        *) die "Unknown option: $arg" ;;
    esac
done

# ---------------------------------------------------------------------------
# Guard rails
# ---------------------------------------------------------------------------
[[ $EUID -eq 0 ]] && die "Do not run as root. Run as your normal user; sudo is invoked only where needed."
have_cmd pacman   || die "This installer targets Arch Linux (pacman not found)."
have_cmd plasmashell || warn "plasmashell not found — install plasma-desktop first, then re-run."

banner "macOS-on-KDE installer   (variant: $WS_VARIANT)"

# ---------------------------------------------------------------------------
# Pipeline — each stage is idempotent and safe to re-run
# ---------------------------------------------------------------------------
run_stage "$SCRIPTS/00-preflight.sh"       # detect session, Plasma version, AUR helper
run_stage "$SCRIPTS/00b-bootstrap.sh"      # ensure Plasma session + SDDM login manager
run_stage "$SCRIPTS/01-packages.sh"        # pacman + AUR dependencies
run_stage "$SCRIPTS/02-fonts.sh"           # SF Pro / Inter fallback
run_stage "$SCRIPTS/03-themes.sh"          # clone + build WhiteSur (gtk/icon/cursor/kde/wallpaper)
run_stage "$SCRIPTS/04-apply-theme.sh"     # look-and-feel, kvantum, window buttons, gtk, wallpaper
run_stage "$SCRIPTS/05-panels.sh"          # top menu bar + floating dock via plasma scripting
[[ $WANT_PLANK -eq 1 ]] && run_stage "$SCRIPTS/06-plank.sh"   # optional Plank dock
[[ $WANT_CONKY -eq 1 ]] && run_stage "$SCRIPTS/07-conky.sh"  # optional Conky widget

banner "Done."
cat <<EOF

  macOS theme applied. Recommended next step:

      log out and back in   (or reboot)

  so SDDM, the global menu and every GTK app pick up the new theme cleanly.

  A backup of your previous KDE config is in:
      $BACKUP_DIR

  To roll back:  cp -rf "$BACKUP_DIR"/. ~/.config/  && rm -rf ~/.config/plasma-org.kde.plasma.desktop-appletsrc && restart the session.
EOF
