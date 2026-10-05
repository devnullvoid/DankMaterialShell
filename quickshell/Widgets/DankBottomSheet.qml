import QtQuick
import qs.Common
import qs.DCommon.Widgets as DCommon

DCommon.DBottomSheet {
    id: shim
    Component.onCompleted: Deprecation.type(shim, "DankBottomSheet", "DBottomSheet", "qs.DCommon.Widgets")
}
