import QtQuick

QtObject {
    id: keyboardController

    required property var modal

    function reset() {
        modal.selectedIndex = 0;
        modal.keyboardNavigationActive = false;
        modal.showKeyboardHints = false;
    }

    function selectNext() {
        if (!modal.clipboardEntries || modal.clipboardEntries.length === 0) {
            return;
        }
        modal.keyboardNavigationActive = true;
        modal.selectedIndex = Math.min(modal.selectedIndex + 1, modal.clipboardEntries.length - 1);
    }

    function selectPrevious() {
        if (!modal.clipboardEntries || modal.clipboardEntries.length === 0) {
            return;
        }
        modal.keyboardNavigationActive = true;
        modal.selectedIndex = Math.max(modal.selectedIndex - 1, 0);
    }

    function copySelected() {
        if (!modal.clipboardEntries || modal.clipboardEntries.length === 0 || modal.selectedIndex < 0 || modal.selectedIndex >= modal.clipboardEntries.length) {
            return;
        }
        const selectedEntry = modal.clipboardEntries[modal.selectedIndex];
        modal.copyEntry(selectedEntry);
    }

    function deleteSelected() {
        if (!modal.clipboardEntries || modal.clipboardEntries.length === 0 || modal.selectedIndex < 0 || modal.selectedIndex >= modal.clipboardEntries.length) {
            return;
        }
        const selectedEntry = modal.clipboardEntries[modal.selectedIndex];
        modal.deleteEntry(selectedEntry);
    }

    function handleKey(event) {
        switch (event.key) {
        case Qt.Key_Escape:
            if (modal.keyboardNavigationActive) {
                modal.keyboardNavigationActive = false;
            } else {
                modal.hide();
            }
            event.accepted = true;
            return;
        case Qt.Key_Down:
        case Qt.Key_Tab:
            if (!modal.keyboardNavigationActive) {
                modal.keyboardNavigationActive = true;
                modal.selectedIndex = 0;
            } else {
                selectNext();
            }
            event.accepted = true;
            return;
        case Qt.Key_Up:
        case Qt.Key_Backtab:
            if (!modal.keyboardNavigationActive) {
                modal.keyboardNavigationActive = true;
                modal.selectedIndex = 0;
            } else if (modal.selectedIndex === 0) {
                modal.keyboardNavigationActive = false;
            } else {
                selectPrevious();
            }
            event.accepted = true;
            return;
        case Qt.Key_F10:
            modal.showKeyboardHints = !modal.showKeyboardHints;
            event.accepted = true;
            return;
        }

        if (event.modifiers & Qt.ControlModifier) {
            switch (event.key) {
            case Qt.Key_N:
            case Qt.Key_J:
                if (!modal.keyboardNavigationActive) {
                    modal.keyboardNavigationActive = true;
                    modal.selectedIndex = 0;
                } else {
                    selectNext();
                }
                event.accepted = true;
                return;
            case Qt.Key_P:
            case Qt.Key_K:
                if (!modal.keyboardNavigationActive) {
                    modal.keyboardNavigationActive = true;
                    modal.selectedIndex = 0;
                } else if (modal.selectedIndex === 0) {
                    modal.keyboardNavigationActive = false;
                } else {
                    selectPrevious();
                }
                event.accepted = true;
                return;
            case Qt.Key_C:
                if (modal.keyboardNavigationActive) {
                    copySelected();
                    event.accepted = true;
                }
                return;
            }
        }

        if (event.modifiers & Qt.ShiftModifier && event.key === Qt.Key_Delete) {
            modal.clearAll();
            modal.hide();
            event.accepted = true;
            return;
        }

        if (modal.keyboardNavigationActive) {
            switch (event.key) {
            case Qt.Key_Return:
            case Qt.Key_Enter:
                copySelected();
                event.accepted = true;
                return;
            case Qt.Key_Delete:
                deleteSelected();
                event.accepted = true;
                return;
            }
        }
    }
}
