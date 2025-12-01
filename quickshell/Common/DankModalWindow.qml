pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.Services
import qs.Widgets

Singleton {
    id: root

    property var activeModal: null
    property bool windowsVisible: false
    property var targetScreen: null
    readonly property bool hasActiveModal: activeModal !== null
    readonly property bool shouldShowModal: hasActiveModal
    readonly property var screen: backgroundWindow.screen
    readonly property real dpr: screen ? CompositorService.getScreenScale(screen) : 1
    readonly property real shadowBuffer: 5

    property bool wantsToHide: false

    property real cachedModalWidth: 400
    property real cachedModalHeight: 300
    property real cachedModalX: 0
    property real cachedModalY: 0
    property var cachedModal: null
    property int cachedAnimationDuration: Theme.shortDuration
    property var cachedEnterCurve: Theme.expressiveCurves.expressiveFastSpatial
    property var cachedExitCurve: Theme.expressiveCurves.expressiveFastSpatial
    property real cachedScaleCollapsed: 0.96

    readonly property real modalWidth: cachedModalWidth
    readonly property real modalHeight: cachedModalHeight
    readonly property real modalX: cachedModalX
    readonly property real modalY: cachedModalY

    Connections {
        target: root.cachedModal
        function onModalWidthChanged() {
            if (!root.hasActiveModal)
                return;
            root.cachedModalWidth = Theme.px(root.cachedModal.modalWidth, root.dpr);
            root.cachedModalX = root.calculateX(root.cachedModal);
        }
        function onModalHeightChanged() {
            if (!root.hasActiveModal)
                return;
            root.cachedModalHeight = Theme.px(root.cachedModal.modalHeight, root.dpr);
            root.cachedModalY = root.calculateY(root.cachedModal);
        }
    }

    onScreenChanged: {
        if (!cachedModal || !screen)
            return;
        cachedModalWidth = Theme.px(cachedModal.modalWidth, dpr);
        cachedModalHeight = Theme.px(cachedModal.modalHeight, dpr);
        cachedModalX = calculateX(cachedModal);
        cachedModalY = calculateY(cachedModal);
    }

    function showModal(modal) {
        wantsToHide = false;
        targetScreen = CompositorService.focusedScreen;

        activeModal = modal;
        cachedModal = modal;
        windowsVisible = true;
        cachedModalWidth = Theme.px(modal.modalWidth, dpr);
        cachedModalHeight = Theme.px(modal.modalHeight, dpr);
        cachedModalX = calculateX(modal);
        cachedModalY = calculateY(modal);
        cachedAnimationDuration = modal.animationDuration ?? Theme.shortDuration;
        cachedEnterCurve = modal.animationEnterCurve ?? Theme.expressiveCurves.expressiveFastSpatial;
        cachedExitCurve = modal.animationExitCurve ?? Theme.expressiveCurves.expressiveFastSpatial;
        cachedScaleCollapsed = modal.animationScaleCollapsed ?? 0.96;

        if (modal.directContent)
            Qt.callLater(focusDirectContent);
    }

    function focusDirectContent() {
        if (!hasActiveModal)
            return;
        if (!cachedModal?.directContent)
            return;
        cachedModal.directContent.forceActiveFocus();
    }

    function hideModal() {
        wantsToHide = true;
        Qt.callLater(completeHide);
    }

    function completeHide() {
        if (!wantsToHide)
            return;
        activeModal = null;
        wantsToHide = false;
    }

    function hideModalInstant() {
        wantsToHide = false;
        activeModal = null;
        windowsVisible = false;
        cleanupInputMethod();
    }

    function onCloseAnimationFinished() {
        if (hasActiveModal)
            return;
        if (cachedModal && typeof cachedModal.onFullyClosed === "function")
            cachedModal.onFullyClosed();
        cleanupInputMethod();
        windowsVisible = false;
    }

    function cleanupInputMethod() {
        if (!Qt.inputMethod)
            return;
        Qt.inputMethod.hide();
        Qt.inputMethod.reset();
    }

    function calculateX(m) {
        const screen = backgroundWindow.screen;
        if (!screen)
            return 0;
        const w = Theme.px(m.modalWidth, dpr);
        switch (m.positioning) {
        case "center":
            return Theme.snap((screen.width - w) / 2, dpr);
        case "top-right":
            return Theme.snap(Math.max(Theme.spacingL, screen.width - w - Theme.spacingL), dpr);
        case "custom":
            return Theme.snap(m.customPosition.x, dpr);
        default:
            return 0;
        }
    }

    function calculateY(m) {
        const screen = backgroundWindow.screen;
        if (!screen)
            return 0;
        const h = Theme.px(m.modalHeight, dpr);
        switch (m.positioning) {
        case "center":
            return Theme.snap((screen.height - h) / 2, dpr);
        case "top-right":
            return Theme.snap(Theme.barHeight + Theme.spacingXS, dpr);
        case "custom":
            return Theme.snap(m.customPosition.y, dpr);
        default:
            return 0;
        }
    }

    PanelWindow {
        id: backgroundWindow
        visible: root.windowsVisible
        screen: root.targetScreen
        color: "transparent"

        WlrLayershell.namespace: "dms:modal:background"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.exclusiveZone: -1
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        anchors {
            top: true
            left: true
            right: true
            bottom: true
        }

        mask: Region {
            item: backgroundMaskRect
            intersection: Intersection.Xor
        }

        Item {
            id: backgroundMaskRect
            x: root.shouldShowModal ? root.modalX : 0
            y: root.shouldShowModal ? root.modalY : 0
            width: root.shouldShowModal ? root.modalWidth : (backgroundWindow.screen?.width ?? 1920)
            height: root.shouldShowModal ? root.modalHeight : (backgroundWindow.screen?.height ?? 1080)
        }

        MouseArea {
            anchors.fill: parent
            enabled: root.windowsVisible
            onClicked: mouse => {
                if (!root.cachedModal || !root.shouldShowModal)
                    return;
                if (!(root.cachedModal.closeOnBackgroundClick ?? true))
                    return;
                const outside = mouse.x < root.modalX || mouse.x > root.modalX + root.modalWidth || mouse.y < root.modalY || mouse.y > root.modalY + root.modalHeight;
                if (!outside)
                    return;
                root.cachedModal.backgroundClicked();
            }
        }

        Rectangle {
            anchors.fill: parent
            color: "black"
            opacity: root.shouldShowModal && SettingsData.modalDarkenBackground ? (root.cachedModal?.backgroundOpacity ?? 0.5) : 0
            visible: SettingsData.modalDarkenBackground

            Behavior on opacity {
                NumberAnimation {
                    duration: root.cachedAnimationDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: root.shouldShowModal ? root.cachedEnterCurve : root.cachedExitCurve
                }
            }
        }
    }

    PanelWindow {
        id: contentWindow
        visible: root.windowsVisible
        screen: root.targetScreen
        color: "transparent"

        WlrLayershell.namespace: root.cachedModal?.layerNamespace ?? "dms:modal"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.exclusiveZone: -1
        WlrLayershell.keyboardFocus: {
            if (!root.hasActiveModal)
                return WlrKeyboardFocus.None;
            if (root.cachedModal?.customKeyboardFocus !== null && root.cachedModal?.customKeyboardFocus !== undefined)
                return root.cachedModal.customKeyboardFocus;
            if (CompositorService.isHyprland)
                return WlrKeyboardFocus.OnDemand;
            return WlrKeyboardFocus.Exclusive;
        }

        anchors {
            left: true
            top: true
        }

        WlrLayershell.margins {
            left: Math.max(0, Theme.snap(root.modalX - root.shadowBuffer, root.dpr))
            top: Math.max(0, Theme.snap(root.modalY - root.shadowBuffer, root.dpr))
        }

        implicitWidth: root.modalWidth + (root.shadowBuffer * 2)
        implicitHeight: root.modalHeight + (root.shadowBuffer * 2)

        mask: Region {
            item: contentMaskRect
        }

        Item {
            id: contentMaskRect
            x: root.shadowBuffer
            y: root.shadowBuffer
            width: root.shouldShowModal ? root.modalWidth : 0
            height: root.shouldShowModal ? root.modalHeight : 0
        }

        HyprlandFocusGrab {
            windows: [contentWindow]
            active: CompositorService.isHyprland && root.hasActiveModal && (root.cachedModal?.shouldHaveFocus ?? false)
        }

        Item {
            id: contentContainer
            x: root.shadowBuffer
            y: root.shadowBuffer
            width: root.modalWidth
            height: root.modalHeight

            readonly property bool hasDirectContent: root.cachedModal ? (root.cachedModal.directContent !== null && root.cachedModal.directContent !== undefined) : false

            opacity: root.shouldShowModal ? 1 : 0
            scale: root.shouldShowModal ? 1 : root.cachedScaleCollapsed

            onHasDirectContentChanged: {
                if (!hasDirectContent)
                    return;
                const dc = root.cachedModal.directContent;
                if (dc.parent === directContentWrapper)
                    return;
                dc.parent = directContentWrapper;
                dc.anchors.fill = directContentWrapper;
            }

            Behavior on opacity {
                NumberAnimation {
                    id: opacityAnimation
                    duration: root.cachedAnimationDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: root.shouldShowModal ? root.cachedEnterCurve : root.cachedExitCurve
                    onRunningChanged: {
                        if (running || root.shouldShowModal)
                            return;
                        root.onCloseAnimationFinished();
                    }
                }
            }

            Behavior on scale {
                NumberAnimation {
                    id: scaleAnimation
                    duration: root.cachedAnimationDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: root.shouldShowModal ? root.cachedEnterCurve : root.cachedExitCurve
                }
            }

            DankRectangle {
                anchors.fill: parent
                color: root.cachedModal?.backgroundColor ?? Theme.surfaceContainer
                borderColor: root.cachedModal?.borderColor ?? Theme.outlineMedium
                borderWidth: root.cachedModal?.borderWidth ?? 1
                radius: root.cachedModal?.cornerRadius ?? Theme.cornerRadius
                z: -1
            }

            FocusScope {
                id: modalFocusScope
                anchors.fill: parent
                focus: root.hasActiveModal

                Keys.onEscapePressed: event => {
                    if (!root.cachedModal?.closeOnEscapeKey)
                        return;
                    root.cachedModal.close();
                    event.accepted = true;
                }

                Keys.forwardTo: contentContainer.hasDirectContent ? [directContentWrapper] : (contentLoader.item ? [contentLoader.item] : [])

                Item {
                    id: directContentWrapper
                    anchors.fill: parent
                    visible: contentContainer.hasDirectContent
                    focus: contentContainer.hasDirectContent && root.hasActiveModal
                }

                Loader {
                    id: contentLoader
                    anchors.fill: parent
                    active: !contentContainer.hasDirectContent && root.windowsVisible
                    asynchronous: false
                    sourceComponent: root.cachedModal?.content ?? null
                    visible: !contentContainer.hasDirectContent
                    focus: !contentContainer.hasDirectContent && root.hasActiveModal
                    onLoaded: {
                        if (!item)
                            return;
                        if (root.cachedModal)
                            root.cachedModal.loadedContent = item;
                        if (root.hasActiveModal)
                            item.forceActiveFocus();
                    }
                    onActiveChanged: {
                        if (active || !root.cachedModal)
                            return;
                        root.cachedModal.loadedContent = null;
                    }
                }
            }
        }
    }
}
