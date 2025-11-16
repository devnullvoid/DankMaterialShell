import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs.Common
import qs.Services
import qs.Widgets

PanelWindow {
    id: root

    property string blurNamespace: "dms:osd"
    WlrLayershell.namespace: blurNamespace

    property alias content: contentLoader.sourceComponent
    property alias contentLoader: contentLoader
    property var modelData
    property bool shouldBeVisible: false
    property int autoHideInterval: 2000
    property bool enableMouseInteraction: false
    property real osdWidth: Theme.iconSize + Theme.spacingS * 2
    property real osdHeight: Theme.iconSize + Theme.spacingS * 2
    property int animationDuration: Theme.mediumDuration
    property var animationEasing: Theme.emphasizedEasing

    signal osdShown
    signal osdHidden

    function show() {
        OSDManager.showOSD(root)
        closeTimer.stop()
        shouldBeVisible = true
        visible = true
        hideTimer.restart()
        osdShown()
    }

    function hide() {
        shouldBeVisible = false
        closeTimer.restart()
    }

    function resetHideTimer() {
        if (shouldBeVisible) {
            hideTimer.restart()
        }
    }

    function updateHoverState() {
        let isHovered = (enableMouseInteraction && mouseArea.containsMouse) || osdContainer.childHovered
        if (enableMouseInteraction) {
            if (isHovered) {
                hideTimer.stop()
            } else if (shouldBeVisible) {
                hideTimer.restart()
            }
        }
    }

    function setChildHovered(hovered) {
        osdContainer.childHovered = hovered
        updateHoverState()
    }

    screen: modelData
    visible: false
    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    color: "transparent"

    readonly property real dpr: CompositorService.getScreenScale(screen)
    readonly property real screenWidth: screen.width
    readonly property real screenHeight: screen.height
    readonly property real alignedWidth: Theme.px(osdWidth, dpr)
    readonly property real alignedHeight: Theme.px(osdHeight, dpr)

    readonly property real barThickness: {
        if (!SettingsData.dankBarVisible) return 0
        const widgetThickness = Math.max(20, 26 + SettingsData.dankBarInnerPadding * 0.6)
        return Math.max(widgetThickness + SettingsData.dankBarInnerPadding + 4, Theme.barHeight - 4 - (8 - SettingsData.dankBarInnerPadding))
    }

    readonly property real barOffset: {
        if (!SettingsData.dankBarVisible) return 0
        return barThickness + SettingsData.dankBarSpacing + SettingsData.dankBarBottomGap
    }

    readonly property real alignedX: {
        const margin = Theme.spacingM
        const centerX = (screenWidth - alignedWidth) / 2

        switch (SettingsData.osdPosition) {
        case SettingsData.Position.Left:
        case SettingsData.Position.Bottom:
            const leftOffset = SettingsData.dankBarPosition === SettingsData.Position.Left ? barOffset : 0
            return Theme.snap(margin + leftOffset, dpr)
        case SettingsData.Position.Top:
        case SettingsData.Position.Right:
            const rightOffset = SettingsData.dankBarPosition === SettingsData.Position.Right ? barOffset : 0
            return Theme.snap(screenWidth - alignedWidth - margin - rightOffset, dpr)
        case SettingsData.Position.TopCenter:
        case SettingsData.Position.BottomCenter:
        default:
            return Theme.snap(centerX, dpr)
        }
    }

    readonly property real alignedY: {
        const margin = Theme.spacingM

        switch (SettingsData.osdPosition) {
        case SettingsData.Position.Top:
        case SettingsData.Position.Left:
        case SettingsData.Position.TopCenter:
            const topOffset = SettingsData.dankBarPosition === SettingsData.Position.Top ? barOffset : 0
            return Theme.snap(margin + topOffset, dpr)
        case SettingsData.Position.Right:
        case SettingsData.Position.Bottom:
        case SettingsData.Position.BottomCenter:
        default:
            const bottomOffset = SettingsData.dankBarPosition === SettingsData.Position.Bottom ? barOffset : 0
            return Theme.snap(screenHeight - alignedHeight - margin - bottomOffset, dpr)
        }
    }

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    Timer {
        id: hideTimer

        interval: autoHideInterval
        repeat: false
        onTriggered: {
            if (!enableMouseInteraction || !mouseArea.containsMouse) {
                hide()
            } else {
                hideTimer.restart()
            }
        }
    }

    Timer {
        id: closeTimer
        interval: animationDuration + 50
        onTriggered: {
            if (!shouldBeVisible) {
                visible = false
                osdHidden()
            }
        }
    }

    Item {
        id: osdContainer
        x: alignedX
        y: alignedY
        width: alignedWidth
        height: alignedHeight
        opacity: shouldBeVisible ? 1 : 0
        scale: shouldBeVisible ? 1 : 0.9

        property bool childHovered: false
        property real shadowBlurPx: 10
        property real shadowSpreadPx: 0
        property real shadowBaseAlpha: 0.60
        readonly property real popupSurfaceAlpha: SettingsData.popupTransparency
        readonly property real effectiveShadowAlpha: Math.max(0, Math.min(1, shadowBaseAlpha * popupSurfaceAlpha * osdContainer.opacity))

        DankRectangle {
            id: background
            anchors.fill: parent
            radius: Theme.cornerRadius
            color: Theme.withAlpha(Theme.surfaceContainer, osdContainer.popupSurfaceAlpha)
            z: -1
        }

        Item {
            id: bgShadowLayer
            anchors.fill: parent
            visible: osdContainer.popupSurfaceAlpha >= 0.95
            layer.enabled: Quickshell.env("DMS_DISABLE_LAYER") !== "true" && Quickshell.env("DMS_DISABLE_LAYER") !== "1"
            layer.smooth: false
            layer.textureSize: Qt.size(Math.round(width * root.dpr), Math.round(height * root.dpr))
            layer.textureMirroring: ShaderEffectSource.MirrorVertically

            layer.effect: MultiEffect {
                id: shadowFx
                autoPaddingEnabled: true
                shadowEnabled: true
                blurEnabled: false
                maskEnabled: false
                property int blurMax: 64
                shadowBlur: Math.max(0, Math.min(1, osdContainer.shadowBlurPx / blurMax))
                shadowScale: 1 + (2 * osdContainer.shadowSpreadPx) / Math.max(1, Math.min(bgShadowLayer.width, bgShadowLayer.height))
                shadowColor: {
                    const baseColor = Theme.isLightMode ? Qt.rgba(0, 0, 0, 1) : Theme.surfaceContainerHighest
                    return Theme.withAlpha(baseColor, osdContainer.effectiveShadowAlpha)
                }
            }

            DankRectangle {
                anchors.fill: parent
                radius: Theme.cornerRadius
            }
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: enableMouseInteraction
            acceptedButtons: Qt.NoButton
            propagateComposedEvents: true
            z: -1
            onContainsMouseChanged: updateHoverState()
        }

        onChildHoveredChanged: updateHoverState()

        Loader {
            id: contentLoader
            anchors.fill: parent
            active: root.visible
            asynchronous: false
        }

        Behavior on opacity {
            NumberAnimation {
                duration: animationDuration
                easing.type: animationEasing
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: animationDuration
                easing.type: animationEasing
            }
        }
    }

    mask: Region {
        item: bgShadowLayer
    }
}
