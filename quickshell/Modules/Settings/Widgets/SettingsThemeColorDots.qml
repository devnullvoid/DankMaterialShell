import QtQuick
import qs.Common
import qs.Widgets
import "../../../Common/ThemePalette.js" as ThemePalette

Item {
    id: root

    readonly property var colorList: ["blue", "purple", "green", "orange", "red", "cyan", "pink", "amber", "coral", "monochrome"]
    readonly property int dotSize: Theme.minimumTouchTargetSize

    implicitHeight: grid.implicitHeight + Math.ceil(dotSize * 0.05)

    Grid {
        id: grid
        columns: Math.ceil(root.colorList.length / 2)
        rowSpacing: Theme.spacingS
        columnSpacing: Theme.spacingS
        anchors.horizontalCenter: parent.horizontalCenter

        Repeater {
            model: root.colorList

            Rectangle {
                required property string modelData
                readonly property var colors: Theme.getThemeColors(modelData)
                readonly property var palette: ThemePalette.pick(colors)
                readonly property bool isActive: Theme.currentThemeName === modelData && Theme.currentTheme !== Theme.dynamic
                width: root.dotSize
                height: root.dotSize
                radius: width / 2
                color: "transparent"
                scale: isActive ? 1.1 : 1

                DankPaletteSwatch {
                    anchors.fill: parent
                    primaryColor: parent.palette.primary
                    secondaryColor: parent.palette.secondary
                    tertiaryColor: parent.palette.tertiary
                }

                DankIcon {
                    anchors.centerIn: parent
                    name: "check"
                    size: Theme.iconSizeMedium
                    color: Theme.isLightColor(parent.colors.primary) ? Theme.contrastDark : Theme.contrastLight
                    visible: parent.isActive
                }

                DankTooltipHost {
                    text: parent.colors.name
                    target: parent
                    hoverArea: mouseArea
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Theme.switchTheme(parent.modelData)
                }

                Behavior on scale {
                    NumberAnimation {
                        duration: Theme.shortDuration
                        easing.type: Theme.emphasizedEasing
                    }
                }
            }
        }
    }
}
