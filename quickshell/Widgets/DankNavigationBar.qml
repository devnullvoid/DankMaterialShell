import QtQuick
import qs.Common
import qs.DCommon.Widgets as DCommon

DCommon.DNavigationBar {
    id: shim
    Component.onCompleted: Deprecation.type(shim, "DankNavigationBar", "DNavigationBar", "qs.DCommon.Widgets")
}
