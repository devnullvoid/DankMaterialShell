import QtQuick
import qs.Common
import qs.DCommon.Widgets as DCommon

DCommon.DIconButton {
    id: shim
    Component.onCompleted: Deprecation.type(shim, "DankIconButton", "DIconButton", "qs.DCommon.Widgets")
}
