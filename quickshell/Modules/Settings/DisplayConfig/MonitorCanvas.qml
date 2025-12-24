import QtQuick
import qs.Common

Rectangle {
    id: root

    width: parent.width
    height: 280
    radius: Theme.cornerRadius
    color: Theme.surfaceContainerHighest
    border.color: Theme.outline
    border.width: 1

    Item {
        id: canvas
        anchors.fill: parent
        anchors.margins: Theme.spacingL

        property var bounds: DisplayConfigState.getOutputBounds()
        property real scaleFactor: {
            if (bounds.width === 0 || bounds.height === 0)
                return 0.1;
            const padding = Theme.spacingL * 2;
            const scaleX = (width - padding) / bounds.width;
            const scaleY = (height - padding) / bounds.height;
            return Math.min(scaleX, scaleY);
        }
        property point offset: Qt.point((width - bounds.width * scaleFactor) / 2 - bounds.minX * scaleFactor, (height - bounds.height * scaleFactor) / 2 - bounds.minY * scaleFactor)

        Connections {
            target: DisplayConfigState
            function onAllOutputsChanged() {
                canvas.bounds = DisplayConfigState.getOutputBounds();
            }
        }

        Repeater {
            model: DisplayConfigState.allOutputs ? Object.keys(DisplayConfigState.allOutputs) : []

            delegate: MonitorRect {
                required property string modelData
                outputName: modelData
                outputData: DisplayConfigState.allOutputs[modelData]
                canvasScaleFactor: canvas.scaleFactor
                canvasOffset: canvas.offset
            }
        }
    }
}
