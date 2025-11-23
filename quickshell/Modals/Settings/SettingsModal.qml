import QtQuick
import Quickshell
import qs.Common
import qs.Modals.FileBrowser
import qs.Services
import qs.Widgets

FloatingWindow {
    id: settingsModal

    property alias profileBrowser: profileBrowser
    property alias wallpaperBrowser: wallpaperBrowser
    property int currentTabIndex: 0
    property bool shouldHaveFocus: visible
    property bool allowFocusOverride: false
    property alias shouldBeVisible: settingsModal.visible

    signal closingModal

    function show() {
        visible = true;
    }

    function hide() {
        visible = false;
    }

    function toggle() {
        visible = !visible;
    }

    objectName: "settingsModal"
    title: "Settings"
    implicitWidth: 800
    implicitHeight: 800
    color: Theme.withAlpha(Theme.surfaceContainer, Theme.popupTransparency)
    visible: false

    onVisibleChanged: {
        if (!visible) {
            closingModal();
        } else {
            Qt.callLater(() => {
                if (contentFocusScope) {
                    contentFocusScope.forceActiveFocus();
                }
            });
        }
    }

    FileBrowserModal {
        id: profileBrowser

        allowStacking: true
        parentModal: settingsModal
        browserTitle: "Select Profile Image"
        browserIcon: "person"
        browserType: "profile"
        showHiddenFiles: true
        fileExtensions: ["*.jpg", "*.jpeg", "*.png", "*.bmp", "*.gif", "*.webp"]
        onFileSelected: path => {
            PortalService.setProfileImage(path);
            close();
        }
        onDialogClosed: () => {
            allowStacking = true;
        }
    }

    FileBrowserModal {
        id: wallpaperBrowser

        allowStacking: true
        parentModal: settingsModal
        browserTitle: "Select Wallpaper"
        browserIcon: "wallpaper"
        browserType: "wallpaper"
        showHiddenFiles: true
        fileExtensions: ["*.jpg", "*.jpeg", "*.png", "*.bmp", "*.gif", "*.webp"]
        onFileSelected: path => {
            SessionData.setWallpaper(path);
            close();
        }
        onDialogClosed: () => {
            allowStacking = true;
        }
    }

    FocusScope {
        id: contentFocusScope

        anchors.fill: parent
        focus: true

        Keys.onPressed: event => {
            const tabCount = 11;
            if (event.key === Qt.Key_Escape) {
                hide();
                event.accepted = true;
                return;
            }
            if (event.key === Qt.Key_Down) {
                currentTabIndex = (currentTabIndex + 1) % tabCount;
                event.accepted = true;
                return;
            }
            if (event.key === Qt.Key_Up) {
                currentTabIndex = (currentTabIndex - 1 + tabCount) % tabCount;
                event.accepted = true;
                return;
            }
            if (event.key === Qt.Key_Tab && !event.modifiers) {
                currentTabIndex = (currentTabIndex + 1) % tabCount;
                event.accepted = true;
                return;
            }
            if (event.key === Qt.Key_Backtab || (event.key === Qt.Key_Tab && event.modifiers & Qt.ShiftModifier)) {
                currentTabIndex = (currentTabIndex - 1 + tabCount) % tabCount;
                event.accepted = true;
                return;
            }
        }

        Column {
            anchors.fill: parent
            anchors.leftMargin: Theme.spacingL
            anchors.rightMargin: Theme.spacingL
            anchors.topMargin: Theme.spacingM
            anchors.bottomMargin: Theme.spacingL
            spacing: 0

            Item {
                width: parent.width
                height: 35

                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.spacingM

                    DankIcon {
                        name: "settings"
                        size: Theme.iconSize
                        color: Theme.primary
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    StyledText {
                        text: I18n.tr("Settings")
                        font.pixelSize: Theme.fontSizeXLarge
                        color: Theme.surfaceText
                        font.weight: Font.Medium
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                DankActionButton {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    circular: false
                    iconName: "close"
                    iconSize: Theme.iconSize - 4
                    iconColor: Theme.surfaceText
                    onClicked: () => {
                        settingsModal.hide();
                    }
                }
            }

            Row {
                width: parent.width
                height: parent.height - 35
                spacing: 0

                SettingsSidebar {
                    id: sidebar

                    parentModal: settingsModal
                    currentIndex: settingsModal.currentTabIndex
                    onCurrentIndexChanged: {
                        settingsModal.currentTabIndex = currentIndex;
                    }
                }

                Item {
                    width: parent.width - sidebar.width
                    height: parent.height

                    SettingsContent {
                        id: content

                        width: Math.min(550, parent.width)
                        height: parent.height
                        anchors.horizontalCenter: parent.horizontalCenter
                        parentModal: settingsModal
                        currentIndex: settingsModal.currentTabIndex
                    }
                }
            }
        }
    }
}
