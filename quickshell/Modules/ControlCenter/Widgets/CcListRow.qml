import QtQuick
import qs.Common
import qs.Modules.ControlCenter
import qs.Modules.Settings.Widgets
import qs.Widgets

SettingsRow {
    id: root

    property bool active: false
    property bool showActiveCheck: false

    paddingH: CcMetrics.rowPaddingH
    paddingV: CcMetrics.rowPaddingV
    rowColor: CcMetrics.rowColor
    iconColor: active ? Theme.primary : Theme.surfaceText

    Loader {
        anchors.verticalCenter: parent.verticalCenter
        active: root.active && root.showActiveCheck
        sourceComponent: DankIcon {
            name: "check"
            size: Theme.iconSize
            color: Theme.primary
        }
    }
}
