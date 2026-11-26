/* macOS-style Plasma 6 layout
 * - removes existing panels
 * - adds a thin TOP menu bar:  Apple launcher | global menu | <spacer> | tray | clock
 * - adds a floating BOTTOM dock: icons-only task manager, content-width
 * - sets the WhiteSur wallpaper on every desktop
 *
 * Applied via:
 *   qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "<this file>"
 *
 * 05-panels.sh substitutes the wallpaper path into the wp variable below.
 */

/* ---- 1. clean slate: drop whatever panels exist -------------------------- */
var existing = panels();
for (var i = 0; i < existing.length; i++) {
    existing[i].remove();
}

/* ---- 2. TOP menu bar ----------------------------------------------------- */
var top = new Panel;
top.location = "top";
top.height   = 28;
try { top.floating = false; } catch (e) {}

// Apple-style launcher on the far left
var launcher = top.addWidget("org.kde.plasma.kickoff");
launcher.currentConfigGroup = ["General"];
// WhiteSur icon theme ships an apple logo; falls back gracefully if absent.
launcher.writeConfig("icon", "distributor-logo-apple");
launcher.writeConfig("menuLabel", "");

// Global application menu (requires appmenu-gtk-module for GTK apps)
top.addWidget("org.kde.plasma.appmenu");

// Expanding spacer pushes the rest to the right
var topSpacer = top.addWidget("org.kde.plasma.panelspacer");
topSpacer.currentConfigGroup = ["General"];
topSpacer.writeConfig("expanding", true);

// Right cluster: system tray + clock
top.addWidget("org.kde.plasma.systemtray");

var clock = top.addWidget("org.kde.plasma.digitalclock");
clock.currentConfigGroup = ["Appearance"];
clock.writeConfig("showDate", true);
clock.writeConfig("dateFormat", "shortDate");
clock.writeConfig("use24hFormat", 0);   // 0 = follow locale

/* ---- 3. BOTTOM floating dock -------------------------------------------- */
var dock = new Panel;
dock.location = "bottom";
dock.height   = 60;
try { dock.floating = true; } catch (e) {}
// "fit" = panel shrinks to its content, giving the centred macOS dock look.
try { dock.lengthMode = "fit"; } catch (e) {}
try { dock.alignment  = "center"; } catch (e) {}

var tasks = dock.addWidget("org.kde.plasma.icontasks");
tasks.currentConfigGroup = ["General"];
// Pinned launchers — only apps guaranteed to be installed, so no broken
// placeholder icons. (Discover is intentionally omitted: it isn't pulled in
// by plasma-desktop and would show a '?' placeholder.)
tasks.writeConfig("launchers",
    "applications:systemsettings.desktop," +
    "applications:org.kde.dolphin.desktop," +
    "applications:org.kde.konsole.desktop," +
    "applications:firefox.desktop");
tasks.writeConfig("fill", false);                 // don't stretch across the panel
tasks.writeConfig("showOnlyCurrentDesktop", false);
tasks.writeConfig("showOnlyCurrentActivity", false);
tasks.writeConfig("maxStripes", 1);
tasks.writeConfig("iconSpacing", 3);              // more air between icons (macOS-ish)
tasks.writeConfig("indicateAudioStreams", false); // no media speaker badges
tasks.reloadConfig();

/* ---- 4. Wallpaper on every desktop -------------------------------------- */
var wp = "@WALLPAPER@";
if (wp.length > 0 && wp.charAt(0) === "/") {
    var ds = desktops();
    for (var j = 0; j < ds.length; j++) {
        ds[j].wallpaperPlugin = "org.kde.image";
        ds[j].currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
        ds[j].writeConfig("Image", "file://" + wp);
        ds[j].writeConfig("FillMode", 2);   // 2 = scaled & cropped (fills screen)
    }
}
