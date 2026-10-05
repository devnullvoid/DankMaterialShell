import QtQuick
import qs.Common
import qs.DCommon.Widgets as DCommon

DCommon.DOrganicBlob {
    id: shim
    Component.onCompleted: Deprecation.type(shim, "DankOrganicBlob", "DOrganicBlob", "qs.DCommon.Widgets")
}
