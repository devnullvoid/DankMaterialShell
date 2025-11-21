import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import qs.Common
import qs.Modals.Spotlight
import qs.Services

Scope {
    id: niriOverviewScope

    property bool searchActive: false
    property string searchActiveScreen: ""
    property bool overlayActive: NiriService.inOverview && !(PopoutService.spotlightModal?.spotlightOpen ?? false)

    function showSpotlight(screenName) {
        searchActive = true
        searchActiveScreen = screenName
    }

    function hideSpotlight() {
        searchActive = false
        searchActiveScreen = ""
    }

    Connections {
        target: NiriService
        function onInOverviewChanged() {
            if (!NiriService.inOverview) {
                hideSpotlight()
            } else {
                searchActive = false
                searchActiveScreen = ""
            }
        }

        function onCurrentOutputChanged() {
            if (NiriService.inOverview && searchActive && searchActiveScreen !== "" && searchActiveScreen !== NiriService.currentOutput) {
                hideSpotlight()
            }
        }
    }

    Connections {
        target: PopoutService.spotlightModal
        function onSpotlightOpenChanged() {
            if (PopoutService.spotlightModal?.spotlightOpen && searchActive) {
                hideSpotlight()
            }
        }
    }

    Loader {
        id: niriOverlayLoader
        active: overlayActive
        asynchronous: false

        sourceComponent: Variants {
            id: overlayVariants
            model: Quickshell.screens

            PanelWindow {
                id: overlayWindow
                required property var modelData

                readonly property real dpr: CompositorService.getScreenScale(screen)
                readonly property bool isActiveScreen: screen.name === NiriService.currentOutput
                readonly property bool shouldShowSpotlight: niriOverviewScope.searchActive && screen.name === niriOverviewScope.searchActiveScreen

                screen: modelData
                visible: NiriService.inOverview
                color: "transparent"

                WlrLayershell.namespace: "dms:niri-overview-spotlight"
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.exclusiveZone: -1
                WlrLayershell.keyboardFocus: {
                    if (!NiriService.inOverview) return WlrKeyboardFocus.None
                    if (!isActiveScreen) return WlrKeyboardFocus.None
                    return WlrKeyboardFocus.Exclusive
                }

                mask: Region {
                    item: shouldShowSpotlight ? spotlightContainer : null
                }

                onShouldShowSpotlightChanged: {
                    if (!shouldShowSpotlight && isActiveScreen) {
                        Qt.callLater(() => keyboardFocusScope.forceActiveFocus())
                    }
                }

                anchors {
                    top: true
                    left: true
                    right: true
                    bottom: true
                }


                FocusScope {
                    id: keyboardFocusScope
                    anchors.fill: parent
                    focus: true

                    Keys.onPressed: event => {
                        if (!overlayWindow.shouldShowSpotlight) {
                            if ([Qt.Key_Escape, Qt.Key_Return].includes(event.key)) {
                                NiriService.toggleOverview()
                                event.accepted = true
                                return
                            }

                            if (event.key === Qt.Key_Left) {
                                NiriService.moveColumnLeft()
                                event.accepted = true
                                return
                            }

                            if (event.key === Qt.Key_Right) {
                                NiriService.moveColumnRight()
                                event.accepted = true
                                return
                            }

                            if (event.key === Qt.Key_Up) {
                                NiriService.moveWorkspaceUp()
                                event.accepted = true
                                return
                            }

                            if (event.key === Qt.Key_Down) {
                                NiriService.moveWorkspaceDown()
                                event.accepted = true
                                return
                            }

                            if (event.modifiers & (Qt.ControlModifier | Qt.MetaModifier) || [Qt.Key_Delete, Qt.Key_Backspace].includes(event.key)) {
                                event.accepted = false
                                return
                            }

                            if (!event.isAutoRepeat && event.text) {
                                niriOverviewScope.showSpotlight(overlayWindow.screen.name)
                                if (spotlightContent?.searchField) {
                                    spotlightContent.searchField.text = event.text.trim()
                                    if (spotlightContent.appLauncher) {
                                        spotlightContent.appLauncher.searchQuery = event.text.trim()
                                    }
                                    Qt.callLater(() => spotlightContent.searchField.forceActiveFocus())
                                }
                                event.accepted = true
                            }
                        }
                    }
                }

                Item {
                    id: spotlightContainer
                    x: Theme.snap((parent.width - width) / 2, overlayWindow.dpr)
                    y: Theme.snap((parent.height - height) / 2, overlayWindow.dpr)
                    width: Theme.px(500, overlayWindow.dpr)
                    height: Theme.px(600, overlayWindow.dpr)

                    property real scaleValue: 0.96

                    scale: scaleValue
                    opacity: overlayWindow.shouldShowSpotlight ? 1 : 0
                    enabled: overlayWindow.shouldShowSpotlight

                    layer.enabled: true
                    layer.smooth: false
                    layer.textureSize: Qt.size(Math.round(width * overlayWindow.dpr), Math.round(height * overlayWindow.dpr))

                    Connections {
                        target: overlayWindow
                        function onShouldShowSpotlightChanged() {
                            spotlightContainer.scaleValue = overlayWindow.shouldShowSpotlight ? 1.0 : 0.96
                        }
                    }

                    Behavior on scaleValue {
                        NumberAnimation {
                            duration: Theme.expressiveDurations.expressiveDefaultSpatial
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: niriOverviewScope.searchActive ? Theme.expressiveCurves.expressiveDefaultSpatial : Theme.expressiveCurves.emphasized
                        }
                    }

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Theme.expressiveDurations.expressiveDefaultSpatial
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: niriOverviewScope.searchActive ? Theme.expressiveCurves.expressiveDefaultSpatial : Theme.expressiveCurves.emphasized
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: Theme.withAlpha(Theme.surfaceContainer, Theme.popupTransparency)
                        radius: Theme.cornerRadius
                        border.color: Theme.outlineMedium
                        border.width: 1
                    }

                    SpotlightContent {
                        id: spotlightContent
                        anchors.fill: parent
                        anchors.margins: 0

                        property var fakeParentModal: QtObject {
                            property bool spotlightOpen: overlayWindow.shouldShowSpotlight
                            function hide() {
                                niriOverviewScope.hideSpotlight()
                                if (overlayWindow.isActiveScreen) {
                                    Qt.callLater(() => keyboardFocusScope.forceActiveFocus())
                                }
                            }
                        }

                        Component.onCompleted: {
                            parentModal = fakeParentModal
                        }
                    }
                }
            }
        }
    }
}
