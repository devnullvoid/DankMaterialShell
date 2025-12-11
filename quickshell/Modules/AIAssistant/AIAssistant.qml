import QtQuick
import QtQuick.Controls
import qs.Common
import qs.Services
import qs.Services.AIAssistantService
import qs.Widgets

Item {
    id: root

    property bool showSettingsMenu: false
    readonly property real panelTransparency: SettingsData.aiAssistantTransparencyOverride >= 0 ? SettingsData.aiAssistantTransparencyOverride : SettingsData.popupTransparency
    signal hideRequested

    Ref {
        service: AIAssistantService
    }

    function sendCurrentMessage() {
        if (!composer.text || composer.text.trim().length === 0)
            return;
        if (!AIAssistantService) {
            console.warn("[AIAssistant UI] service unavailable");
            return;
        }
        console.log("[AIAssistant UI] sendCurrentMessage");
        AIAssistantService.sendMessage(composer.text.trim());
        composer.text = "";
    }

    Column {
        anchors.fill: parent
        spacing: Theme.spacingM

        Row {
            width: parent.width
            spacing: Theme.spacingM

            StyledText {
                text: I18n.tr("Messages: ") + (AIAssistantService.messages ? AIAssistantService.messages.length : 0)
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceTextMedium
            }

            StyledText {
                text: I18n.tr("AI Assistant (Preview)")
                font.pixelSize: Theme.fontSizeLarge
                color: Theme.surfaceText
                font.weight: Font.Medium
            }

            Rectangle {
                width: 10; height: 10
                radius: 5
                color: AIAssistantService.isOnline ? Theme.success : Theme.surfaceVariantText
                anchors.verticalCenter: parent.verticalCenter
            }

            Item { width: Theme.spacingM; height: 1 }

            Button {
                text: showSettingsMenu ? I18n.tr("Hide settings") : I18n.tr("Settings")
                onClicked: showSettingsMenu = !showSettingsMenu
            }

            Button {
                text: I18n.tr("Close")
                onClicked: root.hideRequested()
            }
        }

        Rectangle {
            width: parent.width
            height: parent.height - composer.height - Theme.spacingM * 3
            radius: Theme.cornerRadius
            color: Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, root.panelTransparency)
            border.color: Theme.surfaceVariantAlpha
            border.width: 1

            MessageList {
                id: list
                anchors.fill: parent
                messages: AIAssistantService.messages
            }
        }

        Row {
            id: composerRow
            width: parent.width
            spacing: Theme.spacingM

            TextArea {
                id: composer
                width: Math.max(200, parent.width - actionButtons.implicitWidth - Theme.spacingM)
                implicitHeight: 120
                placeholderText: I18n.tr("Ask anything…")
                wrapMode: TextArea.Wrap

                Keys.onReleased: event => {
                    if (event.key === Qt.Key_Escape) {
                        hideRequested();
                        event.accepted = true;
                    } else if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_Return) {
                        sendCurrentMessage();
                        event.accepted = true;
                    }
                }
            }

            Column {
                id: actionButtons
                spacing: Theme.spacingS

                Button {
                    text: I18n.tr("Send")
                    enabled: composer.text && composer.text.trim().length > 0
                    onClicked: sendCurrentMessage()
                }

                Button {
                    text: I18n.tr("Stop")
                    enabled: AIAssistantService.isStreaming
                    onClicked: AIAssistantService.cancel()
                }
            }
        }
    }

    AIAssistantSettings {
        id: settingsPanel
        anchors.fill: parent
        isVisible: showSettingsMenu
        onCloseRequested: showSettingsMenu = false
    }
}
