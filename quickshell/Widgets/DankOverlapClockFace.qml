import QtQuick
import qs.Common
import qs.DCommon.Widgets as DCommon

DCommon.DOverlapClockFace {
    id: shim
    Component.onCompleted: Deprecation.type(shim, "DankOverlapClockFace", "DOverlapClockFace", "qs.DCommon.Widgets")
}
