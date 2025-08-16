import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.Common
import qs.Services
import qs.Widgets

PanelWindow {
    id: root

    property var modelData
    property bool inhibitorPopupVisible: false

    function show() {
        root.inhibitorPopupVisible = true
        hideTimer.restart()
    }

    screen: modelData
    visible: inhibitorPopupVisible
    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    color: "transparent"

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    Timer {
        id: hideTimer

        interval: 2000
        repeat: false
        onTriggered: {
            root.inhibitorPopupVisible = false
        }
    }

    Connections {
        function onInhibitorChanged() {
            root.show()
        }

        target: IdleInhibitorService
    }

    Rectangle {
        id: inhibitorPopup

        width: Theme.iconSize + Theme.spacingS * 2
        height: Theme.iconSize + Theme.spacingS * 2
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Theme.spacingM
        color: Theme.popupBackground()
        radius: Theme.cornerRadius
        border.color: Qt.rgba(Theme.outline.r, Theme.outline.g,
                              Theme.outline.b, 0.08)
        border.width: 1
        opacity: root.inhibitorPopupVisible ? 1 : 0
        scale: root.inhibitorPopupVisible ? 1 : 0.9
        layer.enabled: true

        DankIcon {
            id: inhibitorContent

            anchors.centerIn: parent
            name: IdleInhibitorService.idleInhibited ? "motion_sensor_active" : "motion_sensor_idle"
            size: Theme.iconSize
            color: IdleInhibitorService.idleInhibited ? Theme.primary : Theme.outline
        }

        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowHorizontalOffset: 0
            shadowVerticalOffset: 4
            shadowBlur: 0.8
            shadowColor: Qt.rgba(0, 0, 0, 0.3)
            shadowOpacity: 0.3
        }

        transform: Translate {
            y: root.inhibitorPopupVisible ? 0 : 20
        }

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.mediumDuration
                easing.type: Theme.emphasizedEasing
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: Theme.mediumDuration
                easing.type: Theme.emphasizedEasing
            }
        }

        Behavior on transform {
            PropertyAnimation {
                duration: Theme.mediumDuration
                easing.type: Theme.emphasizedEasing
            }
        }
    }

    mask: Region {
        item: inhibitorPopup
    }
}