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

    property int lastProfile: -1

    Connections {
        target: typeof PowerProfiles !== "undefined" ? PowerProfiles : null

        function onProfileChanged() {
            if (lastProfile !== -1 && lastProfile !== PowerProfiles.profile && SettingsData.osdPowerProfileEnabled) {
                root.show()
            }
            lastProfile = PowerProfiles.profile
        }
    }

    Component.onCompleted: {
        if (typeof PowerProfiles !== "undefined") {
            lastProfile = PowerProfiles.profile
        }
    }

    content: DankIcon {
        anchors.centerIn: parent
        name: typeof PowerProfiles !== "undefined" ? Theme.getPowerProfileIcon(PowerProfiles.profile) : "settings"
        size: Theme.iconSize
        color: Theme.primary
    }
}
