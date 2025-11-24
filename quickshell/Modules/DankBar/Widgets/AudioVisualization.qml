import QtQuick
import Quickshell.Services.Mpris
import qs.Common
import qs.Services

Item {
    id: root

    readonly property MprisPlayer activePlayer: MprisController.activePlayer
    readonly property bool hasActiveMedia: activePlayer !== null
    readonly property bool isPlaying: hasActiveMedia && activePlayer && activePlayer.playbackState === MprisPlaybackState.Playing

    width: 20
    height: Theme.iconSize

    Loader {
        active: isPlaying

        sourceComponent: Component {
            Ref {
                service: CavaService
            }
        }
    }

    readonly property real maxBarHeight: Theme.iconSize - 2
    readonly property real minBarHeight: 3
    readonly property real heightRange: maxBarHeight - minBarHeight

    Timer {
        id: fallbackTimer

        running: !CavaService.cavaAvailable && isPlaying
        interval: 500
        repeat: true
        onTriggered: {
            CavaService.values = [Math.random() * 20 + 5, Math.random() * 25 + 8, Math.random() * 22 + 6, Math.random() * 20 + 5, Math.random() * 22 + 6, Math.random() * 25 + 8];
        }
    }

    Row {
        anchors.centerIn: parent
        spacing: 1.5

        Repeater {
            model: 6

            Rectangle {
                readonly property real targetHeight: {
                    if (!root.isPlaying || CavaService.values.length <= index)
                        return root.minBarHeight;

                    const rawLevel = CavaService.values[index];
                    const clampedLevel = rawLevel < 0 ? 0 : (rawLevel > 100 ? 100 : rawLevel);
                    const scaledLevel = Math.sqrt(clampedLevel * 0.01);
                    return root.minBarHeight + scaledLevel * root.heightRange;
                }

                width: 2
                height: targetHeight
                radius: 1.5
                color: Theme.primary
                anchors.verticalCenter: parent.verticalCenter

                Behavior on height {
                    NumberAnimation {
                        duration: Anims.durShort
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Anims.standardDecel
                    }
                }
            }
        }
    }
}
