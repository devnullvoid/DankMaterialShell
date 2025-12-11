import QtQuick
import qs.Common
import qs.Widgets

Item {
    id: root
    property string role: "assistant"
    property string text: ""
    property string status: "ok" // ok|streaming|error

    width: parent ? parent.width : implicitWidth
    implicitHeight: bubble.implicitHeight

    Rectangle {
        id: bubble
        width: parent.width
        radius: Theme.cornerRadius
        color: role === "user" ? Theme.surfaceContainerHigh : Theme.surfaceContainer
        border.color: status === "error" ? Theme.error : Theme.surfaceVariantAlpha
        border.width: 1
        anchors.left: parent.left
        anchors.right: parent.right

        Column {
            anchors.fill: parent
            anchors.margins: Theme.spacingM
            spacing: Theme.spacingXS

            StyledText {
                text: role === "user" ? I18n.tr("You") : I18n.tr("Assistant")
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceTextMedium
            }

            StyledText {
                text: root.text
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeMedium
                color: status === "error" ? Theme.error : Theme.surfaceText
            }

            StyledText {
                visible: status === "streaming"
                text: I18n.tr("Streaming…")
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceTextMedium
            }
        }
    }
}
