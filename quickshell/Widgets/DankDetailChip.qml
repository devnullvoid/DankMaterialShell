import QtQuick
import qs.Common
import qs.DCommon.Widgets as DCommon

DCommon.DDetailChip {
    id: shim
    Component.onCompleted: Deprecation.type(shim, "DankDetailChip", "DDetailChip", "qs.DCommon.Widgets")
}
