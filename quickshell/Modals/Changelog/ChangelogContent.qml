pragma ComponentBehavior: Bound

import QtQuick
import qs.Common
import qs.Services
import qs.DCommon.Widgets
import qs.Widgets
import qs.Modules.Settings.Widgets

Column {
    id: root

    readonly property string pluginDocsUrl: Site.docs + "/dms/plugin-development"
    readonly property string compositorDocsUrl: Site.docs + "/dms/compositors"

    readonly property var features: [
        {
            "icon": "palette",
            "shape": "softBurst",
            "hoverShape": "flower",
            "accent": "purple",
            "heading": "A new design",
            "description": "Material 3 Expressive across Settings, Control Center, Dash, and every control",
            "target": "theme_surfaces"
        },
        {
            "icon": "space_dashboard",
            "shape": "cookie9",
            "hoverShape": "sunny",
            "accent": "blue",
            "heading": "Dash plugins",
            "description": "Plugins add full tabs or overview cards, sized and ordered your way",
            "target": "dank_dash"
        },
        {
            "icon": "lock",
            "shape": "clover4",
            "hoverShape": "cookie4",
            "accent": "green",
            "heading": "Build your lock screen",
            "description": "Place the clock, media, status, and any desktop widget where you want",
            "target": "lock_screen"
        },
        {
            "icon": "lyrics",
            "shape": "sunny",
            "hoverShape": "softBurst",
            "accent": "pink",
            "heading": "Lyrical Engine",
            "description": "Word synced lyrics from six providers, right in the media player",
            "target": "media_player"
        },
        {
            "icon": "wallpaper",
            "shape": "gem",
            "hoverShape": "cookie6",
            "accent": "orange",
            "heading": "Material wallpapers",
            "description": "Presets from your seed color, plus layouts from wallpaper.danklinux.com",
            "target": "personalization"
        },
        {
            "icon": "digital_wellbeing",
            "shape": "puffy",
            "hoverShape": "clover8",
            "accent": "teal",
            "heading": "Digital wellbeing",
            "description": "Screen time, daily and app limits, with its own Dash tab",
            "target": "wellbeing"
        }
    ]

    readonly property var additions: [
        {
            "icon": "view_in_ar",
            "accent": "purple",
            "title": "Island",
            "subtitle": "Notch mode, workspace switcher, tray slot, clipboard, and shadows",
            "target": "dankbar_settings"
        },
        {
            "icon": "grid_view",
            "accent": "green",
            "title": "Launcher",
            "subtitle": "Custom keybindings, dmenu mode, Open with, and app editing",
            "target": "launcher"
        },
        {
            "icon": "dock_to_bottom",
            "accent": "orange",
            "title": "Dock",
            "subtitle": "Proximity magnification and a focused app pill",
            "target": "dock_appearance"
        },
        {
            "icon": "notifications",
            "accent": "pink",
            "title": "Notifications",
            "subtitle": "Rule conditions, timed app mutes, and two finger swipe to dismiss",
            "target": "notification_rules"
        },
        {
            "icon": "extension",
            "accent": "teal",
            "title": "Plugin browser",
            "subtitle": "Discover shelves, quick filters, upvotes, and typo tolerant search",
            "target": "plugins"
        },
        {
            "icon": "format_paint",
            "accent": "yellow",
            "title": "Themes",
            "subtitle": "Bold palettes, injected palettes, fixed radius, and terminal opacity",
            "target": "theme"
        },
        {
            "icon": "monitor",
            "accent": "red",
            "title": "Displays",
            "subtitle": "Per-output ICC profiles and color temperature",
            "target": "display_config"
        },
        {
            "icon": "system_update_alt",
            "accent": "blue",
            "title": "Software updates",
            "subtitle": "Update dms from Settings and switch between stable and beta",
            "target": "updater"
        },
        {
            "icon": "devices",
            "accent": "green",
            "title": "More platforms",
            "subtitle": "FreeBSD, Enterprise Linux 10, Mango, Hyprland 0.56, Umbriel, and Aqueous",
            "target": root.compositorDocsUrl
        }
    ]

    readonly property var featurePairs: {
        const pairs = [];
        for (let i = 0; i < features.length; i += 2)
            pairs.push(features.slice(i, i + 2));
        return pairs;
    }

    function open(target) {
        if (target.startsWith("https://")) {
            Qt.openUrlExternally(target);
            return;
        }
        PopoutService.openSettingsWithTab(target);
    }

    topPadding: Theme.spacingS
    spacing: Theme.spacingL

    ChangelogHero {
        width: parent.width
        symbol: "He"
        atomicNumber: 2
        atomicMass: "4.0026"
        remainder: "isenberg"
    }

    Column {
        width: parent.width
        spacing: Theme.spacingS

        Repeater {
            model: root.featurePairs

            delegate: Row {
                id: pair

                required property var modelData
                required property int index

                readonly property real cardWidth: (width - spacing) / 2
                readonly property real rowHeight: Math.max(first.implicitHeight, second.implicitHeight)

                width: parent.width
                spacing: Theme.spacingS
                LayoutMirroring.enabled: I18n.isRtl

                FeatureCard {
                    id: first
                    width: pair.cardWidth
                    height: pair.rowHeight
                    iconName: pair.modelData[0].icon
                    shape: pair.modelData[0].shape
                    hoverShape: pair.modelData[0].hoverShape
                    accent: pair.modelData[0].accent
                    heading: pair.modelData[0].heading
                    description: pair.modelData[0].description
                    onClicked: root.open(pair.modelData[0].target)
                }

                FeatureCard {
                    id: second
                    width: pair.cardWidth
                    height: pair.rowHeight
                    iconName: pair.modelData[1].icon
                    shape: pair.modelData[1].shape
                    hoverShape: pair.modelData[1].hoverShape
                    accent: pair.modelData[1].accent
                    heading: pair.modelData[1].heading
                    description: pair.modelData[1].description
                    onClicked: root.open(pair.modelData[1].target)
                }
            }
        }
    }

    SettingsCard {
        title: "More in " + ChangelogService.currentVersion

        Repeater {
            model: root.additions

            delegate: SettingsRow {
                id: addition

                required property var modelData

                readonly property var accentPair: Theme.accent(modelData.accent)

                title: modelData.title
                subtitle: modelData.subtitle
                resetKeys: []
                clickable: modelData.target !== ""
                showChevron: clickable
                onClicked: root.open(modelData.target)

                leading: Rectangle {
                    width: SettingsMetrics.navIconSize
                    height: width
                    radius: Theme.fullRadius(width, height)
                    color: addition.accentPair?.container ?? Theme.primaryContainer

                    DIcon {
                        anchors.centerIn: parent
                        name: addition.modelData.icon
                        size: Theme.iconSizeMedium
                        color: addition.accentPair?.onContainer ?? Theme.onPrimaryContainer
                    }
                }
            }
        }
    }

    DCard {
        width: parent.width
        height: pluginNote.implicitHeight + pad * 2
        tone: "tertiary"
        pad: Theme.spacingL
        restRadius: Theme.groupedListOuterRadius

        Row {
            id: pluginNote
            width: parent.width
            spacing: Theme.spacingL
            LayoutMirroring.enabled: I18n.isRtl

            DMaterialShape {
                width: Theme.buttonHeightM
                height: width
                shape: "cookie6"
                color: Theme.onTertiaryContainer

                DIcon {
                    anchors.centerIn: parent
                    name: "code"
                    size: Theme.iconSize
                    color: Theme.tertiaryContainer
                }
            }

            Column {
                width: parent.width - Theme.buttonHeightM - docsButton.width - parent.spacing * 2
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.spacingXXS

                StyledText {
                    width: parent.width
                    text: "Plugin authors"
                    font.pixelSize: Theme.fontSizeLarge
                    font.weight: Theme.fontWeightBold
                    color: Theme.onTertiaryContainer
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignLeft
                }

                StyledText {
                    width: parent.width
                    text: "The Dank* widget wrappers are deprecated. Import qs.DCommon.Widgets and use the D names, DankButton becomes DButton. Each old type logs its replacement."
                    font.pixelSize: Theme.fontSizeMedium
                    color: Theme.onTertiaryContainer
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignLeft
                }
            }

            DButton {
                id: docsButton
                anchors.verticalCenter: parent.verticalCenter
                text: I18n.tr("Docs")
                iconName: "open_in_new"
                backgroundColor: Theme.onTertiaryContainer
                textColor: Theme.tertiaryContainer
                onClicked: Qt.openUrlExternally(root.pluginDocsUrl)
            }
        }
    }

    Column {
        width: parent.width
        visible: ChangelogService.release !== null
        spacing: 0

        SettingsSectionLabel {
            text: I18n.tr("What changed", "changelog section heading listing the changes in a release")
        }

        ReleaseNotesCard {
            width: parent.width
            release: ChangelogService.release
            showTitle: false
        }
    }
}
