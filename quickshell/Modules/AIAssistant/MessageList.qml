import QtQuick
import QtQuick.Controls
import qs.Common

Flickable {
    id: root
    clip: true
    contentWidth: width
    contentHeight: contentItem.childrenRect.height
    ScrollBar.vertical: ScrollBar { }

    property var messages: null // expects a ListModel

    Column {
        id: messageColumn
        width: root.width
        spacing: Theme.spacingS

        Component.onCompleted: console.log("[MessageList] ready")

        Repeater {
            model: root.messages

            delegate: MessageBubble {
                width: messageColumn.width
                role: model.role || "assistant"
                text: model.content || ""
                status: model.status || "ok"

                Component.onCompleted: {
                    console.log("[MessageList] add", role, text.slice(0, 40))
                }
            }
        }
    }
}
