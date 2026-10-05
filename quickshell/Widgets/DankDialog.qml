import QtQuick
import qs.Common
import qs.DCommon.Widgets as DCommon

DCommon.DDialog {
    id: shim
    Component.onCompleted: Deprecation.type(shim, "DankDialog", "DDialog", "qs.DCommon.Widgets")
}
