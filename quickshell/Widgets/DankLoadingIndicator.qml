import QtQuick
import qs.Common
import qs.DCommon.Widgets as DCommon

DCommon.DLoadingIndicator {
    id: shim
    Component.onCompleted: Deprecation.type(shim, "DankLoadingIndicator", "DLoadingIndicator", "qs.DCommon.Widgets")
}
