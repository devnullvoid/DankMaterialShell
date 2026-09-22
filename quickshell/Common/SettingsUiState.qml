pragma Singleton

import QtQuick
import Quickshell
import qs.Common

Singleton {
    id: root

    property string selectedBarId: "default"
    property string selectedWallpaperScreen: ""
    // Which dock the Dock hub pages are editing.
    property string dockHubSelection: ""
    // Set only while the widget settings page is showing a dock-hosted widget; empty means bar-hosted.
    property string selectedDockId: ""
    property string selectedDockWidgetId: ""
    property string selectedDesktopWidgetId: ""
    property string selectedWidgetSection: ""
    property int selectedWidgetIndex: -1
    property string selectedWidgetTitle: ""
    property string selectedWidgetDescription: ""
    property string selectedWidgetIcon: ""
    readonly property bool selectedBarIsDot: SettingsData.isDotBarConfig(SettingsData.getBarConfig(selectedBarId))
    readonly property string selectedIslandTitle: selectedBarIsDot ? I18n.tr("Dot", "bar layout: free-floating dot that opens island activities") : I18n.tr("Island", "noun, dank island feature, settings page and layout option")
    readonly property string selectedIslandHint: selectedBarIsDot ? I18n.tr("Popups, expand, badge", "settings hub hint for the dot island page") : I18n.tr("Home layout, notifications, satellites")

    function normalizeSelectedBar() {
        if (SettingsData.getBarConfig(selectedBarId))
            return;
        selectedBarId = SettingsData.barConfigs[0]?.id ?? "default";
    }

    Connections {
        target: SettingsData

        function onBarConfigsChanged() {
            root.normalizeSelectedBar();
        }
    }
}
