import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Common
import qs.Services
import qs.Widgets

Item {
    id: root

    Component.onCompleted: console.info("[AIAssistant UI] ready")

    property bool showSettingsMenu: false
    readonly property real panelTransparency: SettingsData.aiAssistantTransparencyOverride >= 0 ? SettingsData.aiAssistantTransparencyOverride : SettingsData.popupTransparency
    readonly property bool hasApiKey: !!(aiService.service && aiService.service.resolveApiKey && aiService.service.resolveApiKey().length > 0)
    signal hideRequested

    Ref {
        id: aiService
        service: AIAssistantService
    }

    function sendCurrentMessage() {
        if (!composer.text || composer.text.trim().length === 0)
            return;
        if (!aiService || !aiService.service) {
            console.warn("[AIAssistant UI] service unavailable");
            return;
        }
        console.log("[AIAssistant UI] sendCurrentMessage");
        aiService.service.sendMessage(composer.text.trim());
        composer.text = "";
    }

    function getLastAssistantText() {
        const svc = aiService.service;
        if (!svc || !svc.messagesModel)
            return "";
        const model = svc.messagesModel;
        for (let i = model.count - 1; i >= 0; i--) {
            const m = model.get(i);
            if (m.role === "assistant" && m.status === "ok")
                return m.content || "";
        }
        return "";
    }

    function hasAssistantError() {
        const svc = aiService.service;
        if (!svc || !svc.messagesModel)
            return false;
        const model = svc.messagesModel;
        for (let i = model.count - 1; i >= 0; i--) {
            const m = model.get(i);
            if (m.role === "assistant" && m.status === "error")
                return true;
        }
        return false;
    }

    function copyLastAssistant() {
        const text = getLastAssistantText();
        if (!text)
            return;
        Quickshell.execDetached(["wl-copy", text]);
    }

    Column {
        anchors.fill: parent
        spacing: Theme.spacingM

        RowLayout {
            id: headerRow
            width: parent.width
            spacing: Theme.spacingS

            Rectangle {
                radius: Theme.cornerRadius
                color: Theme.surfaceVariant
                height: Theme.fontSizeSmall * 1.6
                Layout.preferredWidth: providerLabel.implicitWidth + Theme.spacingM
                Layout.alignment: Qt.AlignVCenter

                StyledText {
                    id: providerLabel
                    anchors.centerIn: parent
                    text: (aiService.service?.provider ?? SettingsData.aiAssistantProvider).toUpperCase()
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                }
            }

            Rectangle {
                width: 10
                height: 10
                radius: 5
                color: aiService.service?.isOnline ? Theme.success : Theme.surfaceVariantText
                Layout.alignment: Qt.AlignVCenter
            }

            Item { Layout.fillWidth: true }

            DankActionButton {
                iconName: "settings"
                tooltipText: showSettingsMenu ? I18n.tr("Hide settings") : I18n.tr("Settings")
                onClicked: showSettingsMenu = !showSettingsMenu
            }

            DankActionButton {
                iconName: "delete"
                tooltipText: I18n.tr("Clear history")
                enabled: (aiService.service?.messageCount ?? 0) > 0 && !(aiService.service?.isStreaming ?? false)
                onClicked: aiService.service.clearHistory(true)
            }

            DankActionButton {
                id: overflowButton
                iconName: "more_vert"
                tooltipText: I18n.tr("More")
                onClicked: overflowMenu.popup(overflowButton, -overflowMenu.width + overflowButton.width, overflowButton.height + Theme.spacingXS)
            }

            Menu {
                id: overflowMenu
                closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent

                background: Rectangle {
                    color: Theme.withAlpha(Theme.surfaceContainer, Theme.popupTransparency)
                    radius: Theme.cornerRadius
                    border.width: 0
                    border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.12)
                }

                MenuItem {
                    text: showSettingsMenu ? I18n.tr("Hide settings") : I18n.tr("Settings")
                    onTriggered: showSettingsMenu = !showSettingsMenu
                }

                MenuSeparator {}

                MenuItem {
                    text: I18n.tr("Copy last reply")
                    enabled: getLastAssistantText().length > 0
                    onTriggered: copyLastAssistant()
                }

                MenuItem {
                    text: I18n.tr("Retry")
                    enabled: hasAssistantError() && !(aiService.service?.isStreaming ?? false)
                    onTriggered: aiService.service.retryLast()
                }

                MenuItem {
                    text: I18n.tr("Close")
                    onTriggered: root.hideRequested()
                }
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
                messages: aiService.service ? aiService.service.messagesModel : null
            }

            StyledText {
                anchors.centerIn: parent
                visible: !hasApiKey && (aiService.service?.messageCount ?? 0) === 0
                text: I18n.tr("Configure a provider and API key in Settings to start chatting.")
                font.pixelSize: Theme.fontSizeMedium
                color: Theme.surfaceTextMedium
                wrapMode: Text.Wrap
                width: parent.width * 0.8
                horizontalAlignment: Text.AlignHCenter
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
                    enabled: aiService.service?.isStreaming
                    onClicked: aiService.service.cancel()
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
