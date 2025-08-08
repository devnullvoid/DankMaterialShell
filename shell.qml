//@ pragma UseQApplication

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.Modals
import qs.Modules
import qs.Modules.AppDrawer
import qs.Modules.CentcomCenter
import qs.Modules.ControlCenter
import qs.Modules.ControlCenter.Network
import qs.Modules.Lock
import qs.Modules.Notifications.Center
import qs.Modules.Notifications.Popup
import qs.Modules.ProcessList
import qs.Modules.Settings
import qs.Modules.TopBar
import qs.Modules.Dock
import qs.Services

ShellRoot {
    id: root

    WallpaperBackground {}

    Lock {
        id: lock

        anchors.fill: parent
    }

    Variants {
        model: Quickshell.screens

        delegate: TopBar {
            modelData: item
        }
    }

    Variants {
        model: Quickshell.screens

        delegate: Dock {
            modelData: item
            contextMenu: dockContextMenu
            windowsMenu: dockWindowsMenu
        }
    }

    CentcomPopout {
        id: centcomPopout
    }

    DockContextMenu {
        id: dockContextMenu
    }

    DockWindowsMenu {
        id: dockWindowsMenu
    }

    NotificationCenterPopout {
        id: notificationCenter
    }

    Variants {
        model: Quickshell.screens

        delegate: NotificationPopupManager {
            modelData: item
        }
    }

    ControlCenterPopout {
        id: controlCenterPopout

        onPowerActionRequested: (action, title, message) => {
            powerConfirmModal.powerConfirmAction = action;
            powerConfirmModal.powerConfirmTitle = title;
            powerConfirmModal.powerConfirmMessage = message;
            powerConfirmModal.powerConfirmVisible = true;
        }
        onLockRequested: {
            lock.activate();
        }
    }

    WifiPasswordModal {
        id: wifiPasswordModal
    }

    NetworkInfoModal {
        id: networkInfoModal
    }

    BatteryPopout {
        id: batteryPopout
    }

    PowerMenu {
        id: powerMenu
    }

    PowerConfirmModal {
        id: powerConfirmModal
    }

    ProcessListPopout {
        id: processListPopout
    }

    SettingsModal {
        id: settingsModal
    }

    AppDrawerPopout {
        id: appDrawerPopout
    }

    SpotlightModal {
        id: spotlightModal
    }

    ClipboardHistoryModal {
        id: clipboardHistoryModalPopup
    }

    LazyLoader {
        id: processListModalLoader

        active: false

        ProcessListModal {
            id: processListModal
        }
    }

    IpcHandler {
        function open() {
            processListModalLoader.active = true;
            if (processListModalLoader.item)
                processListModalLoader.item.show();

            return "PROCESSLIST_OPEN_SUCCESS";
        }

        function close() {
            if (processListModalLoader.item)
                processListModalLoader.item.hide();

            return "PROCESSLIST_CLOSE_SUCCESS";
        }

        function toggle() {
            processListModalLoader.active = true;
            if (processListModalLoader.item)
                processListModalLoader.item.toggle();

            return "PROCESSLIST_TOGGLE_SUCCESS";
        }

        target: "processlist"
    }

    Variants {
        model: Quickshell.screens

        delegate: Toast {
            modelData: item
        }
    }

    Variants {
        model: Quickshell.screens

        delegate: VolumePopup {
            modelData: item
        }
    }

    Variants {
        model: Quickshell.screens

        delegate: MicMutePopup {
            modelData: item
        }
    }

    Variants {
        model: Quickshell.screens

        delegate: BrightnessPopup {
            modelData: item
        }
    }
}
