import QtQuick
import qs.Common
import qs.DCommon.Widgets as DCommon

DCommon.DColorButton {
    id: shim
    Component.onCompleted: Deprecation.type(shim, "DankColorButton", "DColorButton", "qs.DCommon.Widgets")
}
