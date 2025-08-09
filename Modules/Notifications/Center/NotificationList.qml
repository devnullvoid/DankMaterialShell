import QtQuick
import QtQuick.Controls
import qs.Common
import qs.Services
import qs.Widgets

DankListView {
  id: root

  property alias count: root.count
  property alias listContentHeight: root.contentHeight

  width: parent.width
  height: parent.height
  clip: true
  model: NotificationService.groupedNotifications
  spacing: Theme.spacingL

  NotificationEmptyState {
    visible: root.count === 0
    anchors.centerIn: parent
  }

  delegate: NotificationCard {
    notificationGroup: modelData
  }
}
