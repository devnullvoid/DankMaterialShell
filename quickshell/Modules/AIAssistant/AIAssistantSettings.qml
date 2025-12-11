import QtQuick
import QtQuick.Controls
import qs.Common
import qs.Widgets

Item {
    id: root
    property bool isVisible: false
    signal closeRequested

    visible: isVisible

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, 0.92)
        radius: Theme.cornerRadius
        border.color: Theme.surfaceVariantAlpha
        border.width: 1

        Column {
            anchors.fill: parent
            anchors.margins: Theme.spacingM
            spacing: Theme.spacingM

            Row {
                width: parent.width
                spacing: Theme.spacingM

                StyledText {
                    text: I18n.tr("AI Assistant Settings (stub)")
                    font.pixelSize: Theme.fontSizeLarge
                    color: Theme.surfaceText
                    font.weight: Font.Medium
                }

                Item { width: Theme.spacingM; height: 1 }

                Button {
                    text: I18n.tr("Close")
                    onClicked: closeRequested()
                }
            }

            Row {
                spacing: Theme.spacingM

                Label { text: I18n.tr("Provider") }
                ComboBox {
                    id: providerBox
                    model: ["openai", "anthropic", "gemini", "custom"]
                    currentIndex: Math.max(0, model.indexOf(SettingsData.aiAssistantProvider))
                    onActivated: SettingsData.aiAssistantProvider = model[index]
                }
            }

            Row {
                spacing: Theme.spacingM
                Label { text: I18n.tr("Base URL") }
                TextField {
                    text: SettingsData.aiAssistantBaseUrl
                    onEditingFinished: SettingsData.aiAssistantBaseUrl = text
                    placeholderText: "https://api.openai.com"
                    width: parent.width * 0.6
                }
            }

            Row {
                spacing: Theme.spacingM
                Label { text: I18n.tr("Model") }
                TextField {
                    text: SettingsData.aiAssistantModel
                    onEditingFinished: SettingsData.aiAssistantModel = text
                    placeholderText: "gpt-4.1-mini"
                    width: parent.width * 0.6
                }
            }

            Row {
                spacing: Theme.spacingM
                Label { text: I18n.tr("API key (session)") }
                TextField {
                    text: SettingsData.aiAssistantSessionApiKey
                    echoMode: TextInput.Password
                    onEditingFinished: SettingsData.aiAssistantSessionApiKey = text
                    placeholderText: I18n.tr("Not stored; overrides env & saved while session lasts")
                    width: parent.width * 0.6
                }
            }

            Row {
                spacing: Theme.spacingM
                Label { text: I18n.tr("Save key to settings") }
                Switch {
                    id: saveKeySwitch
                    checked: SettingsData.aiAssistantSaveApiKey
                    onToggled: SettingsData.aiAssistantSaveApiKey = checked
                }
                TextField {
                    enabled: saveKeySwitch.checked
                    text: SettingsData.aiAssistantApiKey
                    echoMode: TextInput.Password
                    onEditingFinished: SettingsData.aiAssistantApiKey = text
                    placeholderText: I18n.tr("Stored only if enabled")
                    width: parent.width * 0.6
                }
            }

            Row {
                spacing: Theme.spacingM
                Label { text: I18n.tr("Temperature") }
                Slider {
                    from: 0; to: 2; stepSize: 0.1
                    value: SettingsData.aiAssistantTemperature
                    onValueChanged: SettingsData.aiAssistantTemperature = value
                    width: parent.width * 0.5
                }
                Label { text: value.toFixed(1) }
            }

            Row {
                spacing: Theme.spacingM
                Label { text: I18n.tr("Max tokens") }
                Slider {
                    from: 16; to: 8192; stepSize: 16
                    value: SettingsData.aiAssistantMaxTokens
                    onValueChanged: SettingsData.aiAssistantMaxTokens = Math.round(value)
                    width: parent.width * 0.5
                }
                Label { text: Math.round(value).toString() }
            }

            Row {
                spacing: Theme.spacingM
                Label { text: I18n.tr("Timeout (s)") }
                Slider {
                    from: 5; to: 120; stepSize: 1
                    value: SettingsData.aiAssistantTimeout
                    onValueChanged: SettingsData.aiAssistantTimeout = Math.round(value)
                    width: parent.width * 0.5
                }
                Label { text: Math.round(value).toString() }
            }

            Row {
                spacing: Theme.spacingM
                Label { text: I18n.tr("Monospace replies") }
                Switch {
                    checked: SettingsData.aiAssistantUseMonospace
                    onToggled: SettingsData.aiAssistantUseMonospace = checked
                }
            }

            StyledText {
                text: I18n.tr("Key source order: session key → saved key → common env vars → DMS_* env vars.")
                wrapMode: Text.Wrap
                color: Theme.surfaceTextMedium
            }
        }
    }
}
