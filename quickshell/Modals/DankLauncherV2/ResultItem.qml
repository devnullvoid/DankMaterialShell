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

    width: parent?.width ?? 200
    height: 52
    color: isSelected ? Theme.primaryPressed : isHovered ? Theme.primaryPressed : "transparent"
    radius: Theme.cornerRadius

    Row {
        anchors.fill: parent
        anchors.leftMargin: Theme.spacingM
        anchors.rightMargin: Theme.spacingM
        spacing: Theme.spacingM

        Item {
            width: 36
            height: 36
            anchors.verticalCenter: parent.verticalCenter

            Image {
                id: appIcon
                anchors.fill: parent
                visible: root.item?.iconType === "image"
                asynchronous: true
                source: root.item?.iconType === "image" ? "image://icon/" + (root.item?.icon || "application-x-executable") : ""
                sourceSize.width: 36
                sourceSize.height: 36
                fillMode: Image.PreserveAspectFit
                cache: false
            }

            DankIcon {
                anchors.centerIn: parent
                visible: root.item?.iconType === "material" || root.item?.iconType === "nerd"
                name: root.item?.icon ?? "apps"
                size: 24
                color: Theme.surfaceText
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
                    sourceSize.width: 36
                    sourceSize.height: 36
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
                        color: Theme.surfaceText
                    }
                }
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 36 - Theme.spacingM * 3 - rightContent.width
            spacing: 2

            StyledText {
                width: parent.width
                text: root.item?.name ?? ""
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.Medium
                color: Theme.surfaceText
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignLeft
            }

            StyledText {
                width: parent.width
                text: root.item?.subtitle ?? ""
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
                elide: Text.ElideRight
                visible: text.length > 0
                horizontalAlignment: Text.AlignLeft
            }
        }

        Row {
            id: rightContent
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.spacingS

            Rectangle {
                visible: root.item?.type && root.item.type !== "app"
                width: typeBadge.implicitWidth + Theme.spacingS * 2
                height: 20
                radius: 10
                color: Theme.surfaceVariantAlpha
                anchors.verticalCenter: parent.verticalCenter

                StyledText {
                    id: typeBadge
                    anchors.centerIn: parent
                    text: {
                        if (!root.item)
                            return "";
                        switch (root.item.type) {
                        case "calculator":
                            return I18n.tr("Calc");
                        case "plugin":
                            return I18n.tr("Plugin");
                        case "file":
                            return I18n.tr("File");
                        default:
                            return "";
                        }
                    }
                    font.pixelSize: Theme.fontSizeSmall - 2
                    color: Theme.surfaceVariantText
                }
            }
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
