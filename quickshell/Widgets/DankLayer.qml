import QtQuick
import qs.Common
import qs.DCommon.Widgets as DCommon

DCommon.DLayer {
    id: shim
    Component.onCompleted: Deprecation.type(shim, "DankLayer", "DLayer", "qs.DCommon.Widgets")
}
