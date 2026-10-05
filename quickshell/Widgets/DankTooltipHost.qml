import QtQuick
import qs.Common
import qs.DCommon.Widgets as DCommon

DCommon.DTooltipHost {
    id: shim
    Component.onCompleted: Deprecation.type(shim, "DankTooltipHost", "DTooltipHost", "qs.DCommon.Widgets")
}
