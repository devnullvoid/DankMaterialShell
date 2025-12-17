pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.Common
import qs.Widgets

Item {
    id: root

    property var displayPreferences: []

    signal preferencesChanged(var preferences)

    readonly property bool allDisplaysEnabled: {
        if (!Array.isArray(displayPreferences))
            return true;
        return displayPreferences.includes("all") || displayPreferences.length === 0;
    }

    width: parent?.width ?? 0
    height: displayColumn.height + Theme.spacingM * 2

    Column {
        id: displayColumn
        width: parent.width - Theme.spacingM * 2
        x: Theme.spacingM
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.spacingM

        StyledText {
            text: I18n.tr("Displays")
            font.pixelSize: Theme.fontSizeMedium
            color: Theme.surfaceText
        }

        DankToggle {
            width: parent.width
            text: I18n.tr("All displays")
            checked: root.allDisplaysEnabled
            onToggled: isChecked => root.preferencesChanged(isChecked ? ["all"] : [])
        }

        Column {
            width: parent.width
            spacing: Theme.spacingXS
            visible: !root.allDisplaysEnabled

            Repeater {
                model: Quickshell.screens

                DankToggle {
                    required property var modelData

                    width: parent.width
                    text: SettingsData.getScreenDisplayName(modelData)
                    description: modelData.width + "×" + modelData.height
                    checked: {
                        const prefs = root.displayPreferences;
                        if (!Array.isArray(prefs) || prefs.includes("all"))
                            return false;
                        return prefs.some(p => p.name === modelData.name);
                    }
                    onToggled: isChecked => {
                        var prefs = root.displayPreferences;
                        if (!Array.isArray(prefs) || prefs.includes("all"))
                            prefs = [];
                        prefs = prefs.filter(p => p.name !== modelData.name);
                        if (isChecked) {
                            prefs.push({
                                name: modelData.name,
                                model: modelData.model || ""
                            });
                        }
                        root.preferencesChanged(prefs);
                    }
                }
            }
        }
    }
}
