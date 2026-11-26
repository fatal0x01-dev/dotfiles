#!/usr/bin/env bash
# Stage 01 — install dependencies.
# Curated, not metapackage-based: only what the theme pipeline actually needs.
set -euo pipefail
source "$(dirname "$0")/lib.sh"

# Build toolchain + runtime deps.
#   git/base-devel/cmake : clone & build the WhiteSur repos
#   kvantum / kvantum-qt5: SVG widget engine WhiteSur uses for its best look
#   appmenu-gtk-module   : lets GTK apps export their menu to the top global-menu
#   xsettingsd           : applies GTK theme changes live without a relog
PKGS=(
    git base-devel cmake
    kvantum kvantum-qt5
    appmenu-gtk-module
    xsettingsd
)

log "Installing pacman packages: ${PKGS[*]}"
# --needed  : skip already-installed packages (idempotent re-runs)
# --noconfirm: unattended
sudo pacman -S --needed --noconfirm "${PKGS[@]}" \
    || die "pacman failed. Fix the errors above (e.g. 'sudo pacman -Syu') and re-run."
ok "Core packages present."

# qt5ct/qt6ct help non-Plasma Qt apps follow Kvantum; install if available, ignore if not.
sudo pacman -S --needed --noconfirm qt5ct qt6ct 2>/dev/null && ok "qt5ct/qt6ct installed." \
    || warn "qt5ct/qt6ct not installed (optional)."

ok "Package stage complete."
