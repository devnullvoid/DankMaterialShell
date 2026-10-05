import QtQuick
import qs.Common
import qs.DCommon.Widgets as DCommon

DCommon.DFab {
    id: shim
    Component.onCompleted: Deprecation.type(shim, "DankFab", "DFab", "qs.DCommon.Widgets")
}
