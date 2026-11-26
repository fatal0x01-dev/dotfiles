#!/usr/bin/env bash
# Stage 05 — build the top menu bar + floating dock + wallpaper.
#
# The panel layout can ONLY be applied to a *running* plasmashell. So:
#   - if a live Plasma session is reachable now  -> apply immediately
#   - if not (you ran this from a TTY)           -> install a one-shot
#     autostart hook that applies it at your next graphical login, then
#     deletes itself. Either way the dock ends up present with no manual step.
set -euo pipefail
source "$(dirname "$0")/lib.sh"

WALLPAPER="$(state_get WALLPAPER)"
LIVE="$(state_get LIVE_PLASMA)"
SRC="$DOTFILES_ROOT/plasma/layout.js"
APPLY_DIR="$HOME/.local/share/macos-kde"
mkdir -p "$APPLY_DIR"

# --- Render the layout with the wallpaper path baked in --------------------
sed "s|@WALLPAPER@|${WALLPAPER//|/\\|}|g" "$SRC" > "$APPLY_DIR/layout.js"

# --- Write the self-contained applier (re-runnable any time) ---------------
cat > "$APPLY_DIR/apply-layout.sh" <<'SH'
#!/usr/bin/env bash
# Apply the macOS panel layout to the running plasmashell, then refresh it.
set -euo pipefail
DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
QD=qdbus; command -v qdbus6 >/dev/null 2>&1 && QD=qdbus6

command -v "$QD" >/dev/null 2>&1 || { echo "qdbus not found"; exit 1; }
pgrep -x plasmashell >/dev/null 2>&1 || { echo "plasmashell not running"; exit 1; }

"$QD" org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$(cat "$DIR/layout.js")"

# Force the freshly-scripted panels to settle (known Plasma 6 quirk where a
# newly-created panel doesn't render until plasmashell reloads).
sleep 1
if systemctl --user restart plasma-plasmashell 2>/dev/null; then
    :
else
    kquitapp6 plasmashell 2>/dev/null || kquitapp5 plasmashell 2>/dev/null || true
    sleep 1
    if command -v kstart >/dev/null 2>&1;  then (kstart  plasmashell >/dev/null 2>&1 &)
    elif command -v kstart6 >/dev/null 2>&1; then (kstart6 plasmashell >/dev/null 2>&1 &)
    else (setsid plasmashell >/dev/null 2>&1 &); fi
fi
echo "macOS panel layout applied."
SH
chmod +x "$APPLY_DIR/apply-layout.sh"

# --- Branch: apply now, or defer to first login ----------------------------
if [[ "$LIVE" == "1" ]] && pgrep -x plasmashell >/dev/null 2>&1; then
    log "Applying panel layout to the running session…"
    if "$APPLY_DIR/apply-layout.sh"; then
        ok "Top bar + floating dock applied."
    else
        warn "Live apply failed; installing the first-login hook as a fallback."
        LIVE="deferred"
    fi
else
    LIVE="deferred"
fi

if [[ "$LIVE" == "deferred" ]]; then
    # One-shot autostart wrapper: apply once, then remove itself so it never
    # clobbers your panels on subsequent logins.
    cat > "$APPLY_DIR/firstrun.sh" <<SH
#!/usr/bin/env bash
sleep 5   # give plasmashell time to come up fully
"$APPLY_DIR/apply-layout.sh" || true
rm -f "\$HOME/.config/autostart/macos-kde-firstrun.desktop"
SH
    chmod +x "$APPLY_DIR/firstrun.sh"

    mkdir -p "$HOME/.config/autostart"
    cat > "$HOME/.config/autostart/macos-kde-firstrun.desktop" <<SH
[Desktop Entry]
Type=Application
Name=macOS-KDE panel setup (first run)
Exec=$APPLY_DIR/firstrun.sh
X-KDE-autostart-phase=2
X-GNOME-Autostart-enabled=true
SH
    ok "Dock not applied yet (no live session). It will appear automatically at your next login."
    warn "Or, once you're in Plasma, run it immediately:  $APPLY_DIR/apply-layout.sh"
fi

ok "Panel stage complete."
