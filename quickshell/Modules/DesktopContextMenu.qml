pragma ComponentBehavior: Bound

import Qt.labs.folderlistmodel
import QtQuick
import qs.Common
import qs.Services
import qs.DCommon.Widgets
import qs.Widgets

DContextMenu {
    id: root

    property bool settingsExpanded: false
    property var stripPaths: []

    readonly property int stripCount: 4
    readonly property real stripUnit: Theme.listItemHeight
    readonly property string currentWallpaper: {
        if (SessionData.perMonitorWallpaper && targetScreen)
            return SessionData.getMonitorWallpaper(targetScreen.name) || "";
        return SessionData.wallpaperPath || "";
    }
    readonly property string wallpaperDir: currentWallpaper.startsWith("/") ? currentWallpaper.substring(0, currentWallpaper.lastIndexOf("/")) : ""

    layerNamespace: "dms:desktop-context-menu"
    keyboardNavigable: true
    itemHeight: Theme.listItemHeight
    itemRadius: Theme.cornerRadiusFull
    itemFontSize: Theme.fontSizeMedium
    containerRadius: Theme.cornerRadiusXL
    minMenuWidth: stripUnit * (stripCount + 1) + Theme.spacingS * (stripCount + 1)

    menuItems: {
        const items = [
            {
                type: "item",
                icon: "dashboard_customize",
                text: I18n.tr("Add widget"),
                action: () => DesktopWidgetRegistry.startEditing(root.targetScreen, true)
            },
            {
                type: "item",
                icon: "extension",
                text: I18n.tr("Plugins"),
                action: () => PopoutService.openSettingsWithTab("plugins")
            },
            {
                type: "item",
                icon: "palette",
                text: I18n.tr("Wallpaper & colors"),
                action: () => PopoutService.openSettingsWithTab("personalization")
            }
        ];
        if (wallpaperDir)
            items.push({
                type: "component",
                component: wallpaperStrip,
                height: stripUnit * 2 + Theme.spacingS
            });
        return items.concat([settingsEntry, allSettingsEntry, desktopWidgetsEntry, displaysEntry]);
    }

    component MenuEntry: QtObject {
        property string type: "item"
        property string icon
        property string text
        property string trailingIcon
        property bool keepOpen
        property bool hidden
        property var action
    }

    MenuEntry {
        id: settingsEntry
        icon: "settings"
        text: I18n.tr("Settings")
        trailingIcon: root.settingsExpanded ? "expand_less" : "expand_more"
        keepOpen: true
        action: () => root.settingsExpanded = !root.settingsExpanded
    }

    MenuEntry {
        id: allSettingsEntry
        icon: "tune"
        text: I18n.tr("All settings")
        hidden: !root.settingsExpanded
        action: () => PopoutService.openSettings()
    }

    MenuEntry {
        id: desktopWidgetsEntry
        icon: "widgets"
        text: I18n.tr("Desktop widgets")
        hidden: !root.settingsExpanded
        action: () => PopoutService.openSettingsWithTab("desktop_widgets")
    }

    MenuEntry {
        id: displaysEntry
        icon: "monitor"
        text: I18n.tr("Displays")
        hidden: !root.settingsExpanded
        action: () => PopoutService.openSettingsWithTab("displays")
    }

    onBackdropRightClicked: (x, y) => open(targetScreen, x, y, false)
    onRenderActiveChanged: {
        if (renderActive)
            return;
        settingsExpanded = false;
        stripPaths = [];
    }
    onWallpaperDirChanged: stripPaths = []

    function setWallpaper(path) {
        if (SessionData.perMonitorWallpaper && targetScreen) {
            SessionData.setMonitorWallpaper(targetScreen.name, path);
            SessionData.setMonitorCyclingFolderPath(targetScreen.name, "");
            return;
        }
        SessionData.setWallpaper(path);
        SessionData.wallpaperCyclingFolderPath = "";
        SessionData.saveSettings();
    }

    function loadStrip(model) {
        const paths = [];
        for (let i = 0; i < model.count; i++)
            paths.push(model.get(i, "filePath"));
        const start = Math.max(0, paths.indexOf(currentWallpaper));
        stripPaths = paths.slice(start).concat(paths.slice(0, start));
    }

    Loader {
        active: root.renderActive && root.wallpaperDir !== ""

        sourceComponent: Item {
            FolderListModel {
                id: folderModel
                showDirs: false
                showDotAndDotDot: false
                caseSensitive: false
                nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.bmp", "*.gif", "*.webp", "*.jxl", "*.avif", "*.heif", "*.exr", "*.svg"]
                folder: "file://" + root.wallpaperDir.split("/").map(s => encodeURIComponent(s)).join("/")
                onStatusChanged: {
                    if (folderModel.status === FolderListModel.Ready)
                        root.loadStrip(folderModel);
                }
            }
        }
    }

    Component {
        id: wallpaperStrip

        Item {
            DCarousel {
                y: Theme.spacingXS
                width: parent.width
                height: root.stripUnit * 2
                preferredItemWidth: width / 2
                model: root.stripPaths

                delegate: DCarouselItem {
                    id: thumb

                    required property string modelData
                    readonly property bool current: thumb.modelData === root.currentWallpaper

                    onClicked: {
                        if (!thumb.current)
                            root.setWallpaper(thumb.modelData);
                    }

                    CachingImage {
                        anchors.fill: parent
                        imagePath: thumb.modelData
                        maxCacheSize: 256
                        animate: false
                    }

                    Rectangle {
                        anchors.centerIn: parent
                        width: Theme.iconSizeLarge
                        height: width
                        radius: width / 2
                        color: Theme.primaryContainer
                        scale: thumb.current ? 1 : 0
                        visible: scale > 0

                        Behavior on scale {
                            NumberAnimation {
                                duration: SettingsData.reduceMotion ? 0 : Theme.expressiveDurations.expressiveFastSpatial
                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: Theme.expressiveCurves.expressiveFastSpatial
                            }
                        }

                        DIcon {
                            anchors.centerIn: parent
                            name: "check"
                            size: Theme.iconSizeMedium
                            color: Theme.onPrimaryContainer
                        }
                    }
                }
            }
        }
    }
}
