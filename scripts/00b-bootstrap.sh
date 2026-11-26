#!/usr/bin/env bash
# Stage 00b — make sure a usable Plasma session + login manager exist.
# This is what turns a bare "pacman -S plasma-desktop" box (which boots to a
# TTY) into a machine that actually starts the desktop. Safe & idempotent:
# it never overrides a login manager you already have enabled.
set -euo pipefail
source "$(dirname "$0")/lib.sh"

# --- Session essentials ----------------------------------------------------
# plasma-workspace : the actual session (plasmashell, kwin, the Wayland/X11
#                    session files in /usr/share/*-sessions)
# sddm             : the graphical login manager
# konsole          : a terminal, so you're never stranded without one
log "Ensuring Plasma session + SDDM are installed…"
sudo pacman -S --needed --noconfirm \
    sddm plasma-workspace plasma-desktop konsole \
    || die "Failed to install the Plasma session packages. Run 'sudo pacman -Syu' and retry."
ok "Session packages present."

# --- Enable a login manager, but only if none is enabled yet ---------------
# The enabled DM is the symlink /etc/systemd/system/display-manager.service.
if [[ -e /etc/systemd/system/display-manager.service ]]; then
    current_dm="$(basename "$(readlink -f /etc/systemd/system/display-manager.service)")"
    ok "A login manager is already enabled: $current_dm (leaving it untouched)."
else
    log "No login manager enabled — enabling SDDM."
    sudo systemctl enable sddm \
        && ok "SDDM enabled (it will start on next boot)." \
        || warn "Could not enable SDDM; enable it manually: sudo systemctl enable sddm"
    # If we're currently in a text console (no graphical session), offer to
    # start it now. We don't force-start if a session is already up.
    if [[ -z "${WAYLAND_DISPLAY:-}" && -z "${DISPLAY:-}" ]]; then
        log "Starting SDDM now…"
        sudo systemctl start sddm 2>/dev/null \
            && ok "SDDM started." \
            || warn "Could not start SDDM now; reboot to get the graphical login."
    fi
fi

# --- Record whether a live Plasma session is reachable this run ------------
# Stage 05 uses this to decide: apply the dock now, or defer to first login.
if pgrep -x plasmashell >/dev/null 2>&1 && { [[ -n "${WAYLAND_DISPLAY:-}" ]] || [[ -n "${DISPLAY:-}" ]]; }; then
    state_set LIVE_PLASMA 1
    ok "Live Plasma session detected — panels will be applied now."
else
    state_set LIVE_PLASMA 0
    warn "No live Plasma session in this run — the dock will auto-apply at your next login."
fi

ok "Bootstrap stage complete."
