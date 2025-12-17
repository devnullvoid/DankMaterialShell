import QtQuick
import QtQuick.Controls
import qs.Common
import qs.Widgets
import qs.Modules.Settings.Widgets

Item {
    id: root
    property bool isVisible: false
    signal closeRequested

    visible: isVisible

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, 0.95)
        radius: Theme.cornerRadius
        border.color: Theme.surfaceVariantAlpha
        border.width: 1

        Column {
            anchors.fill: parent
            anchors.margins: Theme.spacingM
            spacing: Theme.spacingM

            Row {
                width: parent.width
                spacing: Theme.spacingL

                StyledText {
                    text: I18n.tr("AI Assistant Settings")
                    font.pixelSize: Theme.fontSizeLarge
                    color: Theme.surfaceText
                    font.weight: Font.Medium
                    anchors.verticalCenter: parent.verticalCenter
                }

                Item {
                    width: parent.width - parent.children[0].width - parent.children[2].width - Theme.spacingL * 2
                    height: 1
                }

                DankButton {
                    text: I18n.tr("Close")
                    iconName: "close"
                    anchors.verticalCenter: parent.verticalCenter
                    onClicked: closeRequested()
                }
            }

            DankFlickable {
                width: parent.width
                height: parent.height - parent.children[0].height - Theme.spacingM
                clip: true
                contentHeight: settingsColumn.height + Theme.spacingXL
                contentWidth: width

                Column {
                    id: settingsColumn
                    width: Math.min(550, parent.width - Theme.spacingL * 2)
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: Theme.spacingL

                    SettingsCard {
                        width: parent.width
                        iconName: "api"
                        title: I18n.tr("Provider Configuration")

                        SettingsDropdownRow {
                            text: I18n.tr("Provider")
                            description: I18n.tr("Select AI provider type")
                            currentValue: SettingsData.aiAssistantProvider
                            options: ["openai", "anthropic", "gemini", "custom"]
                            onValueChanged: value => SettingsData.set("aiAssistantProvider", value)
                        }

                        Item {
                            width: parent.width
                            height: baseUrlRow.height + Theme.spacingM

                            Column {
                                id: baseUrlRow
                                width: parent.width
                                anchors.left: parent.left
                                anchors.leftMargin: Theme.spacingM
                                spacing: Theme.spacingXS

                                StyledText {
                                    text: I18n.tr("Base URL")
                                    font.pixelSize: Theme.fontSizeMedium
                                    color: Theme.surfaceText
                                    font.weight: Font.Medium
                                }

                                StyledText {
                                    text: I18n.tr("API endpoint URL for the provider")
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.surfaceVariantText
                                    wrapMode: Text.WordWrap
                                    width: parent.width
                                }

                                DankTextField {
                                    width: parent.width - Theme.spacingM * 2
                                    text: SettingsData.aiAssistantBaseUrl
                                    placeholderText: "https://api.openai.com"
                                    onEditingFinished: SettingsData.set("aiAssistantBaseUrl", text)
                                }
                            }
                        }

                        Item {
                            width: parent.width
                            height: modelRow.height + Theme.spacingM

                            Column {
                                id: modelRow
                                width: parent.width
                                anchors.left: parent.left
                                anchors.leftMargin: Theme.spacingM
                                spacing: Theme.spacingXS

                                StyledText {
                                    text: I18n.tr("Model")
                                    font.pixelSize: Theme.fontSizeMedium
                                    color: Theme.surfaceText
                                    font.weight: Font.Medium
                                }

                                StyledText {
                                    text: I18n.tr("Model identifier for the provider")
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.surfaceVariantText
                                    wrapMode: Text.WordWrap
                                    width: parent.width
                                }

                                DankTextField {
                                    width: parent.width - Theme.spacingM * 2
                                    text: SettingsData.aiAssistantModel
                                    placeholderText: "gpt-4o-mini"
                                    onEditingFinished: SettingsData.set("aiAssistantModel", text)
                                }
                            }
                        }
                    }

                    SettingsCard {
                        width: parent.width
                        iconName: "key"
                        title: I18n.tr("API Authentication")

                        Item {
                            width: parent.width
                            height: sessionKeyRow.height + Theme.spacingM

                            Column {
                                id: sessionKeyRow
                                width: parent.width
                                anchors.left: parent.left
                                anchors.leftMargin: Theme.spacingM
                                spacing: Theme.spacingXS

                                StyledText {
                                    text: I18n.tr("API Key (Session Only)")
                                    font.pixelSize: Theme.fontSizeMedium
                                    color: Theme.surfaceText
                                    font.weight: Font.Medium
                                }

                                StyledText {
                                    text: I18n.tr("Temporary key, not saved across sessions")
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.surfaceVariantText
                                    wrapMode: Text.WordWrap
                                    width: parent.width
                                }

                                DankTextField {
                                    width: parent.width - Theme.spacingM * 2
                                    text: SettingsData.aiAssistantSessionApiKey
                                    echoMode: TextInput.Password
                                    placeholderText: I18n.tr("Enter temporary API key")
                                    onEditingFinished: SettingsData.set("aiAssistantSessionApiKey", text)
                                    leftIconName: "vpn_key"
                                }
                            }
                        }

                        SettingsToggleRow {
                            text: I18n.tr("Save API Key")
                            description: I18n.tr("Store API key in settings (persists across sessions)")
                            checked: SettingsData.aiAssistantSaveApiKey
                            onToggled: checked => SettingsData.set("aiAssistantSaveApiKey", checked)
                        }

                        Item {
                            width: parent.width
                            height: savedKeyRow.height + Theme.spacingM
                            visible: SettingsData.aiAssistantSaveApiKey

                            Column {
                                id: savedKeyRow
                                width: parent.width
                                anchors.left: parent.left
                                anchors.leftMargin: Theme.spacingM
                                spacing: Theme.spacingXS

                                StyledText {
                                    text: I18n.tr("Saved API Key")
                                    font.pixelSize: Theme.fontSizeMedium
                                    color: Theme.surfaceText
                                    font.weight: Font.Medium
                                }

                                DankTextField {
                                    width: parent.width - Theme.spacingM * 2
                                    text: SettingsData.aiAssistantApiKey
                                    echoMode: TextInput.Password
                                    placeholderText: I18n.tr("Enter API key to save")
                                    onEditingFinished: SettingsData.set("aiAssistantApiKey", text)
                                    leftIconName: "lock"
                                }
                            }
                        }

                        StyledText {
                            width: parent.width - Theme.spacingM * 2
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: I18n.tr("Priority: Session key → Saved key → Common env vars → DMS_* env vars")
                            wrapMode: Text.Wrap
                            color: Theme.surfaceTextMedium
                            font.pixelSize: Theme.fontSizeSmall
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }

                    SettingsCard {
                        width: parent.width
                        iconName: "tune"
                        title: I18n.tr("Model Parameters")

                        Item {
                            width: parent.width
                            height: tempRow.height + Theme.spacingM

                            Column {
                                id: tempRow
                                width: parent.width
                                anchors.left: parent.left
                                anchors.leftMargin: Theme.spacingM
                                spacing: Theme.spacingXS

                                Row {
                                    width: parent.width - Theme.spacingM * 2
                                    spacing: Theme.spacingS

                                    Column {
                                        width: parent.width - tempValue.width - Theme.spacingS
                                        spacing: Theme.spacingXS

                                        StyledText {
                                            text: I18n.tr("Temperature")
                                            font.pixelSize: Theme.fontSizeMedium
                                            font.weight: Font.Medium
                                            color: Theme.surfaceText
                                        }

                                        StyledText {
                                            text: I18n.tr("Controls randomness (0 = focused, 2 = creative)")
                                            font.pixelSize: Theme.fontSizeSmall
                                            color: Theme.surfaceVariantText
                                            wrapMode: Text.WordWrap
                                            width: parent.width
                                        }
                                    }

                                    StyledText {
                                        id: tempValue
                                        text: (SettingsData.aiAssistantTemperature).toFixed(1)
                                        font.pixelSize: Theme.fontSizeMedium
                                        font.weight: Font.Medium
                                        color: Theme.primary
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }

                                DankSlider {
                                    width: parent.width - Theme.spacingM * 2
                                    height: 32
                                    minimum: 0
                                    maximum: 20
                                    value: Math.round(SettingsData.aiAssistantTemperature * 10)
                                    showValue: false
                                    wheelEnabled: false
                                    thumbOutlineColor: Theme.withAlpha(Theme.surfaceContainerHigh, Theme.popupTransparency)
                                    onSliderValueChanged: newValue => SettingsData.set("aiAssistantTemperature", newValue / 10)
                                }
                            }
                        }

                        SettingsSliderRow {
                            text: I18n.tr("Max Tokens")
                            description: I18n.tr("Maximum response length")
                            minimum: 16
                            maximum: 8192
                            value: SettingsData.aiAssistantMaxTokens
                            unit: ""
                            onSliderValueChanged: newValue => SettingsData.set("aiAssistantMaxTokens", newValue)
                        }

                        SettingsSliderRow {
                            text: I18n.tr("Timeout")
                            description: I18n.tr("Request timeout in seconds")
                            minimum: 5
                            maximum: 120
                            value: SettingsData.aiAssistantTimeout
                            unit: "s"
                            onSliderValueChanged: newValue => SettingsData.set("aiAssistantTimeout", newValue)
                        }
                    }

                    SettingsCard {
                        width: parent.width
                        iconName: "format_size"
                        title: I18n.tr("Display Options")

                        SettingsToggleRow {
                            text: I18n.tr("Monospace Font")
                            description: I18n.tr("Use monospace font for AI replies (better for code)")
                            checked: SettingsData.aiAssistantUseMonospace
                            onToggled: checked => SettingsData.set("aiAssistantUseMonospace", checked)
                        }
                    }
                }
            }
        }
    }
}
