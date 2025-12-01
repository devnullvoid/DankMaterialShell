import QtQuick
import QtQuick.Controls
import Quickshell
import qs.Common
import qs.Modals.Spotlight

Popup {
    id: root

    property var appLauncher: null
    property var searchField: null

    function show(x, y, app, fromKeyboard) {
        fromKeyboard = fromKeyboard || false;
        menuContent.currentApp = app;

        root.x = x + 4;
        root.y = y + 4;

        menuContent.selectedMenuIndex = fromKeyboard ? 0 : -1;
        menuContent.keyboardNavigation = true;

        open();
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
        close();
    }

    width: menuContent.implicitWidth
    height: menuContent.implicitHeight
    padding: 0
    closePolicy: Popup.CloseOnPressOutside
    modal: true
    dim: false
    background: Item {}

    onClosed: {
        if (searchField) {
            Qt.callLater(() => {
                searchField.forceActiveFocus();
            });
        }
    }

    enter: Transition {
        NumberAnimation {
            property: "opacity"
            from: 0
            to: 1
            duration: Theme.shortDuration
            easing.type: Theme.emphasizedEasing
        }
    }

    exit: Transition {
        NumberAnimation {
            property: "opacity"
            from: 1
            to: 0
            duration: Theme.shortDuration
            easing.type: Theme.emphasizedEasing
        }
    }

    contentItem: SpotlightContextMenuContent {
        id: menuContent
        appLauncher: root.appLauncher
        onHideRequested: root.hide()
    }
}
