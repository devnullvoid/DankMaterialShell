import QtQuick
import qs.Common
import qs.DCommon.Widgets as DCommon

DCommon.DClockFace {
    id: shim
    Component.onCompleted: Deprecation.type(shim, "DankClockFace", "DClockFace", "qs.DCommon.Widgets")
}
