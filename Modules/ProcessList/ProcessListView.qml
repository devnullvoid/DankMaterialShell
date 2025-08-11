import QtQuick
import QtQuick.Controls
import qs.Common
import qs.Services
import qs.Widgets

Column {
  id: root

  property var contextMenu: null

  Component.onCompleted: {
    DgopService.addRef(["processes"])
  }
  Component.onDestruction: {
    DgopService.removeRef(["processes"])
  }

  Item {
    id: columnHeaders

    width: parent.width
    anchors.leftMargin: 8
    height: 24

    Rectangle {
      width: 60
      height: 20
      color: processHeaderArea.containsMouse ? Qt.rgba(Theme.surfaceText.r,
                                                       Theme.surfaceText.g,
                                                       Theme.surfaceText.b,
                                                       0.08) : "transparent"
      radius: Theme.cornerRadius
      anchors.left: parent.left
      anchors.leftMargin: 0
      anchors.verticalCenter: parent.verticalCenter

      StyledText {
        text: "Process"
        font.pixelSize: Theme.fontSizeSmall
        font.family: SettingsData.monoFontFamily
        font.weight: DgopService.sortBy === "name" ? Font.Bold : Font.Medium
        color: Theme.surfaceText
        opacity: DgopService.sortBy === "name" ? 1 : 0.7
        anchors.centerIn: parent
      }

      MouseArea {
        id: processHeaderArea

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
          DgopService.setSortBy("name")
        }
      }

      Behavior on color {
        ColorAnimation {
          duration: Theme.shortDuration
        }
      }
    }

    Rectangle {
      width: 80
      height: 20
      color: cpuHeaderArea.containsMouse ? Qt.rgba(Theme.surfaceText.r,
                                                   Theme.surfaceText.g,
                                                   Theme.surfaceText.b,
                                                   0.08) : "transparent"
      radius: Theme.cornerRadius
      anchors.right: parent.right
      anchors.rightMargin: 200
      anchors.verticalCenter: parent.verticalCenter

      StyledText {
        text: "CPU"
        font.pixelSize: Theme.fontSizeSmall
        font.family: SettingsData.monoFontFamily
        font.weight: DgopService.sortBy === "cpu" ? Font.Bold : Font.Medium
        color: Theme.surfaceText
        opacity: DgopService.sortBy === "cpu" ? 1 : 0.7
        anchors.centerIn: parent
      }

      MouseArea {
        id: cpuHeaderArea

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
          DgopService.setSortBy("cpu")
        }
      }

      Behavior on color {
        ColorAnimation {
          duration: Theme.shortDuration
        }
      }
    }

    Rectangle {
      width: 80
      height: 20
      color: memoryHeaderArea.containsMouse ? Qt.rgba(Theme.surfaceText.r,
                                                      Theme.surfaceText.g,
                                                      Theme.surfaceText.b,
                                                      0.08) : "transparent"
      radius: Theme.cornerRadius
      anchors.right: parent.right
      anchors.rightMargin: 112
      anchors.verticalCenter: parent.verticalCenter

      StyledText {
        text: "RAM"
        font.pixelSize: Theme.fontSizeSmall
        font.family: SettingsData.monoFontFamily
        font.weight: DgopService.sortBy === "memory" ? Font.Bold : Font.Medium
        color: Theme.surfaceText
        opacity: DgopService.sortBy === "memory" ? 1 : 0.7
        anchors.centerIn: parent
      }

      MouseArea {
        id: memoryHeaderArea

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
          DgopService.setSortBy("memory")
        }
      }

      Behavior on color {
        ColorAnimation {
          duration: Theme.shortDuration
        }
      }
    }

    Rectangle {
      width: 50
      height: 20
      color: pidHeaderArea.containsMouse ? Qt.rgba(Theme.surfaceText.r,
                                                   Theme.surfaceText.g,
                                                   Theme.surfaceText.b,
                                                   0.08) : "transparent"
      radius: Theme.cornerRadius
      anchors.right: parent.right
      anchors.rightMargin: 53
      anchors.verticalCenter: parent.verticalCenter

      StyledText {
        text: "PID"
        font.pixelSize: Theme.fontSizeSmall
        font.family: SettingsData.monoFontFamily
        font.weight: DgopService.sortBy === "pid" ? Font.Bold : Font.Medium
        color: Theme.surfaceText
        opacity: DgopService.sortBy === "pid" ? 1 : 0.7
        horizontalAlignment: Text.AlignHCenter
        anchors.centerIn: parent
      }

      MouseArea {
        id: pidHeaderArea

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
          DgopService.setSortBy("pid")
        }
      }

      Behavior on color {
        ColorAnimation {
          duration: Theme.shortDuration
        }
      }
    }

    Rectangle {
      width: 28
      height: 28
      radius: Theme.cornerRadius
      color: sortOrderArea.containsMouse ? Qt.rgba(Theme.surfaceText.r,
                                                   Theme.surfaceText.g,
                                                   Theme.surfaceText.b,
                                                   0.08) : "transparent"
      anchors.right: parent.right
      anchors.rightMargin: 8
      anchors.verticalCenter: parent.verticalCenter

      StyledText {
        text: DgopService.sortDescending ? "↓" : "↑"
        font.pixelSize: Theme.fontSizeMedium
        color: Theme.surfaceText
        anchors.centerIn: parent
      }

      MouseArea {
        id: sortOrderArea

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
          // ! TODO - we lost this with dgop
        }
      }

      Behavior on color {
        ColorAnimation {
          duration: Theme.shortDuration
        }
      }
    }
  }

  DankListView {
    id: processListView

    property string keyRoleName: "pid"

    width: parent.width
    height: parent.height - columnHeaders.height
    clip: true
    spacing: 4
    model: DgopService.processes

    delegate: ProcessListItem {
      process: modelData
      contextMenu: root.contextMenu
    }
  }
}
