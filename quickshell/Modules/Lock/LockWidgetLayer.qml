pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.Common
import qs.Services
import qs.Modules.Plugins
import "LockPlacement.js" as Placement
import qs.DankCommon.Session

FocusScope {
    id: root

    required property string screenName
    property var lockHost: null
    property bool editMode: false
    property string selectedInstanceId: ""

    readonly property var screen: Quickshell.screens.find(s => s.name === screenName) ?? null
    readonly property var instances: SettingsData.lockScreenWidgetInstances || []
    readonly property string screenKey: SettingsData.getScreenDisplayName(screen)
    property var _gridSettingsTrigger: SessionData.desktopWidgetGridSettings
    readonly property int gridSize: {
        void _gridSettingsTrigger;
        return SessionData.getDesktopWidgetGridSetting(screenKey, "size", 40);
    }
    readonly property bool gridEnabled: {
        void _gridSettingsTrigger;
        return SessionData.getDesktopWidgetGridSetting(screenKey, "enabled", false);
    }

    signal focusStolen
    signal optionsRequested(var instanceData)

    // Widgets added from the editor start in the nearest free area instead of on top of another widget.
    property var pendingIds: []
    property real bottomInset: 0

    function rectOf(item) {
        return {
            x: item.x,
            y: item.y,
            width: item.width,
            height: item.height
        };
    }

    function placeIfPending(item) {
        if (!pendingIds.includes(item.instanceId))
            return;
        pendingIds = pendingIds.filter(id => id !== item.instanceId);
        if (!editMode || item.width <= 0 || item.height <= 0)
            return;
        const obstacles = [];
        for (let i = 0; i < repeater.count; i++) {
            const other = repeater.itemAt(i);
            if (other && other !== item && other.visible)
                obstacles.push(rectOf(other));
        }
        const rect = rectOf(item);
        if (!obstacles.some(obstacle => Placement.intersects(rect, obstacle)))
            return;
        const free = Placement.candidates(width, height - bottomInset, item.width, item.height, Theme.spacingXL, obstacles);
        if (!free.length)
            return;
        const centerX = width / 2;
        const centerY = height / 2;
        free.sort((a, b) => Math.hypot(a.x + a.width / 2 - centerX, a.y + a.height / 2 - centerY) - Math.hypot(b.x + b.width / 2 - centerX, b.y + b.height / 2 - centerY));
        item.commitPosition(free[0].x, free[0].y);
    }

    function toggleGrid() {
        SessionData.setDesktopWidgetGridSetting(screenKey, "enabled", !gridEnabled);
    }

    function stepGrid(delta) {
        SessionData.setDesktopWidgetGridSetting(screenKey, "size", Math.max(10, Math.min(200, gridSize + delta)));
    }

    activeFocusOnTab: false
    onActiveFocusChanged: {
        if (activeFocus)
            focusStolen();
    }

    function itemOfType(widgetType) {
        for (let i = 0; i < repeater.count; i++) {
            const item = repeater.itemAt(i);
            if (item && item.visible && item.widgetType === widgetType)
                return item;
        }
        return null;
    }

    readonly property real edgeInset: Theme.spacingXL * 2
    property bool completed: false
    property var lockedPositions: ({})
    readonly property string backgroundKey: LockPlacementService.backgroundKey(screenName, width, height)
    readonly property var autoPositions: editMode && completed ? currentPlacement() : lockedPositions

    function currentPlacement() {
        return LockPlacementService.layoutFor(screenName, LockPlacementService.sampleFor(screenName, backgroundKey), placementKey, placeClocks);
    }

    function refreshPlacement() {
        if (!completed || editMode || width <= 0 || height <= 0)
            return;
        lockedPositions = currentPlacement();
        SessionData.setLockScreenAutoPositions(screenKey, {
            width: width,
            height: height,
            positions: lockedPositions
        });
    }

    Component.onCompleted: {
        completed = true;
        refreshPlacement();
    }
    onWidthChanged: refreshPlacement()
    onHeightChanged: refreshPlacement()
    onEditModeChanged: refreshPlacement()

    readonly property string placementKey: JSON.stringify(instances.map(instance => {
        const item = itemById(instance.id);
        return [instance.id, instance.enabled, instance.config, item?.width, item?.height, item?.automaticPlacement ? null : item?.x, item?.automaticPlacement ? null : item?.y, item?.hasSavedPosition, item?.contrastColors];
    }).concat([width, height, Theme.primary.toString(), Theme.secondary.toString(), Theme.lockScreenContentColor.toString(), SessionData.desktopWidgetInstancePositions]))

    function itemById(id) {
        for (let i = 0; i < repeater.count; i++) {
            const item = repeater.itemAt(i);
            if (item && item.visible && item.instanceId === id)
                return item;
        }
        return null;
    }

    function stockRect(widgetType, item) {
        const centerX = (width - item.width) / 2;
        switch (widgetType) {
        case "lockClock":
            return item.automaticPlacement && autoPositions[item.instanceId] ? autoPositions[item.instanceId] : {
                x: Math.max(0, centerX),
                y: edgeInset
            };
        case "lockDate":
            return {
                x: edgeInset,
                y: edgeInset
            };
        case "lockAuth":
            return {
                x: centerX,
                y: height / 2 - item.height / 2
            };
        case "lockNotifications":
            {
                const auth = itemOfType("lockAuth");
                return {
                    x: centerX,
                    y: auth ? auth.y + auth.height + Theme.spacingL : height / 2 + Theme.spacingL
                };
            }
        case "lockStatus":
            return {
                x: width - Theme.spacingXL - item.width,
                y: Theme.spacingXL
            };
        case "lockPower":
            return {
                x: Theme.spacingXL,
                y: height - Theme.spacingXL - item.height
            };
        }
        return null;
    }

    function placeClocks(luminances, sampleWidth, sampleHeight) {
        const clocks = [];
        const obstacles = [];
        for (let i = 0; i < repeater.count; i++) {
            const item = repeater.itemAt(i);
            if (!item || !item.visible)
                continue;
            if (item.automaticPlacement) {
                clocks.push(item);
                continue;
            }
            obstacles.push({
                x: item.x - Theme.spacingL,
                y: item.y - Theme.spacingL,
                width: item.width + Theme.spacingL * 2,
                height: item.height + Theme.spacingL * 2
            });
        }
        const positions = {};
        for (const clock of clocks) {
            const choices = Placement.candidates(width, height, clock.width, clock.height, edgeInset, obstacles);
            const foregrounds = clock.contrastColors.map(color => Placement.luminance(color.r, color.g, color.b));
            const chosen = Placement.choose(luminances, sampleWidth, sampleHeight, width, height, choices, foregrounds);
            if (!chosen)
                continue;
            positions[clock.instanceId] = {
                x: chosen.x,
                y: chosen.y
            };
            obstacles.push(chosen);
        }
        return positions;
    }

    readonly property var draggedItem: {
        for (let i = 0; i < repeater.count; i++) {
            const item = repeater.itemAt(i);
            if (item && item.dragging)
                return item;
        }
        return null;
    }

    Rectangle {
        x: (parent.width - width) / 2
        width: Theme.dividerWidth
        height: parent.height
        visible: root.editMode && root.draggedItem !== null
        color: root.draggedItem?.snappedCenterX ? Theme.primary : Theme.withAlpha(Theme.primary, Theme.stateLayerDrag)
    }

    Rectangle {
        y: (parent.height - height) / 2
        width: parent.width
        height: Theme.dividerWidth
        visible: root.editMode && root.draggedItem !== null
        color: root.draggedItem?.snappedCenterY ? Theme.primary : Theme.withAlpha(Theme.primary, Theme.stateLayerDrag)
    }

    Loader {
        anchors.fill: parent
        active: root.editMode && root.gridEnabled

        sourceComponent: DesktopWidgetGridLines {
            gridSize: root.gridSize
            extentWidth: root.width
            extentHeight: root.height
        }
    }

    Repeater {
        id: repeater
        model: ScriptModel {
            objectProp: "id"
            values: root.instances
        }

        LockWidgetItem {
            required property var modelData
            required property int index

            readonly property var liveInstanceData: root.instances.find(inst => inst.id === modelData.id) ?? modelData

            instanceData: liveInstanceData
            screen: root.screen
            hostLayer: root
            lockHost: root.lockHost
            editMode: root.editMode
            visible: liveInstanceData.enabled !== false && DesktopWidgetRegistry.showsOnScreen(liveInstanceData.config?.displayPreferences, root.screen)
            z: interacting ? repeater.count + 1 : repeater.count - index
            onRemoveRequested: SettingsData.removeDesktopWidgetInstance(liveInstanceData.id)
            onOptionsRequested: root.optionsRequested(liveInstanceData)
        }
    }
}
