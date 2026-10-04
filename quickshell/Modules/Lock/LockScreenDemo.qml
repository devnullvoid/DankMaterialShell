pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Services

Scope {
    id: root
    readonly property var log: Log.scoped("LockScreenDemo")

    property bool demoActive: false

    function showDemo(): void {
        log.debug("Showing lock screen demo");
        demoActive = true;
    }

    function hideDemo(): void {
        log.debug("Hiding lock screen demo");
        demoActive = false;
    }

    Variants {
        model: root.demoActive ? Quickshell.screens : []

        PanelWindow {
            id: demoWindow

            required property var modelData

            screen: modelData
            visible: true

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            WlrLayershell.namespace: "dms:lock-demo"
            WlrLayershell.layer: WlrLayershell.Overlay
            WlrLayershell.exclusiveZone: -1
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            color: "transparent"

            LockScreenContent {
                anchors.fill: parent
                demoMode: true
                screenName: demoWindow.screen?.name ?? ""
                onUnlockRequested: root.hideDemo()
            }
        }
    }
}
