import QtQuick
import Quickshell
import qs.Common
import qs.Modals.Common
import qs.Widgets
import qs.Services

DankModal {
    id: root

    property string url: ""
    property string searchQuery: ""
    property int selectedIndex: 0
    property int gridColumns: 4
    property bool keyboardNavigationActive: false
    property string viewMode: SettingsData.browserPickerViewMode || "grid"

    shouldBeVisible: false
    allowStacking: true
    modalWidth: 520
    modalHeight: 500

    onDialogClosed: {
        url = ""
        searchQuery = ""
        selectedIndex = 0
        keyboardNavigationActive = false
    }

    onOpened: {
        searchQuery = ""
        updateBrowserList()
        selectedIndex = 0
        Qt.callLater(() => {
            if (contentLoader.item && contentLoader.item.searchField) {
                contentLoader.item.searchField.text = ""
                contentLoader.item.searchField.forceActiveFocus()
            }
        })
    }

    function updateBrowserList() {
        browsersModel.clear()
        const apps = AppSearchService.applications
        const appUsageRanking = AppUsageHistoryData.appUsageRanking || {}
        let browsers = []

        for (const app of apps) {
            if (!app || !app.categories) continue

            let isBrowser = false

            try {
                for (const cat of app.categories) {
                    if (cat === "WebBrowser" || cat === "X-WebBrowser") {
                        isBrowser = true
                        break
                    }
                }
            } catch (e) {
                console.warn("BrowserPicker: Error iterating categories for", app.name, ":", e)
                continue
            }

            if (isBrowser) {
                const name = app.name || ""
                const lowerName = name.toLowerCase()
                const lowerQuery = searchQuery.toLowerCase()

                if (searchQuery === "" || lowerName.includes(lowerQuery)) {
                    browsers.push({
                        name: name,
                        icon: app.icon || "web-browser",
                        exec: app.exec || app.execString || "",
                        startupClass: app.startupWMClass || "",
                        appData: app
                    })
                }
            }
        }

        browsers.sort((a, b) => {
            const aId = a.appData.id || a.appData.execString || a.appData.exec || ""
            const bId = b.appData.id || b.appData.execString || b.appData.exec || ""
            const aUsage = appUsageRanking[aId] ? appUsageRanking[aId].usageCount : 0
            const bUsage = appUsageRanking[bId] ? appUsageRanking[bId].usageCount : 0
            if (aUsage !== bUsage) {
                return bUsage - aUsage
            }
            return (a.name || "").localeCompare(b.name || "")
        })

        browsers.forEach(browser => {
            browsersModel.append({
                name: browser.name,
                icon: browser.icon,
                exec: browser.exec,
                startupClass: browser.startupClass,
                appId: browser.appData.id || browser.appData.execString || browser.appData.exec || ""
            })
        })

        console.log("BrowserPicker: Found " + browsers.length + " browsers")
    }

    onSearchQueryChanged: updateBrowserList()

    ListModel {
        id: browsersModel
    }

    content: Component {
        FocusScope {
            id: browserContent

            property alias searchField: searchField

            anchors.fill: parent
            focus: true

            Keys.onEscapePressed: event => {
                root.close()
                event.accepted = true
            }

            Keys.onPressed: event => {
                if (browsersModel.count === 0) return

                if (root.viewMode === "grid") {
                    if (event.key === Qt.Key_Left) {
                        root.keyboardNavigationActive = true
                        root.selectedIndex = Math.max(0, root.selectedIndex - 1)
                        event.accepted = true
                    } else if (event.key === Qt.Key_Right) {
                        root.keyboardNavigationActive = true
                        root.selectedIndex = Math.min(browsersModel.count - 1, root.selectedIndex + 1)
                        event.accepted = true
                    } else if (event.key === Qt.Key_Up) {
                        root.keyboardNavigationActive = true
                        root.selectedIndex = Math.max(0, root.selectedIndex - root.gridColumns)
                        event.accepted = true
                    } else if (event.key === Qt.Key_Down) {
                        root.keyboardNavigationActive = true
                        root.selectedIndex = Math.min(browsersModel.count - 1, root.selectedIndex + root.gridColumns)
                        event.accepted = true
                    }
                } else {
                    if (event.key === Qt.Key_Up) {
                        root.keyboardNavigationActive = true
                        root.selectedIndex = Math.max(0, root.selectedIndex - 1)
                        event.accepted = true
                    } else if (event.key === Qt.Key_Down) {
                        root.keyboardNavigationActive = true
                        root.selectedIndex = Math.min(browsersModel.count - 1, root.selectedIndex + 1)
                        event.accepted = true
                    }
                }

                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    if (root.selectedIndex >= 0 && root.selectedIndex < browsersModel.count) {
                        const browser = browsersModel.get(root.selectedIndex)
                        launchBrowser(browser)
                    }
                    event.accepted = true
                }
            }

            Column {
                width: parent.width - Theme.spacingS * 2
                height: parent.height - Theme.spacingS * 2
                x: Theme.spacingS
                y: Theme.spacingS
                spacing: Theme.spacingS

                Item {
                    width: parent.width
                    height: 40

                    StyledText {
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.spacingS
                        anchors.verticalCenter: parent.verticalCenter
                        text: I18n.tr("Open with...")
                        font.pixelSize: Theme.fontSizeLarge + 4
                        font.weight: Font.Bold
                        color: Theme.surfaceText
                    }

                    Row {
                        spacing: 4
                        anchors.right: parent.right
                        anchors.rightMargin: Theme.spacingS
                        anchors.verticalCenter: parent.verticalCenter

                        DankActionButton {
                            buttonSize: 36
                            circular: false
                            iconName: "view_list"
                            iconSize: 20
                            iconColor: root.viewMode === "list" ? Theme.primary : Theme.surfaceText
                            backgroundColor: root.viewMode === "list" ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12) : "transparent"
                            onClicked: {
                                root.viewMode = "list"
                                SettingsData.set("browserPickerViewMode", "list")
                            }
                        }

                        DankActionButton {
                            buttonSize: 36
                            circular: false
                            iconName: "grid_view"
                            iconSize: 20
                            iconColor: root.viewMode === "grid" ? Theme.primary : Theme.surfaceText
                            backgroundColor: root.viewMode === "grid" ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12) : "transparent"
                            onClicked: {
                                root.viewMode = "grid"
                                SettingsData.set("browserPickerViewMode", "grid")
                            }
                        }
                    }
                }

                DankTextField {
                    id: searchField

                    width: parent.width - Theme.spacingS * 2
                    anchors.horizontalCenter: parent.horizontalCenter
                    height: 52
                    cornerRadius: Theme.cornerRadius
                    backgroundColor: Theme.withAlpha(Theme.surfaceContainerHigh, Theme.popupTransparency)
                    normalBorderColor: Theme.outlineMedium
                    focusedBorderColor: Theme.primary
                    leftIconName: "search"
                    leftIconSize: Theme.iconSize
                    leftIconColor: Theme.surfaceVariantText
                    leftIconFocusedColor: Theme.primary
                    showClearButton: true
                    font.pixelSize: Theme.fontSizeLarge
                    enabled: root.shouldBeVisible
                    ignoreLeftRightKeys: root.viewMode !== "list"
                    ignoreTabKeys: true
                    keyForwardTargets: [browserContent]

                    onTextEdited: {
                        root.searchQuery = text
                    }

                    Keys.onPressed: function (event) {
                        if (event.key === Qt.Key_Escape) {
                            root.close()
                            event.accepted = true
                            return
                        }

                        const isEnterKey = [Qt.Key_Return, Qt.Key_Enter].includes(event.key)
                        const hasText = text.length > 0

                        if (isEnterKey && hasText) {
                            if (root.keyboardNavigationActive && browsersModel.count > 0) {
                                const browser = browsersModel.get(root.selectedIndex)
                                launchBrowser(browser)
                            } else if (browsersModel.count > 0) {
                                const browser = browsersModel.get(0)
                                launchBrowser(browser)
                            }
                            event.accepted = true
                            return
                        }

                        const navigationKeys = [Qt.Key_Down, Qt.Key_Up, Qt.Key_Left, Qt.Key_Right, Qt.Key_Tab, Qt.Key_Backtab]
                        const isNavigationKey = navigationKeys.includes(event.key)
                        const isEmptyEnter = isEnterKey && !hasText

                        event.accepted = !(isNavigationKey || isEmptyEnter)
                    }

                    Connections {
                        function onShouldBeVisibleChanged() {
                            if (!root.shouldBeVisible) {
                                searchField.focus = false
                            }
                        }

                        target: root
                    }
                }

                Rectangle {
                    width: parent.width
                    height: {
                        let usedHeight = 40 + Theme.spacingS
                        usedHeight += 52 + Theme.spacingS
                        usedHeight += 36 + Theme.spacingS
                        return parent.height - usedHeight
                    }
                    radius: Theme.cornerRadius
                    color: "transparent"

                    DankListView {
                        id: browserList
                        anchors.fill: parent
                        anchors.leftMargin: Theme.spacingS
                        anchors.rightMargin: Theme.spacingS
                        anchors.bottomMargin: Theme.spacingS

                        visible: root.viewMode === "list"
                        model: browsersModel
                        currentIndex: root.selectedIndex
                        clip: true
                        spacing: Theme.spacingS

                        onCurrentIndexChanged: {
                            root.selectedIndex = currentIndex
                        }

                        delegate: AppLauncherListDelegate {
                            listView: browserList
                            itemHeight: 60
                            iconSize: 40
                            showDescription: false

                            isCurrentItem: index === root.selectedIndex
                            keyboardNavigationActive: root.keyboardNavigationActive
                            hoverUpdatesSelection: true

                            onItemClicked: (idx, modelData) => {
                                launchBrowser(modelData)
                            }

                            onKeyboardNavigationReset: {
                                root.keyboardNavigationActive = false
                            }
                        }
                    }

                    DankGridView {
                        id: browserGrid
                        anchors.fill: parent
                        anchors.leftMargin: Theme.spacingS
                        anchors.rightMargin: Theme.spacingS
                        anchors.bottomMargin: Theme.spacingS

                        visible: root.viewMode === "grid"
                        model: browsersModel
                        cellWidth: width / root.gridColumns
                        cellHeight: 120
                        clip: true
                        currentIndex: root.selectedIndex

                        onCurrentIndexChanged: {
                            root.selectedIndex = currentIndex
                        }

                        delegate: AppLauncherGridDelegate {
                            gridView: browserGrid
                            cellWidth: browserGrid.cellWidth
                            cellHeight: browserGrid.cellHeight

                            currentIndex: root.selectedIndex
                            keyboardNavigationActive: root.keyboardNavigationActive
                            hoverUpdatesSelection: true

                            onItemClicked: (idx, modelData) => {
                                launchBrowser(modelData)
                            }

                            onKeyboardNavigationReset: {
                                root.keyboardNavigationActive = false
                            }
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 36
                    radius: Theme.cornerRadius
                    color: Theme.withAlpha(Theme.surfaceContainerHigh, 0.5)
                    border.color: Theme.outlineMedium
                    border.width: 1

                    StyledText {
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.spacingM
                        anchors.right: parent.right
                        anchors.rightMargin: Theme.spacingM
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.url
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceTextMedium
                        elide: Text.ElideMiddle
                    }
                }
            }

            function launchBrowser(app) {
                if (!app) return

                let cmd = app.exec || ""

                // Simple replacement of %u, %U, %f, %F
                let hasField = false
                if (cmd.includes("%u")) { cmd = cmd.replace("%u", root.url); hasField = true }
                else if (cmd.includes("%U")) { cmd = cmd.replace("%U", root.url); hasField = true }
                else if (cmd.includes("%f")) { cmd = cmd.replace("%f", root.url); hasField = true }
                else if (cmd.includes("%F")) { cmd = cmd.replace("%F", root.url); hasField = true }

                // Remove other codes
                cmd = cmd.replace(/%[ikc]/g, "")

                if (!hasField) {
                    cmd += " " + root.url
                }

                console.log("BrowserPicker: Launching", cmd)

                if (app.appId) {
                    AppUsageHistoryData.addAppUsage({
                        id: app.appId,
                        name: app.name,
                        exec: app.exec,
                        execString: app.exec
                    })
                }

                Quickshell.execDetached({
                    command: ["sh", "-c", cmd]
                })
                root.close()
            }
        }
    }
}
