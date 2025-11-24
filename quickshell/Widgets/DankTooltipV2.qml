import QtQuick
import QtQuick.Controls
import qs.Common

Item {
    id: root

    property string text: ""

    function show(text, item, offsetX, offsetY) {
        if (!item) return;

        tooltip.parent = item.Window.window?.contentItem || item;
        tooltip.text = text;

        const itemPos = item.mapToItem(tooltip.parent, 0, 0);
        const itemCenterX = itemPos.x + item.width / 2;
        const itemBottomY = itemPos.y + item.height;

        tooltip.x = itemCenterX - tooltip.width / 2 + (offsetX || 0);
        tooltip.y = itemBottomY + 8 + (offsetY || 0);

        tooltip.open();
    }

    function hide() {
        tooltip.close();
    }

    Popup {
        id: tooltip

        property string text: ""

        width: Math.min(300, Math.max(120, textContent.implicitWidth + Theme.spacingM * 2))
        height: textContent.implicitHeight + Theme.spacingS * 2

        padding: 0
        closePolicy: Popup.NoAutoClose
        modal: false
        dim: false

        background: Rectangle {
            color: Theme.withAlpha(Theme.surfaceContainerHigh, Theme.popupTransparency)
            radius: Theme.cornerRadius
            border.width: 1
            border.color: Theme.outlineMedium
        }

        contentItem: Text {
            id: textContent

            text: tooltip.text
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.surfaceText
            wrapMode: Text.NoWrap
            maximumLineCount: 1
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        enter: Transition {
            NumberAnimation {
                property: "opacity"
                from: 0
                to: 1
                duration: 150
                easing.type: Easing.OutQuad
            }
        }

        exit: Transition {
            NumberAnimation {
                property: "opacity"
                from: 1
                to: 0
                duration: 100
                easing.type: Easing.InQuad
            }
        }
    }
}
