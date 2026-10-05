import QtQuick
import qs.Common
import qs.DCommon.Widgets as DCommon

DCommon.DListHighlight {
    id: shim
    Component.onCompleted: Deprecation.type(shim, "DankListHighlight", "DListHighlight", "qs.DCommon.Widgets")
}
