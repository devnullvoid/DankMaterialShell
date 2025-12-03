pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.Common
import qs.Services
import qs.Widgets

Item {
    id: keybindsTab

    property var parentModal: null
    property string selectedCategory: ""
    property string searchQuery: ""
    property string expandedKey: ""
    property bool showingNewBind: false

    property int _lastDataVersion: -1
    property var _cachedCategories: []
    property var _filteredBinds: []

    function _updateFiltered() {
        const allBinds = KeybindsService.getFlatBinds();
        if (!searchQuery && !selectedCategory) {
            _filteredBinds = allBinds;
            return;
        }

        const q = searchQuery.toLowerCase();
        const isOverrideFilter = selectedCategory === "__overrides__";
        const result = [];

        for (let i = 0; i < allBinds.length; i++) {
            const group = allBinds[i];
            if (q) {
                let keyMatch = false;
                for (let k = 0; k < group.keys.length; k++) {
                    if (group.keys[k].key.toLowerCase().indexOf(q) !== -1) {
                        keyMatch = true;
                        break;
                    }
                }
                if (!keyMatch && group.desc.toLowerCase().indexOf(q) === -1 && group.action.toLowerCase().indexOf(q) === -1)
                    continue;
            }
            if (isOverrideFilter) {
                let hasOverride = false;
                for (let k = 0; k < group.keys.length; k++) {
                    if (group.keys[k].isOverride) {
                        hasOverride = true;
                        break;
                    }
                }
                if (!hasOverride)
                    continue;
            } else if (selectedCategory && group.category !== selectedCategory) {
                continue;
            }
            result.push(group);
        }
        _filteredBinds = result;
    }

    function _updateCategories() {
        _cachedCategories = ["__overrides__"].concat(KeybindsService.getCategories());
    }

    function getCategoryLabel(cat) {
        if (cat === "__overrides__")
            return I18n.tr("Overrides");
        return cat;
    }

    function toggleExpanded(action) {
        expandedKey = expandedKey === action ? "" : action;
    }

    function startNewBind() {
        showingNewBind = true;
        expandedKey = "";
    }

    function cancelNewBind() {
        showingNewBind = false;
    }

    function saveNewBind(bindData) {
        KeybindsService.saveBind("", bindData);
        showingNewBind = false;
    }

    function scrollToTop() {
        flickable.contentY = 0;
    }

    Timer {
        id: searchDebounce
        interval: 150
        onTriggered: keybindsTab._updateFiltered()
    }

    Connections {
        target: KeybindsService
        function onBindsLoaded() {
            keybindsTab._lastDataVersion = KeybindsService._dataVersion;
            keybindsTab._updateCategories();
            keybindsTab._updateFiltered();
        }
    }

    function _ensureNiriProvider() {
        if (!KeybindsService.available)
            return;
        const cachedProvider = KeybindsService.keybinds?.provider;
        if (cachedProvider !== "niri" || KeybindsService._dataVersion === 0) {
            KeybindsService.currentProvider = "niri";
            KeybindsService.loadBinds();
            return;
        }
        if (_lastDataVersion !== KeybindsService._dataVersion) {
            _lastDataVersion = KeybindsService._dataVersion;
            _updateCategories();
            _updateFiltered();
        }
    }

    Component.onCompleted: _ensureNiriProvider()

    onVisibleChanged: {
        if (!visible)
            return;
        Qt.callLater(scrollToTop);
        _ensureNiriProvider();
    }

    DankFlickable {
        id: flickable
        anchors.fill: parent
        clip: true
        contentWidth: width
        contentHeight: contentColumn.implicitHeight

        Column {
            id: contentColumn
            width: flickable.width
            spacing: Theme.spacingL
            topPadding: Theme.spacingXL
            bottomPadding: Theme.spacingXL

            StyledRect {
                width: Math.min(650, parent.width - Theme.spacingL * 2)
                height: headerSection.implicitHeight + Theme.spacingL * 2
                anchors.horizontalCenter: parent.horizontalCenter
                radius: Theme.cornerRadius
                color: Theme.withAlpha(Theme.surfaceContainerHigh, Theme.popupTransparency)
                border.width: 0

                Column {
                    id: headerSection
                    anchors.fill: parent
                    anchors.margins: Theme.spacingL
                    spacing: Theme.spacingM

                    Row {
                        width: parent.width
                        spacing: Theme.spacingM

                        DankIcon {
                            name: "keyboard"
                            size: Theme.iconSize
                            color: Theme.primary
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Column {
                            width: parent.width - Theme.iconSize - Theme.spacingM * 2
                            spacing: Theme.spacingXS
                            anchors.verticalCenter: parent.verticalCenter

                            StyledText {
                                text: I18n.tr("Keyboard Shortcuts")
                                font.pixelSize: Theme.fontSizeLarge
                                font.weight: Font.Medium
                                color: Theme.surfaceText
                            }

                            StyledText {
                                text: I18n.tr("Click any shortcut to edit. Changes save to dms/binds.kdl")
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceVariantText
                                wrapMode: Text.WordWrap
                                width: parent.width
                            }
                        }
                    }

                    Row {
                        width: parent.width
                        spacing: Theme.spacingM

                        DankTextField {
                            id: searchField
                            width: parent.width - addButton.width - Theme.spacingM
                            height: 44
                            placeholderText: I18n.tr("Search keybinds...")
                            leftIconName: "search"
                            onTextChanged: {
                                keybindsTab.searchQuery = text;
                                searchDebounce.restart();
                            }
                        }

                        DankActionButton {
                            id: addButton
                            width: 44
                            height: 44
                            circular: false
                            iconName: "add"
                            iconSize: Theme.iconSize
                            iconColor: Theme.primary
                            anchors.verticalCenter: parent.verticalCenter
                            enabled: !keybindsTab.showingNewBind
                            opacity: enabled ? 1 : 0.5
                            onClicked: keybindsTab.startNewBind()
                        }
                    }
                }
            }

            StyledRect {
                width: Math.min(650, parent.width - Theme.spacingL * 2)
                height: warningSection.implicitHeight + Theme.spacingL * 2
                anchors.horizontalCenter: parent.horizontalCenter
                radius: Theme.cornerRadius
                color: Theme.withAlpha(Theme.error, 0.15)
                border.color: Theme.withAlpha(Theme.error, 0.3)
                border.width: 1
                visible: !KeybindsService.dmsBindsIncluded && !KeybindsService.loading

                Column {
                    id: warningSection
                    anchors.fill: parent
                    anchors.margins: Theme.spacingL
                    spacing: Theme.spacingM

                    Row {
                        width: parent.width
                        spacing: Theme.spacingM

                        DankIcon {
                            name: "warning"
                            size: Theme.iconSize
                            color: Theme.error
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Column {
                            width: parent.width - Theme.iconSize - 100 - Theme.spacingM * 2
                            spacing: Theme.spacingXS
                            anchors.verticalCenter: parent.verticalCenter

                            StyledText {
                                text: I18n.tr("Binds Include Missing")
                                font.pixelSize: Theme.fontSizeMedium
                                font.weight: Font.Medium
                                color: Theme.error
                            }

                            StyledText {
                                text: I18n.tr("dms/binds.kdl is not included in config.kdl. Custom keybinds will not work until this is fixed.")
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceVariantText
                                wrapMode: Text.WordWrap
                                width: parent.width
                            }
                        }

                        Rectangle {
                            id: fixButton
                            width: fixButtonText.implicitWidth + Theme.spacingL * 2
                            height: 36
                            radius: Theme.cornerRadius
                            color: KeybindsService.fixing ? Theme.withAlpha(Theme.error, 0.6) : Theme.error
                            anchors.verticalCenter: parent.verticalCenter

                            StyledText {
                                id: fixButtonText
                                text: KeybindsService.fixing ? I18n.tr("Fixing...") : I18n.tr("Fix Now")
                                font.pixelSize: Theme.fontSizeSmall
                                font.weight: Font.Medium
                                color: Theme.surface
                                anchors.centerIn: parent
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                enabled: !KeybindsService.fixing
                                onClicked: KeybindsService.fixDmsBindsInclude()
                            }
                        }
                    }
                }
            }

            StyledRect {
                width: Math.min(650, parent.width - Theme.spacingL * 2)
                height: categorySection.implicitHeight + Theme.spacingL * 2
                anchors.horizontalCenter: parent.horizontalCenter
                radius: Theme.cornerRadius
                color: Theme.withAlpha(Theme.surfaceContainerHigh, Theme.popupTransparency)
                border.width: 0

                Column {
                    id: categorySection
                    anchors.fill: parent
                    anchors.margins: Theme.spacingL
                    spacing: Theme.spacingM

                    Flow {
                        width: parent.width
                        spacing: Theme.spacingS

                        Rectangle {
                            width: allChip.implicitWidth + Theme.spacingL
                            height: 32
                            radius: 16
                            color: !keybindsTab.selectedCategory ? Theme.primary : Theme.surfaceContainerHighest

                            StyledText {
                                id: allChip
                                text: I18n.tr("All")
                                font.pixelSize: Theme.fontSizeSmall
                                color: !keybindsTab.selectedCategory ? Theme.primaryText : Theme.surfaceVariantText
                                anchors.centerIn: parent
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    keybindsTab.selectedCategory = "";
                                    keybindsTab._updateFiltered();
                                }
                            }
                        }

                        Repeater {
                            model: keybindsTab._cachedCategories

                            delegate: Rectangle {
                                required property string modelData
                                required property int index

                                width: catText.implicitWidth + Theme.spacingL
                                height: 32
                                radius: 16
                                color: keybindsTab.selectedCategory === modelData ? Theme.primary : (modelData === "__overrides__" ? Theme.withAlpha(Theme.primary, 0.15) : Theme.surfaceContainerHighest)

                                StyledText {
                                    id: catText
                                    text: keybindsTab.getCategoryLabel(modelData)
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: keybindsTab.selectedCategory === modelData ? Theme.primaryText : (modelData === "__overrides__" ? Theme.primary : Theme.surfaceVariantText)
                                    anchors.centerIn: parent
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        keybindsTab.selectedCategory = modelData;
                                        keybindsTab._updateFiltered();
                                    }
                                }
                            }
                        }
                    }
                }
            }

            StyledRect {
                width: Math.min(650, parent.width - Theme.spacingL * 2)
                height: newBindSection.implicitHeight + Theme.spacingL * 2
                anchors.horizontalCenter: parent.horizontalCenter
                radius: Theme.cornerRadius
                color: Theme.withAlpha(Theme.surfaceContainerHigh, Theme.popupTransparency)
                border.color: Theme.outlineVariant
                border.width: 1
                visible: keybindsTab.showingNewBind

                Column {
                    id: newBindSection
                    anchors.fill: parent
                    anchors.margins: Theme.spacingL
                    spacing: Theme.spacingM

                    Row {
                        width: parent.width
                        spacing: Theme.spacingM

                        DankIcon {
                            name: "add"
                            size: Theme.iconSize
                            color: Theme.surfaceText
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        StyledText {
                            text: I18n.tr("New Keybind")
                            font.pixelSize: Theme.fontSizeMedium
                            font.weight: Font.Medium
                            color: Theme.surfaceText
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    KeybindItem {
                        width: parent.width
                        isNew: true
                        isExpanded: true
                        bindData: ({
                                keys: [
                                    {
                                        key: "",
                                        source: "dms",
                                        isOverride: true
                                    }
                                ],
                                action: "",
                                desc: ""
                            })
                        panelWindow: keybindsTab.parentModal
                        onSaveBind: (originalKey, newData) => keybindsTab.saveNewBind(newData)
                        onCancelEdit: keybindsTab.cancelNewBind()
                    }
                }
            }

            StyledRect {
                width: Math.min(650, parent.width - Theme.spacingL * 2)
                height: bindsListHeader.implicitHeight + Theme.spacingL * 2
                anchors.horizontalCenter: parent.horizontalCenter
                radius: Theme.cornerRadius
                color: Theme.withAlpha(Theme.surfaceContainerHigh, Theme.popupTransparency)
                border.width: 0

                Column {
                    id: bindsListHeader
                    anchors.fill: parent
                    anchors.margins: Theme.spacingL
                    spacing: Theme.spacingM

                    Row {
                        width: parent.width
                        spacing: Theme.spacingM

                        DankIcon {
                            name: "list"
                            size: Theme.iconSize
                            color: Theme.primary
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        StyledText {
                            text: KeybindsService.loading ? I18n.tr("Shortcuts") : I18n.tr("Shortcuts") + " (" + keybindsTab._filteredBinds.length + ")"
                            font.pixelSize: Theme.fontSizeMedium
                            font.weight: Font.Medium
                            color: Theme.surfaceText
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Row {
                        width: parent.width
                        spacing: Theme.spacingM
                        visible: KeybindsService.loading

                        DankIcon {
                            id: loadingIcon
                            name: "sync"
                            size: 20
                            color: Theme.primary
                            anchors.verticalCenter: parent.verticalCenter

                            RotationAnimation on rotation {
                                from: 0
                                to: 360
                                duration: 1000
                                loops: Animation.Infinite
                                running: KeybindsService.loading
                            }
                        }

                        StyledText {
                            text: I18n.tr("Loading keybinds...")
                            font.pixelSize: Theme.fontSizeMedium
                            color: Theme.surfaceVariantText
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    StyledText {
                        text: I18n.tr("No keybinds found")
                        font.pixelSize: Theme.fontSizeMedium
                        color: Theme.surfaceVariantText
                        visible: !KeybindsService.loading && keybindsTab._filteredBinds.length === 0
                    }
                }
            }

            Column {
                width: parent.width
                spacing: Theme.spacingXS

                Repeater {
                    model: ScriptModel {
                        values: keybindsTab._filteredBinds
                        objectProp: "action"
                    }

                    delegate: Item {
                        required property var modelData
                        required property int index

                        width: parent.width
                        height: bindItem.height

                        KeybindItem {
                            id: bindItem
                            width: Math.min(650, parent.width - Theme.spacingL * 2)
                            anchors.horizontalCenter: parent.horizontalCenter
                            bindData: modelData
                            isExpanded: keybindsTab.expandedKey === modelData.action
                            panelWindow: keybindsTab.parentModal
                            onToggleExpand: keybindsTab.toggleExpanded(modelData.action)
                            onSaveBind: (originalKey, newData) => {
                                KeybindsService.saveBind(originalKey, newData);
                                keybindsTab.expandedKey = modelData.action;
                            }
                            onRemoveBind: key => KeybindsService.removeBind(key)
                        }
                    }
                }
            }
        }
    }
}
