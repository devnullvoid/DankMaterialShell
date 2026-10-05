import QtQuick
import qs.Common
import qs.DCommon.Widgets as DCommon

DCommon.DSplitButton {
    id: shim
    Component.onCompleted: Deprecation.type(shim, "DankSplitButton", "DSplitButton", "qs.DCommon.Widgets")
}
