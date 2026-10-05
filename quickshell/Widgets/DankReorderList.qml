import QtQuick
import qs.Common
import qs.DCommon.Widgets as DCommon

DCommon.DReorderList {
    id: shim
    Component.onCompleted: Deprecation.type(shim, "DankReorderList", "DReorderList", "qs.DCommon.Widgets")
}
