import QtQuick
import qs.Common
import qs.DCommon.Widgets as DCommon

DCommon.DRingGauge {
    id: shim
    Component.onCompleted: Deprecation.type(shim, "DankRingGauge", "DRingGauge", "qs.DCommon.Widgets")
}
