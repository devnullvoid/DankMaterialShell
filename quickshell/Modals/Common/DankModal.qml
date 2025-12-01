import QtQuick
import qs.Common

Item {
    id: root

    property string layerNamespace: "dms:modal"
    property Component content: null
    property Item directContent: null
    property Item loadedContent: null
    readonly property var contentLoader: QtObject {
        readonly property var item: root.directContent ?? root.loadedContent
    }
    property real modalWidth: 400
    property real modalHeight: 300
    property var targetScreen: null
    property bool showBackground: true
    property real backgroundOpacity: 0.5
    property string positioning: "center"
    property point customPosition: Qt.point(0, 0)
    property bool closeOnEscapeKey: true
    property bool closeOnBackgroundClick: true
    property string animationType: "scale"
    property int animationDuration: Theme.expressiveDurations.expressiveDefaultSpatial
    property real animationScaleCollapsed: 0.96
    property real animationOffset: Theme.spacingL
    property list<real> animationEnterCurve: Theme.expressiveCurves.expressiveDefaultSpatial
    property list<real> animationExitCurve: Theme.expressiveCurves.emphasized
    property color backgroundColor: Theme.surfaceContainer
    property color borderColor: Theme.outlineMedium
    property real borderWidth: 1
    property real cornerRadius: Theme.cornerRadius
    property bool enableShadow: false
    property bool shouldBeVisible: false
    property bool shouldHaveFocus: shouldBeVisible
    property bool allowFocusOverride: false
    property bool allowStacking: false
    property bool keepContentLoaded: false
    property bool keepPopoutsOpen: false
    property var customKeyboardFocus: null
    property bool useOverlayLayer: false

    signal opened
    signal dialogClosed
    signal backgroundClicked

    onBackgroundClicked: {
        if (closeOnBackgroundClick)
            close();
    }

    function open() {
        ModalManager.openModal(root);
        shouldBeVisible = true;
        shouldHaveFocus = true;
        DankModalWindow.showModal(root);
        opened();
    }

    function openCentered() {
        positioning = "center";
        open();
    }

    function close() {
        shouldBeVisible = false;
        shouldHaveFocus = false;
        DankModalWindow.hideModal();
        dialogClosed();
    }

    function instantClose() {
        shouldBeVisible = false;
        shouldHaveFocus = false;
        DankModalWindow.hideModalInstant();
        dialogClosed();
    }

    function toggle() {
        shouldBeVisible ? close() : open();
    }

    Connections {
        target: ModalManager
        function onCloseAllModalsExcept(excludedModal) {
            if (excludedModal === root || allowStacking || !shouldBeVisible)
                return;
            close();
        }
    }
}
