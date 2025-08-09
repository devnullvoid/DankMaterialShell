import QtQuick
import QtQuick.Controls
import qs.Common
import qs.Services
import qs.Widgets

Rectangle {
  id: root

  property bool showPercentage: true
  property bool showIcon: true
  property var toggleProcessList
  property string section: "right"
  property var popupTarget: null
  property var parentScreen: null
  property var widgetData: null
  property int selectedGpuIndex: (widgetData && widgetData.selectedGpuIndex
                                  !== undefined) ? widgetData.selectedGpuIndex : 0

  Connections {
    target: SettingsData
    function onWidgetDataChanged() {
      // Force property re-evaluation by triggering change detection
      root.selectedGpuIndex = Qt.binding(() => {
                                           return (root.widgetData
                                                   && root.widgetData.selectedGpuIndex !== undefined) ? root.widgetData.selectedGpuIndex : 0
                                         })
    }
  }

  width: 55
  height: 30
  radius: Theme.cornerRadius
  color: {
    const baseColor = gpuArea.containsMouse ? Theme.primaryPressed : Theme.secondaryHover
    return Qt.rgba(baseColor.r, baseColor.g, baseColor.b,
                   baseColor.a * Theme.widgetTransparency)
  }
  Component.onCompleted: {
    SysMonitorService.addRef()
  }
  Component.onDestruction: {
    SysMonitorService.removeRef()
  }

  property real displayTemp: {
    if (!SysMonitorService.availableGpus
        || SysMonitorService.availableGpus.length === 0)
      return 0
    if (selectedGpuIndex >= 0
        && selectedGpuIndex < SysMonitorService.availableGpus.length) {
      return SysMonitorService.availableGpus[selectedGpuIndex].temperature || 0
    }
    return 0
  }

  MouseArea {
    id: gpuArea

    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: {
      if (popupTarget && popupTarget.setTriggerPosition) {
        var globalPos = mapToGlobal(0, 0)
        var currentScreen = parentScreen || Screen
        var screenX = currentScreen.x || 0
        var relativeX = globalPos.x - screenX
        popupTarget.setTriggerPosition(relativeX,
                                       Theme.barHeight + Theme.spacingXS,
                                       width, section, currentScreen)
      }
      SysMonitorService.setSortBy("cpu")
      if (root.toggleProcessList)
        root.toggleProcessList()
    }
  }

  Row {
    anchors.centerIn: parent
    spacing: 3

    DankIcon {
      name: "auto_awesome_mosaic"
      size: Theme.iconSize - 8
      color: {
        if (root.displayTemp > 80)
          return Theme.tempDanger

        if (root.displayTemp > 65)
          return Theme.tempWarning

        return Theme.surfaceText
      }
      anchors.verticalCenter: parent.verticalCenter
    }

    StyledText {
      text: {
        if (root.displayTemp === undefined || root.displayTemp === null
            || root.displayTemp === 0) {
          return "--°"
        }
        return Math.round(root.displayTemp) + "°"
      }
      font.pixelSize: Theme.fontSizeSmall
      font.weight: Font.Medium
      color: Theme.surfaceText
      anchors.verticalCenter: parent.verticalCenter
    }
  }

  Behavior on color {
    ColorAnimation {
      duration: Theme.shortDuration
      easing.type: Theme.standardEasing
    }
  }
}
