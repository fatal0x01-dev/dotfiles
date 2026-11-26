#!/usr/bin/env bash
# Stage 03 — fetch and build the WhiteSur theme set from source (vinceliuice).
# Building from git (rather than AUR) keeps this self-contained and avoids
# depending on an AUR helper for the core theme.
set -euo pipefail
source "$(dirname "$0")/lib.sh"

cd "$BUILD_DIR"

# repo               | install command run inside the clone
# --------------------------------------------------------------------------
# WhiteSur-kde    -> Plasma global theme, color scheme, desktop theme,
#                    Aurorae window decoration, Kvantum theme, SDDM theme
# WhiteSur-icon   -> icon set
# WhiteSur-cursor -> cursor set
# WhiteSur-gtk    -> GTK3/GTK4/libadwaita theme for GTK apps
# WhiteSur-wall   -> matching wallpapers
declare -A REPOS=(
    [WhiteSur-kde]="https://github.com/vinceliuice/WhiteSur-kde"
    [WhiteSur-icon-theme]="https://github.com/vinceliuice/WhiteSur-icon-theme"
    [WhiteSur-cursors]="https://github.com/vinceliuice/WhiteSur-cursors"
    [WhiteSur-gtk-theme]="https://github.com/vinceliuice/WhiteSur-gtk-theme"
    [WhiteSur-wallpapers]="https://github.com/vinceliuice/WhiteSur-wallpapers"
)

clone_or_update() {
    local name="$1" url="$2"
    if [[ -d "$name/.git" ]]; then
        log "Updating $name"
        git -C "$name" pull --ff-only --quiet || warn "Could not update $name; using existing checkout."
    else
        log "Cloning $name"
        git clone --depth 1 "$url" "$name" || die "Failed to clone $name from $url"
    fi
}

for name in "${!REPOS[@]}"; do
    clone_or_update "$name" "${REPOS[$name]}"
done

# --- Build / install each (user-level installs into ~/.local & ~/.themes) ---

log "Installing WhiteSur Plasma theme (Aurorae, Kvantum, color scheme, SDDM)…"
# --sharp : square-ish window corners closer to Big Sur; drop it for rounded.
( cd WhiteSur-kde && ./install.sh ) || die "WhiteSur-kde install.sh failed."
ok "Plasma theme installed."

log "Installing WhiteSur icon theme…"
# Try the 'all variants' form first, fall back to the plain installer.
( cd WhiteSur-icon-theme && ./install.sh -a ) \
    || ( cd WhiteSur-icon-theme && ./install.sh ) \
    || warn "Icon theme install reported an issue."
ok "Icons installed."

log "Installing WhiteSur cursors…"
( cd WhiteSur-cursors && ./install.sh ) || warn "Cursor install reported an issue."
ok "Cursors installed."

log "Installing WhiteSur GTK theme…"
# -l : also theme libadwaita (GTK4) apps;  -c : colour variants light+dark
( cd WhiteSur-gtk-theme && ./install.sh -l -c "${WS_VARIANT:-light}" ) \
    || ( cd WhiteSur-gtk-theme && ./install.sh ) \
    || warn "GTK theme install reported an issue."
ok "GTK theme installed."

# --- Stage a wallpaper (best-effort: copy the first one the repo ships) ----
wall_dest="$HOME/.local/share/wallpapers/WhiteSur"
mkdir -p "$wall_dest"
wall_src="$(find "$BUILD_DIR/WhiteSur-wallpapers" -maxdepth 3 -type f \( -iname '*.jpg' -o -iname '*.png' \) 2>/dev/null | sort | head -1 || true)"
if [[ -n "$wall_src" ]]; then
    cp -f "$wall_src" "$wall_dest/wallpaper.${wall_src##*.}"
    state_set WALLPAPER "$wall_dest/wallpaper.${wall_src##*.}"
    ok "Wallpaper staged: $(basename "$wall_src")"
else
    warn "No wallpaper found in the repo; keeping your current wallpaper."
fi

ok "Theme build stage complete."
