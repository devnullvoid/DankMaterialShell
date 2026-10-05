import QtQuick
import qs.Common
import qs.DCommon.Widgets as DCommon

DCommon.DSearchField {
    id: shim
    Component.onCompleted: Deprecation.type(shim, "DankSearchField", "DSearchField", "qs.DCommon.Widgets")
}
