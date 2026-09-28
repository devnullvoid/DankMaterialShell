pragma ComponentBehavior: Bound

import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.ControlCenter
import "../utils/widgets.js" as WidgetUtils

CcCardTile {
    id: root

    readonly property bool editMode: host?.editMode ?? false
    readonly property var actions: WidgetUtils.quickActions(widgetData).filter(action => action.enabled)
    readonly property string role: WidgetUtils.quickActionRole(widgetData)
    readonly property bool filled: widgetData?.background === true
    readonly property bool powerAccent: widgetData?.powerAccent === true
    readonly property color roleBg: role === "default" ? Theme.secondaryContainer : Theme.roleColor(role)
    readonly property color roleFg: {
        switch (role) {
        case "primary":
            return Theme.primaryText;
        case "primaryContainer":
            return Theme.onPrimaryContainer;
        case "secondary":
        case "surfaceVariant":
            return Theme.surfaceText;
        case "surfaceText":
            return Theme.surface;
        }
        return Theme.onSecondaryContainer;
    }
    // Without a pill the icon carries the role itself, so container roles fall back to their accent.
    readonly property color roleIcon: {
        switch (role) {
        case "primary":
        case "primaryContainer":
            return Theme.primary;
        case "secondary":
            return Theme.secondary;
        }
        return Theme.surfaceText;
    }
    // The edit toggle lights up in primary, so a primary role needs a different active colour.
    readonly property color activeBg: role === "primary" ? Theme.primaryContainer : Theme.primary
    readonly property color activeFg: role === "primary" ? Theme.onPrimaryContainer : Theme.primaryText

    function trigger(id) {
        switch (id) {
        case "lock":
            host?.lockRequested();
            return;
        case "power":
            host?.powerRequested();
            return;
        case "settings":
            host?.settingsRequested();
            return;
        case "edit":
            host?.editRequested();
            return;
        }
    }

    Row {
        anchors.centerIn: parent
        spacing: CcMetrics.actionGap

        Repeater {
            model: root.actions

            DankActionButton {
                required property var modelData
                readonly property string actionId: modelData.id
                readonly property bool destructive: root.powerAccent && actionId === "power"
                readonly property bool active: actionId === "edit" && root.editMode
                readonly property color bg: active ? root.activeBg : destructive ? Theme.errorContainer : root.roleBg
                readonly property color fg: active ? root.activeFg : destructive ? Theme.onErrorContainer : root.roleFg

                buttonSize: CcMetrics.actionSize
                iconSize: CcMetrics.actionIconSize
                iconName: WidgetUtils.quickActionIcon(actionId)
                iconColor: root.filled || active ? fg : destructive ? Theme.error : root.roleIcon
                backgroundColor: root.filled || active ? bg : "transparent"
                Accessible.name: I18n.tr(WidgetUtils.quickActionLabel(actionId))
                onClicked: root.trigger(actionId)
            }
        }
    }
}
