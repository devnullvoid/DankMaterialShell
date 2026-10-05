import QtQuick
import qs.Common
import qs.DCommon.Widgets as DCommon

DCommon.DTone {
    id: shim
    Component.onCompleted: Deprecation.type(shim, "DankTone", "DTone", "qs.DCommon.Widgets")
}
