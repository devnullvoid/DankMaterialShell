import QtQuick
import qs.Common
import qs.Services
import qs.Widgets

Item {
    id: root

    property bool live: Window.window?.visible ?? false
    property var options: ({})
    property real avatarSize: Theme.buttonHeightM
    property bool narrow: false
    property bool tall: false
    property color contentColor: Theme.surfaceText
    property color mutedColor: Theme.surfaceVariantText
    property color badgeColor: Theme.primaryContainer
    property color badgeContentColor: Theme.onPrimaryContainer
    property color ringColor: Theme.avatarRingColor

    readonly property real avatarDiameter: Math.min(avatarSize, width, height)
    readonly property real badgeSize: Math.round(Math.max(Theme.iconSizeSmall + Theme.spacingXS, avatarDiameter / 3))
    readonly property real badgeOverhang: 0.15
    readonly property real badgeIconRatio: 0.6
    readonly property bool showHostname: options.hostname !== false && UserInfoService.hostname !== ""
    readonly property bool showCompositor: options.compositor !== false && compositorName !== ""
    readonly property bool showUptime: options.uptime !== false
    readonly property bool showBadge: options.badge !== false
    readonly property string compositorName: CompositorService.displayName
    readonly property string uptimeText: {
        const prefix = I18n.tr("up", "uptime prefix, e.g. 'up 4h 2m'");
        return DgopService.shortUptime ? prefix + DgopService.shortUptime.slice(2) : prefix;
    }
    readonly property string avatarSource: {
        if (PortalService.profileImage === "")
            return "";
        if (PortalService.profileImage.startsWith("/"))
            return "file://" + PortalService.profileImage;
        return PortalService.profileImage;
    }

    LayoutMirroring.enabled: I18n.isRtl
    LayoutMirroring.childrenInherit: true

    Ref {
        service: DgopService
        modules: ["system"]
        active: root.live && root.showUptime
    }

    Item {
        id: avatarBox

        x: root.narrow ? (parent.width - width) / 2 : 0
        anchors.verticalCenter: parent.verticalCenter
        width: root.avatarDiameter
        height: root.avatarDiameter

        DankCircularImage {
            anchors.fill: parent
            imageSource: root.avatarSource
            fallbackIcon: "material:person"
            ringWidth: Theme.avatarRingWidth
            ringColor: root.ringColor
        }

        Rectangle {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.rightMargin: -root.badgeSize * root.badgeOverhang
            anchors.bottomMargin: -root.badgeSize * root.badgeOverhang
            width: root.badgeSize
            height: root.badgeSize
            radius: Theme.fullRadius(width, height)
            color: root.badgeColor
            border.width: Theme.avatarRingWidth
            border.color: root.ringColor
            visible: root.showBadge

            SystemLogo {
                anchors.centerIn: parent
                width: Math.round(parent.width * root.badgeIconRatio)
                height: width
                colorOverride: String(root.badgeContentColor)
            }
        }
    }

    Column {
        anchors.left: avatarBox.right
        anchors.leftMargin: Theme.spacingM
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        visible: !root.narrow

        StyledText {
            width: parent.width
            text: root.showHostname ? UserInfoService.username + " @ " + UserInfoService.hostname : UserInfoService.username
            font.pixelSize: root.tall ? Theme.fontSizeXLarge : Theme.fontSizeLarge
            font.weight: Theme.fontWeightMedium
            color: root.contentColor
            elide: Text.ElideRight
        }

        // Tall cards have room for a second line, so uptime wraps there and elides everywhere else.
        Flow {
            width: parent.width
            spacing: Theme.spacingS

            Row {
                id: compositorDetails
                spacing: Theme.spacingXS
                visible: root.showCompositor

                DankIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    name: "select_window"
                    size: Theme.iconSizeSmall
                    color: root.mutedColor
                }

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.compositorName
                    font.pixelSize: Theme.fontSizeSmall
                    color: root.mutedColor
                }
            }

            Row {
                readonly property real remaining: parent.width - (compositorDetails.visible ? compositorDetails.width + parent.spacing : 0)

                width: root.tall ? Math.min(implicitWidth, parent.width) : remaining
                spacing: Theme.spacingXS
                visible: root.showUptime && DgopService.shortUptime !== ""

                DankIcon {
                    id: uptimeIcon
                    anchors.verticalCenter: parent.verticalCenter
                    name: "schedule"
                    size: Theme.iconSizeSmall
                    color: root.mutedColor
                }

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    width: root.tall ? implicitWidth : Math.max(0, parent.width - uptimeIcon.width - parent.spacing)
                    text: root.uptimeText
                    font.pixelSize: Theme.fontSizeSmall
                    color: root.mutedColor
                    wrapMode: Text.NoWrap
                    elide: Text.ElideRight
                }
            }
        }
    }
}
