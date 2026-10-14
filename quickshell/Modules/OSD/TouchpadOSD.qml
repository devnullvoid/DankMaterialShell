import QtQuick
import qs.Common
import qs.Services
import qs.Widgets

DOSD {
    id: root

    osdKind: "touchpad"

    osdWidth: Theme.osdHeight
    osdHeight: Theme.osdHeight
    autoHideInterval: 2000
    enableMouseInteraction: false

    Connections {
        target: NiriService

        function onTouchpadToggled() {
            if (SettingsData.osdTouchpadEnabled) {
                root.show();
            }
        }
    }

    content: Item {
        OsdIcon {
            tonal: false
            anchors.centerIn: parent
            iconName: NiriService.touchpadDisabled ? "touchpad_mouse_off" : "touchpad_mouse"
            iconColor: NiriService.touchpadDisabled ? Theme.outline : Theme.primary
        }
    }
}
