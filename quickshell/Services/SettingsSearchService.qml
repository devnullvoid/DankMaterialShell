pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.Common

Singleton {
    id: root

    property string query: ""
    property var results: []
    property string targetSection: ""
    property string highlightSection: ""
    property var registeredCards: ({})

    function registerCard(settingKey, item, flickable) {
        if (!settingKey)
            return;
        registeredCards[settingKey] = {
            item: item,
            flickable: flickable
        };
        if (targetSection === settingKey) {
            scrollTimer.restart();
        }
    }

    function unregisterCard(settingKey) {
        if (!settingKey)
            return;
        let cards = registeredCards;
        delete cards[settingKey];
        registeredCards = cards;
    }

    function navigateToSection(section) {
        targetSection = section;
        if (registeredCards[section]) {
            scrollTimer.restart();
        }
    }

    function scrollToTarget() {
        if (!targetSection)
            return;
        const entry = registeredCards[targetSection];
        if (!entry || !entry.item || !entry.flickable)
            return;
        const flickable = entry.flickable;
        const item = entry.item;
        const contentItem = flickable.contentItem;

        if (!contentItem)
            return;
        const mapped = item.mapToItem(contentItem, 0, 0);
        const targetY = Math.max(0, mapped.y - 16);
        flickable.contentY = targetY;

        highlightSection = targetSection;
        targetSection = "";
        highlightTimer.restart();
    }

    function clearHighlight() {
        highlightSection = "";
    }

    Timer {
        id: scrollTimer
        interval: 50
        onTriggered: root.scrollToTarget()
    }

    Timer {
        id: highlightTimer
        interval: 2500
        onTriggered: root.highlightSection = ""
    }

    readonly property var settingsIndex: [
        {
            label: I18n.tr("Wallpaper"),
            keywords: ["background", "image", "picture", "desktop"],
            tabIndex: 0,
            icon: "wallpaper",
            category: I18n.tr("Personalization"),
            section: "wallpaper"
        },
        {
            label: I18n.tr("Per-Mode Wallpapers"),
            keywords: ["light", "dark", "mode", "theme"],
            tabIndex: 0,
            icon: "contrast",
            category: I18n.tr("Personalization"),
            section: "wallpaper"
        },
        {
            label: I18n.tr("Blur on Overview"),
            keywords: ["niri", "blur", "overview", "compositor"],
            tabIndex: 0,
            icon: "blur_on",
            category: I18n.tr("Personalization"),
            section: "blurWallpaper",
            condition: () => CompositorService.isNiri
        },
        {
            label: I18n.tr("Per-Monitor Wallpapers"),
            keywords: ["multi-monitor", "display", "screen"],
            tabIndex: 0,
            icon: "monitor",
            category: I18n.tr("Personalization"),
            section: "wallpaper"
        },
        {
            label: I18n.tr("Automatic Cycling"),
            keywords: ["cycle", "rotate", "slideshow", "interval"],
            tabIndex: 0,
            icon: "slideshow",
            category: I18n.tr("Personalization"),
            section: "wallpaper"
        },
        {
            label: I18n.tr("Transition Effect"),
            keywords: ["animation", "change", "effect"],
            tabIndex: 0,
            icon: "animation",
            category: I18n.tr("Personalization"),
            section: "wallpaper"
        },
        {
            label: I18n.tr("Disable Built-in Wallpapers"),
            keywords: ["external", "swww", "hyprpaper", "swaybg"],
            tabIndex: 0,
            icon: "wallpaper",
            category: I18n.tr("Personalization"),
            section: "disableWallpaper"
        },
        {
            label: I18n.tr("Duplicate Wallpaper with Blur"),
            keywords: ["blur", "layer", "niri", "compositor"],
            tabIndex: 0,
            icon: "blur_on",
            category: I18n.tr("Personalization"),
            section: "blurWallpaper",
            condition: () => CompositorService.isNiri
        },
        {
            label: I18n.tr("Time Format"),
            keywords: ["clock", "12h", "24h", "am", "pm"],
            tabIndex: 1,
            icon: "schedule",
            category: I18n.tr("Time & Weather"),
            section: "timeFormat"
        },
        {
            label: I18n.tr("Date Format"),
            keywords: ["calendar", "day", "month", "year"],
            tabIndex: 1,
            icon: "calendar_today",
            category: I18n.tr("Time & Weather"),
            section: "dateFormat"
        },
        {
            label: I18n.tr("Weather"),
            keywords: ["city", "temperature", "forecast", "location"],
            tabIndex: 1,
            icon: "thermostat",
            category: I18n.tr("Time & Weather"),
            section: "weather"
        },
        {
            label: I18n.tr("Temperature Unit"),
            keywords: ["celsius", "fahrenheit", "weather"],
            tabIndex: 1,
            icon: "thermostat",
            category: I18n.tr("Time & Weather"),
            section: "weather"
        },
        {
            label: I18n.tr("Keyboard Shortcuts"),
            keywords: ["keybinds", "hotkeys", "bindings"],
            tabIndex: 2,
            icon: "keyboard",
            category: I18n.tr("Keyboard Shortcuts"),
            section: "keybinds",
            condition: () => KeybindsService.available
        },
        {
            label: I18n.tr("Bar Configurations"),
            keywords: ["panel", "multiple", "dankbar", "manage"],
            tabIndex: 3,
            icon: "dashboard",
            category: I18n.tr("Dank Bar"),
            section: "barConfigurations"
        },
        {
            label: I18n.tr("Bar Position"),
            keywords: ["top", "bottom", "left", "right", "panel"],
            tabIndex: 3,
            icon: "vertical_align_center",
            category: I18n.tr("Dank Bar"),
            section: "barPosition"
        },
        {
            label: I18n.tr("Display Assignment"),
            keywords: ["monitor", "screen", "display"],
            tabIndex: 3,
            icon: "display_settings",
            category: I18n.tr("Dank Bar"),
            section: "barDisplay"
        },
        {
            label: I18n.tr("Bar Visibility"),
            keywords: ["bar", "hide", "show", "auto-hide", "panel"],
            tabIndex: 3,
            icon: "visibility_off",
            category: I18n.tr("Dank Bar"),
            section: "barVisibility"
        },
        {
            label: I18n.tr("Bar Spacing"),
            keywords: ["gap", "margin", "padding", "spacing"],
            tabIndex: 3,
            icon: "space_bar",
            category: I18n.tr("Dank Bar"),
            section: "barSpacing"
        },
        {
            label: I18n.tr("Corners & Background"),
            keywords: ["rounded", "radius", "shape", "transparent"],
            tabIndex: 3,
            icon: "rounded_corner",
            category: I18n.tr("Dank Bar"),
            section: "barCorners"
        },
        {
            label: I18n.tr("Bar Transparency"),
            keywords: ["opacity", "alpha", "translucent"],
            tabIndex: 3,
            icon: "opacity",
            category: I18n.tr("Dank Bar"),
            section: "barTransparency"
        },
        {
            label: I18n.tr("Workspaces"),
            keywords: ["workspace", "label", "icon", "desktop"],
            tabIndex: 4,
            icon: "view_module",
            category: I18n.tr("Workspaces"),
            section: "workspaceSettings"
        },
        {
            label: I18n.tr("Workspace Icons"),
            keywords: ["workspace", "named", "icon"],
            tabIndex: 4,
            icon: "label",
            category: I18n.tr("Workspaces"),
            section: "workspaceIcons"
        },
        {
            label: I18n.tr("Dock Position"),
            keywords: ["taskbar", "bottom", "left", "right"],
            tabIndex: 5,
            icon: "dock_to_bottom",
            category: I18n.tr("Dock"),
            section: "dockPosition"
        },
        {
            label: I18n.tr("Dock Visibility"),
            keywords: ["hide", "show", "auto-hide", "taskbar"],
            tabIndex: 5,
            icon: "visibility_off",
            category: I18n.tr("Dock"),
            section: "dockVisibility"
        },
        {
            label: I18n.tr("Dock Behavior"),
            keywords: ["pinned", "apps", "click"],
            tabIndex: 5,
            icon: "apps",
            category: I18n.tr("Dock"),
            section: "dockBehavior"
        },
        {
            label: I18n.tr("Dock Sizing"),
            keywords: ["icon", "size", "scale"],
            tabIndex: 5,
            icon: "photo_size_select_large",
            category: I18n.tr("Dock"),
            section: "dockSizing"
        },
        {
            label: I18n.tr("Dock Spacing"),
            keywords: ["gap", "margin", "padding"],
            tabIndex: 5,
            icon: "space_bar",
            category: I18n.tr("Dock"),
            section: "dockSpacing"
        },
        {
            label: I18n.tr("Dock Transparency"),
            keywords: ["opacity", "alpha"],
            tabIndex: 5,
            icon: "opacity",
            category: I18n.tr("Dock"),
            section: "dockTransparency"
        },
        {
            label: I18n.tr("Dock Border"),
            keywords: ["outline", "stroke"],
            tabIndex: 5,
            icon: "border_style",
            category: I18n.tr("Dock"),
            section: "dockBorder"
        },
        {
            label: I18n.tr("Network"),
            keywords: ["wifi", "ethernet", "internet", "connection"],
            tabIndex: 7,
            icon: "wifi",
            category: I18n.tr("Network"),
            section: "network",
            condition: () => !NetworkService.usingLegacy
        },
        {
            label: I18n.tr("CUPS Print Server"),
            keywords: ["cups", "print", "paper", "printer"],
            tabIndex: 8,
            icon: "print",
            category: I18n.tr("System"),
            section: "printers",
            condition: () => CupsService.cupsAvailable
        },
        {
            label: I18n.tr("Launcher Logo"),
            keywords: ["app", "button", "icon", "drawer"],
            tabIndex: 9,
            icon: "grid_view",
            category: I18n.tr("Launcher"),
            section: "launcherLogo"
        },
        {
            label: I18n.tr("Launch Prefix"),
            keywords: ["terminal", "command", "prefix"],
            tabIndex: 9,
            icon: "terminal",
            category: I18n.tr("Launcher"),
            section: "launchPrefix"
        },
        {
            label: I18n.tr("Sorting & Layout"),
            keywords: ["grid", "list", "sort", "order"],
            tabIndex: 9,
            icon: "sort_by_alpha",
            category: I18n.tr("Launcher"),
            section: "launcherSorting"
        },
        {
            label: I18n.tr("Recent Apps"),
            keywords: ["history", "recent", "apps"],
            tabIndex: 9,
            icon: "history",
            category: I18n.tr("Launcher"),
            section: "recentApps"
        },
        {
            label: I18n.tr("Theme Color"),
            keywords: ["palette", "accent", "primary", "appearance"],
            tabIndex: 10,
            icon: "palette",
            category: I18n.tr("Theme & Colors"),
            section: "themeColor"
        },
        {
            label: I18n.tr("Color Mode"),
            keywords: ["light", "dark", "mode", "appearance"],
            tabIndex: 10,
            icon: "contrast",
            category: I18n.tr("Theme & Colors"),
            section: "colorMode"
        },
        {
            label: I18n.tr("Widget Styling"),
            keywords: ["colorful", "default", "appearance", "transparency"],
            tabIndex: 10,
            icon: "widgets",
            category: I18n.tr("Theme & Colors"),
            section: "widgetStyling"
        },
        {
            label: I18n.tr("Niri Layout Overrides"),
            keywords: ["gaps", "radius", "window", "niri"],
            tabIndex: 10,
            icon: "crop_square",
            category: I18n.tr("Theme & Colors"),
            section: "niriLayout",
            condition: () => CompositorService.isNiri
        },
        {
            label: I18n.tr("Modal Background"),
            keywords: ["overlay", "dim", "popup", "modal", "darken"],
            tabIndex: 10,
            icon: "brightness_low",
            category: I18n.tr("Theme & Colors"),
            section: "modalBackground"
        },
        {
            label: I18n.tr("Applications"),
            keywords: ["dark", "system", "xdg", "portal", "terminal"],
            tabIndex: 10,
            icon: "apps",
            category: I18n.tr("Theme & Colors"),
            section: "applications"
        },
        {
            label: I18n.tr("Matugen Templates"),
            keywords: ["gtk", "qt", "firefox", "theming"],
            tabIndex: 10,
            icon: "auto_awesome",
            category: I18n.tr("Theme & Colors"),
            section: "matugenTemplates"
        },
        {
            label: I18n.tr("Icon Theme"),
            keywords: ["icons", "system", "adwaita"],
            tabIndex: 10,
            icon: "palette",
            category: I18n.tr("Theme & Colors"),
            section: "iconTheme"
        },
        {
            label: I18n.tr("System App Theming"),
            keywords: ["gtk", "qt", "application", "theming"],
            tabIndex: 10,
            icon: "settings",
            category: I18n.tr("Theme & Colors"),
            section: "systemAppTheming"
        },
        {
            label: I18n.tr("Lock Screen Layout"),
            keywords: ["lock", "power", "security", "layout"],
            tabIndex: 11,
            icon: "lock",
            category: I18n.tr("Lock Screen"),
            section: "lockLayout"
        },
        {
            label: I18n.tr("Lock Screen Behaviour"),
            keywords: ["dbus", "systemd", "lock", "behavior", "fingerprint"],
            tabIndex: 11,
            icon: "lock",
            category: I18n.tr("Lock Screen"),
            section: "lockBehavior"
        },
        {
            label: I18n.tr("Lock Screen Display"),
            keywords: ["display", "screen", "oled", "dpms", "monitor"],
            tabIndex: 11,
            icon: "monitor",
            category: I18n.tr("Lock Screen"),
            section: "lockDisplay"
        },
        {
            label: I18n.tr("Plugins"),
            keywords: ["extension", "addon", "widget"],
            tabIndex: 12,
            icon: "extension",
            category: I18n.tr("Plugins"),
            section: "plugins"
        },
        {
            label: I18n.tr("About"),
            keywords: ["version", "info", "credits"],
            tabIndex: 13,
            icon: "info",
            category: I18n.tr("About"),
            section: "about"
        },
        {
            label: I18n.tr("Typography"),
            keywords: ["font", "family", "text", "typeface"],
            tabIndex: 14,
            icon: "text_fields",
            category: I18n.tr("Typography & Motion"),
            section: "typography"
        },
        {
            label: I18n.tr("Animation Speed"),
            keywords: ["motion", "speed", "transition", "duration"],
            tabIndex: 14,
            icon: "animation",
            category: I18n.tr("Typography & Motion"),
            section: "animationSpeed"
        },
        {
            label: I18n.tr("System Sounds"),
            keywords: ["audio", "effects", "notification", "theme", "volume"],
            tabIndex: 15,
            icon: "volume_up",
            category: I18n.tr("Sounds"),
            section: "systemSounds",
            condition: () => AudioService.soundsAvailable
        },
        {
            label: I18n.tr("Media Player"),
            keywords: ["mpris", "music", "controls", "style", "scroll"],
            tabIndex: 16,
            icon: "music_note",
            category: I18n.tr("Media Player"),
            section: "mediaPlayer"
        },
        {
            label: I18n.tr("Notification Popups"),
            keywords: ["toast", "alert", "message", "position"],
            tabIndex: 17,
            icon: "notifications",
            category: I18n.tr("Notifications"),
            section: "notificationPopups"
        },
        {
            label: I18n.tr("Do Not Disturb"),
            keywords: ["dnd", "quiet", "silent", "notification"],
            tabIndex: 17,
            icon: "notifications_off",
            category: I18n.tr("Notifications"),
            section: "doNotDisturb"
        },
        {
            label: I18n.tr("Notification Timeouts"),
            keywords: ["duration", "dismiss", "popup", "low", "normal", "critical"],
            tabIndex: 17,
            icon: "timer",
            category: I18n.tr("Notifications"),
            section: "notificationTimeouts"
        },
        {
            label: I18n.tr("On-screen Displays"),
            keywords: ["osd", "volume", "brightness", "indicator", "position"],
            tabIndex: 18,
            icon: "tune",
            category: I18n.tr("On-screen Displays"),
            section: "osd"
        },
        {
            label: I18n.tr("Running Apps"),
            keywords: ["taskbar", "window", "active", "style"],
            tabIndex: 19,
            icon: "apps",
            category: I18n.tr("Running Apps"),
            section: "runningApps",
            condition: () => CompositorService.isNiri || CompositorService.isHyprland
        },
        {
            label: I18n.tr("System Updater"),
            keywords: ["package", "update", "upgrade", "widget"],
            tabIndex: 20,
            icon: "refresh",
            category: I18n.tr("System Updater"),
            section: "systemUpdater"
        },
        {
            label: I18n.tr("Idle Settings"),
            keywords: ["suspend", "hibernate", "idle", "timeout", "lock", "dpms"],
            tabIndex: 21,
            icon: "schedule",
            category: I18n.tr("Power & Sleep"),
            section: "idleSettings"
        },
        {
            label: I18n.tr("Power Menu"),
            keywords: ["shutdown", "reboot", "logout", "layout"],
            tabIndex: 21,
            icon: "power_settings_new",
            category: I18n.tr("Power & Sleep"),
            section: "powerMenu"
        },
        {
            label: I18n.tr("Power Confirmation"),
            keywords: ["hold", "confirm", "safety"],
            tabIndex: 21,
            icon: "check_circle",
            category: I18n.tr("Power & Sleep"),
            section: "powerConfirmation"
        },
        {
            label: I18n.tr("Custom Power Actions"),
            keywords: ["lock", "logout", "suspend", "script", "command"],
            tabIndex: 21,
            icon: "developer_mode",
            category: I18n.tr("Power & Sleep"),
            section: "customPowerActions"
        },
        {
            label: I18n.tr("Power Advanced"),
            keywords: ["battery", "charge", "limit", "inhibit", "caffeine"],
            tabIndex: 21,
            icon: "tune",
            category: I18n.tr("Power & Sleep"),
            section: "powerAdvanced"
        },
        {
            label: I18n.tr("Bar Widgets"),
            keywords: ["dankbar", "customize", "order", "left", "center", "right"],
            tabIndex: 22,
            icon: "widgets",
            category: I18n.tr("Dank Bar"),
            section: "widgets"
        },
        {
            label: I18n.tr("Clipboard"),
            keywords: ["copy", "paste", "cliphist", "history"],
            tabIndex: 23,
            icon: "content_paste",
            category: I18n.tr("System"),
            section: "clipboard",
            condition: () => DMSService.isConnected && DMSService.apiVersion >= 23
        },
        {
            label: I18n.tr("Monitor Configuration"),
            keywords: ["display", "resolution", "refresh"],
            tabIndex: 24,
            icon: "display_settings",
            category: I18n.tr("Displays"),
            section: "displayConfig"
        },
        {
            label: I18n.tr("Gamma Control"),
            keywords: ["brightness", "color", "temperature", "night", "blue"],
            tabIndex: 25,
            icon: "brightness_6",
            category: I18n.tr("Displays"),
            section: "gammaControl"
        },
        {
            label: I18n.tr("Display Widgets"),
            keywords: ["monitor", "position", "screen"],
            tabIndex: 26,
            icon: "widgets",
            category: I18n.tr("Displays"),
            section: "displayWidgets"
        },
        {
            label: I18n.tr("Desktop Widgets"),
            keywords: ["clock", "monitor", "conky", "desktop"],
            tabIndex: 27,
            icon: "widgets",
            category: I18n.tr("Desktop Widgets"),
            section: "desktopWidgets"
        }
    ]

    function search(text) {
        query = text;
        if (!text || text.length < 2) {
            results = [];
            return;
        }

        const queryLower = text.toLowerCase().trim();
        const queryWords = queryLower.split(/\s+/).filter(w => w.length > 0);
        const scored = [];

        for (const item of settingsIndex) {
            if (item.condition && !item.condition())
                continue;

            const labelLower = item.label.toLowerCase();
            const categoryLower = item.category.toLowerCase();
            let score = 0;

            if (labelLower === queryLower) {
                score = 10000;
            } else if (labelLower.startsWith(queryLower)) {
                score = 5000;
            } else if (labelLower.includes(queryLower)) {
                score = 1000;
            } else if (categoryLower.includes(queryLower)) {
                score = 500;
            }

            if (score === 0) {
                for (const keyword of item.keywords) {
                    if (keyword.startsWith(queryLower)) {
                        score = Math.max(score, 800);
                        break;
                    }
                    if (keyword.includes(queryLower)) {
                        score = Math.max(score, 400);
                    }
                }
            }

            if (score === 0 && queryWords.length > 1) {
                let allMatch = true;
                for (const word of queryWords) {
                    const inLabel = labelLower.includes(word);
                    const inKeywords = item.keywords.some(k => k.includes(word));
                    const inCategory = categoryLower.includes(word);
                    if (!inLabel && !inKeywords && !inCategory) {
                        allMatch = false;
                        break;
                    }
                }
                if (allMatch)
                    score = 300;
            }

            if (score > 0) {
                scored.push({
                    item: item,
                    score: score
                });
            }
        }

        scored.sort((a, b) => b.score - a.score);
        results = scored.slice(0, 15).map(s => s.item);
    }

    function clear() {
        query = "";
        results = [];
    }
}
