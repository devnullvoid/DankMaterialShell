import QtQuick
import Quickshell.Services.UPower
import qs.Common
import qs.Services
import qs.Widgets

DankOSD {
    id: root

    osdWidth: Theme.iconSize + Theme.spacingS * 2
    osdHeight: Theme.iconSize + Theme.spacingS * 2
    autoHideInterval: 2000
    enableMouseInteraction: false

    Connections {
        target: BatteryService

        function onPowerProfileChanged() {
            if (SettingsData.osdPowerProfileEnabled) {
                root.show()
            }
        }
    }

    Component.onCompleted: {
        if (SettingsData.osdPowerProfileEnabled) {
            root.show()
        }
    }

    content: DankIcon {
        anchors.centerIn: parent
        name: typeof PowerProfiles !== "undefined" ? Theme.getPowerProfileIcon(PowerProfiles.profile) : "settings"
        size: Theme.iconSize
        color: Theme.primary
    }
}
