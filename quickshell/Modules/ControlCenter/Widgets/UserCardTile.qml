import QtQuick
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.ControlCenter
import qs.Modules.DankDash

CcCardTile {
    id: root

    // Keys and defaults come from the dashboard user card so both surfaces expose the same toggles.
    readonly property var options: DashRegistry.resolvedOptions("user", widgetData)
    readonly property bool tapToClose: interactive && (host?.tapToClose ?? false)

    Accessible.role: tapToClose ? Accessible.Button : Accessible.Pane
    Accessible.name: UserInfoService.username

    UserIdentity {
        anchors.fill: parent
        anchors.margins: root.pad
        anchors.leftMargin: root.narrow ? root.pad : root.pad + Theme.spacingXS
        live: root.live
        options: root.options
        narrow: root.width < CcMetrics.columnWidth * 2
        tall: root.tall
        avatarSize: root.tall ? DashMetrics.avatarSizeHero : DashMetrics.avatarSize
        contentColor: CcMetrics.tileInactiveContent
        mutedColor: CcMetrics.tileInactiveSubtitle
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.tapToClose
        acceptedButtons: Qt.LeftButton
        onClicked: root.host?.headerTapped()
    }
}
