import QtQuick
import qs.Common
import qs.DCommon.Widgets as DCommon

DCommon.DAnalogClock {
    id: shim
    Component.onCompleted: Deprecation.type(shim, "DankAnalogClock", "DAnalogClock", "qs.DCommon.Widgets")
}
