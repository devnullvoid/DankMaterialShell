import QtQuick
import QtQuick.Effects
import Quickshell.Widgets
import qs.Common
import qs.Services
import qs.DCommon.Widgets

DCard {
    id: root

    property string brand: "DMS"
    property string accent: {
        const semver = ShellVersionService.semverVersion.replace(/^v/, "");
        const base = semver.match(/^\d+\.\d+/);
        return base ? base[0] : semver || SystemUpdateService.shellRunning.replace(/^v/, "");
    }
    property string caption: ShellVersionService.shellCodename.toUpperCase()
    default property alias extra: heroColumn.data

    width: parent?.width ?? 0
    height: heroColumn.implicitHeight + SettingsMetrics.pagePaddingV * 2
    restRadius: Theme.groupedListOuterRadius
    color: SettingsMetrics.rowColor
    pad: 0
    showFocusRing: false

    // Clips the image only: text inside a ClippingRectangle is drawn from a texture and blurs at fractional scales.
    ClippingRectangle {
        anchors.fill: parent
        radius: root.bodyRadius
        color: "transparent"

        Image {
            anchors.fill: parent
            source: "file://" + Theme.shellDir + "/assets/release-banner.svg"
            fillMode: Image.Stretch
            asynchronous: true
            cache: false
            sourceSize.width: SettingsMetrics.windowWidth
            opacity: Theme.pendingOpacity
            layer.enabled: true
            layer.effect: MultiEffect {
                colorization: 1
                colorizationColor: Theme.primary
            }
        }
    }

    Column {
        id: heroColumn
        anchors.centerIn: parent
        width: parent.width - SettingsMetrics.heroPadding * 2
        spacing: Theme.spacingS

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Theme.spacingS

            StyledText {
                id: brandText
                text: root.brand
                font.pixelSize: Theme.fontSizeDisplayLarge
                font.weight: Theme.fontWeightBold
                color: Theme.surfaceText
            }

            StyledText {
                text: root.accent
                font: brandText.font
                color: Theme.primary
            }
        }

        StyledText {
            width: parent.width
            visible: root.caption !== ""
            text: root.caption
            font.pixelSize: Theme.fontSizeMedium
            font.weight: Theme.fontWeightMedium
            color: Theme.primary
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
        }
    }
}
