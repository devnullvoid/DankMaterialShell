import QtQuick
import qs.Common
import qs.Modals
import qs.Services
import qs.Widgets
import qs.Modules.Settings.DisplayConfig

Item {
    id: root

    Connections {
        target: DisplayConfigState
        function onChangesApplied(changeDescriptions) {
            confirmationModal.changes = changeDescriptions;
            confirmationModal.open();
        }
        function onChangesConfirmed() {
        }
        function onChangesReverted() {
        }
    }

    DankFlickable {
        anchors.fill: parent
        clip: true
        contentHeight: mainColumn.height + Theme.spacingXL
        contentWidth: width

        Column {
            id: mainColumn
            topPadding: 4

            width: Math.min(550, parent.width - Theme.spacingL * 2)
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Theme.spacingXL

            IncludeWarningBox {
                width: parent.width
            }

            StyledRect {
                width: parent.width
                height: monitorConfigSection.implicitHeight + Theme.spacingL * 2
                radius: Theme.cornerRadius
                color: Theme.withAlpha(Theme.surfaceContainerHigh, Theme.popupTransparency)
                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
                border.width: 0
                visible: DisplayConfigState.hasOutputBackend

                Column {
                    id: monitorConfigSection
                    anchors.fill: parent
                    anchors.margins: Theme.spacingL
                    spacing: Theme.spacingM

                    Row {
                        width: parent.width
                        spacing: Theme.spacingM

                        DankIcon {
                            name: "monitor"
                            size: Theme.iconSize
                            color: Theme.primary
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Column {
                            width: parent.width - Theme.iconSize - Theme.spacingM - (displayFormatColumn.visible ? displayFormatColumn.width + Theme.spacingM : 0)
                            spacing: Theme.spacingXS
                            anchors.verticalCenter: parent.verticalCenter

                            StyledText {
                                text: I18n.tr("Monitor Configuration")
                                font.pixelSize: Theme.fontSizeLarge
                                font.weight: Font.Medium
                                color: Theme.surfaceText
                            }

                            StyledText {
                                text: I18n.tr("Arrange displays and configure resolution, refresh rate, and VRR")
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceVariantText
                                wrapMode: Text.WordWrap
                                width: parent.width
                            }
                        }

                        Column {
                            id: displayFormatColumn
                            visible: !CompositorService.isDwl
                            spacing: Theme.spacingXS
                            anchors.verticalCenter: parent.verticalCenter

                            StyledText {
                                text: I18n.tr("Config Format")
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceVariantText
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            DankButtonGroup {
                                id: displayFormatGroup
                                model: [I18n.tr("Name"), I18n.tr("Model")]
                                currentIndex: SettingsData.displayNameMode === "model" ? 1 : 0
                                onSelectionChanged: (index, selected) => {
                                    if (!selected)
                                        return;
                                    const newMode = index === 1 ? "model" : "system";
                                    DisplayConfigState.setOriginalDisplayNameMode(SettingsData.displayNameMode);
                                    SettingsData.displayNameMode = newMode;
                                }

                                Connections {
                                    target: SettingsData
                                    function onDisplayNameModeChanged() {
                                        displayFormatGroup.currentIndex = SettingsData.displayNameMode === "model" ? 1 : 0;
                                    }
                                }
                            }
                        }
                    }

                    MonitorCanvas {
                        width: parent.width
                    }

                    Column {
                        width: parent.width
                        spacing: Theme.spacingS

                        Repeater {
                            model: DisplayConfigState.allOutputs ? Object.keys(DisplayConfigState.allOutputs) : []

                            delegate: OutputCard {
                                required property string modelData
                                outputName: modelData
                                outputData: DisplayConfigState.allOutputs[modelData]
                            }
                        }
                    }

                    Row {
                        width: parent.width
                        spacing: Theme.spacingS
                        visible: DisplayConfigState.hasPendingChanges
                        layoutDirection: Qt.RightToLeft

                        DankButton {
                            text: I18n.tr("Apply Changes")
                            iconName: "check"
                            onClicked: DisplayConfigState.applyChanges()
                        }

                        DankButton {
                            text: I18n.tr("Discard")
                            backgroundColor: "transparent"
                            textColor: Theme.surfaceText
                            onClicked: DisplayConfigState.discardChanges()
                        }
                    }
                }
            }

            NoBackendMessage {
                width: parent.width
                visible: !DisplayConfigState.hasOutputBackend
            }
        }
    }

    DisplayConfirmationModal {
        id: confirmationModal
        onConfirmed: DisplayConfigState.confirmChanges()
        onReverted: DisplayConfigState.revertChanges()
    }
}
