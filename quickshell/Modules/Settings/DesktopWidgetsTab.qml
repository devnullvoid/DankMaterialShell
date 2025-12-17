pragma ComponentBehavior: Bound

import QtQuick
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Settings.Widgets

Item {
    id: root

    DankFlickable {
        anchors.fill: parent
        clip: true
        contentHeight: mainColumn.height + Theme.spacingXL
        contentWidth: width

        Column {
            id: mainColumn
            width: Math.min(550, parent.width - Theme.spacingL * 2)
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Theme.spacingXL

            SettingsCard {
                width: parent.width
                iconName: "schedule"
                title: I18n.tr("Desktop Clock")
                collapsible: true
                expanded: false

                SettingsToggleRow {
                    text: I18n.tr("Enable Desktop Clock")
                    checked: SettingsData.desktopClockEnabled
                    onToggled: checked => SettingsData.set("desktopClockEnabled", checked)
                }

                Column {
                    width: parent.width
                    spacing: 0
                    visible: SettingsData.desktopClockEnabled
                    opacity: visible ? 1 : 0

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Theme.mediumDuration
                            easing.type: Theme.emphasizedEasing
                        }
                    }

                    SettingsDivider {}

                    SettingsDropdownRow {
                        text: I18n.tr("Clock Style")
                        options: [I18n.tr("Digital"), I18n.tr("Analog"), I18n.tr("Stacked")]
                        currentValue: {
                            switch (SettingsData.desktopClockStyle) {
                            case "analog":
                                return I18n.tr("Analog");
                            case "stacked":
                                return I18n.tr("Stacked");
                            default:
                                return I18n.tr("Digital");
                            }
                        }
                        onValueChanged: value => {
                            switch (value) {
                            case I18n.tr("Analog"):
                                SettingsData.set("desktopClockStyle", "analog");
                                return;
                            case I18n.tr("Stacked"):
                                SettingsData.set("desktopClockStyle", "stacked");
                                return;
                            default:
                                SettingsData.set("desktopClockStyle", "digital");
                            }
                        }
                    }

                    SettingsDivider {
                        visible: SettingsData.desktopClockStyle === "analog"
                    }

                    SettingsToggleRow {
                        visible: SettingsData.desktopClockStyle === "analog"
                        text: I18n.tr("Show Hour Numbers")
                        checked: SettingsData.desktopClockShowAnalogNumbers
                        onToggled: checked => SettingsData.set("desktopClockShowAnalogNumbers", checked)
                    }

                    SettingsDivider {}

                    SettingsToggleRow {
                        text: I18n.tr("Show Date")
                        checked: SettingsData.desktopClockShowDate
                        onToggled: checked => SettingsData.set("desktopClockShowDate", checked)
                    }

                    SettingsDivider {}

                    SettingsSliderRow {
                        text: I18n.tr("Transparency")
                        minimum: 0
                        maximum: 100
                        value: Math.round(SettingsData.desktopClockTransparency * 100)
                        unit: "%"
                        onSliderValueChanged: newValue => SettingsData.set("desktopClockTransparency", newValue / 100)
                    }

                    SettingsDivider {}

                    SettingsColorPicker {
                        colorMode: SettingsData.desktopClockColorMode
                        customColor: SettingsData.desktopClockCustomColor
                        onColorModeSelected: mode => SettingsData.set("desktopClockColorMode", mode)
                        onCustomColorSelected: selectedColor => SettingsData.set("desktopClockCustomColor", selectedColor.toString())
                    }

                    SettingsDivider {}

                    SettingsDisplayPicker {
                        displayPreferences: SettingsData.desktopClockDisplayPreferences
                        onPreferencesChanged: prefs => SettingsData.set("desktopClockDisplayPreferences", prefs)
                    }

                    SettingsDivider {}

                    Item {
                        width: parent.width
                        height: clockResetRow.height + Theme.spacingM * 2

                        Row {
                            id: clockResetRow
                            x: Theme.spacingM
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Theme.spacingM

                            DankButton {
                                text: I18n.tr("Reset Position")
                                backgroundColor: Theme.surfaceHover
                                textColor: Theme.surfaceText
                                buttonHeight: 36
                                onClicked: {
                                    SettingsData.set("desktopClockX", -1);
                                    SettingsData.set("desktopClockY", -1);
                                }
                            }

                            DankButton {
                                text: I18n.tr("Reset Size")
                                backgroundColor: Theme.surfaceHover
                                textColor: Theme.surfaceText
                                buttonHeight: 36
                                onClicked: {
                                    SettingsData.set("desktopClockWidth", 280);
                                    SettingsData.set("desktopClockHeight", 180);
                                }
                            }
                        }
                    }
                }
            }

            SettingsCard {
                width: parent.width
                iconName: "monitoring"
                title: I18n.tr("System Monitor")
                collapsible: true
                expanded: false

                SettingsToggleRow {
                    text: I18n.tr("Enable System Monitor")
                    checked: SettingsData.systemMonitorEnabled
                    onToggled: checked => SettingsData.set("systemMonitorEnabled", checked)
                }

                Column {
                    width: parent.width
                    spacing: 0
                    visible: SettingsData.systemMonitorEnabled
                    opacity: visible ? 1 : 0

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Theme.mediumDuration
                            easing.type: Theme.emphasizedEasing
                        }
                    }

                    SettingsDivider {}

                    SettingsToggleRow {
                        text: I18n.tr("Show Header")
                        checked: SettingsData.systemMonitorShowHeader
                        onToggled: checked => SettingsData.set("systemMonitorShowHeader", checked)
                    }

                    SettingsDivider {}

                    Item {
                        width: parent.width
                        height: graphIntervalColumn.height + Theme.spacingM * 2

                        Column {
                            id: graphIntervalColumn
                            width: parent.width - Theme.spacingM * 2
                            x: Theme.spacingM
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Theme.spacingS

                            StyledText {
                                text: I18n.tr("Graph Time Range")
                                font.pixelSize: Theme.fontSizeMedium
                                color: Theme.surfaceText
                            }

                            DankButtonGroup {
                                model: ["1m", "5m", "10m", "30m"]
                                currentIndex: {
                                    switch (SettingsData.systemMonitorGraphInterval) {
                                    case 60:
                                        return 0;
                                    case 300:
                                        return 1;
                                    case 600:
                                        return 2;
                                    case 1800:
                                        return 3;
                                    default:
                                        return 0;
                                    }
                                }
                                buttonHeight: 32
                                minButtonWidth: 48
                                textSize: Theme.fontSizeSmall
                                checkEnabled: false
                                onSelectionChanged: (index, selected) => {
                                    if (!selected)
                                        return;
                                    const values = [60, 300, 600, 1800];
                                    SettingsData.set("systemMonitorGraphInterval", values[index]);
                                }
                            }
                        }
                    }

                    SettingsDivider {}

                    SettingsToggleRow {
                        text: I18n.tr("CPU")
                        checked: SettingsData.systemMonitorShowCpu
                        onToggled: checked => SettingsData.set("systemMonitorShowCpu", checked)
                    }

                    SettingsDivider {
                        visible: SettingsData.systemMonitorShowCpu
                    }

                    SettingsToggleRow {
                        visible: SettingsData.systemMonitorShowCpu
                        text: I18n.tr("CPU Graph")
                        checked: SettingsData.systemMonitorShowCpuGraph
                        onToggled: checked => SettingsData.set("systemMonitorShowCpuGraph", checked)
                    }

                    SettingsDivider {
                        visible: SettingsData.systemMonitorShowCpu
                    }

                    SettingsToggleRow {
                        visible: SettingsData.systemMonitorShowCpu
                        text: I18n.tr("CPU Temperature")
                        checked: SettingsData.systemMonitorShowCpuTemp
                        onToggled: checked => SettingsData.set("systemMonitorShowCpuTemp", checked)
                    }

                    SettingsDivider {}

                    SettingsToggleRow {
                        text: I18n.tr("GPU Temperature")
                        checked: SettingsData.systemMonitorShowGpuTemp
                        onToggled: checked => SettingsData.set("systemMonitorShowGpuTemp", checked)
                    }

                    SettingsDivider {
                        visible: SettingsData.systemMonitorShowGpuTemp && DgopService.availableGpus.length > 0
                    }

                    Item {
                        width: parent.width
                        height: gpuSelectColumn.height + Theme.spacingM * 2
                        visible: SettingsData.systemMonitorShowGpuTemp && DgopService.availableGpus.length > 0

                        Column {
                            id: gpuSelectColumn
                            width: parent.width - Theme.spacingM * 2
                            x: Theme.spacingM
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Theme.spacingS

                            StyledText {
                                text: I18n.tr("GPU")
                                font.pixelSize: Theme.fontSizeMedium
                                color: Theme.surfaceText
                            }

                            Column {
                                width: parent.width
                                spacing: Theme.spacingXS

                                Repeater {
                                    model: DgopService.availableGpus

                                    Rectangle {
                                        required property var modelData

                                        width: parent.width
                                        height: 44
                                        radius: Theme.cornerRadius
                                        color: SettingsData.systemMonitorGpuPciId === modelData.pciId ? Theme.primarySelected : Theme.surfaceHover
                                        border.color: SettingsData.systemMonitorGpuPciId === modelData.pciId ? Theme.primary : "transparent"
                                        border.width: 2

                                        Row {
                                            anchors.fill: parent
                                            anchors.margins: Theme.spacingS
                                            spacing: Theme.spacingS

                                            DankIcon {
                                                name: "videocam"
                                                size: Theme.iconSizeSmall
                                                color: SettingsData.systemMonitorGpuPciId === modelData.pciId ? Theme.primary : Theme.surfaceVariantText
                                                anchors.verticalCenter: parent.verticalCenter
                                            }

                                            Column {
                                                width: parent.width - Theme.iconSizeSmall - Theme.spacingS
                                                anchors.verticalCenter: parent.verticalCenter
                                                spacing: 0

                                                StyledText {
                                                    text: modelData.displayName || "Unknown GPU"
                                                    font.pixelSize: Theme.fontSizeSmall
                                                    color: Theme.surfaceText
                                                    width: parent.width
                                                    elide: Text.ElideRight
                                                }

                                                StyledText {
                                                    text: modelData.driver || ""
                                                    font.pixelSize: Theme.fontSizeSmall - 2
                                                    color: Theme.surfaceVariantText
                                                    visible: text !== ""
                                                }
                                            }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: SettingsData.set("systemMonitorGpuPciId", modelData.pciId)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    SettingsDivider {}

                    SettingsToggleRow {
                        text: I18n.tr("Memory")
                        checked: SettingsData.systemMonitorShowMemory
                        onToggled: checked => SettingsData.set("systemMonitorShowMemory", checked)
                    }

                    SettingsDivider {
                        visible: SettingsData.systemMonitorShowMemory
                    }

                    SettingsToggleRow {
                        visible: SettingsData.systemMonitorShowMemory
                        text: I18n.tr("Memory Graph")
                        checked: SettingsData.systemMonitorShowMemoryGraph
                        onToggled: checked => SettingsData.set("systemMonitorShowMemoryGraph", checked)
                    }

                    SettingsDivider {}

                    SettingsToggleRow {
                        text: I18n.tr("Network")
                        checked: SettingsData.systemMonitorShowNetwork
                        onToggled: checked => SettingsData.set("systemMonitorShowNetwork", checked)
                    }

                    SettingsDivider {
                        visible: SettingsData.systemMonitorShowNetwork
                    }

                    SettingsToggleRow {
                        visible: SettingsData.systemMonitorShowNetwork
                        text: I18n.tr("Network Graph")
                        checked: SettingsData.systemMonitorShowNetworkGraph
                        onToggled: checked => SettingsData.set("systemMonitorShowNetworkGraph", checked)
                    }

                    SettingsDivider {}

                    SettingsToggleRow {
                        text: I18n.tr("Disk")
                        checked: SettingsData.systemMonitorShowDisk
                        onToggled: checked => SettingsData.set("systemMonitorShowDisk", checked)
                    }

                    SettingsDivider {}

                    SettingsToggleRow {
                        text: I18n.tr("Top Processes")
                        checked: SettingsData.systemMonitorShowTopProcesses
                        onToggled: checked => SettingsData.set("systemMonitorShowTopProcesses", checked)
                    }

                    SettingsDivider {
                        visible: SettingsData.systemMonitorShowTopProcesses
                    }

                    Item {
                        width: parent.width
                        height: topProcessesColumn.height + Theme.spacingM * 2
                        visible: SettingsData.systemMonitorShowTopProcesses

                        Column {
                            id: topProcessesColumn
                            width: parent.width - Theme.spacingM * 2
                            x: Theme.spacingM
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Theme.spacingM

                            Row {
                                width: parent.width
                                spacing: Theme.spacingM

                                StyledText {
                                    width: parent.width - processCountButtons.width - Theme.spacingM
                                    text: I18n.tr("Process Count")
                                    font.pixelSize: Theme.fontSizeMedium
                                    color: Theme.surfaceText
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                DankButtonGroup {
                                    id: processCountButtons
                                    model: ["3", "5", "10"]
                                    currentIndex: {
                                        switch (SettingsData.systemMonitorTopProcessCount) {
                                        case 3:
                                            return 0;
                                        case 5:
                                            return 1;
                                        case 10:
                                            return 2;
                                        default:
                                            return 1;
                                        }
                                    }
                                    buttonHeight: 32
                                    minButtonWidth: 36
                                    textSize: Theme.fontSizeSmall
                                    checkEnabled: false
                                    onSelectionChanged: (index, selected) => {
                                        if (!selected)
                                            return;
                                        const values = [3, 5, 10];
                                        SettingsData.set("systemMonitorTopProcessCount", values[index]);
                                    }
                                }
                            }

                            Row {
                                width: parent.width
                                spacing: Theme.spacingM

                                StyledText {
                                    width: parent.width - sortByButtons.width - Theme.spacingM
                                    text: I18n.tr("Sort By")
                                    font.pixelSize: Theme.fontSizeMedium
                                    color: Theme.surfaceText
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                DankButtonGroup {
                                    id: sortByButtons
                                    model: ["CPU", "MEM"]
                                    currentIndex: SettingsData.systemMonitorTopProcessSortBy === "cpu" ? 0 : 1
                                    buttonHeight: 32
                                    minButtonWidth: 48
                                    textSize: Theme.fontSizeSmall
                                    checkEnabled: false
                                    onSelectionChanged: (index, selected) => {
                                        if (!selected)
                                            return;
                                        SettingsData.set("systemMonitorTopProcessSortBy", index === 0 ? "cpu" : "memory");
                                    }
                                }
                            }
                        }
                    }

                    SettingsDivider {}

                    SettingsDropdownRow {
                        text: I18n.tr("Layout")
                        options: [I18n.tr("Auto"), I18n.tr("Grid"), I18n.tr("List")]
                        currentValue: {
                            switch (SettingsData.systemMonitorLayoutMode) {
                            case "grid":
                                return I18n.tr("Grid");
                            case "list":
                                return I18n.tr("List");
                            default:
                                return I18n.tr("Auto");
                            }
                        }
                        onValueChanged: value => {
                            switch (value) {
                            case I18n.tr("Grid"):
                                SettingsData.set("systemMonitorLayoutMode", "grid");
                                return;
                            case I18n.tr("List"):
                                SettingsData.set("systemMonitorLayoutMode", "list");
                                return;
                            default:
                                SettingsData.set("systemMonitorLayoutMode", "auto");
                            }
                        }
                    }

                    SettingsDivider {}

                    SettingsSliderRow {
                        text: I18n.tr("Transparency")
                        minimum: 0
                        maximum: 100
                        value: Math.round(SettingsData.systemMonitorTransparency * 100)
                        unit: "%"
                        onSliderValueChanged: newValue => SettingsData.set("systemMonitorTransparency", newValue / 100)
                    }

                    SettingsDivider {}

                    SettingsColorPicker {
                        colorMode: SettingsData.systemMonitorColorMode
                        customColor: SettingsData.systemMonitorCustomColor
                        onColorModeSelected: mode => SettingsData.set("systemMonitorColorMode", mode)
                        onCustomColorSelected: selectedColor => SettingsData.set("systemMonitorCustomColor", selectedColor.toString())
                    }

                    SettingsDivider {}

                    SettingsDisplayPicker {
                        displayPreferences: SettingsData.systemMonitorDisplayPreferences
                        onPreferencesChanged: prefs => SettingsData.set("systemMonitorDisplayPreferences", prefs)
                    }

                    SettingsDivider {}

                    Item {
                        width: parent.width
                        height: sysMonResetRow.height + Theme.spacingM * 2

                        Row {
                            id: sysMonResetRow
                            x: Theme.spacingM
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Theme.spacingM

                            DankButton {
                                text: I18n.tr("Reset Position")
                                backgroundColor: Theme.surfaceHover
                                textColor: Theme.surfaceText
                                buttonHeight: 36
                                onClicked: {
                                    SettingsData.set("systemMonitorX", -1);
                                    SettingsData.set("systemMonitorY", -1);
                                }
                            }

                            DankButton {
                                text: I18n.tr("Reset Size")
                                backgroundColor: Theme.surfaceHover
                                textColor: Theme.surfaceText
                                buttonHeight: 36
                                onClicked: {
                                    SettingsData.set("systemMonitorWidth", 320);
                                    SettingsData.set("systemMonitorHeight", 480);
                                }
                            }
                        }
                    }

                    SettingsDivider {}

                    Item {
                        width: parent.width
                        height: variantsColumn.height + Theme.spacingM * 2

                        Column {
                            id: variantsColumn
                            width: parent.width - Theme.spacingM * 2
                            x: Theme.spacingM
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Theme.spacingM

                            Row {
                                width: parent.width
                                spacing: Theme.spacingM

                                StyledText {
                                    width: parent.width - addVariantBtn.width - Theme.spacingM
                                    text: I18n.tr("Widget Variants")
                                    font.pixelSize: Theme.fontSizeMedium
                                    color: Theme.surfaceText
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                DankButton {
                                    id: addVariantBtn
                                    text: I18n.tr("Add")
                                    iconName: "add"
                                    onClicked: {
                                        const variant = SettingsData.createSystemMonitorVariant("Monitor " + (SettingsData.systemMonitorVariants.length + 1), SettingsData.getDefaultSystemMonitorConfig());
                                        if (variant)
                                            ToastService.showInfo(I18n.tr("Variant created - expand to configure"));
                                    }
                                }
                            }

                            Column {
                                id: variantsListColumn
                                width: parent.width
                                spacing: Theme.spacingS
                                visible: SettingsData.systemMonitorVariants.length > 0

                                property var expandedStates: ({})

                                Repeater {
                                    model: SettingsData.systemMonitorVariants

                                    SystemMonitorVariantCard {
                                        required property var modelData
                                        required property int index

                                        width: parent.width
                                        variant: modelData
                                        expanded: variantsListColumn.expandedStates[modelData.id] || false

                                        onExpandToggled: isExpanded => {
                                            var states = JSON.parse(JSON.stringify(variantsListColumn.expandedStates));
                                            states[modelData.id] = isExpanded;
                                            variantsListColumn.expandedStates = states;
                                        }

                                        onDeleteRequested: {
                                            SettingsData.removeSystemMonitorVariant(modelData.id);
                                            ToastService.showInfo(I18n.tr("Variant removed"));
                                        }

                                        onNameChanged: newName => {
                                            SettingsData.updateSystemMonitorVariant(modelData.id, {
                                                name: newName
                                            });
                                        }

                                        onConfigChanged: (key, value) => {
                                            var update = {};
                                            update[key] = value;
                                            SettingsData.updateSystemMonitorVariant(modelData.id, update);
                                        }
                                    }
                                }
                            }

                            StyledText {
                                visible: SettingsData.systemMonitorVariants.length === 0
                                text: I18n.tr("No variants created. Click Add to create a new monitor widget.")
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceVariantText
                                width: parent.width
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                }
            }

            SettingsCard {
                width: parent.width
                iconName: "info"
                title: I18n.tr("Help")

                Column {
                    width: parent.width - Theme.spacingM * 2
                    x: Theme.spacingM
                    spacing: Theme.spacingM

                    Row {
                        spacing: Theme.spacingM

                        Rectangle {
                            width: 40
                            height: 40
                            radius: 20
                            color: Theme.primarySelected

                            DankIcon {
                                anchors.centerIn: parent
                                name: "drag_pan"
                                size: Theme.iconSize
                                color: Theme.primary
                            }
                        }

                        Column {
                            spacing: 2
                            anchors.verticalCenter: parent.verticalCenter

                            StyledText {
                                text: I18n.tr("Move Widget")
                                font.pixelSize: Theme.fontSizeMedium
                                font.weight: Font.Medium
                                color: Theme.surfaceText
                            }

                            StyledText {
                                text: I18n.tr("Right-click and drag anywhere on the widget")
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceVariantText
                            }
                        }
                    }

                    Row {
                        spacing: Theme.spacingM

                        Rectangle {
                            width: 40
                            height: 40
                            radius: 20
                            color: Theme.primarySelected

                            DankIcon {
                                anchors.centerIn: parent
                                name: "open_in_full"
                                size: Theme.iconSize
                                color: Theme.primary
                            }
                        }

                        Column {
                            spacing: 2
                            anchors.verticalCenter: parent.verticalCenter

                            StyledText {
                                text: I18n.tr("Resize Widget")
                                font.pixelSize: Theme.fontSizeMedium
                                font.weight: Font.Medium
                                color: Theme.surfaceText
                            }

                            StyledText {
                                text: I18n.tr("Right-click and drag the bottom-right corner")
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceVariantText
                            }
                        }
                    }
                }
            }
        }
    }
}
