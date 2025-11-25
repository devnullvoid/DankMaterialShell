import QtQuick
import Quickshell
import qs.Common
import qs.Modals.Common
import qs.Widgets
import qs.Services

DankModal {
    id: root

    property string url: ""
    property int selectedIndex: 0
    property int gridColumns: 4
    property bool keyboardNavigationActive: false

    shouldBeVisible: false
    allowStacking: true
    modalWidth: 620
    modalHeight: 450

    onDialogClosed: {
        url = ""
        selectedIndex = 0
        keyboardNavigationActive = false
    }

    onOpened: {
        browsersModel.clear()
        const apps = AppSearchService.applications
        let browserCount = 0

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
                browsersModel.append({
                    name: app.name || "",
                    icon: app.icon || "web-browser",
                    exec: app.exec || app.execString || "",
                    startupClass: app.startupWMClass || ""
                })
                browserCount++
            }
        }

        console.log("BrowserPicker: Found " + browserCount + " browsers")
        selectedIndex = 0
        if (browserCount > 0) {
            browserContent.forceActiveFocus()
        }
    }

    ListModel {
        id: browsersModel
    }

    content: Component {
        FocusScope {
            id: browserContent
            anchors.fill: parent
            focus: true

            Keys.onEscapePressed: event => {
                root.close()
                event.accepted = true
            }

            Keys.onPressed: event => {
                if (browsersModel.count === 0) return

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
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    if (root.selectedIndex >= 0 && root.selectedIndex < browsersModel.count) {
                        const browser = browsersModel.get(root.selectedIndex)
                        launchBrowser(browser)
                    }
                    event.accepted = true
                }
            }

            Item {
                anchors.fill: parent
                anchors.margins: Theme.spacingM

                Column {
                    id: headerCol
                    width: parent.width
                    spacing: Theme.spacingXS

                    StyledText {
                        text: I18n.tr("Open with...")
                        font.pixelSize: Theme.fontSizeLarge
                        font.weight: Font.Bold
                        color: Theme.surfaceText
                    }

                    StyledText {
                        text: root.url
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceTextMedium
                        elide: Text.ElideMiddle
                        width: parent.width
                    }
                }

                DankGridView {
                    id: browserGrid
                    anchors.top: headerCol.bottom
                    anchors.topMargin: Theme.spacingM
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom

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
            
            DankActionButton {
                anchors.top: parent.top
                anchors.right: parent.right
                iconName: "close"
                onClicked: root.close()
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
                
                Quickshell.execDetached({
                    command: ["sh", "-c", cmd]
                })
                root.close()
            }
        }
    }
}
