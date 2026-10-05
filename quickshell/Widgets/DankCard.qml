import QtQuick
import qs.Common
import qs.DCommon.Widgets as DCommon

DCommon.DCard {
    id: shim
    Component.onCompleted: Deprecation.type(shim, "DankCard", "DCard", "qs.DCommon.Widgets")
}
