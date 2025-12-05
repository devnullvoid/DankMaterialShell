import QtQuick
import qs.Common
import qs.Widgets

Rectangle {
    id: resultsContainer

    property var appLauncher: null

    signal itemRightClicked(int index, var modelData, real mouseX, real mouseY)

    function resetScroll() {
        resultsList.contentY = 0;
        if (gridLoader.item) {
            gridLoader.item.contentY = 0;
        }
    }

    function getSelectedItemPosition() {
        if (!appLauncher)
            return {
                x: 0,
                y: 0
            };

        const selectedIndex = appLauncher.selectedIndex;
        if (appLauncher.viewMode === "list") {
            const itemY = selectedIndex * (resultsList.itemHeight + resultsList.itemSpacing) - resultsList.contentY;
            return {
                x: resultsList.width / 2,
                y: itemY + resultsList.itemHeight / 2
            };
        } else if (gridLoader.item) {
            const grid = gridLoader.item;
            const row = Math.floor(selectedIndex / grid.actualColumns);
            const col = selectedIndex % grid.actualColumns;
            const itemX = col * grid.cellWidth + grid.leftMargin + grid.cellWidth / 2;
            const itemY = row * grid.cellHeight - grid.contentY + grid.cellHeight / 2;
            return {
                x: itemX,
                y: itemY
            };
        }
        return {
            x: 0,
            y: 0
        };
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
            if (!appLauncher)
                return false;
            const view = appLauncher.viewMode === "list" ? resultsList : (gridLoader.item || resultsList);
            const isLastItem = appLauncher.viewMode === "list" ? view.currentIndex >= view.count - 1 : (gridLoader.item ? Math.floor(view.currentIndex / view.actualColumns) >= Math.floor((view.count - 1) / view.actualColumns) : false);
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
        id: resultsList

        property int itemHeight: 60
        property int iconSize: 40
        property bool showDescription: true
        property int itemSpacing: Theme.spacingS
        property bool hoverUpdatesSelection: false
        property bool keyboardNavigationActive: appLauncher ? appLauncher.keyboardNavigationActive : false

        signal keyboardNavigationReset
        signal itemClicked(int index, var modelData)
        signal itemRightClicked(int index, var modelData, real mouseX, real mouseY)

        function ensureVisible(index) {
            if (index < 0 || index >= count)
                return;
            const itemY = index * (itemHeight + itemSpacing);
            const itemBottom = itemY + itemHeight;
            const fadeHeight = 32;
            const isLastItem = index === count - 1;
            if (itemY < contentY)
                contentY = itemY;
            else if (itemBottom > contentY + height - (isLastItem ? 0 : fadeHeight))
                contentY = Math.min(itemBottom - height + (isLastItem ? 0 : fadeHeight), contentHeight - height);
        }

        anchors.fill: parent
        anchors.leftMargin: Theme.spacingS
        anchors.rightMargin: Theme.spacingS
        anchors.topMargin: Theme.spacingS
        anchors.bottomMargin: 1
        visible: appLauncher && appLauncher.viewMode === "list"
        model: appLauncher ? appLauncher.model : null
        currentIndex: appLauncher ? appLauncher.selectedIndex : -1
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
        onItemClicked: (index, modelData) => {
            if (appLauncher)
                appLauncher.launchApp(modelData);
        }
        onItemRightClicked: (index, modelData, mouseX, mouseY) => {
            resultsContainer.itemRightClicked(index, modelData, mouseX, mouseY);
        }
        onKeyboardNavigationReset: () => {
            if (appLauncher)
                appLauncher.keyboardNavigationActive = false;
        }

        delegate: AppLauncherListDelegate {
            listView: resultsList
            itemHeight: resultsList.itemHeight
            iconSize: resultsList.iconSize
            showDescription: resultsList.showDescription
            hoverUpdatesSelection: resultsList.hoverUpdatesSelection
            keyboardNavigationActive: resultsList.keyboardNavigationActive
            isCurrentItem: ListView.isCurrentItem
            iconMaterialSizeAdjustment: 0
            iconUnicodeScale: 0.8
            onItemClicked: (idx, modelData) => resultsList.itemClicked(idx, modelData)
            onItemRightClicked: (idx, modelData, mouseX, mouseY) => {
                resultsList.itemRightClicked(idx, modelData, mouseX, mouseY);
            }
            onKeyboardNavigationReset: resultsList.keyboardNavigationReset
        }
    }

    Loader {
        id: gridLoader

        property real _lastWidth: 0

        anchors.fill: parent
        anchors.leftMargin: Theme.spacingS
        anchors.rightMargin: Theme.spacingS
        anchors.topMargin: Theme.spacingS
        anchors.bottomMargin: 1
        visible: appLauncher && appLauncher.viewMode === "grid"
        active: appLauncher && appLauncher.viewMode === "grid"
        asynchronous: false

        onLoaded: {
            if (item) {
                item.appLauncher = Qt.binding(() => resultsContainer.appLauncher);
            }
        }

        onWidthChanged: {
            if (visible && Math.abs(width - _lastWidth) > 1) {
                _lastWidth = width;
                active = false;
                Qt.callLater(() => {
                    active = true;
                });
            }
        }
        sourceComponent: Component {
            DankGridView {
                id: resultsGrid

                property var appLauncher: null

                property int currentIndex: appLauncher ? appLauncher.selectedIndex : -1
                property int columns: appLauncher ? appLauncher.gridColumns : 4
                property bool adaptiveColumns: false
                property int minCellWidth: 120
                property int maxCellWidth: 160
                property real iconSizeRatio: 0.55
                property int maxIconSize: 48
                property int minIconSize: 32
                property bool hoverUpdatesSelection: false
                property bool keyboardNavigationActive: appLauncher ? appLauncher.keyboardNavigationActive : false
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
                    const itemY = Math.floor(index / actualColumns) * cellHeight;
                    const itemBottom = itemY + cellHeight;
                    const fadeHeight = 32;
                    const isLastRow = Math.floor(index / actualColumns) >= Math.floor((count - 1) / actualColumns);
                    if (itemY < contentY)
                        contentY = itemY;
                    else if (itemBottom > contentY + height - (isLastRow ? 0 : fadeHeight))
                        contentY = Math.min(itemBottom - height + (isLastRow ? 0 : fadeHeight), contentHeight - height);
                }

                anchors.fill: parent
                model: appLauncher ? appLauncher.model : null
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
                onItemClicked: (index, modelData) => {
                    if (appLauncher)
                        appLauncher.launchApp(modelData);
                }
                onItemRightClicked: (index, modelData, mouseX, mouseY) => {
                    resultsContainer.itemRightClicked(index, modelData, mouseX, mouseY);
                }
                onKeyboardNavigationReset: () => {
                    if (appLauncher)
                        appLauncher.keyboardNavigationActive = false;
                }

                delegate: AppLauncherGridDelegate {
                    gridView: resultsGrid
                    cellWidth: resultsGrid.cellWidth
                    cellHeight: resultsGrid.cellHeight
                    minIconSize: resultsGrid.minIconSize
                    maxIconSize: resultsGrid.maxIconSize
                    iconSizeRatio: resultsGrid.iconSizeRatio
                    hoverUpdatesSelection: resultsGrid.hoverUpdatesSelection
                    keyboardNavigationActive: resultsGrid.keyboardNavigationActive
                    currentIndex: resultsGrid.currentIndex
                    onItemClicked: (idx, modelData) => resultsGrid.itemClicked(idx, modelData)
                    onItemRightClicked: (idx, modelData, mouseX, mouseY) => {
                        resultsGrid.itemRightClicked(idx, modelData, mouseX, mouseY);
                    }
                    onKeyboardNavigationReset: resultsGrid.keyboardNavigationReset
                }
            }
        }
    }
}
