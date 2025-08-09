import QtQuick
import Quickshell.Services.Mpris
import qs.Common
import qs.Services
import qs.Widgets

Rectangle {
  id: root

  readonly property MprisPlayer activePlayer: MprisController.activePlayer
  readonly property bool playerAvailable: activePlayer !== null
  property bool compactMode: false
  readonly property int baseContentWidth: mediaRow.implicitWidth + Theme.spacingS * 2
  readonly property int normalContentWidth: Math.min(280, baseContentWidth)
  readonly property int compactContentWidth: Math.min(120, baseContentWidth)
  property string section: "center"
  property var popupTarget: null
  property var parentScreen: null

  signal clicked

  height: 30
  radius: Theme.cornerRadius
  color: {
    const baseColor = Theme.surfaceTextHover
    return Qt.rgba(baseColor.r, baseColor.g, baseColor.b,
                   baseColor.a * Theme.widgetTransparency)
  }
  states: [
    State {
      name: "shown"
      when: playerAvailable

      PropertyChanges {
        target: root
        opacity: 1
        width: SettingsData.mediaCompactMode ? compactContentWidth : normalContentWidth
      }
    },
    State {
      name: "hidden"
      when: !playerAvailable

      PropertyChanges {
        target: root
        opacity: 0
        width: 0
      }
    }
  ]
  transitions: [
    Transition {
      from: "shown"
      to: "hidden"

      SequentialAnimation {
        PauseAnimation {
          duration: 500
        }

        NumberAnimation {
          properties: "opacity,width"
          duration: Theme.shortDuration
          easing.type: Theme.standardEasing
        }
      }
    },
    Transition {
      from: "hidden"
      to: "shown"

      NumberAnimation {
        properties: "opacity,width"
        duration: Theme.shortDuration
        easing.type: Theme.standardEasing
      }
    }
  ]

  Row {
    id: mediaRow

    anchors.centerIn: parent
    spacing: Theme.spacingXS

    Row {
      id: mediaInfo

      spacing: Theme.spacingXS

      AudioVisualization {
        anchors.verticalCenter: parent.verticalCenter
      }

      StyledText {
        id: mediaText

        anchors.verticalCenter: parent.verticalCenter
        width: SettingsData.mediaCompactMode ? 60 : 140
        visible: !SettingsData.mediaCompactMode
        text: {
          if (!activePlayer || !activePlayer.trackTitle)
            return ""

          let identity = activePlayer.identity || ""
          let isWebMedia = identity.toLowerCase().includes("firefox")
              || identity.toLowerCase().includes(
                "chrome") || identity.toLowerCase().includes("chromium")
              || identity.toLowerCase().includes(
                "edge") || identity.toLowerCase().includes("safari")
          let title = ""
          let subtitle = ""
          if (isWebMedia && activePlayer.trackTitle) {
            title = activePlayer.trackTitle
            subtitle = activePlayer.trackArtist || identity
          } else {
            title = activePlayer.trackTitle || "Unknown Track"
            subtitle = activePlayer.trackArtist || ""
          }
          return subtitle.length > 0 ? title + " • " + subtitle : title
        }
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceText
        font.weight: Font.Medium
        elide: Text.ElideRight
        wrapMode: Text.NoWrap
        maximumLineCount: 1

        MouseArea {
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            if (root.popupTarget && root.popupTarget.setTriggerPosition) {
              var globalPos = mapToGlobal(0, 0)
              var currentScreen = root.parentScreen || Screen
              var screenX = currentScreen.x || 0
              var relativeX = globalPos.x - screenX
              root.popupTarget.setTriggerPosition(
                    relativeX, Theme.barHeight + Theme.spacingXS, root.width,
                    root.section, currentScreen)
            }
            root.clicked()
          }
        }
      }
    }

    Row {
      spacing: Theme.spacingXS
      anchors.verticalCenter: parent.verticalCenter

      Rectangle {
        width: 20
        height: 20
        radius: 10
        anchors.verticalCenter: parent.verticalCenter
        color: prevArea.containsMouse ? Theme.primaryHover : "transparent"
        visible: root.playerAvailable
        opacity: (activePlayer && activePlayer.canGoPrevious) ? 1 : 0.3

        DankIcon {
          anchors.centerIn: parent
          name: "skip_previous"
          size: 12
          color: Theme.surfaceText
        }

        MouseArea {
          id: prevArea

          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            if (activePlayer)
              activePlayer.previous()
          }
        }
      }

      Rectangle {
        width: 24
        height: 24
        radius: 12
        anchors.verticalCenter: parent.verticalCenter
        color: activePlayer
               && activePlayer.playbackState === 1 ? Theme.primary : Theme.primaryHover
        visible: root.playerAvailable
        opacity: activePlayer ? 1 : 0.3

        DankIcon {
          anchors.centerIn: parent
          name: activePlayer
                && activePlayer.playbackState === 1 ? "pause" : "play_arrow"
          size: 14
          color: activePlayer
                 && activePlayer.playbackState === 1 ? Theme.background : Theme.primary
        }

        MouseArea {
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            if (activePlayer)
              activePlayer.togglePlaying()
          }
        }
      }

      Rectangle {
        width: 20
        height: 20
        radius: 10
        anchors.verticalCenter: parent.verticalCenter
        color: nextArea.containsMouse ? Theme.primaryHover : "transparent"
        visible: playerAvailable
        opacity: (activePlayer && activePlayer.canGoNext) ? 1 : 0.3

        DankIcon {
          anchors.centerIn: parent
          name: "skip_next"
          size: 12
          color: Theme.surfaceText
        }

        MouseArea {
          id: nextArea

          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            if (activePlayer)
              activePlayer.next()
          }
        }
      }
    }
  }

  Behavior on color {
    ColorAnimation {
      duration: Theme.shortDuration
      easing.type: Theme.standardEasing
    }
  }

  Behavior on width {
    NumberAnimation {
      duration: Theme.shortDuration
      easing.type: Theme.standardEasing
    }
  }
}
