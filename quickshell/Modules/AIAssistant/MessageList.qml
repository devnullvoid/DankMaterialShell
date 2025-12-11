import QtQuick
import QtQuick.Controls
import qs.Common

Flickable {
    id: root
    clip: true
    contentWidth: width
    contentHeight: contentItem.childrenRect.height
    ScrollBar.vertical: ScrollBar { }

    property var messages: []

    Column {
        id: messageColumn
        width: root.width
        spacing: Theme.spacingS

        Repeater {
            model: root.messages || []

            delegate: MessageBubble {
                width: messageColumn.width
                role: modelData.role || "assistant"
                text: modelData.content || ""
                status: modelData.status || "ok"
            }
        }
    }
}
