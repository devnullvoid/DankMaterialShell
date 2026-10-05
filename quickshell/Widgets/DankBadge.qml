import QtQuick
import qs.Common
import qs.DCommon.Widgets as DCommon

DCommon.DBadge {
    id: shim
    Component.onCompleted: Deprecation.type(shim, "DankBadge", "DBadge", "qs.DCommon.Widgets")
}
