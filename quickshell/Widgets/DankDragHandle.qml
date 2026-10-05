import QtQuick
import qs.Common
import qs.DCommon.Widgets as DCommon

DCommon.DDragHandle {
    id: shim
    Component.onCompleted: Deprecation.type(shim, "DankDragHandle", "DDragHandle", "qs.DCommon.Widgets")
}
