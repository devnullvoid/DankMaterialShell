import QtQuick
import qs.Common
import qs.DCommon.Widgets as DCommon

DCommon.DListItem {
    id: shim
    Component.onCompleted: Deprecation.type(shim, "DankListItem", "DListItem", "qs.DCommon.Widgets")
}
