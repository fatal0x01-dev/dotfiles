#!/usr/bin/env bash
# Stage 06 (optional, --plank) — install Plank for a magnifying macOS dock.
# Plank is an X11 dock; it does NOT work on Wayland. On Wayland the native
# floating Plasma dock from stage 05 is the right choice, so we skip here.
set -euo pipefail
source "$(dirname "$0")/lib.sh"

SESSION="$(state_get SESSION)"
AUR_HELPER="$(state_get AUR_HELPER)"

if [[ "$SESSION" == "wayland" ]]; then
    warn "Wayland session detected — Plank only runs on X11. Keeping the native Plasma dock."
    exit 0
fi

if [[ -z "$AUR_HELPER" ]]; then
    warn "Plank is in the AUR and no AUR helper is installed; skipping. Native dock is active."
    exit 0
fi

log "Installing Plank from AUR…"
"$AUR_HELPER" -S --needed --noconfirm plank || { warn "Plank install failed; keeping native dock."; exit 0; }

# Autostart Plank for this user.
mkdir -p "$HOME/.config/autostart"
cat > "$HOME/.config/autostart/plank.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=Plank
Exec=plank
X-GNOME-Autostart-enabled=true
EOF

ok "Plank installed and set to autostart. Apply the WhiteSur Plank theme via: plank --preferences"
warn "With Plank active you may want to remove the native bottom dock from stage 05 to avoid two docks."
