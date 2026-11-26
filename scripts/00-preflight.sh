#!/usr/bin/env bash
# Stage 00 — detect the environment and record it for later stages.
set -euo pipefail
source "$(dirname "$0")/lib.sh"

mkdir -p "$BUILD_DIR"
: > "$STATE_FILE"

# --- Session type: wayland vs x11 (affects Plank availability) -------------
session="${XDG_SESSION_TYPE:-unknown}"
state_set SESSION "$session"
ok "Session type: $session"

# --- Plasma major version --------------------------------------------------
pver="unknown"
if have_cmd plasmashell; then
    pver="$(plasmashell --version 2>/dev/null | grep -oE '[0-9]+' | head -1 || true)"
fi
state_set PLASMA "$pver"
ok "Plasma major version: ${pver:-unknown}"
[[ "$pver" == "5" ]] && warn "Plasma 5 detected — WhiteSur still works but these scripts are tuned for Plasma 6."

# --- AUR helper (yay/paru) for optional fonts & plank ----------------------
aur=""
for h in paru yay; do have_cmd "$h" && { aur="$h"; break; }; done
state_set AUR_HELPER "$aur"
if [[ -n "$aur" ]]; then ok "AUR helper: $aur"; else warn "No AUR helper found — SF Pro fonts / Plank will be skipped unless one is installed."; fi

# --- Keep sudo alive for the pacman stage ----------------------------------
log "Requesting sudo (used only for pacman)…"
sudo -v
# refresh the timestamp in the background so long builds don't expire it
( while true; do sudo -n true 2>/dev/null; sleep 50; kill -0 "$$" 2>/dev/null || exit; done ) &
state_set SUDO_KEEPALIVE_PID "$!"

ok "Preflight complete."
