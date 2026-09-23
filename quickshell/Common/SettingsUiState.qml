pragma Singleton

import QtQuick
import Quickshell
import qs.Common

Singleton {
    id: root

    property string selectedBarId: "default"
    readonly property string selectedBarTitle: {
        SettingsData.barConfigs;
        return SettingsData.getBarConfig(selectedBarId)?.name || I18n.tr("Bar", "fallback name for an unnamed bar");
    }
    readonly property string selectedBarGeneralTitle: selectedBarTitle + " • " + I18n.tr("General", "adjective, settings page and section title for general options")
    readonly property string selectedBarAppearanceTitle: selectedBarTitle + " • " + I18n.tr("Appearance", "settings page and section title for visual options")
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

    // The dot has its own page, so bar selection never lands on it.
    function normalizeSelectedBar() {
        const config = SettingsData.getBarConfig(selectedBarId);
        if (config && !SettingsData.isDotBarConfig(config))
            return;
        selectedBarId = SettingsData.barConfigs.find(cfg => !SettingsData.isDotBarConfig(cfg))?.id ?? "default";
    }

    Connections {
        target: SettingsData

        function onBarConfigsChanged() {
            root.normalizeSelectedBar();
        }
    }
}
