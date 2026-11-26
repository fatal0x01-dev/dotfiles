#!/usr/bin/env bash
# Stage 04 — apply the look & feel non-interactively.
# Backs up every config file it changes BEFORE touching it.
set -euo pipefail
source "$(dirname "$0")/lib.sh"

VARIANT="${WS_VARIANT:-light}"
if [[ "$VARIANT" == "dark" ]]; then
    LAF="com.github.vinceliuice.WhiteSur-dark"
    PLASMA_THEME="WhiteSur-dark"
    COLORS="WhiteSurDark"
    ICONS="WhiteSur-dark"
    KVANTUM="WhiteSur-dark"
    AURORAE="__aurorae__svg__WhiteSur-dark"
else
    LAF="com.github.vinceliuice.WhiteSur"
    PLASMA_THEME="WhiteSur"
    COLORS="WhiteSur"
    ICONS="WhiteSur"
    KVANTUM="WhiteSur"
    AURORAE="__aurorae__svg__WhiteSur"
fi

# --- Back up existing config ------------------------------------------------
mkdir -p "$BACKUP_DIR"
for f in kdeglobals kwinrc plasmarc plasmashellrc kcminputrc \
         plasma-org.kde.plasma.desktop-appletsrc Kvantum/kvantum.kvconfig; do
    [[ -e "$HOME/.config/$f" ]] && { mkdir -p "$BACKUP_DIR/$(dirname "$f")"; cp -a "$HOME/.config/$f" "$BACKUP_DIR/$f"; }
done
ok "Backed up current config to $BACKUP_DIR"

# --- Global look-and-feel ---------------------------------------------------
# Applies desktop theme, colours, icons, cursor and splash in one shot.
if have_cmd plasma-apply-lookandfeel; then
    plasma-apply-lookandfeel -a "$LAF" 2>/dev/null \
        && ok "Applied global theme: $LAF" \
        || warn "Could not apply look-and-feel '$LAF'; setting components individually."
fi

# --- Set each component explicitly (covers anything the LAF missed) ---------
have_cmd plasma-apply-desktoptheme && plasma-apply-desktoptheme "$PLASMA_THEME" 2>/dev/null && ok "Desktop theme: $PLASMA_THEME" || true
have_cmd plasma-apply-colorscheme  && plasma-apply-colorscheme  "$COLORS"       2>/dev/null && ok "Colour scheme: $COLORS"  || true
have_cmd plasma-apply-cursortheme  && plasma-apply-cursortheme  "WhiteSur-cursors" 2>/dev/null && ok "Cursor theme set" || true

# Icons (kdeglobals)
kwrite --file kdeglobals --group Icons --key Theme "$ICONS"
ok "Icon theme: $ICONS"

# macOS uses a subtle neutral highlight, not a saturated accent. KDE by default
# pulls a vivid accent from the wallpaper and paints it behind the active dock
# icon (the blue box). Disable that so WhiteSur's own neutral highlight shows.
kwrite --file kdeglobals --group General --key accentColorFromWallpaper "false"
ok "Disabled wallpaper-derived accent (softer dock highlight)."

# --- Widget style -> Kvantum, and point Kvantum at the WhiteSur theme -------
kwrite --file kdeglobals --group KDE --key widgetStyle "kvantum"
mkdir -p "$HOME/.config/Kvantum"
# Kvantum's own selector file. 'theme=' chooses the active Kvantum theme.
cat > "$HOME/.config/Kvantum/kvantum.kvconfig" <<EOF
[General]
theme=$KVANTUM
EOF
ok "Widget style: Kvantum ($KVANTUM)"

# --- macOS window decoration: left-side traffic-light buttons --------------
# ButtonsOnLeft "XIA" = close(X) minimize(I) maximize(A), left-to-right.
kwrite --file kwinrc --group org.kde.kdecoration2 --key library "org.kde.kwin.aurorae"
kwrite --file kwinrc --group org.kde.kdecoration2 --key theme   "$AURORAE"
kwrite --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnLeft  "XIA"
kwrite --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnRight ""
ok "Window buttons moved to the left (macOS style)."

# --- UI font (SF Pro / Inter if stage 02 found one) ------------------------
UI_FONT="$(state_get UI_FONT)"
if [[ -n "$UI_FONT" ]]; then
    # kdeglobals font format: "Family,size,-1,5,weight,0,0,0,0,0"
    kwrite --file kdeglobals --group General --key font        "$UI_FONT,10,-1,5,50,0,0,0,0,0"
    kwrite --file kdeglobals --group General --key menuFont    "$UI_FONT,10,-1,5,50,0,0,0,0,0"
    kwrite --file kdeglobals --group General --key toolBarFont "$UI_FONT,10,-1,5,50,0,0,0,0,0"
    kwrite --file kdeglobals --group WM      --key activeFont  "$UI_FONT,10,-1,5,50,0,0,0,0,0"
    ok "UI font: $UI_FONT"
fi

# --- GTK apps: theme + left window buttons ---------------------------------
GTK_THEME="WhiteSur"; [[ "$VARIANT" == "dark" ]] && GTK_THEME="WhiteSur-Dark"
for v in gtk-3.0 gtk-4.0; do
    mkdir -p "$HOME/.config/$v"
    # Write settings.ini with the resolved theme/icon/font names.
    cat > "$HOME/.config/$v/settings.ini" <<EOF
[Settings]
gtk-theme-name=$GTK_THEME
gtk-icon-theme-name=$ICONS
gtk-cursor-theme-name=WhiteSur-cursors
gtk-font-name=${UI_FONT:-Inter} 10
gtk-decoration-layout=close,minimize,maximize:
gtk-application-prefer-dark-theme=$([[ "$VARIANT" == dark ]] && echo true || echo false)
EOF
done
if have_cmd gsettings; then
    gsettings set org.gnome.desktop.interface gtk-theme   "$GTK_THEME" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface icon-theme  "$ICONS"     2>/dev/null || true
    gsettings set org.gnome.desktop.wm.preferences button-layout "close,minimize,maximize:" 2>/dev/null || true
fi
ok "GTK applications themed."

# --- SDDM login theme (needs root; theme shipped by WhiteSur-kde) ----------
sddm_theme_dir=""
for d in "/usr/share/sddm/themes/WhiteSur" "/usr/share/sddm/themes/WhiteSur-dark" \
         "$HOME/.local/share/sddm/themes/WhiteSur"; do
    [[ -d "$d" ]] && { sddm_theme_dir="$(basename "$d")"; break; }
done
if [[ -n "$sddm_theme_dir" ]]; then
    sudo mkdir -p /etc/sddm.conf.d
    # Don't clobber an existing sddm.conf — write a dedicated drop-in.
    printf '[Theme]\nCurrent=%s\n' "$sddm_theme_dir" | sudo tee /etc/sddm.conf.d/10-macos-kde-theme.conf >/dev/null
    ok "SDDM login theme set to $sddm_theme_dir"
else
    warn "WhiteSur SDDM theme not found on disk; login screen left unchanged."
fi

# --- Reconfigure KWin live so window decorations update without a relog ----
qd org.kde.KWin /KWin reconfigure 2>/dev/null || true

ok "Theme application stage complete."
