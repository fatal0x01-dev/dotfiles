#!/usr/bin/env bash
# Stage 04b — build the real macOS dock: Apple's app icons (Finder, Launchpad,
# Safari, Messages, Mail, …) as named launchers, pinned in macOS order.
#
# Icon artwork: PuruVJ/macos-web (MIT) — faithful Big Sur/Monterey app icons.
# Each launcher opens the nearest installed Linux app, or a web equivalent, so
# no dock icon is a dead click. If the fetch fails we fall back to the KDE dock.
set -euo pipefail
source "$(dirname "$0")/lib.sh"

APPLY_DIR="$HOME/.local/share/macos-kde"
ICON_DIR="$APPLY_DIR/dock-icons"
APP_DIR="$HOME/.local/share/applications"
mkdir -p "$ICON_DIR" "$APP_DIR"

# --- The dock lineup, in order (left -> right) ------------------------------
APPS=(finder launchpad safari messages mail maps photos facetime calendar \
      contacts reminders notes tv music podcasts news appstore keynote \
      system-preferences terminal)

declare -A NAME=(
    [finder]="Finder" [launchpad]="Launchpad" [safari]="Safari"
    [messages]="Messages" [mail]="Mail" [maps]="Maps" [photos]="Photos"
    [facetime]="FaceTime" [calendar]="Calendar" [contacts]="Contacts"
    [reminders]="Reminders" [notes]="Notes" [tv]="TV" [music]="Music"
    [podcasts]="Podcasts" [news]="News" [appstore]="App Store"
    [keynote]="Keynote" [system-preferences]="System Preferences"
    [terminal]="Terminal"
)

# --- Fetch the icon artwork (sparse, shallow — only the dirs we need) -------
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
log "Fetching macOS app icons (PuruVJ/macos-web, MIT)…"
if git clone --depth 1 --filter=blob:none --sparse \
        https://github.com/PuruVJ/macos-web "$TMP" >/dev/null 2>&1; then
    git -C "$TMP" sparse-checkout set $(printf 'public/app-icons/%s ' "${APPS[@]}") >/dev/null 2>&1 || true
else
    warn "Could not fetch macOS icons (offline?). Keeping the native KDE dock."
    exit 0
fi

# --- Copy the best size for each app ---------------------------------------
copied=0
for key in "${APPS[@]}"; do
    src="$TMP/public/app-icons/$key"
    for sz in 512 256 1024 128; do
        if [[ -f "$src/$sz.png" ]]; then cp -f "$src/$sz.png" "$ICON_DIR/$key.png"; copied=$((copied+1)); break; fi
    done
done
if [[ $copied -eq 0 ]]; then
    warn "No icons were copied; keeping the native KDE dock."
    exit 0
fi
ok "Installed $copied macOS dock icons -> $ICON_DIR"

# --- Dispatcher: open the nearest Linux app, else a web equivalent ----------
cat > "$APPLY_DIR/macos-launch" <<'SH'
#!/usr/bin/env bash
# macos-launch <key> — route a macOS dock icon to a real action.
key="${1:-}"
declare -A CMDS=(
  [finder]="dolphin nautilus pcmanfm-qt pcmanfm nemo thunar"
  [safari]="firefox firefox-esr chromium chromium-browser brave falkon"
  [mail]="thunderbird kmail geary evolution"
  [maps]="marble gnome-maps"
  [photos]="gwenview shotwell eog gthumb"
  [calendar]="korganizer merkuro-calendar kalendar gnome-calendar"
  [contacts]="kaddressbook gnome-contacts"
  [notes]="knotes xpad"
  [music]="elisa strawberry clementine rhythmbox audacious"
  [podcasts]="kasts gpodder"
  [appstore]="plasma-discover gnome-software"
  [keynote]="libreoffice"
  [system-preferences]="systemsettings systemsettings5"
  [terminal]="konsole alacritty kitty foot xterm"
)
declare -A URLS=(
  [messages]="https://messages.google.com/web"
  [mail]="https://mail.google.com"
  [maps]="https://www.google.com/maps"
  [facetime]="https://meet.google.com"
  [calendar]="https://calendar.google.com"
  [reminders]="https://www.icloud.com/reminders"
  [notes]="https://www.icloud.com/notes"
  [tv]="https://tv.apple.com"
  [news]="https://news.google.com"
  [keynote]="https://www.icloud.com/keynote"
)

# Launchpad -> open the Plasma application launcher
if [[ "$key" == "launchpad" ]]; then
  QD=qdbus; command -v qdbus6 >/dev/null 2>&1 && QD=qdbus6
  "$QD" org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.activateLauncherMenu 2>/dev/null && exit 0
  command -v krunner >/dev/null 2>&1 && exec krunner
fi

for c in ${CMDS[$key]:-}; do
  if command -v "$c" >/dev/null 2>&1; then
    [[ "$key" == "keynote" ]] && exec "$c" --impress
    exec "$c"
  fi
done
url="${URLS[$key]:-}"
[[ -n "$url" ]] && exec xdg-open "$url"
command -v notify-send >/dev/null 2>&1 && notify-send "macOS dock" "No app installed for ${key}."
SH
chmod +x "$APPLY_DIR/macos-launch"

# --- Generate the .desktop launchers ---------------------------------------
for key in "${APPS[@]}"; do
    [[ -f "$ICON_DIR/$key.png" ]] || continue
    cat > "$APP_DIR/macos-$key.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=${NAME[$key]}
Icon=$ICON_DIR/$key.png
Exec=$APPLY_DIR/macos-launch $key
Terminal=false
StartupNotify=true
Categories=Utility;
EOF
done
ok "Created macOS launchers in $APP_DIR"

# Refresh the KDE service cache so the launchers resolve when pinned.
have_cmd kbuildsycoca6 && kbuildsycoca6 --noincremental >/dev/null 2>&1 || true

# --- Hand the pinned order to the panel stage ------------------------------
dl=""
for key in "${APPS[@]}"; do
    [[ -f "$APP_DIR/macos-$key.desktop" ]] && dl+="applications:macos-$key.desktop,"
done
dl="${dl%,}"   # strip trailing comma
state_set DOCK_LAUNCHERS "$dl"
ok "macOS dock lineup ready (${#APPS[@]} apps)."
