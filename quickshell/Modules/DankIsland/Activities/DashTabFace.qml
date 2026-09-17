pragma ComponentBehavior: Bound

import QtQuick
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.DankDash
import qs.Modules.DankDash.Overview

FocusScope {
    id: root

    required property var controller
    required property string activityId
    required property Component tabComponent
    property string entryId: activityId
    property bool editMode: false
    property bool contentStaged: false
    readonly property bool live: root.controller.expanded && root.controller.activeActivity === root.activityId
    readonly property var tab: tabLoader.item
    readonly property real tabHeight: tab?.implicitHeight ?? 0
    readonly property real contentHeight: DashMetrics.panelHeightFor(entryId, tabHeight)
    readonly property real chromeHeight: header.height + Theme.spacingXS * 2 + DashMetrics.contentPadding

    clip: true
    LayoutMirroring.enabled: I18n.isRtl
    LayoutMirroring.childrenInherit: true
    KeyNavigation.tab: root.tab?.focusTarget ?? null

    function focusFace() {
        (root.tab?.focusTarget ?? root).forceActiveFocus();
        return true;
    }

    function focusHeader(backwards) {
        const targets = root.editMode ? editControls.focusTargets : [menuButton];
        targets[backwards ? targets.length - 1 : 0].forceActiveFocus();
    }

    function reportHeight() {
        root.controller.setDashboardContentHeight(root.activityId, root.contentHeight + root.chromeHeight);
    }

    onContentHeightChanged: reportHeight()
    onChromeHeightChanged: reportHeight()
    onLiveChanged: {
        if (live)
            return;
        editMode = false;
        headerMenu.close();
        tabOptions.dismiss();
    }
    onEditModeChanged: {
        if (!editMode)
            return;
        Qt.callLater(() => {
            if (root.live && root.editMode)
                root.focusHeader(false);
        });
    }

    Keys.onPressed: event => {
        if (root.tab?.handleKeyEvent?.(event) === true) {
            event.accepted = true;
            return;
        }
        if (event.key !== Qt.Key_Escape || !root.editMode)
            return;
        root.editMode = false;
        root.focusFace();
        event.accepted = true;
    }

    Item {
        id: header
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            topMargin: Theme.spacingXS
            leftMargin: DashMetrics.contentPadding
            rightMargin: DashMetrics.contentPadding
        }
        height: root.editMode ? editControls.height : Theme.buttonHeightXS

        DankActionButton {
            id: menuButton
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            buttonSize: Theme.buttonHeightXS
            iconName: "more_vert"
            Accessible.name: I18n.tr("Options")
            visible: !root.editMode
            KeyNavigation.tab: root.tab?.focusTarget ?? null
            KeyNavigation.backtab: root.tab?.previousFocusTarget ?? root.tab?.focusTarget ?? null
            onClicked: headerMenu.openAt(menuButton)
        }

        DashEditControls {
            id: editControls
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            visible: root.editMode
            canAdd: (root.tab?.addable?.length ?? 0) > 0
            onAddRequested: anchor => root.tab?.openAddMenu(anchor)
            onMenuRequested: anchor => headerMenu.openAt(anchor)
            onFinished: {
                root.editMode = false;
                root.focusFace();
            }
        }
    }

    DankFlickable {
        id: pages
        anchors {
            top: header.bottom
            topMargin: Theme.spacingXS
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            leftMargin: DashMetrics.contentPadding
            rightMargin: DashMetrics.contentPadding
            bottomMargin: DashMetrics.contentPadding
        }
        contentHeight: tabLoader.height
        clip: contentHeight > height

        Loader {
            id: tabLoader
            width: pages.width
            height: Math.max(pages.height, root.tabHeight)
            active: root.contentStaged
            asynchronous: true
            visible: status === Loader.Ready
            sourceComponent: root.tabComponent
            onLoaded: {
                root.reportHeight();
                if (root.live)
                    root.focusFace();
            }
        }
    }

    Connections {
        target: root.tab
        ignoreUnknownSignals: true
        function onNavFocusRequested(backwards) {
            root.focusHeader(backwards);
        }
    }

    DankSpinner {
        anchors.centerIn: pages
        size: DashMetrics.spinnerSize
        visible: !tabLoader.visible
    }

    DashOptionsSheet {
        id: tabOptions
        onDismissed: root.focusFace()
    }

    DashPageMenu {
        id: headerMenu
        entryId: root.entryId
        tabItem: root.tab
        editMode: root.editMode
        onEditRequested: root.editMode = true
        onOptionsRequested: tabOptions.presentFor(root.entryId)
        onSettingsRequested: {
            root.controller.requestCollapse();
            PopoutService.openSettingsWithTab("dank_dash");
        }
    }

    Component.onCompleted: {
        root.contentStaged = true;
        root.reportHeight();
    }
}
