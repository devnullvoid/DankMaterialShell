import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.Common
import qs.Services
import qs.Widgets

PanelWindow {
  id: root

  property bool notificationHistoryVisible: false
  property real triggerX: Screen.width - 400 - Theme.spacingL
  property real triggerY: Theme.barHeight + Theme.spacingXS
  property real triggerWidth: 40
  property string triggerSection: "right"

  function setTriggerPosition(x, y, width, section) {
    triggerX = x
    triggerY = y
    triggerWidth = width
    triggerSection = section
  }

  visible: notificationHistoryVisible
  onNotificationHistoryVisibleChanged: {
    NotificationService.disablePopups(notificationHistoryVisible)
  }
  implicitWidth: 400
  implicitHeight: Math.min(Screen.height * 0.8, 400)
  WlrLayershell.layer: WlrLayershell.Overlay
  WlrLayershell.exclusiveZone: -1
  WlrLayershell.keyboardFocus: notificationHistoryVisible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
  color: "transparent"

  anchors {
    top: true
    left: true
    right: true
    bottom: true
  }

  MouseArea {
    anchors.fill: parent
    onClicked: {
      notificationHistoryVisible = false
    }
  }

  Rectangle {
    id: mainRect

    function calculateHeight() {
      let baseHeight = Theme.spacingL * 2
      baseHeight += notificationHeader.height
      baseHeight += Theme.spacingM
      let listHeight = notificationList.listContentHeight
      if (NotificationService.groupedNotifications.length === 0)
        listHeight = 200

      baseHeight += Math.min(listHeight, 600)
      return Math.max(300, baseHeight)
    }

    readonly property real popupWidth: 400
    readonly property real calculatedX: {
      var centerX = root.triggerX + (root.triggerWidth / 2) - (popupWidth / 2)

      if (centerX >= Theme.spacingM
          && centerX + popupWidth <= Screen.width - Theme.spacingM) {
        return centerX
      }

      if (centerX < Theme.spacingM) {
        return Theme.spacingM
      }

      if (centerX + popupWidth > Screen.width - Theme.spacingM) {
        return Screen.width - popupWidth - Theme.spacingM
      }

      return centerX
    }

    width: popupWidth
    height: calculateHeight()
    x: calculatedX
    y: root.triggerY
    color: Theme.popupBackground()
    radius: Theme.cornerRadius
    border.color: Qt.rgba(Theme.outline.r, Theme.outline.g,
                          Theme.outline.b, 0.08)
    border.width: 1
    opacity: notificationHistoryVisible ? 1 : 0
    scale: notificationHistoryVisible ? 1 : 0.9

    MouseArea {
      anchors.fill: parent
      onClicked: {

      }
    }

    Column {
      id: contentColumn

      anchors.fill: parent
      anchors.margins: Theme.spacingL
      spacing: Theme.spacingM
      focus: true
      Component.onCompleted: {
        if (notificationHistoryVisible)
          forceActiveFocus()
      }
      Keys.onPressed: function (event) {
        if (event.key === Qt.Key_Escape) {
          notificationHistoryVisible = false
          event.accepted = true
        }
      }

      Connections {
        function onNotificationHistoryVisibleChanged() {
          if (notificationHistoryVisible)
            Qt.callLater(function () {
              contentColumn.forceActiveFocus()
            })
          else
            contentColumn.focus = false
        }
        target: root
      }

      NotificationHeader {
        id: notificationHeader
      }

      NotificationList {
        id: notificationList

        width: parent.width
        height: parent.height - notificationHeader.height - contentColumn.spacing
      }
    }

    Connections {
      function onNotificationsChanged() {
        mainRect.height = mainRect.calculateHeight()
      }

      function onGroupedNotificationsChanged() {
        mainRect.height = mainRect.calculateHeight()
      }

      function onExpandedGroupsChanged() {
        mainRect.height = mainRect.calculateHeight()
      }

      function onExpandedMessagesChanged() {
        mainRect.height = mainRect.calculateHeight()
      }

      target: NotificationService
    }

    Behavior on height {
      NumberAnimation {
        duration: Theme.mediumDuration
        easing.type: Theme.emphasizedEasing
      }
    }

    Behavior on opacity {
      NumberAnimation {
        duration: Anims.durMed
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Anims.emphasized
      }
    }

    Behavior on scale {
      NumberAnimation {
        duration: Anims.durMed
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Anims.emphasized
      }
    }
  }
}
