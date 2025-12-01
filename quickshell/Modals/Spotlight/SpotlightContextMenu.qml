import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Common
import qs.Modals.Spotlight

PanelWindow {
    id: root

    WlrLayershell.namespace: "dms:spotlight-context-menu"
    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    property var appLauncher: null
    property real menuPositionX: 0
    property real menuPositionY: 0

    readonly property real shadowBuffer: 5

    screen: DankModalWindow.targetScreen

    function show(x, y, app, fromKeyboard) {
        fromKeyboard = fromKeyboard || false;
        menuContent.currentApp = app;

        let screenX = x;
        let screenY = y;

        const modalX = DankModalWindow.modalX;
        const modalY = DankModalWindow.modalY;

        if (fromKeyboard) {
            screenX = x + modalX;
            screenY = y + modalY;
        } else {
            screenX = x + (modalX - shadowBuffer);
            screenY = y + (modalY - shadowBuffer);
        }

        menuPositionX = screenX;
        menuPositionY = screenY;

        menuContent.selectedMenuIndex = fromKeyboard ? 0 : -1;
        menuContent.keyboardNavigation = true;
        visible = true;
    }

    function handleKey(event) {
        switch (event.key) {
        case Qt.Key_Down:
            menuContent.selectNext();
            event.accepted = true;
            break;
        case Qt.Key_Up:
            menuContent.selectPrevious();
            event.accepted = true;
            break;
        case Qt.Key_Return:
        case Qt.Key_Enter:
            menuContent.activateSelected();
            event.accepted = true;
            break;
        case Qt.Key_Escape:
        case Qt.Key_Menu:
            hide();
            event.accepted = true;
            break;
        }
    }

    function hide() {
        visible = false;
    }

    visible: false
    color: "transparent"
    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }


    SpotlightContextMenuContent {
        id: menuContent

        x: {
            const left = 10;
            const right = root.width - width - 10;
            const want = menuPositionX;
            return Math.max(left, Math.min(right, want));
        }
        y: {
            const top = 10;
            const bottom = root.height - height - 10;
            const want = menuPositionY;
            return Math.max(top, Math.min(bottom, want));
        }

        appLauncher: root.appLauncher

        opacity: root.visible ? 1 : 0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.shortDuration
                easing.type: Theme.emphasizedEasing
            }
        }

        onHideRequested: root.hide()
    }

    MouseArea {
        anchors.fill: parent
        z: -1
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: root.hide()
    }
}
