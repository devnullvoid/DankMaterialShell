pragma ComponentBehavior: Bound

import QtQuick
import qs.Common
import qs.Modules.ControlCenter
import qs.Modules.DankDash
import qs.Services
import qs.Widgets
import "../utils/widgets.js" as WidgetUtils

Item {
    id: root

    LayoutMirroring.enabled: I18n.isRtl
    LayoutMirroring.childrenInherit: true

    property var widgetData: ({})
    property var widgetDef: null
    property var host: null
    property bool live: true
    property bool interactive: true
    property real columns: 4
    property real rows: 1
    property bool compact: false

    // The slot and its chrome keep drag and resize input away from this region so the buttons stay clickable in edit mode.
    readonly property Item passthrough: actionRow
    readonly property bool editMode: host?.editMode ?? false
    readonly property bool tapToClose: interactive && (host?.tapToClose ?? false)
    readonly property bool tall: height >= CcMetrics.gridRowUnit * 2
    readonly property real avatarSize: tall ? DashMetrics.avatarSizeHero : CcMetrics.headerAvatarSize
    readonly property real identityWidth: width - pad * 2 - actionRow.width - CcMetrics.tileTextGap
    readonly property bool showUser: WidgetUtils.headerShowsUser(widgetData) && identityWidth >= avatarSize
    readonly property var userOptions: DashRegistry.resolvedOptions("user", widgetData)
    readonly property var actions: WidgetUtils.enabledQuickActions(widgetData)
    readonly property bool background: WidgetUtils.headerHasBackground(widgetData)
    readonly property bool powerAccent: widgetData?.powerAccent === true
    readonly property real pad: background ? Theme.spacingS : 0
    readonly property real bodyRadius: tall ? Math.min(CcMetrics.tallTileRadius, width / 2, height / 2) : Theme.fullRadius(width, height)

    width: parent?.width ?? 0
    height: CcMetrics.tileHeight
    Accessible.role: tapToClose ? Accessible.Button : Accessible.Pane
    Accessible.name: UserInfoService.username

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

    Rectangle {
        anchors.fill: parent
        radius: root.bodyRadius
        color: CcMetrics.tileInactiveColor
        border.width: Theme.layerOutlineWidth
        border.color: Theme.outlineMedium
        visible: root.background
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.tapToClose
        acceptedButtons: Qt.LeftButton
        onClicked: root.host?.headerTapped()
    }

    UserIdentity {
        anchors.left: parent.left
        anchors.leftMargin: root.pad - CcMetrics.avatarFrameInset
        anchors.right: actionRow.left
        anchors.rightMargin: CcMetrics.tileTextGap
        anchors.verticalCenter: parent.verticalCenter
        height: parent.height
        visible: root.showUser
        live: root.live && root.showUser
        options: root.userOptions
        narrow: root.identityWidth < root.avatarSize + Theme.spacingM + Theme.buttonHeightM
        tall: root.tall
        avatarSize: root.avatarSize
        textGap: CcMetrics.tileTextGap - CcMetrics.avatarFrameInset
        contentColor: CcMetrics.tileInactiveContent
        mutedColor: CcMetrics.tileInactiveSubtitle
    }

    Row {
        id: actionRow

        anchors.right: parent.right
        anchors.rightMargin: root.pad
        anchors.verticalCenter: parent.verticalCenter
        spacing: CcMetrics.actionGap

        Repeater {
            model: root.actions

            DankActionButton {
                required property var modelData
                readonly property string actionId: modelData.id
                readonly property bool destructive: root.powerAccent && actionId === "power"
                readonly property bool active: actionId === "edit" && root.editMode

                buttonSize: CcMetrics.actionSize
                iconSize: CcMetrics.actionIconSize
                iconName: WidgetUtils.quickActionIcon(actionId)
                iconColor: active ? Theme.primaryText : destructive ? Theme.error : Theme.surfaceText
                backgroundColor: active ? Theme.primary : "transparent"
                Accessible.name: I18n.tr(WidgetUtils.quickActionLabel(actionId))
                onClicked: root.trigger(actionId)
            }
        }
    }
}
