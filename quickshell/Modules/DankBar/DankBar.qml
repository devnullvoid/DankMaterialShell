import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell
import Quickshell.Hyprland
import Quickshell.I3
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Services.Notifications
import Quickshell.Services.SystemTray
import Quickshell.Wayland
import Quickshell.Widgets
import qs.Common
import qs.Modules
import qs.Modules.DankBar.Widgets
import qs.Modules.DankBar.Popouts
import qs.Services
import qs.Widgets

Item {
    id: root

    signal colorPickerRequested

    property alias barVariants: barVariants
    property var hyprlandOverviewLoader: null
    property bool systemTrayMenuOpen: false

    function triggerControlCenterOnFocusedScreen() {
        let focusedScreenName = ""
        if (CompositorService.isHyprland && Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.monitor) {
            focusedScreenName = Hyprland.focusedWorkspace.monitor.name
        } else if (CompositorService.isNiri && NiriService.currentOutput) {
            focusedScreenName = NiriService.currentOutput
        } else if (CompositorService.isSway) {
            const focusedWs = I3.workspaces?.values?.find(ws => ws.focused === true)
            focusedScreenName = focusedWs?.monitor?.name || ""
        }

        if (!focusedScreenName && barVariants.instances.length > 0) {
            const firstBar = barVariants.instances[0]
            firstBar.triggerControlCenter()
            return true
        }

        for (var i = 0; i < barVariants.instances.length; i++) {
            const barInstance = barVariants.instances[i]
            if (barInstance.modelData && barInstance.modelData.name === focusedScreenName) {
                barInstance.triggerControlCenter()
                return true
            }
        }
        return false
    }

    function triggerWallpaperBrowserOnFocusedScreen() {
        let focusedScreenName = ""
        if (CompositorService.isHyprland && Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.monitor) {
            focusedScreenName = Hyprland.focusedWorkspace.monitor.name
        } else if (CompositorService.isNiri && NiriService.currentOutput) {
            focusedScreenName = NiriService.currentOutput
        } else if (CompositorService.isSway) {
            const focusedWs = I3.workspaces?.values?.find(ws => ws.focused === true)
            focusedScreenName = focusedWs?.monitor?.name || ""
        }

        if (!focusedScreenName && barVariants.instances.length > 0) {
            const firstBar = barVariants.instances[0]
            firstBar.triggerWallpaperBrowser()
            return true
        }

        for (var i = 0; i < barVariants.instances.length; i++) {
            const barInstance = barVariants.instances[i]
            if (barInstance.modelData && barInstance.modelData.name === focusedScreenName) {
                barInstance.triggerWallpaperBrowser()
                return true
            }
        }
        return false
    }

    Variants {
        id: barVariants
        model: SettingsData.getFilteredScreens("dankBar")

        delegate: DankBarWindow {
            rootWindow: root
        }
    }
}
