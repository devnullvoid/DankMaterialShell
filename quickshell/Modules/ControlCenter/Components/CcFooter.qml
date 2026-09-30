pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.Common
import qs.Modules.ControlCenter
import qs.Modules.ControlCenter.Widgets
import qs.Widgets
import "../utils/widgets.js" as WidgetUtils

Item {
    id: root

    LayoutMirroring.enabled: I18n.isRtl
    LayoutMirroring.childrenInherit: true

    required property var grid
    property bool editMode: false
    property var items: []
    property bool onTop: false
    property var transientSurfaceTracker: null
    // A grid tile hovering the row: {"cells", "at"}.
    property var incoming: null
    // Takes (savedIndex, cells, scenePoint) and returns true when it takes the dropped item.
    property var dropHandler: null
    // Takes the dragged item's scene rect and returns true while something outside the row will take it.
    property var leavesRow: null
    property int liftedIndex: -1
    property int liftedAt: -1
    property var resizePreview: null

    signal addWidgetRequested
    signal resetRequested
    signal clearRequested
    signal moveRequested
    signal editToggled
    signal cancelRequested
    signal removeRequested(int index)
    signal configRequested(int index, var widgetData, var anchor)
    signal itemMoved(int index, rect sceneRect, bool leaving)
    signal resized(int index, int cells, bool fill)

    // Grid columns, so footer widths line up with the tiles above.
    readonly property real spacing: CcMetrics.gridGap
    readonly property real pitch: grid.cellWidth
    readonly property real editActionsWidth: Theme.iconButtonSize * 2 + spacing
    readonly property real trackWidth: Math.max(0, width - trailing.width - CcMetrics.footerGap)
    // Edit mode shows the whole row scaled into the room beside the edit buttons, so every width stays reachable.
    readonly property real editScale: trackWidth > 0 ? Math.min(1, (trackWidth - editActionsWidth - CcMetrics.footerGap) / trackWidth) : 1
    readonly property real trackScale: editMode ? editScale : 1
    readonly property int capacity: Math.max(0, Math.floor((trackWidth + spacing) / pitch))
    readonly property var fills: items.map(item => resizePreview?.index === item.index ? resizePreview.fill : WidgetUtils.footerFills(item.widget))
    readonly property var mins: items.map(item => WidgetUtils.footerMinCells(item.widget.id))
    // Fill items count at their minimum, so a drop or a neighbour growing takes room from them first.
    readonly property var fixedCells: WidgetUtils.fitFooterCells(items.map((item, i) => fills[i] ? mins[i] : (resizePreview?.index === item.index ? resizePreview.cells : WidgetUtils.footerCells(item.widget))), mins, capacity)
    readonly property int fixedUsed: fixedCells.reduce((sum, count) => sum + count, 0)
    readonly property var cells: WidgetUtils.spreadFooterFill(fixedCells, fills, capacity - fixedUsed - (incoming?.cells ?? 0))
    readonly property int slackIndex: fills.findIndex((fill, i) => fill && cells[i] > 0)
    // The first fill item also takes the part of a cell left over, so it ends exactly at the next button.
    readonly property real fillSlack: slackIndex < 0 ? 0 : Math.max(0, trackWidth + spacing - (cells.reduce((sum, count) => sum + count, 0) + (incoming?.cells ?? 0)) * pitch)
    // Stable keys keep delegates alive across resizes and reorders, so they update in place instead of rebuilding.
    readonly property var keys: {
        const seen = {};
        return items.map(item => {
            const base = (item.widget.id ?? "") + "|" + (item.widget.instanceId ?? "");
            seen[base] = (seen[base] ?? 0) + 1;
            return base + "#" + seen[base];
        });
    }
    readonly property var layout: {
        const lifted = items.findIndex(item => item.index === liftedIndex);
        const order = items.map((item, i) => i).filter(i => i !== lifted && cells[i] > 0);
        const gapAt = lifted >= 0 ? liftedAt : (incoming?.at ?? -1);
        const gapCells = lifted >= 0 ? cells[lifted] : (incoming?.cells ?? 0);
        const offsets = [];
        let offset = 0;
        let gapOffset = -1;
        for (let k = 0; k <= order.length; k++) {
            if (k === gapAt) {
                gapOffset = offset;
                offset += gapCells * pitch;
            }
            if (k === order.length)
                break;
            offsets[order[k]] = offset;
            offset += cells[order[k]] * pitch + (order[k] === slackIndex ? fillSlack : 0);
        }
        return {
            "offsets": offsets,
            "gapOffset": gapOffset,
            "gapCells": gapCells
        };
    }

    implicitHeight: CcMetrics.footerHeight

    function spanWidth(count) {
        return count * pitch - spacing;
    }

    function xFor(offset, span) {
        return track.overhang + (I18n.isRtl ? trackWidth - offset - span : offset);
    }

    function freeCells() {
        return capacity - fixedUsed;
    }

    function containsScene(scenePosition) {
        const point = mapFromItem(null, scenePosition.x, scenePosition.y);
        return point.x >= 0 && point.x <= width && point.y >= -CcMetrics.gridGap && point.y <= height + CcMetrics.gridGap;
    }

    function insertionAt(scenePosition) {
        const local = track.mapFromItem(null, scenePosition.x, scenePosition.y).x - track.overhang;
        const distance = I18n.isRtl ? trackWidth - local : local;
        let offset = 0;
        let position = 0;
        for (let i = 0; i < items.length; i++) {
            if (items[i].index === liftedIndex || cells[i] === 0)
                continue;
            const span = cells[i] * pitch;
            if (distance < offset + span / 2)
                return position;
            offset += span;
            position++;
        }
        return position;
    }

    // The saved index of the item a drop at `position` lands before, or -1 for the end.
    function savedIndexAt(position) {
        const shown = items.filter((item, i) => item.index !== liftedIndex && cells[i] > 0);
        return shown[position]?.index ?? -1;
    }

    function followingIndex(savedIndex) {
        const shown = items.filter((item, i) => cells[i] > 0);
        const at = shown.findIndex(item => item.index === savedIndex);
        return shown[at + 1]?.index ?? -1;
    }

    Item {
        id: track

        // The layer only draws inside the item, so it reaches out far enough for the edit chrome.
        readonly property real overhang: PopoutMetrics.editOverflow

        anchors.left: parent.left
        anchors.leftMargin: -overhang
        anchors.verticalCenter: parent.verticalCenter
        width: root.trackWidth + overhang * 2
        height: CcMetrics.footerHeight + overhang * 2
        // Scaled glyphs and icons alias; a mipmapped full-size layer shrinks them cleanly.
        layer.enabled: trackScale.xScale < 1
        layer.smooth: true
        layer.mipmap: true
        transform: Scale {
            id: trackScale

            origin.x: I18n.isRtl ? track.width - track.overhang : track.overhang
            origin.y: track.height / 2
            xScale: root.trackScale
            yScale: root.trackScale

            Behavior on xScale {
                enabled: CcMetrics.animationsEnabled
                NumberAnimation {
                    duration: Theme.expressiveDurations.expressiveEffects
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Theme.expressiveCurves.emphasizedDecel
                }
            }

            Behavior on yScale {
                enabled: CcMetrics.animationsEnabled
                NumberAnimation {
                    duration: Theme.expressiveDurations.expressiveEffects
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Theme.expressiveCurves.emphasizedDecel
                }
            }
        }

        StyledRect {
            x: root.xFor(root.layout.gapOffset, root.spanWidth(root.layout.gapCells))
            y: track.overhang
            width: root.spanWidth(root.layout.gapCells)
            height: CcMetrics.footerHeight
            radius: Theme.fullRadius(width, height)
            color: Theme.withAlpha(Theme.primary, Theme.stateLayerDrag)
            visible: root.layout.gapOffset >= 0 && root.layout.gapCells > 0
        }

        Repeater {
            model: ScriptModel {
                values: root.keys
            }

            Item {
                id: footerItem

                required property int index
                readonly property var entry: root.items[index] ?? ({
                        "index": -1,
                        "widget": ({})
                    })
                readonly property int cells: root.cells[index] ?? 0
                readonly property bool lifted: root.liftedIndex === entry.index
                readonly property real span: root.spanWidth(Math.max(1, cells)) + (index === root.slackIndex ? root.fillSlack : 0)
                readonly property real restX: root.xFor(root.layout.offsets[index] ?? 0, span)
                property point grab: Qt.point(0, 0)
                property point dragScene: Qt.point(0, 0)
                readonly property point dragPosition: {
                    // The panel can grow under a drag and move the row, so the pointer is re-mapped whenever it does.
                    root.y;
                    const point = track.mapFromItem(null, dragScene.x, dragScene.y);
                    return Qt.point(point.x - grab.x, point.y - grab.y);
                }
                property bool landed: false

                x: lifted || landed ? dragPosition.x : restX
                y: lifted || landed ? dragPosition.y : track.overhang
                z: lifted || landed ? 1 : 0
                width: span
                height: CcMetrics.footerHeight
                visible: cells > 0

                // A reorder moves this entry, which is the moment a dropped item leaves the pointer for its slot.
                onIndexChanged: landed = false

                Behavior on x {
                    enabled: !footerItem.lifted && !footerItem.landed && CcMetrics.animationsEnabled
                    NumberAnimation {
                        duration: Theme.expressiveDurations.expressiveEffects
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Theme.expressiveCurves.emphasizedDecel
                    }
                }

                CcTileLoader {
                    id: tile

                    anchors.fill: parent
                    grid: root.grid
                    widgetData: footerItem.entry.widget
                    savedIndex: footerItem.entry.index
                    columns: Math.max(1, footerItem.cells)
                    rows: 1
                    compact: footerItem.cells <= 1
                    small: true
                    docked: true
                }

                CcEditChrome {
                    id: chrome

                    property real startX: 0
                    property int startCells: 0
                    property bool startFill: false

                    anchors.fill: parent
                    anchors.margins: -contentInset
                    z: 2
                    visible: root.editMode
                    widgetData: footerItem.entry.widget
                    passthrough: tile.item?.passthrough ?? null
                    dragging: footerItem.lifted
                    resizing: root.resizePreview?.index === footerItem.entry.index
                    horizontalResize: true
                    sizeText: root.resizePreview?.index === footerItem.entry.index && root.resizePreview.fill ? I18n.tr("Fill") : String(footerItem.cells)
                    cornerRadius: tile.item?.bodyRadius ?? Theme.fullRadius(footerItem.width, footerItem.height)
                    onResizeStarted: (px, py) => {
                        startX = mapToItem(null, px, py).x;
                        startCells = footerItem.cells;
                        startFill = root.fills[footerItem.index] ?? false;
                        root.resizePreview = {
                            "index": footerItem.entry.index,
                            "cells": startCells,
                            "fill": startFill
                        };
                    }
                    // Pulling past the edit buttons turns the item into a fill, which runs on to the pencil outside edit mode.
                    onResizeMoved: (px, py) => {
                        const delta = (mapToItem(null, px, py).x - startX) * (I18n.isRtl ? -1 : 1) / root.trackScale;
                        const min = root.mins[footerItem.index];
                        const max = Math.max(min, root.capacity - (root.fixedUsed - root.fixedCells[footerItem.index]));
                        const wanted = Math.round(startCells + delta / root.pitch);
                        root.resizePreview = {
                            "index": footerItem.entry.index,
                            "cells": Math.max(min, Math.min(max, wanted)),
                            "fill": startFill ? wanted >= max : wanted > max
                        };
                    }
                    onResizeEnded: {
                        const preview = root.resizePreview;
                        const cells = preview?.cells ?? startCells;
                        const fill = preview?.fill ?? startFill;
                        if (cells !== startCells || fill !== startFill)
                            root.resized(footerItem.entry.index, cells, fill);
                        root.resizePreview = null;
                    }
                    onResizeCanceled: root.resizePreview = null
                    onRemoveRequested: root.removeRequested(footerItem.entry.index)
                    onConfigRequested: anchor => root.configRequested(footerItem.entry.index, footerItem.entry.widget, anchor)
                }

                DragHandler {
                    id: dragHandler

                    target: null
                    enabled: root.editMode && root.resizePreview === null && !footerItem.landed
                    cursorShape: Qt.ClosedHandCursor
                    onActiveChanged: {
                        if (active) {
                            footerItem.grab = footerItem.mapFromItem(null, centroid.scenePressPosition.x, centroid.scenePressPosition.y);
                            footerItem.dragScene = centroid.scenePosition;
                            root.liftedIndex = footerItem.entry.index;
                            root.liftedAt = root.insertionAt(centroid.scenePosition);
                            return;
                        }
                        footerItem.landed = root.dropHandler?.(footerItem.entry.index, footerItem.cells, footerItem.dragScene) ?? false;
                        root.liftedIndex = -1;
                        root.liftedAt = -1;
                    }
                    onCentroidChanged: {
                        if (!active)
                            return;
                        footerItem.dragScene = centroid.scenePosition;
                        const visual = footerItem.mapToItem(null, 0, 0, footerItem.width, footerItem.height);
                        const leaving = root.leavesRow?.(visual) ?? false;
                        root.liftedAt = leaving ? -1 : root.insertionAt(footerItem.dragScene);
                        root.itemMoved(footerItem.entry.index, visual, leaving);
                    }
                }
            }
        }
    }

    Row {
        anchors.right: trailing.left
        anchors.rightMargin: CcMetrics.footerGap
        anchors.verticalCenter: parent.verticalCenter
        spacing: root.spacing
        visible: root.editMode

        DankActionButton {
            buttonSize: Theme.iconButtonSize
            iconName: "add"
            iconSize: CcMetrics.iconBoxIconSize
            iconColor: Theme.onSecondaryContainer
            backgroundColor: Theme.secondaryContainer
            tooltipText: I18n.tr("Add widget")
            onClicked: root.addWidgetRequested()
        }

        DankActionButton {
            id: moreButton

            buttonSize: Theme.iconButtonSize
            iconName: "more_horiz"
            iconSize: CcMetrics.iconBoxIconSize
            iconColor: CcMetrics.tileInactiveContent
            backgroundColor: CcMetrics.tileInactiveColor
            border.width: Theme.layerOutlineWidth
            border.color: Theme.outlineMedium
            tooltipText: I18n.tr("More")
            onClicked: editMenu.openAt(moreButton)
        }
    }

    CcMenu {
        id: editMenu

        transientSurfaceTracker: root.transientSurfaceTracker
        items: [
            {
                "iconName": root.onTop ? "vertical_align_bottom" : "vertical_align_top",
                "label": root.onTop ? I18n.tr("Move down") : I18n.tr("Move up"),
                "action": () => root.moveRequested()
            },
            {
                "iconName": "settings_backup_restore",
                "label": I18n.tr("Reset to default"),
                "action": () => root.resetRequested()
            },
            {
                "iconName": "clear_all",
                "label": I18n.tr("Clear All"),
                "destructive": true,
                "action": () => root.clearRequested()
            },
            {
                "iconName": "close",
                "label": I18n.tr("Discard"),
                "action": () => root.cancelRequested()
            }
        ]
    }

    Item {
        id: trailing

        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: CcMetrics.footerHeight
        height: CcMetrics.footerHeight

        DankActionButton {
            buttonSize: CcMetrics.footerHeight
            iconName: "check"
            iconSize: CcMetrics.iconBoxIconSize
            iconColor: Theme.onPrimary
            backgroundColor: Theme.primary
            tooltipText: I18n.tr("Save")
            visible: root.editMode
            onClicked: root.editToggled()
        }

        DankActionButton {
            buttonSize: CcMetrics.footerHeight
            iconName: "edit"
            iconSize: CcMetrics.iconBoxIconSize
            iconColor: CcMetrics.tileInactiveContent
            backgroundColor: CcMetrics.tileInactiveColor
            border.width: Theme.layerOutlineWidth
            border.color: Theme.outlineMedium
            tooltipText: I18n.tr("Edit")
            visible: !root.editMode
            onClicked: root.editToggled()
        }
    }
}
