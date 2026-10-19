pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import qs.Common
import qs.Services
import qs.DCommon.Widgets
import qs.Widgets

Item {
    id: root

    readonly property int columns: 3
    readonly property real cardWidth: (content.width - Theme.spacingS * (columns - 1)) / columns
    readonly property var features: [
        {
            "icon": "palette",
            "shape": "softBurst",
            "hoverShape": "flower",
            "accent": "purple",
            "heading": I18n.tr("Dynamic Theming", "greeter feature card title"),
            "description": I18n.tr("Colors from wallpaper", "greeter feature card description"),
            "target": "theme"
        },
        {
            "icon": "toolbar",
            "shape": "pill",
            "hoverShape": "cookie4",
            "accent": "blue",
            "heading": I18n.tr("Bar"),
            "description": I18n.tr("Modular widget bar", "greeter feature card description"),
            "target": "dankbar_settings"
        },
        {
            "icon": "extension",
            "shape": "puffy",
            "hoverShape": "clover8",
            "accent": "green",
            "heading": I18n.tr("Plugins", "greeter feature card title"),
            "description": I18n.tr("Extensible architecture", "greeter feature card description"),
            "target": "plugins"
        },
        {
            "icon": "monitor",
            "shape": "gem",
            "hoverShape": "cookie6",
            "accent": "orange",
            "heading": I18n.tr("Multi-Monitor", "greeter feature card title"),
            "description": I18n.tr("Per-screen config", "greeter feature card description"),
            "target": CompositorService.supportsDisplayConfig ? "display_config" : "display_widgets"
        },
        {
            "icon": "nightlight",
            "shape": "sunny",
            "hoverShape": "softBurst",
            "accent": "pink",
            "heading": I18n.tr("Display Control", "greeter feature card title"),
            "description": I18n.tr("Night mode & gamma", "greeter feature card description"),
            "target": "display_gamma"
        },
        {
            "icon": "tune",
            "shape": "cookie9",
            "hoverShape": "sunny",
            "accent": "teal",
            "heading": I18n.tr("Control Center", "greeter feature card title"),
            "description": I18n.tr("Quick system toggles", "greeter feature card description"),
            "target": "control_center"
        }
    ]

    function open(target) {
        switch (target) {
        case "control_center":
            BarWidgetService.getBarWindowOnFocusedScreen()?.triggerControlCenter();
            return;
        }
        PopoutService.openSettingsWithTab(target);
    }

    DFlickable {
        anchors.fill: parent
        clip: true
        contentWidth: width
        contentHeight: Math.max(height, content.height + Theme.spacingL * 2)

        Column {
            id: content
            anchors.horizontalCenter: parent.horizontalCenter
            y: Math.max(Theme.spacingS, (parent.height - height) / 2)
            width: Math.min(640, parent.width - Theme.spacingXL * 2)
            spacing: Theme.spacingL

            ShapeHero {
                width: parent.width
                paddingV: Theme.spacingXL
                backdrop: Item {
                    DMaterialShape {
                        width: parent.height * 1.6
                        height: width
                        x: parent.width - width * 0.72
                        y: -height * 0.38
                        shape: "cookie12"
                        respectThemeShape: false
                        color: Theme.withAlpha(Theme.primary, Theme.tonalTintAlpha)
                        rotation: 10
                    }

                    DMaterialShape {
                        width: parent.height * 1.1
                        height: width
                        x: parent.width - width * 1.35
                        y: parent.height - height * 0.55
                        shape: "softBurst"
                        respectThemeShape: false
                        color: Theme.withAlpha(Theme.tertiary, Theme.tonalTintAlpha)
                        rotation: -12
                    }

                    DMaterialShape {
                        width: parent.height * 0.75
                        height: width
                        x: parent.width * 0.6
                        y: -height * 0.2
                        shape: "pill"
                        respectThemeShape: false
                        color: Theme.withAlpha(Theme.secondary, Theme.tonalTintAlpha)
                        rotation: -35
                    }
                }

                Row {
                    width: parent.width
                    spacing: Theme.spacingXL
                    LayoutMirroring.enabled: I18n.isRtl
                    LayoutMirroring.childrenInherit: true

                    Item {
                        id: logo
                        width: Theme.buttonHeightM * 1.6
                        height: width
                        anchors.verticalCenter: parent.verticalCenter

                        Image {
                            readonly property real dpr: Screen.devicePixelRatio

                            anchors.centerIn: parent
                            height: parent.height
                            width: height
                            // 2x raster plus mipmap keeps the thin rings smooth at fractional scales
                            sourceSize.height: Math.ceil(height * dpr * 2)
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                            mipmap: true
                            asynchronous: true
                            source: "file://" + Theme.shellDir + "/assets/danklogo.svg"
                            layer.enabled: true
                            layer.smooth: true
                            layer.textureSize: Qt.size(Math.ceil(width * dpr), Math.ceil(height * dpr))
                            layer.effect: MultiEffect {
                                saturation: 0
                                colorization: 1
                                colorizationColor: Theme.primary
                            }
                        }
                    }

                    Column {
                        width: parent.width - logo.width - parent.spacing
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.spacingS

                        StyledText {
                            width: parent.width
                            text: I18n.tr("Welcome to DankMaterialShell", "greeter welcome page title")
                            font.pixelSize: Theme.fontSizeXXLarge
                            font.weight: Theme.fontWeightBold
                            color: Theme.onPrimaryContainer
                            horizontalAlignment: Text.AlignLeft
                            wrapMode: Text.WordWrap
                        }

                        StyledText {
                            width: parent.width
                            text: I18n.tr("A modern desktop shell for Wayland compositors", "greeter welcome page tagline")
                            font.pixelSize: Theme.fontSizeLarge
                            color: Theme.onPrimaryContainer
                            horizontalAlignment: Text.AlignLeft
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }

            Grid {
                id: grid

                readonly property real cellHeight: {
                    let tallest = 0;
                    for (const card of children)
                        tallest = Math.max(tallest, card.implicitHeight ?? 0);
                    return tallest;
                }

                width: parent.width
                columns: root.columns
                rowSpacing: Theme.spacingS
                columnSpacing: Theme.spacingS
                layoutDirection: I18n.isRtl ? Qt.RightToLeft : Qt.LeftToRight

                Repeater {
                    model: root.features

                    delegate: FeatureCard {
                        required property var modelData

                        width: root.cardWidth
                        height: grid.cellHeight
                        iconName: modelData.icon
                        shape: modelData.shape
                        hoverShape: modelData.hoverShape
                        accent: modelData.accent
                        heading: modelData.heading
                        description: modelData.description
                        onClicked: root.open(modelData.target)
                    }
                }
            }
        }
    }
}
