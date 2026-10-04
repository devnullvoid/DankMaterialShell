import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.Common
import qs.Services
import qs.Widgets

Item {
    id: root

    required property string pluginId
    required property var screen

    property string instanceId: ""
    property var instanceData: null
    property bool widgetEnabled: true

    readonly property bool showOnOverlay: instanceData?.config?.showOnOverlay ?? false
    readonly property bool showOnOverview: instanceData?.config?.showOnOverview ?? false
    readonly property bool showOnOverviewOnly: instanceData?.config?.showOnOverviewOnly ?? false
    readonly property bool overviewActive: CompositorService.isNiri && NiriService.inOverview
    readonly property bool clickThrough: instanceData?.config?.clickThrough ?? false

    // Unmapping with the widget still in the last buffer leaves a stale image in
    // Hyprland's blur cache behind transparent tiled windows (#2955), so hide the
    // content, present a transparent frame, then unmap.
    readonly property bool contentShowing: widgetEnabled && content.activeComponent !== null && (!showOnOverviewOnly || overviewActive)
    property bool surfaceLingering: false

    onContentShowingChanged: {
        if (contentShowing) {
            lingerTimer.stop();
            surfaceLingering = false;
            return;
        }
        surfaceLingering = true;
        lingerTimer.restart();
    }

    Timer {
        id: lingerTimer
        interval: 64
        onTriggered: root.surfaceLingering = false
    }

    DesktopWidgetGeometry {
        id: geometry
        instanceId: root.instanceId
        instanceData: root.instanceData
        screen: root.screen
        minWidth: content.contentMinWidth
        minHeight: content.contentMinHeight
        forceSquare: content.contentForceSquare
    }

    readonly property bool useGhostPreview: !CompositorService.isNiri

    property real previewX: geometry.widgetX
    property real previewY: geometry.widgetY
    property real previewWidth: geometry.widgetWidth
    property real previewHeight: geometry.widgetHeight

    property bool isInteracting: dragArea.pressed || resizeArea.pressed

    PanelWindow {
        id: widgetWindow
        screen: root.screen
        visible: root.contentShowing || root.surfaceLingering
        color: "transparent"

        Region {
            id: emptyMask
        }

        mask: root.clickThrough ? emptyMask : null

        WlrLayershell.namespace: "dms:desktop-widget:" + root.pluginId + (root.instanceId ? ":" + root.instanceId : "")
        WlrLayershell.layer: {
            if (root.isInteracting && !CompositorService.useHyprlandFocusGrab)
                return WlrLayer.Overlay;
            if (root.showOnOverlay)
                return WlrLayer.Overlay;
            if (root.overviewActive && (root.showOnOverview || root.showOnOverviewOnly))
                return WlrLayer.Overlay;
            return WlrLayer.Bottom;
        }
        WlrLayershell.exclusionMode: ExclusionMode.Ignore
        WlrLayershell.keyboardFocus: {
            if (PopoutManager.screenshotActive)
                return WlrKeyboardFocus.None;
            if (root.isInteracting) {
                if (CompositorService.useHyprlandFocusGrab)
                    return WlrKeyboardFocus.OnDemand;
                return WlrKeyboardFocus.Exclusive;
            }
            if (content.acceptsKeyboardFocus)
                return WlrKeyboardFocus.OnDemand;
            return WlrKeyboardFocus.None;
        }

        HyprlandFocusGrab {
            active: CompositorService.isHyprland && root.isInteracting
            windows: [widgetWindow]
        }

        Item {
            anchors.fill: parent
            focus: root.isInteracting

            Keys.onPressed: event => {
                if (!root.isInteracting)
                    return;
                switch (event.key) {
                case Qt.Key_G:
                    SessionData.setDesktopWidgetGridSetting(geometry.screenKey, "enabled", !geometry.gridEnabled);
                    event.accepted = true;
                    break;
                case Qt.Key_Z:
                    SessionData.setDesktopWidgetGridSetting(geometry.screenKey, "size", Math.max(10, geometry.gridSize - 10));
                    event.accepted = true;
                    break;
                case Qt.Key_X:
                    SessionData.setDesktopWidgetGridSetting(geometry.screenKey, "size", Math.min(200, geometry.gridSize + 10));
                    event.accepted = true;
                    break;
                }
            }
        }

        anchors {
            left: true
            top: true
        }

        WlrLayershell.margins {
            left: geometry.widgetX
            top: geometry.widgetY
        }

        implicitWidth: geometry.widgetWidth
        implicitHeight: geometry.widgetHeight

        DesktopWidgetContent {
            id: content
            anchors.fill: parent
            active: root.widgetEnabled
            visible: root.contentShowing
            pluginId: root.pluginId
            instanceId: root.instanceId
            instanceData: root.instanceData
            screen: root.screen
            geometry: geometry
        }

        Rectangle {
            id: interactionBorder
            anchors.fill: parent
            color: "transparent"
            border.color: Theme.primary
            border.width: 2
            radius: Theme.cornerRadius
            visible: root.isInteracting && !root.useGhostPreview
            opacity: 0.8

            Rectangle {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                width: 48
                height: 48
                topLeftRadius: Theme.cornerRadius
                bottomRightRadius: Theme.cornerRadius
                color: Theme.primary
                opacity: resizeArea.pressed ? 1 : 0.6
            }
        }

        MouseArea {
            id: dragArea
            anchors.fill: parent
            acceptedButtons: Qt.RightButton
            enabled: !root.clickThrough
            cursorShape: pressed ? Qt.ClosedHandCursor : Qt.ArrowCursor

            property point startPos
            property real startX
            property real startY

            onPressed: mouse => {
                startPos = root.useGhostPreview ? Qt.point(mouse.x, mouse.y) : mapToGlobal(mouse.x, mouse.y);
                startX = geometry.widgetX;
                startY = geometry.widgetY;
                root.previewX = geometry.widgetX;
                root.previewY = geometry.widgetY;
                geometry.dragOverrideX = geometry.widgetX;
                geometry.dragOverrideY = geometry.widgetY;
            }

            onPositionChanged: mouse => {
                if (!pressed)
                    return;
                const currentPos = root.useGhostPreview ? Qt.point(mouse.x, mouse.y) : mapToGlobal(mouse.x, mouse.y);
                const next = geometry.dragMoveTo(startX, startY, currentPos.x - startPos.x, currentPos.y - startPos.y);
                if (root.useGhostPreview) {
                    root.previewX = next.x;
                    root.previewY = next.y;
                    return;
                }
                geometry.dragOverrideX = next.x;
                geometry.dragOverrideY = next.y;
            }

            onReleased: {
                const finalX = root.useGhostPreview ? root.previewX : geometry.dragOverrideX;
                const finalY = root.useGhostPreview ? root.previewY : geometry.dragOverrideY;
                geometry.savePosition(finalX, finalY);
                geometry.clearDragOverrides();
            }
        }

        MouseArea {
            id: resizeArea
            width: 48
            height: 48
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            acceptedButtons: Qt.RightButton
            enabled: !root.clickThrough
            cursorShape: pressed ? Qt.SizeFDiagCursor : Qt.ArrowCursor

            property point startPos
            property real startWidth
            property real startHeight

            onPressed: mouse => {
                startPos = root.useGhostPreview ? Qt.point(mouse.x, mouse.y) : mapToGlobal(mouse.x, mouse.y);
                startWidth = geometry.widgetWidth;
                startHeight = geometry.widgetHeight;
                root.previewWidth = geometry.widgetWidth;
                root.previewHeight = geometry.widgetHeight;
                geometry.dragOverrideW = geometry.widgetWidth;
                geometry.dragOverrideH = geometry.widgetHeight;
            }

            onPositionChanged: mouse => {
                if (!pressed)
                    return;
                const currentPos = root.useGhostPreview ? Qt.point(mouse.x, mouse.y) : mapToGlobal(mouse.x, mouse.y);
                const next = geometry.dragResizeTo(startWidth, startHeight, currentPos.x - startPos.x, currentPos.y - startPos.y);
                if (root.useGhostPreview) {
                    root.previewWidth = next.width;
                    root.previewHeight = next.height;
                    return;
                }
                geometry.dragOverrideW = next.width;
                geometry.dragOverrideH = next.height;
            }

            onReleased: {
                const finalW = root.useGhostPreview ? root.previewWidth : geometry.dragOverrideW;
                const finalH = root.useGhostPreview ? root.previewHeight : geometry.dragOverrideH;
                geometry.saveSize(finalW, finalH);
                geometry.clearDragOverrides();
            }
        }
    }

    Loader {
        active: root.isInteracting && root.useGhostPreview

        sourceComponent: PanelWindow {
            id: ghostPreviewWindow
            screen: root.screen
            color: "transparent"

            anchors {
                left: true
                right: true
                top: true
                bottom: true
            }

            mask: Region {}

            WlrLayershell.namespace: "dms:desktop-widget-preview"
            WlrLayershell.layer: WlrLayer.Bottom
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            DesktopWidgetGridLines {
                id: gridOverlay
                anchors.fill: parent
                visible: geometry.gridEnabled
                gridSize: geometry.gridSize
                extentWidth: geometry.screenWidth
                extentHeight: geometry.screenHeight
            }

            Rectangle {
                x: root.previewX
                y: root.previewY
                width: root.previewWidth
                height: root.previewHeight
                color: "transparent"
                border.color: Theme.primary
                border.width: 2
                radius: Theme.cornerRadius

                Rectangle {
                    width: 48
                    height: 48
                    anchors {
                        right: parent.right
                        bottom: parent.bottom
                    }
                    topLeftRadius: Theme.cornerRadius
                    bottomRightRadius: Theme.cornerRadius
                    color: Theme.primary
                    opacity: resizeArea.pressed ? 1 : 0.6
                }
            }
        }
    }

    Loader {
        active: root.isInteracting && geometry.gridEnabled && !root.useGhostPreview

        sourceComponent: PanelWindow {
            screen: root.screen
            color: "transparent"

            anchors {
                left: true
                right: true
                top: true
                bottom: true
            }

            mask: Region {}

            WlrLayershell.namespace: "dms:desktop-widget-grid"
            WlrLayershell.layer: root.overviewActive && (root.showOnOverview || root.showOnOverviewOnly) ? WlrLayer.Overlay : WlrLayer.Background
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            DesktopWidgetGridLines {
                anchors.fill: parent
                gridSize: geometry.gridSize
                extentWidth: geometry.screenWidth
                extentHeight: geometry.screenHeight
            }
        }
    }

    Loader {
        active: root.isInteracting

        sourceComponent: PanelWindow {
            id: helperWindow
            screen: root.screen
            color: "transparent"

            WlrLayershell.namespace: "dms:desktop-widget-helper"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            anchors {
                bottom: true
                left: true
                right: true
            }

            implicitHeight: 60

            Rectangle {
                id: helperContent
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Theme.spacingL
                width: helperRow.implicitWidth + Theme.spacingM * 2
                height: 32
                radius: Theme.cornerRadius
                color: Theme.hostSurface

                Row {
                    id: helperRow
                    anchors.centerIn: parent
                    spacing: Theme.spacingM
                    height: parent.height

                    Row {
                        spacing: Theme.spacingS
                        anchors.verticalCenter: parent.verticalCenter

                        DankIcon {
                            name: "grid_on"
                            size: 16
                            color: geometry.gridEnabled ? Theme.primary : Theme.surfaceText
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        StyledText {
                            text: geometry.gridEnabled ? I18n.tr("Grid: ON", "Widget grid snap status") : I18n.tr("Grid: OFF", "Widget grid snap status")
                            font.pixelSize: Theme.fontSizeSmall
                            font.family: Theme.fontFamily
                            color: geometry.gridEnabled ? Theme.primary : Theme.surfaceText
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        DankKeycap {
                            text: "G"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Rectangle {
                        width: 1
                        height: 16
                        color: Theme.outline
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Row {
                        spacing: Theme.spacingS
                        anchors.verticalCenter: parent.verticalCenter

                        DankKeycap {
                            text: "Z"
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        NumericText {
                            text: geometry.gridSize + "px"
                            reserveText: "200px"
                            width: Math.ceil(reservedWidth)
                            horizontalAlignment: Text.AlignHCenter
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceText
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        DankKeycap {
                            text: "X"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }
        }
    }
}
