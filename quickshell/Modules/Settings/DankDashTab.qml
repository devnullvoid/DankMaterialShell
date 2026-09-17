pragma ComponentBehavior: Bound

import QtQuick
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Settings.Widgets
import qs.Modules.DankDash
import qs.Modules.DankDash.Overview

FocusScope {
    id: root

    property var parentModal: null

    focus: true

    readonly property var tabs: DashRegistry.tabEntries
    readonly property var optionEntries: DashRegistry.entries.filter(e => (e.options?.length ?? 0) > 0)
    SettingsPage {
        SettingsCard {
            title: I18n.tr("Weather")

            SettingsNavRow {
                tab: "dank_dash"
                settingKey: "dashWeatherSettings"
                title: I18n.tr("Weather")
                iconName: "partly_cloudy_day"
                onClicked: root.parentModal?.navigateTo("weather")
            }
        }

        SettingsCard {
            title: I18n.tr("Media player")

            SettingsNavRow {
                tab: "dank_dash"
                settingKey: "dashMediaSettings"
                title: I18n.tr("Media player")
                hint: I18n.tr("Lyrics providers", "Lyrics source priority settings")
                iconName: "music_note"
                onClicked: root.parentModal?.navigateTo("media_player")
            }
        }

        SettingsCard {
            title: I18n.tr("Tabs", "noun, card title for dashboard tabs")
            settingKey: "dashTabs"
            tab: "dank_dash"

            headerActions: DankActionButton {
                iconName: "refresh"
                iconSize: Theme.iconSizeSmall
                tooltipText: I18n.tr("Reset")
                onClicked: SettingsData.resetDashTabs()
            }

            SettingsReorderList {
                id: tabList

                model: root.tabs
                onReordered: indices => SettingsData.setDashTabOrder(indices.map(i => root.tabs[i].id))

                delegate: SettingsReorderRow {
                    id: tabRow

                    required property var modelData

                    reorderList: tabList

                    readonly property bool available: modelData.available !== false
                    readonly property bool locked: modelData.locked === true

                    iconName: modelData.icon
                    iconColor: available && modelData.enabled ? Theme.primary : Theme.onSurface_38
                    titleColor: available ? Theme.surfaceText : Theme.onSurface_38
                    title: modelData.text
                    subtitle: available ? modelData.description ?? "" : I18n.tr("Disabled")
                    clickable: available && !locked
                    onClicked: SettingsData.setDashTabEnabled(modelData.id, !modelData.enabled)

                    Row {
                        spacing: Theme.spacingXS
                        anchors.verticalCenter: parent.verticalCenter

                        DankToggle {
                            anchors.verticalCenter: parent.verticalCenter
                            hideText: true
                            checked: tabRow.modelData.enabled
                            enabled: tabRow.available && !tabRow.locked
                            onToggled: checked => SettingsData.setDashTabEnabled(tabRow.modelData.id, checked)
                        }
                    }
                }
            }
        }

        Repeater {
            model: root.optionEntries

            SettingsCard {
                id: optionCard

                required property var modelData

                title: modelData.text
                settingKey: "dashOptions:" + modelData.id
                tab: "dank_dash"
                collapsible: true
                expanded: false

                Repeater {
                    model: optionCard.modelData.options

                    DashOptionRow {
                        required property var modelData

                        entryId: optionCard.modelData?.id ?? ""
                        spec: modelData ?? ({})
                        settingKey: "dashOptions:" + entryId + ":" + spec.key
                    }
                }
            }
        }
    }
}
