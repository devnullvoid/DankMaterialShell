import QtQuick
import qs.Common
import qs.DCommon.Widgets as DCommon

DCommon.DSparkline {
    id: shim
    Component.onCompleted: Deprecation.type(shim, "DankSparkline", "DSparkline", "qs.DCommon.Widgets")
}
