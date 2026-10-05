import QtQuick
import qs.Common
import qs.DCommon.Widgets as DCommon

DCommon.DReorderGroup {
    id: shim
    Component.onCompleted: Deprecation.type(shim, "DankReorderGroup", "DReorderGroup", "qs.DCommon.Widgets")
}
