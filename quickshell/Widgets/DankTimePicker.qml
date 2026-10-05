import QtQuick
import qs.Common
import qs.DCommon.Widgets as DCommon

DCommon.DTimePicker {
    id: shim
    Component.onCompleted: Deprecation.type(shim, "DankTimePicker", "DTimePicker", "qs.DCommon.Widgets")
}
