import QtQuick
import qs.Common
import qs.Services
import qs.Widgets

Row {
  width: parent.width
  spacing: Theme.spacingM
  Component.onCompleted: {
    SysMonitorService.addRef()
  }
  Component.onDestruction: {
    SysMonitorService.removeRef()
  }

  Rectangle {
    width: (parent.width - Theme.spacingM * 2) / 3
    height: 80
    radius: Theme.cornerRadius
    color: {
      if (SysMonitorService.sortBy === "cpu")
        return Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.16)
      else if (cpuCardMouseArea.containsMouse)
        return Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12)
      else
        return Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.08)
    }
    border.color: SysMonitorService.sortBy === "cpu" ? Qt.rgba(Theme.primary.r,
                                                               Theme.primary.g,
                                                               Theme.primary.b,
                                                               0.4) : Qt.rgba(
                                                         Theme.primary.r,
                                                         Theme.primary.g,
                                                         Theme.primary.b, 0.2)
    border.width: SysMonitorService.sortBy === "cpu" ? 2 : 1

    MouseArea {
      id: cpuCardMouseArea

      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: SysMonitorService.setSortBy("cpu")
    }

    Column {
      anchors.left: parent.left
      anchors.leftMargin: Theme.spacingM
      anchors.verticalCenter: parent.verticalCenter
      spacing: 2

      StyledText {
        text: "CPU"
        font.pixelSize: Theme.fontSizeSmall
        font.weight: Font.Medium
        color: SysMonitorService.sortBy === "cpu" ? Theme.primary : Theme.secondary
        opacity: SysMonitorService.sortBy === "cpu" ? 1 : 0.8
      }

      Row {
        spacing: Theme.spacingS

        StyledText {
          text: SysMonitorService.totalCpuUsage.toFixed(1) + "%"
          font.pixelSize: Theme.fontSizeLarge
          font.family: SettingsData.monoFontFamily
          font.weight: Font.Bold
          color: Theme.surfaceText
          anchors.verticalCenter: parent.verticalCenter
        }

        Rectangle {
          width: 1
          height: 20
          color: Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g,
                         Theme.surfaceText.b, 0.3)
          anchors.verticalCenter: parent.verticalCenter
        }

        StyledText {
          text: {
            if (SysMonitorService.cpuTemperature === undefined
                || SysMonitorService.cpuTemperature === null
                || SysMonitorService.cpuTemperature < 0) {
              return "--°"
            }
            return Math.round(SysMonitorService.cpuTemperature) + "°"
          }
          font.pixelSize: Theme.fontSizeMedium
          font.family: SettingsData.monoFontFamily
          font.weight: Font.Medium
          color: {
            if (SysMonitorService.cpuTemperature > 80)
              return Theme.error
            if (SysMonitorService.cpuTemperature > 60)
              return Theme.warning
            return Theme.surfaceText
          }
          anchors.verticalCenter: parent.verticalCenter
        }
      }

      StyledText {
        text: SysMonitorService.cpuCount + " cores"
        font.pixelSize: Theme.fontSizeSmall
        font.family: SettingsData.monoFontFamily
        color: Theme.surfaceText
        opacity: 0.7
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

  Rectangle {
    width: (parent.width - Theme.spacingM * 2) / 3
    height: 80
    radius: Theme.cornerRadius
    color: {
      if (SysMonitorService.sortBy === "memory")
        return Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.16)
      else if (memoryCardMouseArea.containsMouse)
        return Qt.rgba(Theme.secondary.r, Theme.secondary.g,
                       Theme.secondary.b, 0.12)
      else
        return Qt.rgba(Theme.secondary.r, Theme.secondary.g,
                       Theme.secondary.b, 0.08)
    }
    border.color: SysMonitorService.sortBy === "memory" ? Qt.rgba(
                                                            Theme.primary.r,
                                                            Theme.primary.g,
                                                            Theme.primary.b,
                                                            0.4) : Qt.rgba(
                                                            Theme.secondary.r,
                                                            Theme.secondary.g,
                                                            Theme.secondary.b,
                                                            0.2)
    border.width: SysMonitorService.sortBy === "memory" ? 2 : 1

    MouseArea {
      id: memoryCardMouseArea

      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: SysMonitorService.setSortBy("memory")
    }

    Column {
      anchors.left: parent.left
      anchors.leftMargin: Theme.spacingM
      anchors.verticalCenter: parent.verticalCenter
      spacing: 2

      StyledText {
        text: "Memory"
        font.pixelSize: Theme.fontSizeSmall
        font.weight: Font.Medium
        color: SysMonitorService.sortBy === "memory" ? Theme.primary : Theme.secondary
        opacity: SysMonitorService.sortBy === "memory" ? 1 : 0.8
      }

      Row {
        spacing: Theme.spacingS

        StyledText {
          text: SysMonitorService.formatSystemMemory(
                  SysMonitorService.usedMemoryKB)
          font.pixelSize: Theme.fontSizeLarge
          font.family: SettingsData.monoFontFamily
          font.weight: Font.Bold
          color: Theme.surfaceText
          anchors.verticalCenter: parent.verticalCenter
        }

        Rectangle {
          width: 1
          height: 20
          color: Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g,
                         Theme.surfaceText.b, 0.3)
          anchors.verticalCenter: parent.verticalCenter
          visible: SysMonitorService.totalSwapKB > 0
        }

        StyledText {
          text: SysMonitorService.totalSwapKB > 0 ? SysMonitorService.formatSystemMemory(
                                                      SysMonitorService.usedSwapKB) : ""
          font.pixelSize: Theme.fontSizeMedium
          font.family: SettingsData.monoFontFamily
          font.weight: Font.Medium
          color: SysMonitorService.usedSwapKB > 0 ? Theme.warning : Theme.surfaceText
          anchors.verticalCenter: parent.verticalCenter
          visible: SysMonitorService.totalSwapKB > 0
        }
      }

      StyledText {
        text: {
          if (SysMonitorService.totalSwapKB > 0) {
            return "of " + SysMonitorService.formatSystemMemory(
                  SysMonitorService.totalMemoryKB) + " + swap"
          }
          return "of " + SysMonitorService.formatSystemMemory(
                SysMonitorService.totalMemoryKB)
        }
        font.pixelSize: Theme.fontSizeSmall
        font.family: SettingsData.monoFontFamily
        color: Theme.surfaceText
        opacity: 0.7
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

  Rectangle {
    width: (parent.width - Theme.spacingM * 2) / 3
    height: 80
    radius: Theme.cornerRadius
    color: {
      if (gpuCardMouseArea.containsMouse
          && SysMonitorService.availableGpus.length > 1)
        return Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g,
                       Theme.surfaceVariant.b, 0.16)
      else
        return Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g,
                       Theme.surfaceVariant.b, 0.08)
    }
    border.color: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g,
                          Theme.surfaceVariant.b, 0.2)
    border.width: 1

    MouseArea {
      id: gpuCardMouseArea
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: SysMonitorService.availableGpus.length
                   > 1 ? Qt.PointingHandCursor : Qt.ArrowCursor
      onClicked: {
        if (SysMonitorService.availableGpus.length > 1) {
          var nextIndex = (SessionData.selectedGpuIndex + 1)
              % SysMonitorService.availableGpus.length
          SessionData.setSelectedGpuIndex(nextIndex)
        }
      }
    }

    Column {
      anchors.left: parent.left
      anchors.leftMargin: Theme.spacingM
      anchors.verticalCenter: parent.verticalCenter
      spacing: 2

      StyledText {
        text: "GPU"
        font.pixelSize: Theme.fontSizeSmall
        font.weight: Font.Medium
        color: Theme.secondary
        opacity: 0.8
      }

      StyledText {
        text: {
          if (!SysMonitorService.availableGpus
              || SysMonitorService.availableGpus.length === 0) {
            return "--°"
          }

          var gpu = SysMonitorService.availableGpus[Math.min(
                                                      SessionData.selectedGpuIndex,
                                                      SysMonitorService.availableGpus.length - 1)]
          var temp = gpu.temperature
          return (temp === undefined || temp === null
                  || temp === 0) ? "--°" : Math.round(temp) + "°"
        }
        font.pixelSize: Theme.fontSizeLarge
        font.family: SettingsData.monoFontFamily
        font.weight: Font.Bold
        color: {
          if (!SysMonitorService.availableGpus
              || SysMonitorService.availableGpus.length === 0) {
            return Theme.surfaceText
          }

          var gpu = SysMonitorService.availableGpus[Math.min(
                                                      SessionData.selectedGpuIndex,
                                                      SysMonitorService.availableGpus.length - 1)]
          var temp = gpu.temperature || 0
          if (temp > 80)
            return Theme.error
          if (temp > 60)
            return Theme.warning
          return Theme.surfaceText
        }
      }

      StyledText {
        text: {
          if (!SysMonitorService.availableGpus
              || SysMonitorService.availableGpus.length === 0) {
            return "No GPUs detected"
          }

          var gpu = SysMonitorService.availableGpus[Math.min(
                                                      SessionData.selectedGpuIndex,
                                                      SysMonitorService.availableGpus.length - 1)]
          return gpu.vendor + " " + gpu.displayName
        }
        font.pixelSize: Theme.fontSizeSmall
        font.family: SettingsData.monoFontFamily
        color: Theme.surfaceText
        opacity: 0.7
        width: parent.parent.width - Theme.spacingM * 2
        elide: Text.ElideRight
        maximumLineCount: 1
      }
    }

    Behavior on color {
      ColorAnimation {
        duration: Theme.shortDuration
      }
    }
  }
}
