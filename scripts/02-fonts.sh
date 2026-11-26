#!/usr/bin/env bash
# Stage 02 — fonts. macOS uses "SF Pro"; it is not freely redistributable,
# so we try AUR, and fall back to Inter (visually close, in the official repos).
set -euo pipefail
source "$(dirname "$0")/lib.sh"

AUR_HELPER="$(state_get AUR_HELPER)"
WANT_AUR="${WANT_AUR:-1}"

font_present() { fc-list | grep -qi "$1"; }

if font_present "SF Pro"; then
    ok "SF Pro already installed."
    state_set UI_FONT "SF Pro Text"
    state_set UI_FONT_DISPLAY "SF Pro Display"
    exit 0
fi

installed_sf=0
if [[ "$WANT_AUR" -eq 1 && -n "$AUR_HELPER" ]]; then
    log "Attempting SF Pro via AUR ($AUR_HELPER)…"
    # 'apple-fonts' is a community meta-package bundling the SF family.
    if "$AUR_HELPER" -S --needed --noconfirm apple-fonts 2>/dev/null && font_present "SF Pro"; then
        installed_sf=1
    else
        warn "AUR SF Pro install did not succeed; falling back to Inter."
    fi
fi

if [[ $installed_sf -eq 1 ]]; then
    ok "SF Pro installed."
    state_set UI_FONT "SF Pro Text"
    state_set UI_FONT_DISPLAY "SF Pro Display"
else
    # Inter is an excellent, freely-licensed stand-in for SF Pro.
    sudo pacman -S --needed --noconfirm inter-font 2>/dev/null \
        && ok "Installed Inter as the SF Pro fallback." \
        || warn "Could not install Inter; the theme will use Plasma's default font."
    if font_present "Inter"; then
        state_set UI_FONT "Inter"
        state_set UI_FONT_DISPLAY "Inter"
    fi
fi
ok "Font stage complete."
