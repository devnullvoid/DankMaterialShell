import QtQuick
import Quickshell.Widgets
import qs.Common
import qs.DCommon.Widgets

Item {
    id: root

    default property alias content: contentColumn.data
    property real paddingV: Theme.spacingXL + Theme.spacingS
    property real accentSize: Theme.buttonHeightM * 1.6
    property Component backdrop: defaultBackdrop

    readonly property real availableWidth: width - Theme.spacingXL * 2

    height: contentColumn.implicitHeight + paddingV * 2

    component Decoration: DMaterialShape {
        respectThemeShape: false
    }

    Component {
        id: defaultBackdrop

        Item {
            Decoration {
                width: root.height * 1.15
                height: width
                x: parent.width - width * 0.62
                y: -height * 0.42
                shape: "cookie12"
                color: Theme.withAlpha(Theme.primary, Theme.tonalTintAlpha)
                rotation: 12
            }

            Decoration {
                width: root.height * 0.8
                height: width
                x: -width * 0.38
                y: parent.height - height * 0.58
                shape: "softBurst"
                color: Theme.withAlpha(Theme.tertiary, Theme.tonalTintAlpha)
                rotation: -8
            }

            Decoration {
                width: root.accentSize * 0.6
                height: width
                x: parent.width * 0.12
                y: root.paddingV * 0.6
                shape: "flower"
                color: Theme.withAlpha(Theme.onPrimaryContainer, Theme.stateLayerHover)
            }

            Decoration {
                width: root.accentSize * 0.75
                height: width
                x: parent.width * 0.8
                y: parent.height - height - root.paddingV * 0.5
                shape: "pill"
                color: Theme.withAlpha(Theme.secondary, Theme.tonalTintAlpha)
                rotation: -40
            }
        }
    }

    ClippingRectangle {
        anchors.fill: parent
        radius: Theme.cornerRadiusXL
        color: Theme.primaryContainer

        Loader {
            anchors.fill: parent
            sourceComponent: root.backdrop
        }
    }

    Column {
        id: contentColumn
        anchors.centerIn: parent
        width: root.availableWidth
        spacing: Theme.spacingM
    }
}
