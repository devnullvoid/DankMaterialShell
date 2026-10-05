import QtQuick
import qs.Common
import qs.DCommon.Widgets as DCommon

DCommon.DWindowHeader {
    id: shim
    Component.onCompleted: Deprecation.type(shim, "DankWindowHeader", "DWindowHeader", "qs.DCommon.Widgets")
}
