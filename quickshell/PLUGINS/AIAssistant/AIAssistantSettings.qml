import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Common
import qs.Widgets

Item {
    id: root
    property bool isVisible: false
    signal closeRequested

    required property var aiService
    property var pluginService: aiService.pluginService
    property string pluginId: aiService.pluginId

    function save(key, value) {
        if (pluginService) pluginService.savePluginData(pluginId, key, value)
    }

    visible: isVisible

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, 0.98)
        radius: Theme.cornerRadius
        border.color: Theme.surfaceVariantAlpha
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.spacingM
            spacing: Theme.spacingM

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.spacingL

                StyledText {
                    text: I18n.tr("AI Assistant Settings")
                    font.pixelSize: Theme.fontSizeLarge
                    color: Theme.surfaceText
                    font.weight: Font.Medium
                    Layout.alignment: Qt.AlignVCenter
                }

                Item { Layout.fillWidth: true }

                DankButton {
                    text: I18n.tr("Close")
                    iconName: "close"
                    onClicked: closeRequested()
                }
            }

            DankFlickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                contentHeight: settingsColumn.implicitHeight + Theme.spacingXL
                contentWidth: width

                Column {
                    id: settingsColumn
                    width: Math.min(550, parent.width - Theme.spacingL * 2)
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: Theme.spacingL

                    // Provider Section
                    Column {
                        width: parent.width
                        spacing: Theme.spacingS

                        StyledText {
                            text: I18n.tr("Provider Configuration")
                            font.pixelSize: Theme.fontSizeMedium
                            font.weight: Font.Bold
                            color: Theme.primary
                        }

                        // Provider Dropdown
                        StyledText { text: I18n.tr("Provider"); font.pixelSize: Theme.fontSizeSmall; color: Theme.surfaceVariantText }
                        DankDropdown {
                            width: parent.width
                            model: ["openai", "anthropic", "gemini", "custom"]
                            currentIndex: model.indexOf(aiService.provider)
                            onActivated: index => save("provider", model[index])
                        }

                        // Base URL
                        StyledText { text: I18n.tr("Base URL"); font.pixelSize: Theme.fontSizeSmall; color: Theme.surfaceVariantText }
                        DankTextField {
                            width: parent.width
                            text: aiService.baseUrl
                            placeholderText: "https://api.openai.com"
                            onEditingFinished: save("baseUrl", text)
                        }

                        // Model
                        StyledText { text: I18n.tr("Model"); font.pixelSize: Theme.fontSizeSmall; color: Theme.surfaceVariantText }
                        DankTextField {
                            width: parent.width
                            text: aiService.model
                            placeholderText: "gpt-4-mini"
                            onEditingFinished: save("model", text)
                        }
                    }

                    // Auth Section
                    Column {
                        width: parent.width
                        spacing: Theme.spacingS

                        StyledText {
                            text: I18n.tr("API Authentication")
                            font.pixelSize: Theme.fontSizeMedium
                            font.weight: Font.Bold
                            color: Theme.primary
                        }

                        // API Key
                        StyledText { text: I18n.tr("API Key"); font.pixelSize: Theme.fontSizeSmall; color: Theme.surfaceVariantText }
                        DankTextField {
                            width: parent.width
                            text: aiService.saveApiKey ? aiService.apiKey : aiService.sessionApiKey
                            echoMode: TextInput.Password
                            placeholderText: I18n.tr("Enter API key")
                            leftIconName: aiService.saveApiKey ? "lock" : "vpn_key"
                            onEditingFinished: {
                                if (aiService.saveApiKey) {
                                    save("apiKey", text)
                                } else {
                                    aiService.sessionApiKey = text // In memory
                                }
                            }
                        }

                        // Env Var
                        StyledText { text: I18n.tr("API Key Env Var"); font.pixelSize: Theme.fontSizeSmall; color: Theme.surfaceVariantText }
                        DankTextField {
                            width: parent.width
                            text: aiService.apiKeyEnvVar
                            placeholderText: I18n.tr("e.g. OPENAI_API_KEY")
                            leftIconName: "terminal"
                            onEditingFinished: save("apiKeyEnvVar", text.trim())
                        }

                        // Save Toggle
                        RowLayout {
                            width: parent.width
                            spacing: Theme.spacingM
                            StyledText {
                                text: I18n.tr("Remember API Key")
                                Layout.fillWidth: true
                                color: Theme.surfaceText
                            }
                            DankToggle {
                                checked: aiService.saveApiKey
                                onToggled: checked => {
                                    save("saveApiKey", checked)
                                    // Logic to move key handled by user re-entry or I can try to move it here
                                    // For simplicity, user re-enters or we rely on them typing it.
                                }
                            }
                        }
                    }

                    // Parameters Section
                    Column {
                        width: parent.width
                        spacing: Theme.spacingS

                        StyledText {
                            text: I18n.tr("Model Parameters")
                            font.pixelSize: Theme.fontSizeMedium
                            font.weight: Font.Bold
                            color: Theme.primary
                        }

                        // Temperature
                        RowLayout {
                            width: parent.width
                            StyledText { text: I18n.tr("Temperature"); color: Theme.surfaceVariantText }
                            Item { Layout.fillWidth: true }
                            StyledText { text: aiService.temperature.toFixed(1); color: Theme.primary }
                        }
                        DankSlider {
                            width: parent.width
                            height: 32
                            minimum: 0
                            maximum: 20
                            value: Math.round(aiService.temperature * 10)
                            showValue: false
                            onSliderValueChanged: newValue => save("temperature", newValue / 10)
                        }

                        // Max Tokens
                        RowLayout {
                            width: parent.width
                            StyledText { text: I18n.tr("Max Tokens"); color: Theme.surfaceVariantText }
                            Item { Layout.fillWidth: true }
                            StyledText { text: aiService.maxTokens; color: Theme.primary }
                        }
                        DankSlider {
                            width: parent.width
                            height: 32
                            minimum: 128
                            maximum: 32768
                            step: 256
                            value: aiService.maxTokens
                            showValue: false
                            onSliderValueChanged: newValue => save("maxTokens", newValue)
                        }
                    }

                    // Display Section
                    Column {
                        width: parent.width
                        spacing: Theme.spacingS

                        StyledText {
                            text: I18n.tr("Display Options")
                            font.pixelSize: Theme.fontSizeMedium
                            font.weight: Font.Bold
                            color: Theme.primary
                        }

                        RowLayout {
                            width: parent.width
                            spacing: Theme.spacingM
                            StyledText {
                                text: I18n.tr("Monospace Font")
                                Layout.fillWidth: true
                                color: Theme.surfaceText
                            }
                            DankToggle {
                                checked: aiService.useMonospace
                                onToggled: checked => save("useMonospace", checked)
                            }
                        }
                    }
                }
            }
        }
    }
}
