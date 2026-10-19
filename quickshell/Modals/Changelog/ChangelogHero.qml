import QtQuick
import qs.Common
import qs.Services
import qs.DCommon.Widgets
import qs.Widgets

ShapeHero {
    id: root

    property string symbol: ""
    property int atomicNumber: 0
    property string atomicMass: ""
    property string remainder: ""

    readonly property real lockupBaseSize: Theme.fontSizeDisplayLarge * 0.8
    readonly property real lockupScale: Math.min(1, availableWidth / Math.max(1, lockupBaseSize * 1.6 + Theme.spacingS + remainderMetrics.width))
    readonly property real lockupSize: lockupBaseSize * lockupScale
    readonly property real tileSize: lockupSize * 1.6

    accentSize: tileSize
    paddingV: Theme.spacingXL

    StyledTextMetrics {
        id: remainderMetrics
        text: root.remainder
        font.pixelSize: root.lockupBaseSize
        font.weight: Theme.fontWeightBold
    }

    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Theme.spacingS

        Rectangle {
            id: tile
            width: root.tileSize
            height: width
            radius: Theme.cornerRadiusS
            color: Theme.primary
            anchors.verticalCenter: parent.verticalCenter

            StyledText {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.margins: tile.width * 0.07
                text: root.atomicNumber
                font.pixelSize: tile.width * 0.15
                font.weight: Theme.fontWeightMedium
                color: Theme.onPrimary
            }

            StyledText {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: tile.width * 0.03
                text: root.symbol
                font.pixelSize: root.lockupSize * 0.9
                font.weight: Theme.fontWeightBold
                color: Theme.onPrimary
            }

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: tile.width * 0.05
                text: root.atomicMass
                font.pixelSize: tile.width * 0.11
                color: Theme.onPrimary
            }
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: root.remainder
            font.pixelSize: root.lockupSize
            font.weight: Theme.fontWeightBold
            color: Theme.onPrimaryContainer
        }
    }

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        width: versionText.implicitWidth + Theme.spacingL * 2
        height: Theme.buttonHeightXXS
        radius: Theme.fullRadius(width, height)
        color: Theme.primary

        StyledText {
            id: versionText
            anchors.centerIn: parent
            text: "dms " + ChangelogService.currentVersion
            font.pixelSize: Theme.fontSizeMedium
            font.weight: Theme.fontWeightBold
            color: Theme.onPrimary
        }
    }
}
