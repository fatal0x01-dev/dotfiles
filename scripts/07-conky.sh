#!/usr/bin/env bash
# Stage 07 (optional, --conky) — a minimal macOS-style Conky desktop widget:
# big clock + date + CPU/RAM/disk/network, translucent, top-right.
set -euo pipefail
source "$(dirname "$0")/lib.sh"

SESSION="$(state_get SESSION)"
APPLY_DIR="$HOME/.local/share/macos-kde"
CONF_DIR="$HOME/.config/conky"
mkdir -p "$APPLY_DIR" "$CONF_DIR"

# --- Install conky ----------------------------------------------------------
log "Installing conky…"
sudo pacman -S --needed --noconfirm conky || { warn "conky install failed; skipping."; exit 0; }

# --- Resolve font + primary network interface ------------------------------
FONT="Inter"; fc-list 2>/dev/null | grep -qi "SF Pro" && FONT="SF Pro Display"
IFACE="$(ip route show default 2>/dev/null | awk '/default/{print $5; exit}')"
[[ -z "$IFACE" ]] && IFACE="$(ls /sys/class/net 2>/dev/null | grep -v '^lo$' | head -1)"
[[ -z "$IFACE" ]] && IFACE="lo"
ok "Conky font: $FONT   interface: $IFACE"

# --- Render the config ------------------------------------------------------
sed -e "s|@FONT@|$FONT|g" -e "s|@IFACE@|$IFACE|g" \
    "$DOTFILES_ROOT/conky/macos.conf" > "$CONF_DIR/macos.conf"
ok "Conky config written to $CONF_DIR/macos.conf"

# --- Launcher wrapper (delays so the session is ready, kills duplicates) ----
cat > "$APPLY_DIR/conky-start.sh" <<SH
#!/usr/bin/env bash
sleep 6
pkill -x conky 2>/dev/null || true
exec conky -c "$CONF_DIR/macos.conf"
SH
chmod +x "$APPLY_DIR/conky-start.sh"

# --- Autostart --------------------------------------------------------------
mkdir -p "$HOME/.config/autostart"
cat > "$HOME/.config/autostart/conky-macos.desktop" <<SH
[Desktop Entry]
Type=Application
Name=Conky (macOS widget)
Exec=$APPLY_DIR/conky-start.sh
X-KDE-autostart-phase=2
X-GNOME-Autostart-enabled=true
SH
ok "Conky set to autostart."

# --- Start now if a desktop is live ----------------------------------------
if pgrep -x plasmashell >/dev/null 2>&1 && { [[ -n "${WAYLAND_DISPLAY:-}" ]] || [[ -n "${DISPLAY:-}" ]]; }; then
    ( "$APPLY_DIR/conky-start.sh" >/dev/null 2>&1 & )
    ok "Conky started."
fi

# --- Wayland honesty note ---------------------------------------------------
if [[ "$SESSION" == "wayland" ]]; then
    warn "Conky is an X11 app. On Wayland it runs via XWayland and may not stay pinned to the"
    warn "desktop (it can float above/below windows). It behaves perfectly on an X11 session."
fi

ok "Conky stage complete."
