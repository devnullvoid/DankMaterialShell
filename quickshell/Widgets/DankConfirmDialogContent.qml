import QtQuick
import qs.Common
import qs.DCommon.Widgets as DCommon

DCommon.DConfirmDialogContent {
    id: shim
    Component.onCompleted: Deprecation.type(shim, "DankConfirmDialogContent", "DConfirmDialogContent", "qs.DCommon.Widgets")
}
