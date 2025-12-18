import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.Common
import qs.Services

Item {
    id: root

    required property string pluginId
    required property var pluginComponent
    required property var screen

    property var pluginService: null
    property string variantId: ""
    property var variantData: null

    readonly property string settingsKey: variantId ? variantId : pluginId
    readonly property bool isVariant: variantId !== "" && variantData !== null
    readonly property bool usePluginService: pluginService !== null && !isVariant
    readonly property string screenKey: SettingsData.getScreenDisplayName(screen)

    readonly property int screenWidth: screen?.width ?? 1920
    readonly property int screenHeight: screen?.height ?? 1080

    readonly property bool useGhostPreview: !CompositorService.isNiri

    property real previewX: widgetX
    property real previewY: widgetY
    property real previewWidth: widgetWidth
    property real previewHeight: widgetHeight

    readonly property bool hasSavedPosition: {
        if (isVariant)
            return variantData?.positions?.[screenKey]?.x !== undefined;
        if (usePluginService)
            return pluginService.loadPluginData(pluginId, "desktopX_" + screenKey, null) !== null;
        return SettingsData.getDesktopWidgetPosition(pluginId, screenKey, "x", null) !== null;
    }

    readonly property bool hasSavedSize: {
        if (isVariant)
            return variantData?.positions?.[screenKey]?.width !== undefined;
        if (usePluginService)
            return pluginService.loadPluginData(pluginId, "desktopWidth_" + screenKey, null) !== null;
        return SettingsData.getDesktopWidgetPosition(pluginId, screenKey, "width", null) !== null;
    }

    property real savedX: {
        if (isVariant)
            return variantData?.positions?.[screenKey]?.x ?? (screenWidth / 2 - savedWidth / 2);
        if (usePluginService)
            return pluginService.loadPluginData(pluginId, "desktopX_" + screenKey, screenWidth / 2 - savedWidth / 2);
        return SettingsData.getDesktopWidgetPosition(pluginId, screenKey, "x", screenWidth / 2 - savedWidth / 2);
    }
    property real savedY: {
        if (isVariant)
            return variantData?.positions?.[screenKey]?.y ?? (screenHeight / 2 - savedHeight / 2);
        if (usePluginService)
            return pluginService.loadPluginData(pluginId, "desktopY_" + screenKey, screenHeight / 2 - savedHeight / 2);
        return SettingsData.getDesktopWidgetPosition(pluginId, screenKey, "y", screenHeight / 2 - savedHeight / 2);
    }
    property real savedWidth: {
        if (isVariant)
            return variantData?.positions?.[screenKey]?.width ?? 280;
        if (usePluginService)
            return pluginService.loadPluginData(pluginId, "desktopWidth_" + screenKey, 200);
        return SettingsData.getDesktopWidgetPosition(pluginId, screenKey, "width", 280);
    }
    property real savedHeight: {
        if (isVariant)
            return variantData?.positions?.[screenKey]?.height ?? 180;
        if (usePluginService)
            return pluginService.loadPluginData(pluginId, "desktopHeight_" + screenKey, 200);
        return SettingsData.getDesktopWidgetPosition(pluginId, screenKey, "height", 180);
    }

    property real widgetX: Math.max(0, Math.min(savedX, screenWidth - widgetWidth))
    property real widgetY: Math.max(0, Math.min(savedY, screenHeight - widgetHeight))
    property real widgetWidth: Math.max(minWidth, Math.min(savedWidth, screenWidth))
    property real widgetHeight: Math.max(minHeight, Math.min(savedHeight, screenHeight))

    property real minWidth: contentLoader.item?.minWidth ?? 100
    property real minHeight: contentLoader.item?.minHeight ?? 100
    property bool forceSquare: contentLoader.item?.forceSquare ?? false
    property bool isInteracting: dragArea.pressed || resizeArea.pressed

    function updateVariantPositions(updates) {
        const positions = JSON.parse(JSON.stringify(variantData?.positions || {}));
        positions[screenKey] = Object.assign({}, positions[screenKey] || {}, updates);
        SettingsData.updateSystemMonitorVariant(variantId, {
            positions: positions
        });
    }

    function savePosition() {
        if (isVariant && variantData) {
            updateVariantPositions({
                x: root.widgetX,
                y: root.widgetY
            });
            return;
        }
        if (usePluginService) {
            pluginService.savePluginData(pluginId, "desktopX_" + screenKey, root.widgetX);
            pluginService.savePluginData(pluginId, "desktopY_" + screenKey, root.widgetY);
            return;
        }
        SettingsData.updateDesktopWidgetPosition(pluginId, screenKey, {
            x: root.widgetX,
            y: root.widgetY
        });
    }

    function saveSize() {
        if (isVariant && variantData) {
            updateVariantPositions({
                width: root.widgetWidth,
                height: root.widgetHeight
            });
            return;
        }
        if (usePluginService) {
            pluginService.savePluginData(pluginId, "desktopWidth_" + screenKey, root.widgetWidth);
            pluginService.savePluginData(pluginId, "desktopHeight_" + screenKey, root.widgetHeight);
            return;
        }
        SettingsData.updateDesktopWidgetPosition(pluginId, screenKey, {
            width: root.widgetWidth,
            height: root.widgetHeight
        });
    }

    PanelWindow {
        id: widgetWindow
        screen: root.screen
        visible: root.visible
        color: "transparent"

        WlrLayershell.namespace: "quickshell:desktop-widget:" + root.pluginId + (root.variantId ? ":" + root.variantId : "")
        WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.exclusionMode: ExclusionMode.Ignore
        WlrLayershell.keyboardFocus: (CompositorService.useHyprlandFocusGrab && root.isInteracting) ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        HyprlandFocusGrab {
            active: CompositorService.isHyprland && root.isInteracting
            windows: [widgetWindow]
        }

        anchors {
            left: true
            top: true
        }

        WlrLayershell.margins {
            left: root.widgetX
            top: root.widgetY
        }

        implicitWidth: root.widgetWidth
        implicitHeight: root.widgetHeight

        Loader {
            id: contentLoader
            anchors.fill: parent
            sourceComponent: root.pluginComponent

            onLoaded: {
                if (!item)
                    return;
                if (root.usePluginService) {
                    item.pluginService = root.pluginService;
                    item.pluginId = root.pluginId;
                }
                if (item.variantId !== undefined)
                    item.variantId = root.variantId;
                if (item.variantData !== undefined)
                    item.variantData = Qt.binding(() => root.variantData);
                if (!root.hasSavedSize) {
                    const defW = item.defaultWidth ?? item.widgetWidth ?? 280;
                    const defH = item.defaultHeight ?? item.widgetHeight ?? 180;
                    root.widgetWidth = Math.max(root.minWidth, Math.min(defW, root.screenWidth));
                    root.widgetHeight = Math.max(root.minHeight, Math.min(defH, root.screenHeight));
                }
                if (!root.hasSavedPosition) {
                    root.widgetX = Math.max(0, Math.min(root.screenWidth / 2 - root.widgetWidth / 2, root.screenWidth - root.widgetWidth));
                    root.widgetY = Math.max(0, Math.min(root.screenHeight / 2 - root.widgetHeight / 2, root.screenHeight - root.widgetHeight));
                }
                if (item.widgetWidth !== undefined)
                    item.widgetWidth = Qt.binding(() => contentLoader.width);
                if (item.widgetHeight !== undefined)
                    item.widgetHeight = Qt.binding(() => contentLoader.height);
            }
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
            cursorShape: pressed ? Qt.ClosedHandCursor : Qt.ArrowCursor

            property point startPos
            property real startX
            property real startY

            onPressed: mouse => {
                startPos = root.useGhostPreview ? Qt.point(mouse.x, mouse.y) : mapToGlobal(mouse.x, mouse.y);
                startX = root.widgetX;
                startY = root.widgetY;
                root.previewX = root.widgetX;
                root.previewY = root.widgetY;
            }

            onPositionChanged: mouse => {
                if (!pressed)
                    return;
                const currentPos = root.useGhostPreview ? Qt.point(mouse.x, mouse.y) : mapToGlobal(mouse.x, mouse.y);
                const newX = Math.max(0, Math.min(startX + currentPos.x - startPos.x, root.screenWidth - root.widgetWidth));
                const newY = Math.max(0, Math.min(startY + currentPos.y - startPos.y, root.screenHeight - root.widgetHeight));
                if (root.useGhostPreview) {
                    root.previewX = newX;
                    root.previewY = newY;
                    return;
                }
                root.widgetX = newX;
                root.widgetY = newY;
            }

            onReleased: {
                if (root.useGhostPreview) {
                    root.widgetX = root.previewX;
                    root.widgetY = root.previewY;
                }
                root.savePosition();
            }
        }

        MouseArea {
            id: resizeArea
            width: 48
            height: 48
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            acceptedButtons: Qt.RightButton
            cursorShape: pressed ? Qt.SizeFDiagCursor : Qt.ArrowCursor

            property point startPos
            property real startWidth
            property real startHeight

            onPressed: mouse => {
                startPos = root.useGhostPreview ? Qt.point(mouse.x, mouse.y) : mapToGlobal(mouse.x, mouse.y);
                startWidth = root.widgetWidth;
                startHeight = root.widgetHeight;
                root.previewWidth = root.widgetWidth;
                root.previewHeight = root.widgetHeight;
            }

            onPositionChanged: mouse => {
                if (!pressed)
                    return;
                const currentPos = root.useGhostPreview ? Qt.point(mouse.x, mouse.y) : mapToGlobal(mouse.x, mouse.y);
                let newW = Math.max(root.minWidth, Math.min(startWidth + currentPos.x - startPos.x, root.screenWidth - root.widgetX));
                let newH = Math.max(root.minHeight, Math.min(startHeight + currentPos.y - startPos.y, root.screenHeight - root.widgetY));
                if (root.forceSquare) {
                    const size = Math.max(newW, newH);
                    newW = Math.min(size, root.screenWidth - root.widgetX);
                    newH = Math.min(size, root.screenHeight - root.widgetY);
                }
                if (root.useGhostPreview) {
                    root.previewWidth = newW;
                    root.previewHeight = newH;
                    return;
                }
                root.widgetWidth = newW;
                root.widgetHeight = newH;
            }

            onReleased: {
                if (root.useGhostPreview) {
                    root.widgetWidth = root.previewWidth;
                    root.widgetHeight = root.previewHeight;
                }
                root.saveSize();
            }
        }
    }

    Loader {
        active: root.isInteracting && root.useGhostPreview

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

            WlrLayershell.namespace: "quickshell:desktop-widget-preview"
            WlrLayershell.layer: WlrLayer.Background
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

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
}
