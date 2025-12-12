import QtQuick
import QtQuick.Controls
import qs.Common

Item {
    id: root
    clip: true
    property var messages: null // expects a ListModel

    Component.onCompleted: console.log("[MessageList] ready")

    Connections {
        target: root.messages
        function onCountChanged() {
            listView.positionViewAtEnd();
        }
    }

    ListView {
        id: listView
        anchors.fill: parent
        model: root.messages
        spacing: Theme.spacingS
        clip: true
        ScrollBar.vertical: ScrollBar { }

        onModelChanged: {
            Qt.callLater(() => listView.positionViewAtEnd());
        }

        delegate: MessageBubble {
            width: listView.width
            role: model.role
            text: model.content
            status: model.status

            Component.onCompleted: {
                console.log("[MessageList] add", role, text ? text.slice(0, 40) : "")
            }
        }
    }
}
