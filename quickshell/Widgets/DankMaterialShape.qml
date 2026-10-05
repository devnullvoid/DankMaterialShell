import QtQuick
import qs.Common
import qs.DCommon.Widgets as DCommon

DCommon.DMaterialShape {
    id: shim
    Component.onCompleted: Deprecation.type(shim, "DankMaterialShape", "DMaterialShape", "qs.DCommon.Widgets")
}
