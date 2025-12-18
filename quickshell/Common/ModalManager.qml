pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import QtQuick

Singleton {
    id: modalManager

    signal closeAllModalsExcept(var excludedModal)
    signal modalChanged

    property var currentModalsByScreen: ({})

    function openModal(modal) {
        if (!modal.allowStacking) {
            closeAllModalsExcept(modal);
        }
        if (!modal.keepPopoutsOpen) {
            PopoutManager.closeAllPopouts();
        }
        TrayMenuManager.closeAllMenus();

        const screenName = modal.effectiveScreen?.name ?? "unknown";
        currentModalsByScreen[screenName] = modal;
        modalChanged();
    }

    function closeModal(modal) {
        const screenName = modal.effectiveScreen?.name ?? "unknown";
        if (currentModalsByScreen[screenName] === modal) {
            delete currentModalsByScreen[screenName];
            modalChanged();
        }
    }
}
