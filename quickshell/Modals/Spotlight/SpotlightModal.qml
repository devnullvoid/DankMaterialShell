import QtQuick
import Quickshell.Io
import qs.Common
import qs.Modals.Common

DankModal {
    id: spotlightModal

    layerNamespace: "dms:spotlight"

    property bool spotlightOpen: false
    property alias spotlightContent: spotlightContentInstance
    property bool openedFromOverview: false

    function show() {
        openedFromOverview = false;
        spotlightOpen = true;
        open();
    }

    function showWithQuery(query) {
        if (spotlightContent) {
            if (spotlightContent.appLauncher)
                spotlightContent.appLauncher.searchQuery = query;
            if (spotlightContent.searchField)
                spotlightContent.searchField.text = query;
        }

        spotlightOpen = true;
        open();
    }

    function hide() {
        openedFromOverview = false;
        spotlightOpen = false;
        close();
    }

    function onFullyClosed() {
        resetContent();
    }

    function resetContent() {
        if (!spotlightContent)
            return;
        if (spotlightContent.appLauncher) {
            spotlightContent.appLauncher.searchQuery = "";
            spotlightContent.appLauncher.selectedIndex = 0;
            spotlightContent.appLauncher.setCategory(I18n.tr("All"));
        }
        if (spotlightContent.fileSearchController)
            spotlightContent.fileSearchController.reset();
        if (spotlightContent.resetScroll)
            spotlightContent.resetScroll();
        if (spotlightContent.searchField)
            spotlightContent.searchField.text = "";
    }

    function toggle() {
        if (spotlightOpen) {
            hide();
        } else {
            show();
        }
    }

    shouldBeVisible: spotlightOpen
    modalWidth: 500
    modalHeight: 600
    backgroundColor: Theme.withAlpha(Theme.surfaceContainer, Theme.popupTransparency)
    cornerRadius: Theme.cornerRadius
    borderColor: Theme.outlineMedium
    borderWidth: 1
    enableShadow: true
    keepContentLoaded: true
    onVisibleChanged: () => {
        if (!visible)
            return;
        if (!spotlightOpen)
            show();
    }
    onBackgroundClicked: () => {
        return hide();
    }

    Connections {
        function onCloseAllModalsExcept(excludedModal) {
            if (excludedModal !== spotlightModal && !allowStacking && spotlightOpen) {
                spotlightOpen = false;
            }
        }

        target: ModalManager
    }

    IpcHandler {
        function open(): string {
            spotlightModal.show();
            return "SPOTLIGHT_OPEN_SUCCESS";
        }

        function close(): string {
            spotlightModal.hide();
            return "SPOTLIGHT_CLOSE_SUCCESS";
        }

        function toggle(): string {
            spotlightModal.toggle();
            return "SPOTLIGHT_TOGGLE_SUCCESS";
        }

        function openQuery(query: string): string {
            spotlightModal.showWithQuery(query);
            return "SPOTLIGHT_OPEN_QUERY_SUCCESS";
        }

        function toggleQuery(query: string): string {
            if (spotlightModal.spotlightOpen) {
                spotlightModal.hide();
            } else {
                spotlightModal.showWithQuery(query);
            }
            return "SPOTLIGHT_TOGGLE_QUERY_SUCCESS";
        }

        target: "spotlight"
    }

    SpotlightContent {
        id: spotlightContentInstance

        parentModal: spotlightModal
    }

    directContent: spotlightContentInstance
}
