import QtQuick
import qs.Common
import qs.Modals.Spotlight
import qs.Modules.AppDrawer
import qs.Widgets

DankPopout {
    id: appDrawerPopout

    layerNamespace: "dms:app-launcher"

    property string searchMode: "apps"
    property alias fileSearch: fileSearchController
    property bool editMode: false
    property var editingApp: null
    property string editAppId: ""

    function openEditMode(app) {
        if (!app)
            return;
        editingApp = app;
        editAppId = app.id || app.execString || app.exec || "";
        const existing = SessionData.getAppOverride(editAppId);
        if (contentLoader.item) {
            contentLoader.item.searchField.focus = false;
            contentLoader.item.editNameField.text = existing?.name || "";
            contentLoader.item.editIconField.text = existing?.icon || "";
            contentLoader.item.editCommentField.text = existing?.comment || "";
            contentLoader.item.editEnvVarsField.text = existing?.envVars || "";
            contentLoader.item.editExtraFlagsField.text = existing?.extraFlags || "";
        }
        editMode = true;
        Qt.callLater(() => {
            if (contentLoader.item?.editNameField)
                contentLoader.item.editNameField.forceActiveFocus();
        });
    }

    function closeEditMode() {
        editMode = false;
        editingApp = null;
        editAppId = "";
        Qt.callLater(() => {
            if (contentLoader.item?.searchField)
                contentLoader.item.searchField.forceActiveFocus();
        });
    }

    function saveAppOverride() {
        const override = {};
        if (contentLoader.item) {
            if (contentLoader.item.editNameField.text.trim())
                override.name = contentLoader.item.editNameField.text.trim();
            if (contentLoader.item.editIconField.text.trim())
                override.icon = contentLoader.item.editIconField.text.trim();
            if (contentLoader.item.editCommentField.text.trim())
                override.comment = contentLoader.item.editCommentField.text.trim();
            if (contentLoader.item.editEnvVarsField.text.trim())
                override.envVars = contentLoader.item.editEnvVarsField.text.trim();
            if (contentLoader.item.editExtraFlagsField.text.trim())
                override.extraFlags = contentLoader.item.editExtraFlagsField.text.trim();
        }
        SessionData.setAppOverride(editAppId, override);
        closeEditMode();
    }

    function resetAppOverride() {
        SessionData.clearAppOverride(editAppId);
        closeEditMode();
    }

    function updateSearchMode(text) {
        if (text.startsWith("/")) {
            if (searchMode === "files") {
                fileSearchController.searchQuery = text.substring(1);
                return;
            }
            searchMode = "files";
            fileSearchController.searchQuery = text.substring(1);
            return;
        }
        if (searchMode === "apps") {
            return;
        }
        searchMode = "apps";
        fileSearchController.reset();
        appLauncher.searchQuery = text;
    }

    function show() {
        open();
    }

    popupWidth: 520
    popupHeight: 600
    triggerWidth: 40
    positioning: ""
    contentHandlesKeys: editMode

    onBackgroundClicked: {
        if (contextMenu.visible) {
            contextMenu.close();
            return;
        }
        if (editMode) {
            closeEditMode();
            return;
        }
        close();
    }

    onOpened: {
        searchMode = "apps";
        editMode = false;
        editingApp = null;
        editAppId = "";
        appLauncher.ensureInitialized();
        appLauncher.searchQuery = "";
        appLauncher.selectedIndex = 0;
        appLauncher.setCategory(I18n.tr("All"));
        fileSearchController.reset();
        if (contentLoader.item?.searchField) {
            contentLoader.item.searchField.text = "";
            contentLoader.item.searchField.forceActiveFocus();
        }
        contextMenu.parent = contentLoader.item;
    }

    AppLauncher {
        id: appLauncher

        viewMode: SettingsData.appLauncherViewMode
        gridColumns: SettingsData.appLauncherGridColumns
        onAppLaunched: appDrawerPopout.close()
        onViewModeSelected: function (mode) {
            SettingsData.set("appLauncherViewMode", mode);
        }
    }

    FileSearchController {
        id: fileSearchController

        onFileOpened: appDrawerPopout.close()
    }

    onSearchModeChanged: {
        switch (searchMode) {
        case "files":
            appLauncher.keyboardNavigationActive = false;
            break;
        case "apps":
            fileSearchController.keyboardNavigationActive = false;
            break;
        }
    }

    content: Component {
        Rectangle {
            id: launcherPanel

            LayoutMirroring.enabled: I18n.isRtl
            LayoutMirroring.childrenInherit: true

            property alias searchField: searchField
            property alias keyHandler: keyHandler
            property alias editNameField: editNameField
            property alias editIconField: editIconField
            property alias editCommentField: editCommentField
            property alias editEnvVarsField: editEnvVarsField
            property alias editExtraFlagsField: editExtraFlagsField

            focus: true
            color: "transparent"

            Keys.onPressed: function (event) {
                if (appDrawerPopout.editMode) {
                    switch (event.key) {
                    case Qt.Key_Escape:
                        appDrawerPopout.closeEditMode();
                        event.accepted = true;
                        return;
                    case Qt.Key_Return:
                    case Qt.Key_Enter:
                        if (event.modifiers & Qt.ControlModifier) {
                            appDrawerPopout.saveAppOverride();
                            event.accepted = true;
                        }
                        return;
                    case Qt.Key_S:
                        if (event.modifiers & Qt.ControlModifier) {
                            appDrawerPopout.saveAppOverride();
                            event.accepted = true;
                        }
                        return;
                    case Qt.Key_R:
                        if ((event.modifiers & Qt.ControlModifier) && SessionData.getAppOverride(appDrawerPopout.editAppId) !== null) {
                            appDrawerPopout.resetAppOverride();
                            event.accepted = true;
                        }
                        return;
                    }
                }
            }
            radius: Theme.cornerRadius
            antialiasing: true
            smooth: true

            // Multi-layer border effect
            Repeater {
                model: [
                    {
                        "margin": -3,
                        "color": Qt.rgba(0, 0, 0, 0.05),
                        "z": -3
                    },
                    {
                        "margin": -2,
                        "color": Qt.rgba(0, 0, 0, 0.08),
                        "z": -2
                    },
                    {
                        "margin": 0,
                        "color": Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.12),
                        "z": -1
                    }
                ]
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: modelData.margin
                    color: "transparent"
                    radius: parent.radius + Math.abs(modelData.margin)
                    border.color: modelData.color
                    border.width: 0
                    z: modelData.z
                }
            }

            Item {
                id: keyHandler

                anchors.fill: parent
                focus: !appDrawerPopout.editMode

                function selectNext() {
                    switch (appDrawerPopout.searchMode) {
                    case "files":
                        fileSearchController.selectNext();
                        return;
                    default:
                        appLauncher.selectNext();
                    }
                }

                function selectPrevious() {
                    switch (appDrawerPopout.searchMode) {
                    case "files":
                        fileSearchController.selectPrevious();
                        return;
                    default:
                        appLauncher.selectPrevious();
                    }
                }

                function activateSelected() {
                    switch (appDrawerPopout.searchMode) {
                    case "files":
                        fileSearchController.openSelected();
                        return;
                    default:
                        appLauncher.launchSelected();
                    }
                }

                function getSelectedItemPosition() {
                    const index = appLauncher.selectedIndex;
                    if (appLauncher.viewMode === "list") {
                        const y = index * (appList.itemHeight + appList.itemSpacing) - appList.contentY;
                        return Qt.point(appList.width / 2, y + appList.itemHeight / 2 + appList.y);
                    }
                    const row = Math.floor(index / appGrid.actualColumns);
                    const col = index % appGrid.actualColumns;
                    const x = col * appGrid.cellWidth + appGrid.cellWidth / 2;
                    const y = row * appGrid.cellHeight - appGrid.contentY + appGrid.cellHeight / 2 + appGrid.y;
                    return Qt.point(x, y);
                }

                function openContextMenuForSelected() {
                    if (appDrawerPopout.searchMode !== "apps" || appLauncher.model.count === 0)
                        return;
                    const selectedApp = appLauncher.model.get(appLauncher.selectedIndex);
                    if (!selectedApp)
                        return;
                    const pos = getSelectedItemPosition();
                    contextMenu.show(pos.x, pos.y, selectedApp, true);
                }

                readonly property var keyMappings: {
                    const mappings = {};
                    mappings[Qt.Key_Escape] = () => appDrawerPopout.close();
                    mappings[Qt.Key_Down] = () => keyHandler.selectNext();
                    mappings[Qt.Key_Up] = () => keyHandler.selectPrevious();
                    mappings[Qt.Key_Return] = () => keyHandler.activateSelected();
                    mappings[Qt.Key_Enter] = () => keyHandler.activateSelected();
                    mappings[Qt.Key_Tab] = () => appDrawerPopout.searchMode === "apps" && appLauncher.viewMode === "grid" ? appLauncher.selectNextInRow() : keyHandler.selectNext();
                    mappings[Qt.Key_Backtab] = () => appDrawerPopout.searchMode === "apps" && appLauncher.viewMode === "grid" ? appLauncher.selectPreviousInRow() : keyHandler.selectPrevious();
                    mappings[Qt.Key_Menu] = () => keyHandler.openContextMenuForSelected();
                    mappings[Qt.Key_F10] = () => keyHandler.openContextMenuForSelected();

                    if (appDrawerPopout.searchMode === "apps" && appLauncher.viewMode === "grid") {
                        mappings[Qt.Key_Right] = () => I18n.isRtl ? appLauncher.selectPreviousInRow() : appLauncher.selectNextInRow();
                        mappings[Qt.Key_Left] = () => I18n.isRtl ? appLauncher.selectNextInRow() : appLauncher.selectPreviousInRow();
                    }

                    return mappings;
                }

                Keys.onPressed: function (event) {
                    if (appDrawerPopout.editMode)
                        return;

                    if (keyMappings[event.key]) {
                        keyMappings[event.key]();
                        event.accepted = true;
                        return;
                    }

                    const hasCtrl = event.modifiers & Qt.ControlModifier;
                    if (!hasCtrl)
                        return;

                    switch (event.key) {
                    case Qt.Key_N:
                    case Qt.Key_J:
                        keyHandler.selectNext();
                        event.accepted = true;
                        return;
                    case Qt.Key_P:
                    case Qt.Key_K:
                        keyHandler.selectPrevious();
                        event.accepted = true;
                        return;
                    case Qt.Key_L:
                        if (appDrawerPopout.searchMode === "apps" && appLauncher.viewMode === "grid") {
                            I18n.isRtl ? appLauncher.selectPreviousInRow() : appLauncher.selectNextInRow();
                            event.accepted = true;
                        }
                        return;
                    case Qt.Key_H:
                        if (appDrawerPopout.searchMode === "apps" && appLauncher.viewMode === "grid") {
                            I18n.isRtl ? appLauncher.selectNextInRow() : appLauncher.selectPreviousInRow();
                            event.accepted = true;
                        }
                        return;
                    }
                }

                Column {
                    width: parent.width - Theme.spacingS * 2
                    height: parent.height - Theme.spacingS * 2
                    x: Theme.spacingS
                    y: Theme.spacingS
                    spacing: Theme.spacingS
                    visible: !appDrawerPopout.editMode

                    Item {
                        width: parent.width
                        height: 40

                        StyledText {
                            anchors.left: parent.left
                            anchors.leftMargin: Theme.spacingS
                            anchors.verticalCenter: parent.verticalCenter
                            text: appDrawerPopout.searchMode === "files" ? I18n.tr("Files") : I18n.tr("Applications")
                            font.pixelSize: Theme.fontSizeLarge + 4
                            font.weight: Font.Bold
                            color: Theme.surfaceText
                        }

                        StyledText {
                            anchors.right: parent.right
                            anchors.rightMargin: Theme.spacingS
                            anchors.verticalCenter: parent.verticalCenter
                            text: {
                                switch (appDrawerPopout.searchMode) {
                                case "files":
                                    return fileSearchController.model.count + " " + I18n.tr("files");
                                default:
                                    return appLauncher.model.count + " " + I18n.tr("apps");
                                }
                            }
                            font.pixelSize: Theme.fontSizeMedium
                            color: Theme.surfaceVariantText
                        }
                    }

                    DankTextField {
                        id: searchField

                        width: parent.width - Theme.spacingS * 2
                        anchors.horizontalCenter: parent.horizontalCenter
                        height: 52
                        cornerRadius: Theme.cornerRadius
                        backgroundColor: Theme.withAlpha(Theme.surfaceContainerHigh, Theme.popupTransparency)
                        normalBorderColor: Theme.outlineMedium
                        focusedBorderColor: Theme.primary
                        leftIconName: appDrawerPopout.searchMode === "files" ? "folder" : "search"
                        leftIconSize: Theme.iconSize
                        leftIconColor: Theme.surfaceVariantText
                        leftIconFocusedColor: Theme.primary
                        showClearButton: true
                        font.pixelSize: Theme.fontSizeLarge
                        enabled: appDrawerPopout.shouldBeVisible
                        ignoreLeftRightKeys: appDrawerPopout.searchMode === "apps" && appLauncher.viewMode !== "list"
                        ignoreTabKeys: true
                        keyForwardTargets: [keyHandler]
                        onTextChanged: {
                            if (appDrawerPopout.searchMode === "apps") {
                                appLauncher.searchQuery = text;
                            }
                        }
                        onTextEdited: {
                            appDrawerPopout.updateSearchMode(text);
                        }
                        Keys.onPressed: function (event) {
                            if (event.key === Qt.Key_Escape) {
                                appDrawerPopout.close();
                                event.accepted = true;
                                return;
                            }

                            const isEnterKey = [Qt.Key_Return, Qt.Key_Enter].includes(event.key);
                            const hasText = text.length > 0;

                            if (isEnterKey && hasText) {
                                switch (appDrawerPopout.searchMode) {
                                case "files":
                                    if (fileSearchController.model.count > 0) {
                                        fileSearchController.openSelected();
                                    }
                                    event.accepted = true;
                                    return;
                                default:
                                    if (appLauncher.keyboardNavigationActive && appLauncher.model.count > 0) {
                                        appLauncher.launchSelected();
                                    } else if (appLauncher.model.count > 0) {
                                        appLauncher.launchApp(appLauncher.model.get(0));
                                    }
                                    event.accepted = true;
                                    return;
                                }
                            }

                            const navigationKeys = [Qt.Key_Down, Qt.Key_Up, Qt.Key_Left, Qt.Key_Right, Qt.Key_Tab, Qt.Key_Backtab];
                            const isNavigationKey = navigationKeys.includes(event.key);
                            const isEmptyEnter = isEnterKey && !hasText;

                            event.accepted = !(isNavigationKey || isEmptyEnter);
                        }

                        Connections {
                            function onShouldBeVisibleChanged() {
                                if (!appDrawerPopout.shouldBeVisible) {
                                    searchField.focus = false;
                                }
                            }

                            target: appDrawerPopout
                        }
                    }

                    Item {
                        width: parent.width - Theme.spacingS * 2
                        height: 40
                        anchors.horizontalCenter: parent.horizontalCenter
                        visible: appDrawerPopout.searchMode === "apps"

                        Rectangle {
                            width: 180
                            height: 40
                            radius: Theme.cornerRadius
                            color: "transparent"
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter

                            DankDropdown {
                                anchors.fill: parent
                                text: ""
                                dropdownWidth: 180
                                currentValue: appLauncher.selectedCategory
                                options: appLauncher.categories
                                optionIcons: appLauncher.categoryIcons
                                onValueChanged: function (value) {
                                    appLauncher.setCategory(value);
                                }
                            }
                        }

                        Row {
                            spacing: 4
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter

                            DankActionButton {
                                buttonSize: 36
                                circular: false
                                iconName: "view_list"
                                iconSize: 20
                                iconColor: appLauncher.viewMode === "list" ? Theme.primary : Theme.surfaceText
                                backgroundColor: appLauncher.viewMode === "list" ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12) : "transparent"
                                onClicked: {
                                    appLauncher.setViewMode("list");
                                }
                            }

                            DankActionButton {
                                buttonSize: 36
                                circular: false
                                iconName: "grid_view"
                                iconSize: 20
                                iconColor: appLauncher.viewMode === "grid" ? Theme.primary : Theme.surfaceText
                                backgroundColor: appLauncher.viewMode === "grid" ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12) : "transparent"
                                onClicked: {
                                    appLauncher.setViewMode("grid");
                                }
                            }
                        }
                    }

                    Rectangle {
                        width: searchField.width
                        x: searchField.x
                        height: {
                            let usedHeight = 40 + Theme.spacingS;
                            usedHeight += 52 + Theme.spacingS;
                            usedHeight += appDrawerPopout.searchMode === "apps" ? 40 : 0;
                            return parent.height - usedHeight;
                        }
                        radius: Theme.cornerRadius
                        color: "transparent"
                        clip: true

                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: 32
                            z: 100
                            visible: {
                                if (appDrawerPopout.searchMode !== "apps")
                                    return false;
                                const view = appLauncher.viewMode === "list" ? appList : appGrid;
                                const isLastItem = view.currentIndex >= view.count - 1;
                                const hasOverflow = view.contentHeight > view.height;
                                const atBottom = view.contentY >= view.contentHeight - view.height - 1;
                                return hasOverflow && (!isLastItem || !atBottom);
                            }
                            gradient: Gradient {
                                GradientStop {
                                    position: 0.0
                                    color: "transparent"
                                }
                                GradientStop {
                                    position: 1.0
                                    color: Theme.withAlpha(Theme.surfaceContainer, Theme.popupTransparency)
                                }
                            }
                        }

                        DankListView {
                            id: appList

                            property int itemHeight: 72
                            property int iconSize: 56
                            property bool showDescription: true
                            property int itemSpacing: Theme.spacingS
                            property bool hoverUpdatesSelection: false
                            property bool keyboardNavigationActive: appLauncher.keyboardNavigationActive

                            signal keyboardNavigationReset
                            signal itemClicked(int index, var modelData)
                            signal itemRightClicked(int index, var modelData, real mouseX, real mouseY)

                            function ensureVisible(index) {
                                if (index < 0 || index >= count)
                                    return;
                                var itemY = index * (itemHeight + itemSpacing);
                                var itemBottom = itemY + itemHeight;
                                var fadeHeight = 32;
                                var isLastItem = index === count - 1;
                                if (itemY < contentY)
                                    contentY = itemY;
                                else if (itemBottom > contentY + height - (isLastItem ? 0 : fadeHeight))
                                    contentY = Math.min(itemBottom - height + (isLastItem ? 0 : fadeHeight), contentHeight - height);
                            }

                            anchors.fill: parent
                            anchors.bottomMargin: 1
                            visible: appDrawerPopout.searchMode === "apps" && appLauncher.viewMode === "list"
                            model: appLauncher.model
                            currentIndex: appLauncher.selectedIndex
                            clip: true
                            spacing: itemSpacing
                            focus: true
                            interactive: true
                            cacheBuffer: Math.max(0, Math.min(height * 2, 1000))
                            reuseItems: true

                            onCurrentIndexChanged: {
                                if (keyboardNavigationActive)
                                    ensureVisible(currentIndex);
                            }

                            onItemClicked: function (index, modelData) {
                                appLauncher.launchApp(modelData);
                            }
                            onItemRightClicked: function (index, modelData, mouseX, mouseY) {
                                contextMenu.show(mouseX, mouseY, modelData, false);
                            }
                            onKeyboardNavigationReset: {
                                appLauncher.keyboardNavigationActive = false;
                            }

                            delegate: AppLauncherListDelegate {
                                listView: appList
                                itemHeight: appList.itemHeight
                                iconSize: appList.iconSize
                                showDescription: appList.showDescription
                                hoverUpdatesSelection: appList.hoverUpdatesSelection
                                keyboardNavigationActive: appList.keyboardNavigationActive
                                isCurrentItem: ListView.isCurrentItem
                                mouseAreaLeftMargin: Theme.spacingS
                                mouseAreaRightMargin: Theme.spacingS
                                mouseAreaBottomMargin: Theme.spacingM
                                iconMargins: Theme.spacingXS
                                iconFallbackLeftMargin: Theme.spacingS
                                iconFallbackRightMargin: Theme.spacingS
                                iconFallbackBottomMargin: Theme.spacingM
                                onItemClicked: (idx, modelData) => appList.itemClicked(idx, modelData)
                                onItemRightClicked: (idx, modelData, mouseX, mouseY) => {
                                    const panelPos = contextMenu.parent.mapFromItem(null, mouseX, mouseY);
                                    appList.itemRightClicked(idx, modelData, panelPos.x, panelPos.y);
                                }
                                onKeyboardNavigationReset: appList.keyboardNavigationReset
                            }
                        }

                        DankGridView {
                            id: appGrid

                            property int currentIndex: appLauncher.selectedIndex
                            property int columns: appLauncher.gridColumns
                            property bool adaptiveColumns: false
                            property int minCellWidth: 120
                            property int maxCellWidth: 160
                            property real iconSizeRatio: 0.6
                            property int maxIconSize: 56
                            property int minIconSize: 32
                            property bool hoverUpdatesSelection: false
                            property bool keyboardNavigationActive: appLauncher.keyboardNavigationActive
                            property real baseCellWidth: adaptiveColumns ? Math.max(minCellWidth, Math.min(maxCellWidth, width / columns)) : width / columns
                            property real baseCellHeight: baseCellWidth + 20
                            property int actualColumns: adaptiveColumns ? Math.floor(width / cellWidth) : columns

                            property int remainingSpace: width - (actualColumns * cellWidth)

                            signal keyboardNavigationReset
                            signal itemClicked(int index, var modelData)
                            signal itemRightClicked(int index, var modelData, real mouseX, real mouseY)

                            function ensureVisible(index) {
                                if (index < 0 || index >= count)
                                    return;
                                var itemY = Math.floor(index / actualColumns) * cellHeight;
                                var itemBottom = itemY + cellHeight;
                                var fadeHeight = 32;
                                var isLastRow = Math.floor(index / actualColumns) >= Math.floor((count - 1) / actualColumns);
                                if (itemY < contentY)
                                    contentY = itemY;
                                else if (itemBottom > contentY + height - (isLastRow ? 0 : fadeHeight))
                                    contentY = Math.min(itemBottom - height + (isLastRow ? 0 : fadeHeight), contentHeight - height);
                            }

                            anchors.fill: parent
                            anchors.bottomMargin: 1
                            visible: appDrawerPopout.searchMode === "apps" && appLauncher.viewMode === "grid"
                            model: appLauncher.model
                            clip: true
                            cellWidth: baseCellWidth
                            cellHeight: baseCellHeight
                            focus: true
                            interactive: true
                            cacheBuffer: Math.max(0, Math.min(height * 2, 1000))
                            reuseItems: true

                            onCurrentIndexChanged: {
                                if (keyboardNavigationActive)
                                    ensureVisible(currentIndex);
                            }

                            onItemClicked: function (index, modelData) {
                                appLauncher.launchApp(modelData);
                            }
                            onItemRightClicked: function (index, modelData, mouseX, mouseY) {
                                contextMenu.show(mouseX, mouseY, modelData, false);
                            }
                            onKeyboardNavigationReset: {
                                appLauncher.keyboardNavigationActive = false;
                            }

                            delegate: AppLauncherGridDelegate {
                                gridView: appGrid
                                cellWidth: appGrid.cellWidth
                                cellHeight: appGrid.cellHeight
                                minIconSize: appGrid.minIconSize
                                maxIconSize: appGrid.maxIconSize
                                iconSizeRatio: appGrid.iconSizeRatio
                                hoverUpdatesSelection: appGrid.hoverUpdatesSelection
                                keyboardNavigationActive: appGrid.keyboardNavigationActive
                                currentIndex: appGrid.currentIndex
                                mouseAreaLeftMargin: Theme.spacingS
                                mouseAreaRightMargin: Theme.spacingS
                                mouseAreaBottomMargin: Theme.spacingS
                                iconFallbackLeftMargin: Theme.spacingS
                                iconFallbackRightMargin: Theme.spacingS
                                iconFallbackBottomMargin: Theme.spacingS
                                iconMaterialSizeAdjustment: Theme.spacingL
                                onItemClicked: (idx, modelData) => appGrid.itemClicked(idx, modelData)
                                onItemRightClicked: (idx, modelData, mouseX, mouseY) => {
                                    const panelPos = contextMenu.parent.mapFromItem(null, mouseX, mouseY);
                                    appGrid.itemRightClicked(idx, modelData, panelPos.x, panelPos.y);
                                }
                                onKeyboardNavigationReset: appGrid.keyboardNavigationReset
                            }
                        }

                        FileSearchResults {
                            anchors.fill: parent
                            fileSearchController: appDrawerPopout.fileSearch
                            visible: appDrawerPopout.searchMode === "files"
                        }
                    }
                }
            }

            Item {
                id: editView
                anchors.fill: parent
                anchors.margins: Theme.spacingS
                visible: appDrawerPopout.editMode

                Column {
                    anchors.fill: parent
                    spacing: Theme.spacingM

                    Row {
                        width: parent.width
                        spacing: Theme.spacingM

                        Rectangle {
                            width: 40
                            height: 40
                            radius: Theme.cornerRadius
                            color: backButtonArea.containsMouse ? Theme.surfaceHover : "transparent"

                            DankIcon {
                                anchors.centerIn: parent
                                name: "arrow_back"
                                size: 20
                                color: Theme.surfaceText
                            }

                            MouseArea {
                                id: backButtonArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: appDrawerPopout.closeEditMode()
                            }
                        }

                        Image {
                            width: 40
                            height: 40
                            source: appDrawerPopout.editingApp?.icon ? "image://icon/" + appDrawerPopout.editingApp.icon : "image://icon/application-x-executable"
                            sourceSize.width: 40
                            sourceSize.height: 40
                            fillMode: Image.PreserveAspectFit
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2

                            StyledText {
                                text: I18n.tr("Edit App")
                                font.pixelSize: Theme.fontSizeLarge
                                color: Theme.surfaceText
                                font.weight: Font.Medium
                            }

                            StyledText {
                                text: appDrawerPopout.editingApp?.name || ""
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceVariantText
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 1
                        color: Theme.outlineMedium
                    }

                    Flickable {
                        width: parent.width
                        height: parent.height - y - editButtonsRow.height - Theme.spacingM
                        contentHeight: editFieldsColumn.height
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        Column {
                            id: editFieldsColumn
                            width: parent.width
                            spacing: Theme.spacingS

                            Column {
                                width: parent.width
                                spacing: 4

                                StyledText {
                                    text: I18n.tr("Name")
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.surfaceText
                                    font.weight: Font.Medium
                                }

                                DankTextField {
                                    id: editNameField
                                    width: parent.width
                                    height: 44
                                    focus: true
                                    placeholderText: appDrawerPopout.editingApp?.name || ""
                                    keyNavigationTab: editIconField
                                    keyNavigationBacktab: editExtraFlagsField
                                }
                            }

                            Column {
                                width: parent.width
                                spacing: 4

                                StyledText {
                                    text: I18n.tr("Icon")
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.surfaceText
                                    font.weight: Font.Medium
                                }

                                DankTextField {
                                    id: editIconField
                                    width: parent.width
                                    height: 44
                                    placeholderText: appDrawerPopout.editingApp?.icon || ""
                                    keyNavigationTab: editCommentField
                                    keyNavigationBacktab: editNameField
                                }
                            }

                            Column {
                                width: parent.width
                                spacing: 4

                                StyledText {
                                    text: I18n.tr("Description")
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.surfaceText
                                    font.weight: Font.Medium
                                }

                                DankTextField {
                                    id: editCommentField
                                    width: parent.width
                                    height: 44
                                    placeholderText: appDrawerPopout.editingApp?.comment || ""
                                    keyNavigationTab: editEnvVarsField
                                    keyNavigationBacktab: editIconField
                                }
                            }

                            Column {
                                width: parent.width
                                spacing: 4

                                StyledText {
                                    text: I18n.tr("Environment Variables")
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.surfaceText
                                    font.weight: Font.Medium
                                }

                                StyledText {
                                    text: "KEY=value KEY2=value2"
                                    font.pixelSize: Theme.fontSizeSmall - 1
                                    color: Theme.surfaceVariantText
                                }

                                DankTextField {
                                    id: editEnvVarsField
                                    width: parent.width
                                    height: 44
                                    placeholderText: "VAR=value"
                                    keyNavigationTab: editExtraFlagsField
                                    keyNavigationBacktab: editCommentField
                                }
                            }

                            Column {
                                width: parent.width
                                spacing: 4

                                StyledText {
                                    text: I18n.tr("Extra Arguments")
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.surfaceText
                                    font.weight: Font.Medium
                                }

                                DankTextField {
                                    id: editExtraFlagsField
                                    width: parent.width
                                    height: 44
                                    placeholderText: "--flag --option=value"
                                    keyNavigationTab: editNameField
                                    keyNavigationBacktab: editEnvVarsField
                                }
                            }
                        }
                    }

                    Row {
                        id: editButtonsRow
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: Theme.spacingM

                        Rectangle {
                            width: 90
                            height: 40
                            radius: Theme.cornerRadius
                            color: resetButtonArea.containsMouse ? Theme.surfacePressed : Theme.surfaceVariantAlpha
                            visible: SessionData.getAppOverride(appDrawerPopout.editAppId) !== null

                            StyledText {
                                text: I18n.tr("Reset")
                                font.pixelSize: Theme.fontSizeMedium
                                color: Theme.error
                                font.weight: Font.Medium
                                anchors.centerIn: parent
                            }

                            MouseArea {
                                id: resetButtonArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: appDrawerPopout.resetAppOverride()
                            }
                        }

                        Rectangle {
                            width: 90
                            height: 40
                            radius: Theme.cornerRadius
                            color: cancelButtonArea.containsMouse ? Theme.surfacePressed : Theme.surfaceVariantAlpha

                            StyledText {
                                text: I18n.tr("Cancel")
                                font.pixelSize: Theme.fontSizeMedium
                                color: Theme.surfaceText
                                font.weight: Font.Medium
                                anchors.centerIn: parent
                            }

                            MouseArea {
                                id: cancelButtonArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: appDrawerPopout.closeEditMode()
                            }
                        }

                        Rectangle {
                            width: 90
                            height: 40
                            radius: Theme.cornerRadius
                            color: saveButtonArea.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.9) : Theme.primary

                            StyledText {
                                text: I18n.tr("Save")
                                font.pixelSize: Theme.fontSizeMedium
                                color: Theme.onPrimary
                                font.weight: Font.Medium
                                anchors.centerIn: parent
                            }

                            MouseArea {
                                id: saveButtonArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: appDrawerPopout.saveAppOverride()
                            }
                        }
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                visible: contextMenu.visible
                z: 998
                onClicked: contextMenu.hide()
            }
        }
    }

    SpotlightContextMenuPopup {
        id: contextMenu

        parent: contentLoader.item
        appLauncher: appLauncher
        parentHandler: contentLoader.item?.keyHandler ?? null
        searchField: contentLoader.item?.searchField ?? null
        visible: false
        z: 1000
    }

    Connections {
        target: contextMenu
        function onEditAppRequested(app) {
            appDrawerPopout.openEditMode(app);
        }
    }
}
