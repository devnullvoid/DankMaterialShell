import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import qs.Common
import qs.Modules.ProcessList
import qs.Services
import qs.Widgets

DankModal {
  id: processListModal

  property int currentTab: 0
  property var tabNames: ["Processes", "Performance", "System"]

  function show() {
    processListModal.visible = true
    UserInfoService.getUptime()
  }

  function hide() {
    processListModal.visible = false
    if (processContextMenu.visible)
      processContextMenu.close()
  }

  function toggle() {
    if (processListModal.visible)
      hide()
    else
      show()
  }

  width: 900
  height: 680
  visible: false
  keyboardFocus: "exclusive"
  backgroundColor: Theme.popupBackground()
  cornerRadius: Theme.cornerRadius
  enableShadow: true
  onBackgroundClicked: hide()

  Ref {
    service: SysMonitorService
  }

  Component {
    id: processesTabComponent

    ProcessesTab {
      contextMenu: processContextMenu
    }
  }

  Component {
    id: performanceTabComponent

    PerformanceTab {}
  }

  Component {
    id: systemTabComponent

    SystemTab {}
  }

  ProcessContextMenu {
    id: processContextMenu
  }

  content: Component {
    Item {
      anchors.fill: parent
      focus: true
      Keys.onPressed: function (event) {
        if (event.key === Qt.Key_Escape) {
          processListModal.hide()
          event.accepted = true
        } else if (event.key === Qt.Key_1) {
          currentTab = 0
          event.accepted = true
        } else if (event.key === Qt.Key_2) {
          currentTab = 1
          event.accepted = true
        } else if (event.key === Qt.Key_3) {
          currentTab = 2
          event.accepted = true
        }
      }

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacingL
        spacing: Theme.spacingL

        RowLayout {
          Layout.fillWidth: true
          height: 40

          StyledText {
            text: "System Monitor"
            font.pixelSize: Theme.fontSizeLarge + 4
            font.weight: Font.Bold
            color: Theme.surfaceText
            Layout.alignment: Qt.AlignVCenter
          }

          Item {
            Layout.fillWidth: true
          }

          DankActionButton {
            circular: false
            iconName: "close"
            iconSize: Theme.iconSize - 4
            iconColor: Theme.surfaceText
            hoverColor: Theme.errorHover
            onClicked: processListModal.hide()
            Layout.alignment: Qt.AlignVCenter
          }
        }

        Rectangle {
          Layout.fillWidth: true
          height: 52
          color: Theme.surfaceSelected
          radius: Theme.cornerRadius
          border.color: Theme.outlineLight
          border.width: 1

          Row {
            anchors.fill: parent
            anchors.margins: 4
            spacing: 2

            Repeater {
              model: tabNames

              Rectangle {
                width: (parent.width - (tabNames.length - 1) * 2) / tabNames.length
                height: 44
                radius: Theme.cornerRadius
                color: currentTab === index ? Theme.primaryPressed : (tabMouseArea.containsMouse ? Theme.primaryHoverLight : "transparent")
                border.color: currentTab === index ? Theme.primary : "transparent"
                border.width: currentTab === index ? 1 : 0

                Row {
                  anchors.centerIn: parent
                  spacing: Theme.spacingXS

                  DankIcon {
                    name: {
                      switch (index) {
                      case 0:
                        return "list_alt"
                      case 1:
                        return "analytics"
                      case 2:
                        return "settings"
                      default:
                        return "tab"
                      }
                    }
                    size: Theme.iconSize - 2
                    color: currentTab === index ? Theme.primary : Theme.surfaceText
                    opacity: currentTab === index ? 1 : 0.7
                    anchors.verticalCenter: parent.verticalCenter

                    Behavior on color {
                      ColorAnimation {
                        duration: Theme.shortDuration
                      }
                    }
                  }

                  StyledText {
                    text: modelData
                    font.pixelSize: Theme.fontSizeLarge
                    font.weight: Font.Medium
                    color: currentTab === index ? Theme.primary : Theme.surfaceText
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: -1

                    Behavior on color {
                      ColorAnimation {
                        duration: Theme.shortDuration
                      }
                    }
                  }
                }

                MouseArea {
                  id: tabMouseArea

                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    currentTab = index
                  }
                }

                Behavior on color {
                  ColorAnimation {
                    duration: Theme.shortDuration
                  }
                }

                Behavior on border.color {
                  ColorAnimation {
                    duration: Theme.shortDuration
                  }
                }
              }
            }
          }
        }

        Rectangle {
          Layout.fillWidth: true
          Layout.fillHeight: true
          radius: Theme.cornerRadius
          color: Theme.surfaceLight
          border.color: Theme.outlineLight
          border.width: 1

          Loader {
            id: processesTab

            anchors.fill: parent
            anchors.margins: Theme.spacingS
            active: currentTab === 0
            visible: currentTab === 0
            opacity: currentTab === 0 ? 1 : 0
            sourceComponent: processesTabComponent

            Behavior on opacity {
              NumberAnimation {
                duration: Theme.mediumDuration
                easing.type: Theme.emphasizedEasing
              }
            }
          }

          Loader {
            id: performanceTab

            anchors.fill: parent
            anchors.margins: Theme.spacingS
            active: currentTab === 1
            visible: currentTab === 1
            opacity: currentTab === 1 ? 1 : 0
            sourceComponent: performanceTabComponent

            Behavior on opacity {
              NumberAnimation {
                duration: Theme.mediumDuration
                easing.type: Theme.emphasizedEasing
              }
            }
          }

          Loader {
            id: systemTab

            anchors.fill: parent
            anchors.margins: Theme.spacingS
            active: currentTab === 2
            visible: currentTab === 2
            opacity: currentTab === 2 ? 1 : 0
            sourceComponent: systemTabComponent

            Behavior on opacity {
              NumberAnimation {
                duration: Theme.mediumDuration
                easing.type: Theme.emphasizedEasing
              }
            }
          }
        }
      }
    }
  }
}
