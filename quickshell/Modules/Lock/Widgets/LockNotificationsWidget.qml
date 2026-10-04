pragma ComponentBehavior: Bound

import QtQuick
import qs.Common
import qs.Modules.Notifications as Notifications
import qs.Services
import qs.Widgets
import qs.DankCommon.Session

Item {
    id: root

    property var instanceData: null
    property var lockHost: null
    readonly property var cfg: instanceData?.config ?? ({})
    readonly property int notificationMode: cfg.mode ?? 1
    readonly property bool resizable: true
    readonly property real minWidth: Theme.listItemTwoLineHeight * 2
    readonly property real minHeight: Theme.listItemHeight

    readonly property var notifications: NotificationService.groupedNotifications
    readonly property int totalCount: {
        let count = 0;
        for (const group of notifications)
            count += group.count || 0;
        return count;
    }
    readonly property bool hasNotifications: totalCount > 0
    readonly property var appNameGroups: {
        const groups = {};
        for (const group of notifications) {
            const appName = (group.appName || "Unknown").toLowerCase();
            if (!groups[appName]) {
                groups[appName] = {
                    appName: group.appName || I18n.tr("Unknown"),
                    count: 0,
                    latestNotification: group.latestNotification
                };
            }
            groups[appName].count += group.count || 0;
            if (group.latestNotification && (!groups[appName].latestNotification || group.latestNotification.time > groups[appName].latestNotification.time))
                groups[appName].latestNotification = group.latestNotification;
        }
        return Object.values(groups).sort((a, b) => b.count - a.count);
    }

    readonly property bool editPlaceholder: !hasNotifications && (lockHost?.demoMode ?? false)
    readonly property bool chips: notificationMode === 2 && !editPlaceholder
    readonly property var visibleGroups: appNameGroups.slice(0, LockMetrics.notificationLimit)
    readonly property int hiddenGroups: Math.max(0, appNameGroups.length - LockMetrics.notificationLimit)

    implicitWidth: chips ? contentLoader.implicitWidth : LockMetrics.notificationCardWidth
    implicitHeight: hasNotifications || editPlaceholder ? contentLoader.implicitHeight : 0
    clip: true

    Loader {
        id: contentLoader
        anchors.left: parent.left
        anchors.right: root.chips ? undefined : parent.right
        anchors.top: parent.top
        active: root.hasNotifications || root.editPlaceholder
        sourceComponent: {
            if (root.notificationMode === 1 || root.editPlaceholder)
                return countOnlyComponent;
            return root.chips ? chipRowComponent : notificationListComponent;
        }
    }

    Component {
        id: chipRowComponent

        Row {
            spacing: Theme.spacingS

            Repeater {
                model: root.visibleGroups

                Rectangle {
                    id: chip

                    required property var modelData
                    readonly property string appIcon: NotificationService.notificationAppIcon(modelData.latestNotification?.appIcon || "", modelData.latestNotification?.desktopEntry || "")

                    height: Theme.buttonHeightXS
                    width: chipRow.implicitWidth + Theme.spacingM * 2
                    radius: Theme.cornerRadiusM
                    color: Theme.notificationFloatingSurface
                    border.width: Theme.layerOutlineWidth
                    border.color: Theme.outlineVariant
                    Accessible.name: modelData.appName

                    Row {
                        id: chipRow
                        anchors.centerIn: parent
                        spacing: Theme.spacingXS

                        Item {
                            width: Theme.iconSizeSmall
                            height: width
                            anchors.verticalCenter: parent.verticalCenter

                            Image {
                                id: appImage
                                anchors.fill: parent
                                asynchronous: true
                                smooth: true
                                fillMode: Image.PreserveAspectFit
                                sourceSize: Qt.size(width * 2, height * 2)
                                source: NotificationService.notificationImageSource("", chip.appIcon)
                                visible: status === Image.Ready
                            }

                            AppIconRenderer {
                                anchors.fill: parent
                                visible: !appImage.visible
                                iconValue: NotificationService.notificationFallbackIcon("", chip.appIcon)
                                iconSize: Theme.iconSizeSmall
                                iconColor: Theme.onSurfaceVariant
                                colorOverride: "transparent"
                                fallbackText: (chip.modelData.appName || "?").charAt(0).toUpperCase()
                                fallbackRadius: Theme.fullRadius(width, height)
                                fallbackBackgroundColor: Theme.secondaryContainer
                                fallbackTextColor: Theme.onSecondaryContainer
                            }
                        }

                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: chip.modelData.appName
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Theme.fontWeightMedium
                            color: Theme.onSurface
                        }

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: chip.modelData.count > 1
                            width: Math.max(height, countText.implicitWidth + Theme.spacingXS * 2)
                            height: Theme.iconSizeSmall
                            radius: Theme.fullRadius(width, height)
                            color: Theme.primary

                            StyledText {
                                id: countText
                                anchors.centerIn: parent
                                text: chip.modelData.count
                                font.pixelSize: Theme.fontSizeSmall
                                font.weight: Theme.fontWeightMedium
                                color: Theme.onPrimary
                            }
                        }
                    }
                }
            }

            Rectangle {
                visible: root.hiddenGroups > 0
                height: Theme.buttonHeightXS
                width: moreText.implicitWidth + Theme.spacingM * 2
                radius: Theme.cornerRadiusM
                color: Theme.notificationFloatingSurface
                border.width: Theme.layerOutlineWidth
                border.color: Theme.outlineVariant

                StyledText {
                    id: moreText
                    anchors.centerIn: parent
                    text: I18n.tr("+ %1 more", "lock screen notification list overflow, %1 is a count of hidden apps").arg(root.hiddenGroups)
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Theme.fontWeightMedium
                    color: Theme.onSurfaceVariant
                }
            }
        }
    }

    Component {
        id: countOnlyComponent

        LockNotificationCard {
            implicitHeight: Theme.listItemHeight
            color: Theme.notificationFloatingSurface
            Accessible.name: countLabel.text

            Row {
                anchors.centerIn: parent
                spacing: Theme.spacingS

                DankIcon {
                    name: "notifications"
                    size: Theme.iconSize
                    color: Theme.onSurfaceVariant
                    anchors.verticalCenter: parent.verticalCenter
                }

                StyledText {
                    id: countLabel
                    text: root.editPlaceholder ? I18n.tr("Notifications") : root.totalCount === 1 ? I18n.tr("1 notification") : I18n.tr("%1 notifications").arg(root.totalCount)
                    font.pixelSize: Theme.fontSizeMedium
                    color: Theme.onSurface
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }

    Component {
        id: notificationListComponent

        DankFlickable {
            implicitHeight: Math.min(notificationColumn.implicitHeight, LockMetrics.notificationMaxHeight, Math.max(0, (root.lockHost?.height ?? 0) - (root.parent?.y ?? 0) - Theme.spacingXL))
            height: Math.min(notificationColumn.implicitHeight, root.height)
            contentHeight: notificationColumn.implicitHeight
            clip: true

            Column {
                id: notificationColumn
                width: parent.width
                spacing: Theme.groupedListGap

                Repeater {
                    id: notificationRepeater
                    model: root.appNameGroups.slice(0, LockMetrics.notificationLimit)

                    Notifications.NotificationCard {
                        required property var modelData
                        required property int index
                        width: notificationColumn.width
                        notificationData: modelData.latestNotification
                        groupCount: modelData.count
                        interactive: false
                        headerOnly: false
                        showActions: false
                        showDismiss: false
                        showClose: false
                        showTime: !headerOnly
                        animateHeight: false
                        firstInGroup: index === 0
                        lastInGroup: index === notificationRepeater.count - 1
                    }
                }

                StyledText {
                    width: parent.width
                    visible: root.appNameGroups.length > LockMetrics.notificationLimit
                    text: I18n.tr("+ %1 more", "lock screen notification list overflow, %1 is a count of hidden apps").arg(root.appNameGroups.length - LockMetrics.notificationLimit)
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.lockScreenContentColor
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }
}
