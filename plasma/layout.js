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

/* ---- 2. TOP menu bar (macOS: Apple | AppName(bold) | menus | … | tray | clock) */
var top = new Panel;
top.location = "top";
top.height   = 26;                    // thin, like the macOS menu bar
try { top.floating = false; } catch (e) {}

// Apple menu — launcher with the apple logo on the far left
var launcher = top.addWidget("org.kde.plasma.kickoff");
launcher.currentConfigGroup = ["General"];
launcher.writeConfig("icon", "distributor-logo-apple");
launcher.writeConfig("menuLabel", "");

// Bold application name of the focused window (the signature macOS element).
// Needs the org.kde.windowtitle applet (installed by 04c-topbar-applets.sh);
// if it's absent this block is skipped and the global menu still appears.
try {
    var appname = top.addWidget("org.kde.windowtitle");
    if (appname) {
        appname.currentConfigGroup = ["Appearance"];
        appname.writeConfig("txt", "%a");        // application name only
        appname.writeConfig("isBold", true);     // bold, like macOS
        appname.writeConfig("noIcon", true);     // the Apple logo is separate
        appname.writeConfig("activityIcon", false);
        appname.reloadConfig();
    }
} catch (e) {}

// Global application menu (File / Edit / View …) — needs appmenu-gtk-module for GTK apps
top.addWidget("org.kde.plasma.appmenu");

// Expanding spacer pushes the rest to the right
var topSpacer = top.addWidget("org.kde.plasma.panelspacer");
topSpacer.currentConfigGroup = ["General"];
topSpacer.writeConfig("expanding", true);

// Right cluster: system tray + macOS-format clock
top.addWidget("org.kde.plasma.systemtray");

var clock = top.addWidget("org.kde.plasma.digitalclock");
clock.currentConfigGroup = ["Appearance"];
clock.writeConfig("showDate", true);
clock.writeConfig("dateFormat", "custom");
clock.writeConfig("customDateFormat", "ddd MMM d");  // e.g. "Tue Dec 28"
clock.writeConfig("use24hFormat", 0);                // 12-hour with AM/PM

/* ---- 3. BOTTOM floating dock -------------------------------------------- */
var dock = new Panel;
dock.location = "bottom";
dock.height   = 74;                               // large, macOS-sized icons
try { dock.floating = true; } catch (e) {}
// "fit" = panel shrinks to its content, giving the centred macOS dock look.
try { dock.lengthMode = "fit"; } catch (e) {}
try { dock.alignment  = "center"; } catch (e) {}

var tasks = dock.addWidget("org.kde.plasma.icontasks");
tasks.currentConfigGroup = ["General"];
// Pinned launchers — the macOS app lineup, substituted by 05-panels.sh from
// the icons built in stage 04b. Falls back to a KDE set if that stage skipped.
tasks.writeConfig("launchers", "@DOCK_LAUNCHERS@");
tasks.writeConfig("fill", false);                 // don't stretch across the panel
tasks.writeConfig("showOnlyCurrentDesktop", false);
tasks.writeConfig("showOnlyCurrentActivity", false);
tasks.writeConfig("maxStripes", 1);
tasks.writeConfig("iconSpacing", 1);              // tight like the real dock
tasks.writeConfig("indicateAudioStreams", false); // no media speaker badges
tasks.reloadConfig();

// Trash can at the far end of the dock, macOS-style.
try { dock.addWidget("org.kde.plasma.trash"); } catch (e) {}

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
