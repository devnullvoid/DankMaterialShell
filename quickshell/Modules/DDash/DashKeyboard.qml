pragma ComponentBehavior: Bound

import QtQuick
import "../../DCommon/Common/FocusNavigation.js" as FocusNavigation

Item {
    id: root

    property bool active: false
    property bool editable: true
    property bool editMode: false
    property bool optionsShown: false
    property bool menuOpen: false
    property var tabItem: null
    property Item contentScope: null
    property Item contentTarget: null
    property var headerTargets: []
    property string headerEdge: "up"

    readonly property bool idle: active && !optionsShown && !menuOpen
    readonly property bool contentFocused: contentScope?.activeFocus ?? false
    readonly property bool headerFocused: headerTargets.some(item => item?.activeFocus ?? false)
    readonly property bool browsing: idle && !editMode && !(tabItem?.blocksTabNavigation ?? false)

    signal tabCycleRequested(int direction)
    signal editModeRequested(bool on)
    signal optionsDismissRequested
    signal closeRequested

    function visibleHeaderTargets() {
        return headerTargets.filter(item => item && item.visible && item.enabled);
    }

    function focusHeader(backwards) {
        const targets = visibleHeaderTargets();
        const target = backwards ? targets[targets.length - 1] : targets[0];
        target?.forceActiveFocus(backwards ? Qt.BacktabFocusReason : Qt.TabFocusReason);
    }

    function enterContent(backwards) {
        const target = backwards ? (tabItem?.previousFocusTarget ?? contentTarget) : contentTarget;
        FocusNavigation.focusItem(target, backwards);
    }

    function cycleRegion(backwards) {
        const targets = visibleHeaderTargets();
        if (!targets.some(FocusNavigation.containsFocus) && targets.length > 0) {
            focusHeader(backwards);
            return;
        }
        if (FocusNavigation.moveFocus(targets, backwards))
            return;
        enterContent(backwards);
    }

    function inContent(item) {
        for (let p = item; p; p = p.parent) {
            if (p === contentScope)
                return true;
        }
        return false;
    }

    // Tab wraps inside the content, as in Settings.
    function walkContent(backwards) {
        if (!contentFocused) {
            enterContent(backwards);
            return;
        }
        let item = Window.activeFocusItem;
        for (let step = 0; item && step < 1000; step++) {
            item = item.nextItemInFocusChain(!backwards);
            if (inContent(item)) {
                item.forceActiveFocus(backwards ? Qt.BacktabFocusReason : Qt.TabFocusReason);
                return;
            }
        }
    }

    // A tab without restoreFocus parks focus on the host, which counts as content.
    function toggleRegion() {
        if (headerFocused || visibleHeaderTargets().length === 0)
            enterContent(false);
        else
            focusHeader(false);
    }

    function moveCard(direction) {
        if (!contentFocused) {
            if (direction === headerEdge)
                focusHeader(false);
            else
                enterContent(false);
            return;
        }
        if (tabItem?.moveCardFocus?.(direction) !== true && direction === headerEdge)
            focusHeader(false);
    }

    function arrowDirection(event) {
        if ((event.modifiers & ~Qt.KeypadModifier) !== Qt.NoModifier)
            return "";
        switch (event.key) {
        case Qt.Key_Left:
            return "left";
        case Qt.Key_Right:
            return "right";
        case Qt.Key_Up:
            return "up";
        case Qt.Key_Down:
            return "down";
        }
        return "";
    }

    function contentEntryFor(key) {
        switch (key) {
        case Qt.Key_Down:
        case Qt.Key_Right:
            return "forwards";
        case Qt.Key_Up:
        case Qt.Key_Left:
            return "backwards";
        }
        return "";
    }

    function handleKeyEvent(event) {
        if (!active || menuOpen)
            return false;
        if (optionsShown) {
            if (event.key !== Qt.Key_Escape)
                return false;
            optionsDismissRequested();
            return true;
        }
        const forTab = !headerFocused || event.key === Qt.Key_Escape;
        if (forTab && typeof tabItem?.handleKeyEvent === "function" && tabItem.handleKeyEvent(event) === true)
            return true;
        const direction = arrowDirection(event);
        if (direction !== "" && contentFocused)
            return !tabItem?.blocksTabNavigation && tabItem?.moveCardFocus?.(direction) === true;
        const entry = contentEntryFor(event.key);
        if (entry !== "" && !contentFocused) {
            enterContent(entry === "backwards");
            return true;
        }
        if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
            if (!editMode)
                return false;
            focusHeader(event.key === Qt.Key_Backtab || !!(event.modifiers & Qt.ShiftModifier));
            return true;
        }
        if (event.key !== Qt.Key_Escape)
            return false;
        if (editMode)
            editModeRequested(false);
        else
            closeRequested();
        return true;
    }

    // The tab row takes Tab itself to move its highlight.
    Shortcut {
        sequence: "Tab"
        enabled: root.browsing && !root.headerFocused
        context: Qt.WindowShortcut
        onActivated: root.walkContent(false)
    }

    Shortcut {
        sequence: "Shift+Tab"
        enabled: root.browsing && !root.headerFocused
        context: Qt.WindowShortcut
        onActivated: root.walkContent(true)
    }

    Shortcut {
        sequences: ["Ctrl+Tab", "Ctrl+Shift+Tab"]
        enabled: root.browsing
        context: Qt.WindowShortcut
        onActivated: root.toggleRegion()
    }

    Shortcut {
        sequence: "Ctrl+PgDown"
        enabled: root.idle
        context: Qt.WindowShortcut
        onActivated: root.tabCycleRequested(1)
    }

    Shortcut {
        sequence: "Ctrl+PgUp"
        enabled: root.idle
        context: Qt.WindowShortcut
        onActivated: root.tabCycleRequested(-1)
    }

    Shortcut {
        sequences: ["F2", "Ctrl+E"]
        enabled: root.browsing && root.editable
        context: Qt.WindowShortcut
        onActivated: root.editModeRequested(true)
    }

    Shortcut {
        sequence: "F6"
        enabled: root.browsing
        context: Qt.WindowShortcut
        onActivated: root.cycleRegion(false)
    }

    Shortcut {
        sequence: "Shift+F6"
        enabled: root.browsing
        context: Qt.WindowShortcut
        onActivated: root.cycleRegion(true)
    }

    Shortcut {
        sequence: "Alt+Tab"
        enabled: root.browsing
        context: Qt.WindowShortcut
        onActivated: root.tabItem?.cycleCardFocus?.(false)
    }

    Shortcut {
        sequence: "Alt+Shift+Tab"
        enabled: root.browsing
        context: Qt.WindowShortcut
        onActivated: root.tabItem?.cycleCardFocus?.(true)
    }

    Shortcut {
        sequences: ["Alt+Left", "Alt+H"]
        enabled: root.browsing
        context: Qt.WindowShortcut
        onActivated: root.moveCard("left")
    }

    Shortcut {
        sequences: ["Alt+Right", "Alt+L"]
        enabled: root.browsing
        context: Qt.WindowShortcut
        onActivated: root.moveCard("right")
    }

    Shortcut {
        sequences: ["Alt+Up", "Alt+K"]
        enabled: root.browsing
        context: Qt.WindowShortcut
        onActivated: root.moveCard("up")
    }

    Shortcut {
        sequences: ["Alt+Down", "Alt+J"]
        enabled: root.browsing
        context: Qt.WindowShortcut
        onActivated: root.moveCard("down")
    }
}
