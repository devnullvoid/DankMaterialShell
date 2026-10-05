import QtQuick
import qs.Common
import qs.DCommon.Widgets as DCommon

DCommon.DPaletteSwatch {
    id: shim
    Component.onCompleted: Deprecation.type(shim, "DankPaletteSwatch", "DPaletteSwatch", "qs.DCommon.Widgets")
}
