import QtQuick
import qs.Common
import qs.Modules.ControlCenter

Rectangle {
    id: root

    property var widgetData: ({})
    property var widgetDef: null
    property var host: null
    property bool live: true
    property bool interactive: true
    property real columns: 4
    property real rows: 1
    property bool compact: columns <= 2 && rows === 1
    readonly property bool tall: height >= CcMetrics.gridRowUnit * 2
    readonly property bool narrow: width < CcMetrics.expandedTileMinWidth
    readonly property real pad: tall && !narrow ? Theme.spacingM : Theme.spacingS
    readonly property real bodyRadius: tall ? Math.min(CcMetrics.tallTileRadius, width / 2, height / 2) : Theme.fullRadius(width, height)

    width: parent?.width ?? 0
    height: CcMetrics.tileHeight
    radius: bodyRadius
    color: CcMetrics.tileInactiveColor
    border.width: Theme.layerOutlineWidth
    border.color: Theme.outlineMedium

    Behavior on radius {
        enabled: CcMetrics.animationsEnabled && !SettingsData.reduceMotion
        NumberAnimation {
            duration: Theme.expressiveDurations.expressiveEffects
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.expressiveCurves.expressiveEffects
        }
    }
}
