pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Window
import qs.Common
import qs.Modals
import qs.Modules.ControlCenter.Widgets
import qs.Modules.DankDash.Overview
import qs.Modules.Plugins
import qs.Modules.Settings.DesktopWidgetSettings
import qs.Modules.Settings.Widgets
import qs.Services
import qs.Widgets
import qs.DankCommon.Session

FocusScope {
    id: root
    readonly property var log: Log.scoped("LockScreenContent")

    property string passwordBuffer: ""
    property bool inputRevealed: false
    signal inputRevealRequested(bool revealed)

    function setInputRevealed(revealed) {
        inputRevealRequested(revealed);
    }
    property bool demoMode: false
    property var pam: demoPam
    property string screenName: ""
    property bool unlocking: false
    property string pamState: ""
    property bool lockerReadySent: false
    property bool lockerReadyArmed: false
    property var sessionLock: null
    property Item authWidget: null
    readonly property Item backgroundItem: background
    readonly property bool backgroundReady: background.ready
    readonly property string backgroundKey: background.renderKey

    signal unlockRequested
    signal passwordEdited(string text)
    signal authFailed

    function resetLockState() {
        widgetLayer.refreshPlacement();
        lockerReadySent = false;
        lockerReadyArmed = true;
        unlocking = false;
        pamState = "";
        if (pam)
            pam.lockMessage = "";
    }

    function focusPasswordField() {
        if (demoMode)
            return;
        authWidget?.focusPasswordField();
    }

    function showPowerMenu() {
        if (demoMode)
            return;
        powerMenu.show();
    }

    function contentColor(mode, custom) {
        switch (mode) {
        case "primary":
            return Theme.primary;
        case "secondary":
            return Theme.secondary;
        case "custom":
            return custom;
        }
        return Theme.lockScreenContentColor;
    }

    function addLockWidget(widgetType) {
        const def = DesktopWidgetRegistry.getWidget(widgetType);
        const instance = SettingsData.createDesktopWidgetInstance(widgetType, def?.name ?? widgetType, DesktopWidgetRegistry.getDefaultConfig(widgetType), "lockScreenWidgetInstances");
        widgetLayer.pendingIds = widgetLayer.pendingIds.concat([instance.id]);
    }

    Component.onCompleted: {
        WeatherService.addRef();
        UserInfoService.getUserInfo();

        lockerReadyArmed = true;
    }

    Component.onDestruction: {
        WeatherService.removeRef();
    }

    function sendLockerReadyOnce() {
        if (root.demoMode)
            return;
        if (lockerReadySent)
            return;
        if (root.unlocking)
            return;
        lockerReadySent = true;
        if (SessionService.loginctlAvailable && DMSService.apiVersion >= 2) {
            DMSService.sendRequest("loginctl.lockerReady", null, resp => {
                if (resp?.error)
                    log.warn("lockerReady failed:", resp.error);
                else
                    log.debug("lockerReady sent (afterAnimating/afterRendering)");
            });
        }
    }

    function maybeSend() {
        if (!lockerReadyArmed)
            return;
        if (root.unlocking)
            return;
        if (!root.visible || root.opacity <= 0)
            return;
        if (root.sessionLock && !root.sessionLock.secure)
            return;
        Qt.callLater(() => {
            if (root.visible && root.opacity > 0 && !root.unlocking)
                sendLockerReadyOnce();
        });
    }

    Connections {
        target: root.sessionLock
        enabled: target !== null
        function onSecureChanged() {
            root.maybeSend();
        }
    }

    Connections {
        target: root.Window.window
        enabled: target !== null

        function onAfterAnimating() {
            maybeSend();
        }
        function onAfterRendering() {
            maybeSend();
        }
    }

    onVisibleChanged: maybeSend()
    onOpacityChanged: maybeSend()

    LockScreenBackground {
        id: background
        anchors.fill: parent
        screenName: root.screenName
    }

    // Grid keys live here because a selected widget holds active focus inside the layer, not the editor.
    Keys.onPressed: event => {
        if (!demoMode)
            return;
        switch (event.key) {
        case Qt.Key_G:
            widgetLayer.toggleGrid();
            break;
        case Qt.Key_Z:
            widgetLayer.stepGrid(-10);
            break;
        case Qt.Key_X:
            widgetLayer.stepGrid(10);
            break;
        default:
            return;
        }
        event.accepted = true;
    }

    LockWidgetLayer {
        id: widgetLayer
        anchors.fill: parent
        focus: true
        screenName: root.screenName
        lockHost: root
        editMode: root.demoMode
        bottomInset: editorLoader.item?.fabReserved ?? 0
        onFocusStolen: root.focusPasswordField()
        onOptionsRequested: instanceData => editorLoader.item?.showOptions(instanceData)
    }

    Pam {
        id: demoPam
        lockSecured: false
    }

    Connections {
        target: root.pam

        function onUnlockRequested() {
            root.unlocking = true;
            lockerReadyArmed = false;
            root.passwordEdited("");
            root.unlockRequested();
        }

        function onStateChanged() {
            root.pamState = root.pam.state;
            if (root.pam.state === "")
                return;
            root.unlocking = false;
            root.authFailed();
            placeholderDelay.restart();
            root.passwordEdited("");
        }

        function onUnlockInProgressChanged() {
            if (!root.pam.unlockInProgress && root.unlocking)
                root.unlocking = false;
        }
    }

    Timer {
        id: placeholderDelay

        interval: 4000
        onTriggered: root.pamState = ""
    }

    Loader {
        id: editorLoader
        anchors.fill: parent
        active: root.demoMode

        sourceComponent: FocusScope {
            id: editor

            property bool libraryOpen: false
            readonly property real fabReserved: fabBar.reservedHeight

            function closeLibrary() {
                libraryOpen = false;
                forceActiveFocus();
            }

            function showOptions(instanceData) {
                optionsSheet.instanceId = instanceData?.id ?? "";
                optionsSheet.opened = true;
            }

            focus: true
            Component.onCompleted: forceActiveFocus()

            Keys.onEscapePressed: {
                if (editControls.pendingAction !== "") {
                    editControls.cancelConfirmation();
                    return;
                }
                if (libraryOpen) {
                    closeLibrary();
                    return;
                }
                root.unlockRequested();
            }

            MouseArea {
                anchors.fill: parent
                visible: editor.libraryOpen
                acceptedButtons: Qt.AllButtons
                onClicked: editor.closeLibrary()
            }

            Loader {
                anchors.centerIn: parent
                active: editor.libraryOpen

                sourceComponent: CcWidgetLibrary {
                    width: Math.min(implicitWidth, editor.width - Theme.spacingL * 2)
                    height: Math.min(implicitHeight, editor.height - Theme.spacingL * 2)
                    widgets: DesktopWidgetRegistry.registeredWidgetsList.filter(widget => widget.id !== "lockAuth" || !SettingsData.lockWidgetInstance("lockAuth")).map(widget => ({
                                id: widget.id,
                                text: widget.name,
                                icon: widget.icon,
                                description: widget.description
                            }))
                    Component.onCompleted: reset()
                    onChosen: widgetId => {
                        root.addLockWidget(widgetId);
                        editor.closeLibrary();
                    }
                    onDismissed: editor.closeLibrary()
                }
            }

            DankBottomSheet {
                id: optionsSheet

                property string instanceId: ""
                readonly property var instanceData: SettingsData.getDesktopWidgetInstance(instanceId)
                readonly property var widgetDef: DesktopWidgetRegistry.getWidget(instanceData?.widgetType ?? "")

                maximumWidth: Math.min(Theme.mediumBreakpoint, editor.width - Theme.spacingXL * 2)
                topMargin: editor.height * 0.3
                returnFocusItem: editor
                title: instanceData?.name || widgetDef?.name || ""
                onDismissRequested: opened = false
                onActiveChanged: {
                    if (!active)
                        instanceId = "";
                }

                DesktopWidgetTypeSettings {
                    width: parent.width
                    instanceId: optionsSheet.instanceId
                    instanceData: optionsSheet.instanceData
                    widgetDef: optionsSheet.widgetDef
                }
            }

            DesktopWidgetGridHint {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: fabBar.reservedHeight + Theme.spacingL
                visible: fabBar.shown && (widgetLayer.selectedInstanceId !== "" || widgetLayer.interactingItem !== null)
                gridEnabled: widgetLayer.gridEnabled
                gridSize: widgetLayer.gridSize
            }

            SettingsFabBar {
                id: fabBar
                shown: !editor.libraryOpen && !optionsSheet.active

                DashEditControls {
                    id: editControls
                    canClear: false
                    onAddRequested: editor.libraryOpen = true
                    onResetRequested: SettingsData.resetLockScreenWidgets()
                    onFinished: root.unlockRequested()
                }
            }
        }
    }

    LockPowerMenu {
        id: powerMenu
        expressive: true
        showLogout: true
        onClosed: {
            if (!demoMode)
                Qt.callLater(() => root.focusPasswordField());
        }
        onSwitchUserRequested: {
            switchUserPicker.showFromLockScreen();
        }
    }

    SwitchUserModal {
        id: switchUserPicker
    }
}
