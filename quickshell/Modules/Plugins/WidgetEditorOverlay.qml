pragma ComponentBehavior: Bound

import QtQuick
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.ControlCenter.Widgets
import qs.Modules.DankDash.Overview
import qs.Modules.Settings.DesktopWidgetSettings
import qs.Modules.Settings.Widgets

FocusScope {
    id: root

    required property WidgetEditLayer editLayer
    readonly property bool lockScreen: editLayer.lockScreen
    property bool libraryOpen: false
    readonly property real fabReserved: fabBar.reservedHeight
    readonly property var libraryWidgets: DesktopWidgetRegistry.registeredWidgetsList.filter(widget => {
        if (!lockScreen)
            return !widget.lockOnly;
        return widget.id !== "lockAuth" || !SettingsData.lockWidgetInstance("lockAuth");
    }).map(widget => ({
                id: widget.id,
                text: widget.name,
                icon: widget.icon,
                description: widget.description
            }))

    signal finished

    function closeLibrary() {
        libraryOpen = false;
        forceActiveFocus();
    }

    function showOptions(instanceData) {
        optionsSheet.instanceId = instanceData?.id ?? "";
        optionsSheet.opened = true;
    }

    function addWidget(widgetType) {
        const def = DesktopWidgetRegistry.getWidget(widgetType);
        const instance = SettingsData.createDesktopWidgetInstance(widgetType, def?.name ?? widgetType, DesktopWidgetRegistry.getDefaultConfig(widgetType), editLayer.listKey);
        editLayer.pendingIds = editLayer.pendingIds.concat([instance.id]);
    }

    function resetLayout() {
        if (lockScreen) {
            SettingsData.resetLockScreenWidgets();
            return;
        }
        for (const instance of SettingsData.desktopWidgetInstances || [])
            SessionData.resetDesktopWidgetInstanceGeometry(instance.id, ["x", "y", "width", "height"]);
    }

    function dismiss() {
        if (editControls.pendingAction !== "") {
            editControls.cancelConfirmation();
            return;
        }
        if (libraryOpen) {
            closeLibrary();
            return;
        }
        finished();
    }

    focus: true
    Component.onCompleted: forceActiveFocus()
    Keys.onEscapePressed: dismiss()

    MouseArea {
        anchors.fill: parent
        visible: root.libraryOpen
        acceptedButtons: Qt.AllButtons
        onClicked: root.closeLibrary()
    }

    Loader {
        anchors.centerIn: parent
        active: root.libraryOpen

        sourceComponent: CcWidgetLibrary {
            width: Math.min(implicitWidth, root.width - Theme.spacingL * 2)
            height: Math.min(implicitHeight, root.height - Theme.spacingL * 2)
            widgets: root.libraryWidgets
            Component.onCompleted: reset()
            onChosen: widgetId => {
                root.addWidget(widgetId);
                root.closeLibrary();
            }
            onDismissed: root.closeLibrary()
        }
    }

    DankBottomSheet {
        id: optionsSheet

        property string instanceId: ""
        readonly property var instanceData: SettingsData.getDesktopWidgetInstance(instanceId)
        readonly property var widgetDef: DesktopWidgetRegistry.getWidget(instanceData?.widgetType ?? "")

        maximumWidth: Math.min(Theme.mediumBreakpoint, root.width - Theme.spacingXL * 2)
        topMargin: root.height * 0.3
        returnFocusItem: root
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
        visible: fabBar.shown && (root.editLayer.selectedInstanceId !== "" || root.editLayer.interactingItem !== null)
        gridEnabled: root.editLayer.gridEnabled
        gridSize: root.editLayer.gridSize
    }

    SettingsFabBar {
        id: fabBar
        shown: !root.libraryOpen && !optionsSheet.active

        DashEditControls {
            id: editControls
            canClear: false
            onAddRequested: root.libraryOpen = true
            onResetRequested: root.resetLayout()
            onFinished: root.finished()
        }
    }
}
