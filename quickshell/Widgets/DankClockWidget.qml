import QtQuick
import qs.Common
import qs.DCommon.Widgets as DCommon

DCommon.DClockWidget {
    id: shim
    Component.onCompleted: Deprecation.type(shim, "DankClockWidget", "DClockWidget", "qs.DCommon.Widgets")
}
