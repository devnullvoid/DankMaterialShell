pragma ComponentBehavior: Bound

import QtQuick
import qs.Common
import qs.Widgets

Rectangle {
    id: root

    property var item: null
    property bool isSelected: false
    property bool isHovered: itemArea.containsMouse
    property var controller: null
    property int flatIndex: -1

    signal clicked
    signal rightClicked(real mouseX, real mouseY)

    radius: Theme.cornerRadius
    color: isSelected ? Theme.primaryPressed : isHovered ? Theme.primaryPressed : "transparent"

    Column {
        anchors.centerIn: parent
        anchors.margins: Theme.spacingS
        spacing: Theme.spacingS
        width: parent.width - Theme.spacingM

        Item {
            width: iconSize
            height: iconSize
            anchors.horizontalCenter: parent.horizontalCenter

            property int iconSize: Math.min(48, Math.max(32, root.width * 0.45))

            Image {
                id: appIcon
                anchors.fill: parent
                visible: root.item?.iconType === "image"
                asynchronous: true
                source: root.item?.iconType === "image" ? "image://icon/" + (root.item?.icon || "application-x-executable") : ""
                sourceSize.width: parent.iconSize
                sourceSize.height: parent.iconSize
                fillMode: Image.PreserveAspectFit
                cache: false
            }

            DankIcon {
                anchors.centerIn: parent
                visible: root.item?.iconType === "material" || root.item?.iconType === "nerd"
                name: root.item?.icon ?? "apps"
                size: parent.iconSize * 0.7
                color: root.isSelected ? Theme.primary : Theme.surfaceText
            }

            StyledText {
                anchors.centerIn: parent
                visible: root.item?.iconType === "unicode"
                text: root.item?.icon ?? ""
                font.pixelSize: parent.iconSize * 0.7
                color: root.isSelected ? Theme.primary : Theme.surfaceText
            }

            Item {
                anchors.fill: parent
                visible: root.item?.iconType === "composite"

                Image {
                    anchors.fill: parent
                    asynchronous: true
                    source: {
                        if (!root.item || root.item.iconType !== "composite")
                            return "";
                        var iconFull = root.item.iconFull || "";
                        if (iconFull.startsWith("svg+corner:")) {
                            var parts = iconFull.substring(11).split("|");
                            return parts[0] || "";
                        }
                        return "";
                    }
                    sourceSize.width: parent.width
                    sourceSize.height: parent.height
                    fillMode: Image.PreserveAspectFit
                }

                Rectangle {
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    width: 16
                    height: 16
                    radius: 8
                    color: Theme.surfaceContainer

                    DankIcon {
                        anchors.centerIn: parent
                        name: {
                            if (!root.item || root.item.iconType !== "composite")
                                return "";
                            var iconFull = root.item.iconFull || "";
                            if (iconFull.startsWith("svg+corner:")) {
                                var parts = iconFull.substring(11).split("|");
                                return parts[1] || "";
                            }
                            return "";
                        }
                        size: 12
                        color: root.isSelected ? Theme.primary : Theme.surfaceText
                    }
                }
            }
        }

        StyledText {
            width: parent.width
            text: root.item?.name ?? ""
            font.pixelSize: Theme.fontSizeSmall
            font.weight: Font.Medium
            color: root.isSelected ? Theme.primary : Theme.surfaceText
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
            maximumLineCount: 2
            wrapMode: Text.Wrap
        }
    }

    MouseArea {
        id: itemArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                var scenePos = mapToItem(null, mouse.x, mouse.y);
                root.rightClicked(scenePos.x, scenePos.y);
            } else {
                root.clicked();
            }
        }

        onPositionChanged: {
            if (root.controller) {
                root.controller.keyboardNavigationActive = false;
            }
        }
    }
}
