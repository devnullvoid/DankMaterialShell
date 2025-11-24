import QtQuick
import Quickshell
import qs.Common
import qs.Modals.Common
import qs.Widgets
import qs.Services

DankModal {
    id: root

    property string url: ""

    shouldBeVisible: false
    allowStacking: true
    modalWidth: 600
    modalHeight: 400

    property var browsers: []

    onOpened: {
        browsers = AppSearchService.applications.filter(app => {
            if (app.noDisplay) return false
            const categories = AppSearchService.getCategoriesForApp(app)
            // Filter for WebBrowser category
            return app.categories && (app.categories.includes("WebBrowser") || app.categories.includes("X-WebBrowser"))
        })
    }
    
    onClosed: {
        url = ""
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

            Column {
                anchors.fill: parent
                anchors.margins: Theme.spacingM
                spacing: Theme.spacingM

                StyledText {
                    text: I18n.tr("Open with...")
                    font.pixelSize: Theme.fontSizeLarge
                    font.weight: Font.Bold
                }
                
                StyledText {
                    text: root.url
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceTextMedium
                    elide: Text.ElideMiddle
                    width: parent.width
                }

                DankGridView {
                    id: browserGrid
                    width: parent.width
                    height: parent.height - y
                    model: root.browsers
                    cellWidth: 100
                    cellHeight: 110
                    
                    delegate: Item {
                        width: browserGrid.cellWidth
                        height: browserGrid.cellHeight
                        
                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 4
                            radius: Theme.cornerRadius
                            color: mouseArea.containsMouse ? Theme.surfaceContainerHigh : "transparent"
                            
                            MouseArea {
                                id: mouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    launchBrowser(modelData)
                                }
                            }
                        }

                        Column {
                            anchors.centerIn: parent
                            spacing: 8
                            
                            DankIcon {
                                name: modelData.icon
                                size: 48
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                            
                            StyledText {
                                text: modelData.name
                                font.pixelSize: Theme.fontSizeSmall
                                horizontalAlignment: Text.AlignHCenter
                                width: parent.width - 8
                                wrapMode: Text.Wrap
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
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
