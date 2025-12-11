import QtQuick
import QtQuick.Controls
import qs.Common

Item {
    id: root
    clip: true
    property var messages: null // expects a ListModel

    Component.onCompleted: console.log("[MessageList] ready")

    ListView {
        id: listView
        anchors.fill: parent
        model: root.messages
        spacing: Theme.spacingS
        clip: true
        ScrollBar.vertical: ScrollBar { }

        delegate: MessageBubble {
            width: listView.width
            role: role || "assistant"
            text: content || ""
            status: status || "ok"

            Component.onCompleted: {
                console.log("[MessageList] add", role, text ? text.slice(0, 40) : "")
            }
        }
    }
}
