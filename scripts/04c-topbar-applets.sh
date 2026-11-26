#!/usr/bin/env bash
# Stage 04c — install the menu-bar "application name" applet so the top panel
# shows the focused app's name in bold, exactly like the macOS menu bar.
# Applet: dhruv8sh/plasma6-window-title-applet (org.kde.windowtitle), Plasma 6.
set -euo pipefail
source "$(dirname "$0")/lib.sh"

APPLET_ID="org.kde.windowtitle"

if ! have_cmd kpackagetool6; then
    warn "kpackagetool6 not found; skipping the app-name applet (global menu still shows)."
    state_set HAVE_WINDOWTITLE 0
    exit 0
fi

# Already installed?
if kpackagetool6 -t Plasma/Applet -l 2>/dev/null | grep -q "$APPLET_ID"; then
    ok "App-name applet already installed."
    state_set HAVE_WINDOWTITLE 1
    exit 0
fi

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
log "Fetching macOS menu-bar app-name applet…"
if ! git clone --depth 1 https://github.com/dhruv8sh/plasma6-window-title-applet "$TMP/wt" >/dev/null 2>&1; then
    warn "Could not fetch the app-name applet (offline?); top bar will use the global menu only."
    state_set HAVE_WINDOWTITLE 0
    exit 0
fi

# -i install, or -u upgrade if a previous version exists.
if kpackagetool6 -t Plasma/Applet -i "$TMP/wt" >/dev/null 2>&1 \
   || kpackagetool6 -t Plasma/Applet -u "$TMP/wt" >/dev/null 2>&1; then
    ok "Installed app-name applet ($APPLET_ID)."
    state_set HAVE_WINDOWTITLE 1
else
    warn "Could not install the app-name applet; top bar will use the global menu only."
    state_set HAVE_WINDOWTITLE 0
fi
