import QtQuick
import qs.Common
import qs.DCommon.Widgets as DCommon

DCommon.DListRow {
    id: shim
    Component.onCompleted: Deprecation.type(shim, "DankListRow", "DListRow", "qs.DCommon.Widgets")
}
