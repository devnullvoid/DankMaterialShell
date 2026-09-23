import QtQuick
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Settings.Widgets

Item {
    id: root

    readonly property var barLengthModes: ["full", "percent", "fit"]

    LayoutMirroring.enabled: I18n.isRtl
    LayoutMirroring.childrenInherit: true

    property var parentModal: null
    readonly property bool widgetBackgroundEnabled: !(bar.selectedBarConfig?.noBackground ?? false)
    readonly property var outlineColors: ["surfaceText", "secondary", "primary"]
    readonly property var outlineColorLabels: [I18n.tr("Surface"), I18n.tr("Secondary"), I18n.tr("Primary")]
    readonly property var paletteValues: ["default", "bright", "dim"]
    readonly property var batteryStyleValues: ["solid", "outline", "ring"]
    readonly property var satellitePositionValues: ["island", "edges"]
    readonly property bool isDot: SettingsData.isDotBarConfig(bar.selectedBarConfig)
    readonly property bool selectedIslandEnabled: bar.selectedBarIsIsland && (bar.selectedBarConfig?.enabled ?? false)
    readonly property bool selectedIslandFree: bar.selectedBarIsIsland && SettingsData.islandFreePlacement(bar.selectedBarConfig)
    readonly property int frameInsetPaddingDisplay: Math.round(SettingsData.frameBarContentGap)

    function valueIndex(values, value, fallback) {
        const index = values.indexOf(value);
        return index >= 0 ? index : Math.max(0, values.indexOf(fallback));
    }

    BarSelectionState {
        id: bar
    }

    SettingsPage {
        id: mainColumn

        SettingsCard {
            iconName: "border_outer"
            title: I18n.tr("Frame")
            settingKey: "frameBorder"
            collapsible: true
            visible: !root.isDot && SettingsData.frameEnabled

            SettingsSliderRow {
                settingKey: "frameRounding"
                tags: ["frame", "border", "rounding", "radius", "corner"]
                text: I18n.tr("Radius", "corner radius slider label")
                unit: "px"
                minimum: 0
                maximum: 100
                step: 1
                value: SettingsData.frameRounding
                onSliderDragFinished: v => SettingsData.set("frameRounding", v)
            }

            SettingsSliderRow {
                settingKey: "frameThickness"
                tags: ["frame", "border", "thickness", "size", "width"]
                text: I18n.tr("Width")
                unit: "px"
                minimum: 2
                maximum: 100
                step: 1
                value: SettingsData.frameThickness
                onSliderDragFinished: v => SettingsData.set("frameThickness", v)
            }

            SettingsSliderRow {
                settingKey: "frameBarSize"
                tags: ["frame", "bar", "thickness", "size", "height", "width"]
                text: I18n.tr("Bar size")
                unit: "px"
                minimum: 24
                maximum: 100
                step: 1
                value: SettingsData.frameBarSize
                onSliderDragFinished: v => SettingsData.set("frameBarSize", v)
            }

            SettingsSliderRow {
                settingKey: "frameBarInsetPadding"
                tags: ["frame", "bar", "edge", "inset", "padding", "corner", "end"]
                text: I18n.tr("Bar inset padding")
                minimumLabel: I18n.tr("Edge to edge", "slider minimum label, bar touches the screen edges")
                unit: "px"
                minimum: 0
                maximum: 48
                step: 1
                value: root.frameInsetPaddingDisplay
                onSliderDragFinished: v => SettingsData.set("frameBarInsetPadding", v)
            }

            SettingsToggleRow {
                id: frameBlurToggle
                settingKey: "frameBlurEnabled"
                tags: ["frame", "blur", "background", "glass", "transparency", "frosted"]
                text: I18n.tr("Blur")
                checked: SettingsData.frameBlurEnabled
                onToggled: checked => SettingsData.set("frameBlurEnabled", checked)
                enabled: BlurService.available && SettingsData.blurEnabled
                visible: BlurService.available
            }

            SettingsRow {
                visible: BlurService.available && !SettingsData.blurEnabled
                body: Item {
                    width: parent.width
                    height: blurToggleNote.height + Theme.spacingM * 2

                    Row {
                        id: blurToggleNote
                        x: Theme.spacingM
                        width: parent.width - Theme.spacingM * 2
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.spacingS

                        DankIcon {
                            name: "blur_on"
                            size: Theme.fontSizeMedium
                            color: Theme.primary
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        StyledText {
                            text: I18n.tr("Frame Blur follows Background Blur in Theme & Colors")
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceVariantText
                            wrapMode: Text.WordWrap
                            width: parent.width - Theme.fontSizeMedium - Theme.spacingS
                        }
                    }
                }
            }
        }

        SettingsCard {
            iconName: "rounded_corner"
            title: !root.isDot ? I18n.tr("Bar") : I18n.tr("Dot", "bar layout: free-floating dot that opens island activities")
            settingKey: "barCorners"
            tags: ["background", "opacity", "corners", "rounded", "goth", "shadow"]
            // Frame styling never reaches the dot's surface, which always paints its own palette and background.
            visible: (bar.selectedBarConfig?.enabled ?? false) && (root.isDot || !bar.selectedBarFrameStyled)

            SettingsButtonGroupRow {
                settingKey: "islandPalette"
                tags: ["island", "appearance", "palette", "surface", "bright", "dim"]
                visible: bar.selectedBarIsIsland
                resetStore: bar
                resetKeys: ["islandPalette"]
                text: I18n.tr("Palette", "island settings: surface tone choice")
                model: [I18n.tr("Default", "island settings: default surface tone"), I18n.tr("Bright", "island settings: bright surface tone"), I18n.tr("Dim", "island settings: dim surface tone")]
                currentIndex: root.valueIndex(root.paletteValues, bar.islandSetting("islandPalette"), "default")
                onSelectionChanged: (index, selected) => {
                    if (selected)
                        bar.apply("islandPalette", root.paletteValues[index] ?? "default");
                }
            }

            SettingsToggleRow {
                settingKey: "islandHighContrast"
                tags: ["island", "appearance", "contrast", "accessibility", "outline"]
                visible: bar.selectedBarIsIsland
                resetStore: bar
                resetKeys: ["islandHighContrast"]
                text: I18n.tr("High contrast", "island settings: high contrast toggle")
                checked: bar.islandSetting("islandHighContrast")
                onToggled: checked => bar.apply("islandHighContrast", checked)
            }

            SettingsButtonGroupRow {
                settingKey: "islandBatteryStyle"
                tags: ["island", "battery", "gauge", "solid", "outline", "ring", "circle", "appearance"]
                resetStore: bar
                resetKeys: ["islandBatteryStyle"]
                text: I18n.tr("Battery style", "island settings: battery meter style row")
                visible: bar.selectedBarIsIsland && !root.isDot && SettingsData.islandHomeGroupEnabled(bar.selectedBarConfig, "status") && BatteryService.batteryAvailable && SettingsData.islandHomeStatusContent(bar.selectedBarConfig) === "battery"
                model: [I18n.tr("Solid", "island settings: filled battery meter style"), I18n.tr("Outline", "island settings: outlined battery meter style"), I18n.tr("Circle", "island settings: circular battery meter style")]
                currentIndex: root.valueIndex(root.batteryStyleValues, bar.islandSetting("islandBatteryStyle"), "solid")
                onSelectionChanged: (index, selected) => {
                    if (selected)
                        bar.apply("islandBatteryStyle", root.batteryStyleValues[index] ?? "solid");
                }
            }

            SettingsButtonGroupRow {
                settingKey: "islandBatteryColorMode"
                tags: ["island", "battery", "color", "level", "theme", "meter", "accent", "green", "red"]
                resetStore: bar
                resetKeys: ["batteryColorMode"]
                text: I18n.tr("Battery")
                visible: bar.selectedBarIsIsland && !root.isDot && SettingsData.islandHomeGroupEnabled(bar.selectedBarConfig, "status") && BatteryService.batteryAvailable && SettingsData.islandHomeStatusContent(bar.selectedBarConfig) === "battery"
                model: [I18n.tr("Theme", "battery settings: theme accent indicator colors"), I18n.tr("Level", "battery settings: charge level indicator colors")]
                currentIndex: (bar.selectedBarConfig?.batteryColorMode ?? "theme") === "level" ? 1 : 0
                onSelectionChanged: (index, selected) => {
                    if (selected)
                        bar.apply("batteryColorMode", index === 1 ? "level" : "theme");
                }
            }

            SurfaceColorRow {
                settingKey: "barSurfaceColor"
                tags: ["background", "color", "surface", "bar", "material"]
                visible: root.isDot || !bar.selectedBarFrameStyled
                resetStore: bar
                resetKeys: ["surfaceColor", "surfaceCustomColor"]
                text: I18n.tr("Background")
                defaultColor: Theme.hostSurface
                currentMode: bar.selectedBarConfig?.surfaceColor ?? "default"
                customColor: bar.selectedBarConfig?.surfaceCustomColor ?? SettingsData.barConfigDefault("surfaceCustomColor")
                pickerTitle: I18n.tr("Background")
                onModeSelected: mode => bar.apply("surfaceColor", mode)
                onCustomColorSelected: selectedColor => bar.apply("surfaceCustomColor", selectedColor.toString())
            }

            SettingsControlledBy {
                visible: !root.isDot && !bar.selectedBarFrameStyled && !bar.islandOwnsSelectedBarTop
                target: "surfaces"
                parentModal: root.parentModal
                section: "surfaceOpacity_bar_" + bar.selectedBarId
                settingLabel: I18n.tr("Opacity")
            }

            SettingsSliderRow {
                settingKey: "dotOpacity"
                tags: ["dot", "opacity", "transparency", "background"]
                visible: root.isDot
                resetStore: bar
                resetKeys: ["transparency"]
                text: I18n.tr("Opacity")
                minimum: 0
                maximum: 100
                step: 1
                value: Math.round(SettingsData.barTransparency(bar.selectedBarConfig) * 100)
                onSliderDragFinished: finalValue => SettingsData.updateBarConfig(bar.selectedBarId, {
                        followInterfaceStyle: false,
                        transparency: finalValue / 100
                    })
            }

            SettingsSliderRow {
                settingKey: "islandFreeIdleOpacity"
                tags: ["island", "free", "dot", "idle", "opacity", "fade"]
                visible: root.isDot
                resetStore: bar
                resetKeys: ["islandFreeIdleOpacity"]
                text: I18n.tr("Idle opacity", "island settings: dot opacity while idle")
                unit: "%"
                minimum: 5
                maximum: 100
                step: 1
                value: Math.round(bar.islandSetting("islandFreeIdleOpacity") * 100)
                enabled: bar.islandSetting("islandFreeIdleDelay") > 0
                onSliderValueChanged: value => bar.apply("islandFreeIdleOpacity", value / 100)
            }

            SettingsButtonGroupRow {
                settingKey: "barCornerStyle"
                tags: ["rounded", "attached", "square", "corners", "edge", "screen", "flush"]
                text: I18n.tr("Corner style")
                visible: !bar.selectedBarFrameSanitized && !bar.islandOwnsSelectedBarTop
                resetStore: bar
                resetKeys: ["squareCorners", "attachToScreenEdge"]
                model: [I18n.tr("Rounded", "bar corner style option"), I18n.tr("Flush", "bar corner style option"), I18n.tr("Square", "bar corner style option")]
                currentIndex: {
                    if (bar.selectedBarConfig?.squareCorners ?? false)
                        return 2;
                    if (bar.selectedBarConfig?.attachToScreenEdge ?? false)
                        return 1;
                    return 0;
                }
                onSelectionChanged: (index, selected) => {
                    if (!selected)
                        return;
                    SettingsData.updateBarConfig(bar.selectedBarId, {
                        squareCorners: index === 2,
                        attachToScreenEdge: index === 1
                    });
                }
            }

            SettingsToggleRow {
                settingKey: "barGothCorners"
                tags: ["goth", "corners", "concave", "cutout"]
                text: I18n.tr("Goth corners")
                visible: !bar.selectedBarFrameSanitized && !bar.islandOwnsSelectedBarTop
                resetStore: bar
                resetKeys: ["gothCornersEnabled"]
                checked: bar.selectedBarConfig?.gothCornersEnabled ?? false
                onToggled: checked => SettingsData.updateBarConfig(bar.selectedBarId, {
                        gothCornersEnabled: checked
                    })
            }

            SettingsToggleRow {
                text: I18n.tr("Custom radius")
                tags: ["goth", "corners", "radius"]
                visible: (bar.selectedBarConfig?.gothCornersEnabled ?? false) && !bar.selectedBarFrameSanitized && !bar.islandOwnsSelectedBarTop
                resetStore: bar
                resetKeys: ["gothCornerRadiusOverride"]
                checked: bar.selectedBarConfig?.gothCornerRadiusOverride ?? false
                onToggled: checked => SettingsData.updateBarConfig(bar.selectedBarId, {
                        gothCornerRadiusOverride: checked
                    })
            }

            SettingsSliderRow {
                visible: (bar.selectedBarConfig?.gothCornersEnabled ?? false) && (bar.selectedBarConfig?.gothCornerRadiusOverride ?? false) && !bar.selectedBarFrameSanitized && !bar.islandOwnsSelectedBarTop
                text: I18n.tr("Radius")
                unit: "px"
                resetStore: bar
                resetKeys: ["gothCornerRadiusValue"]
                value: bar.selectedBarConfig?.gothCornerRadiusValue ?? 12
                minimum: 0
                maximum: 64
                onSliderDragFinished: finalValue => SettingsData.updateBarConfig(bar.selectedBarId, {
                        gothCornerRadiusValue: finalValue
                    })
            }

            SettingsControlledBy {
                visible: !bar.selectedBarFrameSanitized && !bar.islandOwnsSelectedBarTop
                target: "shadows"
                parentModal: root.parentModal
                section: "barShadow"
                settingLabel: I18n.tr("Shadow", "bar shadow settings card")
            }
        }

        SettingsToggleCard {
            settingKey: "barBorder"
            iconName: "border_style"
            title: I18n.tr("Border", "noun, settings toggle card title for an outline around a surface")
            visible: (bar.selectedBarConfig?.enabled ?? false) && !bar.selectedBarFrameSanitized && !bar.islandOwnsSelectedBarTop
            resetStore: bar
            resetKeys: ["borderEnabled"]
            checked: bar.selectedBarConfig?.borderEnabled ?? false
            onToggled: checked => SettingsData.updateBarConfig(bar.selectedBarId, {
                    borderEnabled: checked
                })

            SettingsButtonGroupRow {
                text: I18n.tr("Color")
                resetStore: bar
                resetKeys: ["borderColor"]
                model: root.outlineColorLabels
                currentIndex: Math.max(0, root.outlineColors.indexOf(bar.selectedBarConfig?.borderColor || "surfaceText"))
                onSelectionChanged: (index, selected) => {
                    if (!selected)
                        return;
                    SettingsData.updateBarConfig(bar.selectedBarId, {
                        borderColor: root.outlineColors[index]
                    });
                }
            }

            SettingsSliderRow {
                text: I18n.tr("Opacity")
                resetStore: bar
                resetKeys: ["borderOpacity"]
                value: (bar.selectedBarConfig?.borderOpacity ?? 1.0) * 100
                minimum: 0
                maximum: 100
                onSliderDragFinished: finalValue => SettingsData.updateBarConfig(bar.selectedBarId, {
                        borderOpacity: finalValue / 100
                    })
            }

            SettingsSliderRow {
                text: I18n.tr("Thickness")
                resetStore: bar
                resetKeys: ["borderThickness"]
                value: bar.selectedBarConfig?.borderThickness ?? 1
                minimum: 1
                maximum: 10
                unit: "px"
                onSliderDragFinished: finalValue => SettingsData.updateBarConfig(bar.selectedBarId, {
                        borderThickness: finalValue
                    })
            }
        }

        SettingsCard {
            iconName: "space_bar"
            title: I18n.tr("Size & spacing")
            settingKey: "barSpacing"
            tags: ["size", "scale", "font", "icon", "spacing", "padding", "inset", "length"]
            visible: (bar.selectedBarConfig?.enabled ?? false) && !root.isDot

            SettingsSliderRow {
                settingKey: "islandReserveThickness"
                tags: ["island", "placement", "reservation", "exclusive", "height", "width", "thickness"]
                visible: bar.selectedBarIsIsland && !root.selectedIslandFree
                resetStore: bar
                resetKeys: ["islandReserveThickness"]
                text: bar.selectedBarIsVertical ? I18n.tr("Reserved width", "island settings: reserved strip width slider") : I18n.tr("Reserved height", "island settings: reserved strip height slider")
                unit: "px"
                minimum: 24
                maximum: 128
                step: 1
                value: bar.islandSetting("islandReserveThickness")
                enabled: !bar.islandSetting("islandFloating")
                onSliderValueChanged: value => bar.apply("islandReserveThickness", value)
            }

            SettingsSliderRow {
                settingKey: "islandCompactThickness"
                tags: ["island", "placement", "compact", "height", "width", "thickness", "size", "satellite"]
                visible: bar.selectedBarIsIsland && !root.selectedIslandFree
                resetStore: bar
                resetKeys: ["islandCompactThickness"]
                text: bar.selectedBarIsVertical ? I18n.tr("Compact width", "island settings: compact pill width slider") : I18n.tr("Compact height", "island settings: compact pill height slider")
                unit: "px"
                minimum: 24
                maximum: 72
                step: 1
                value: bar.islandSetting("islandCompactThickness")
                onSliderValueChanged: value => bar.apply("islandCompactThickness", value)
            }

            SettingsSliderRow {
                settingKey: "islandOuterGap"
                tags: ["island", "placement", "gap", "top", "margin"]
                visible: bar.selectedBarIsIsland && !root.selectedIslandFree
                resetStore: bar
                resetKeys: ["islandOuterGap"]
                text: I18n.tr("Outer gap", "island settings: gap between screen edge and island")
                unit: "px"
                minimum: 0
                maximum: 48
                step: 1
                value: bar.islandSetting("islandOuterGap")
                onSliderValueChanged: value => bar.apply("islandOuterGap", value)
            }

            SettingsSliderRow {
                settingKey: "islandAlongOffset"
                tags: ["island", "placement", "horizontal", "vertical", "offset", "center"]
                visible: bar.selectedBarIsIsland && !root.selectedIslandFree
                resetStore: bar
                resetKeys: ["islandAlongOffset"]
                text: bar.selectedBarIsVertical ? I18n.tr("Vertical offset", "island settings: vertical offset slider") : I18n.tr("Horizontal offset", "island settings: horizontal offset slider")
                unit: "px"
                minimum: -600
                maximum: 600
                step: 1
                value: bar.islandSetting("islandAlongOffset")
                onSliderValueChanged: value => bar.apply("islandAlongOffset", value)
            }

            SettingsSliderRow {
                settingKey: "barSize"
                tags: ["size", "thickness", "height", "inner"]
                visible: !bar.selectedBarFrameStyled
                text: I18n.tr("Size")
                resetStore: bar
                resetKeys: ["innerPadding"]
                value: bar.selectedBarConfig?.innerPadding ?? 4
                minimum: -8
                maximum: 24
                unit: "px"
                onSliderDragFinished: finalValue => SettingsData.updateBarConfig(bar.selectedBarId, {
                        innerPadding: finalValue
                    })
            }

            SettingsSliderRow {
                settingKey: "barFontScale"
                tags: ["font", "text", "scale", "size"]
                text: I18n.tr("Font scale")
                resetStore: bar
                resetKeys: ["fontScale"]
                value: Math.round((bar.selectedBarConfig?.fontScale ?? 1.0) * 100)
                minimum: 50
                maximum: 200
                onSliderValueChanged: newValue => SettingsData.updateBarConfig(bar.selectedBarId, {
                        fontScale: newValue / 100
                    })
            }

            SettingsSliderRow {
                settingKey: "barIconScale"
                tags: ["icon", "scale", "size"]
                text: I18n.tr("Icon scale")
                resetStore: bar
                resetKeys: ["iconScale"]
                value: Math.round((bar.selectedBarConfig?.iconScale ?? 1.0) * 100)
                minimum: 50
                maximum: 200
                onSliderValueChanged: newValue => SettingsData.updateBarConfig(bar.selectedBarId, {
                        iconScale: newValue / 100
                    })
            }

            SettingsSliderRow {
                visible: !bar.selectedBarFrameStyled && !bar.islandOwnsSelectedBarTop
                text: I18n.tr("Edge spacing")
                tags: ["edge", "spacing", "gap", "margin"]
                resetStore: bar
                resetKeys: ["spacing"]
                value: bar.selectedBarConfig?.spacing ?? 4
                minimum: 0
                maximum: 32
                unit: "px"
                onSliderDragFinished: finalValue => SettingsData.updateBarConfig(bar.selectedBarId, {
                        spacing: finalValue
                    })
            }

            SettingsButtonGroupRow {
                settingKey: "barLengthMode"
                tags: ["bar", "width", "height", "length", "fit", "full", "custom", "percent", "compact", "widgets", "hug", "shrink"]
                text: bar.selectedBarIsVertical ? I18n.tr("Height") : I18n.tr("Width")
                visible: !bar.selectedBarFrameStyled && !bar.islandOwnsSelectedBarTop
                resetStore: bar
                resetKeys: ["barLengthMode", "barLengthPercent"]
                model: [I18n.tr("Full", "bar length option, the bar spans the whole edge"), I18n.tr("Custom", "bar length option, the bar spans a percentage of the edge"), I18n.tr("Fit", "bar length option, the bar spans only its widgets")]
                currentIndex: Math.max(0, root.barLengthModes.indexOf(bar.selectedBarConfig?.barLengthMode ?? "full"))
                onSelectionChanged: (index, selected) => {
                    if (!selected)
                        return;
                    SettingsData.updateBarConfig(bar.selectedBarId, {
                        barLengthMode: root.barLengthModes[index] ?? "full"
                    });
                }
            }

            SettingsSliderRow {
                settingKey: "barLengthPercent"
                tags: ["bar", "width", "height", "length", "percent", "custom"]
                visible: !bar.selectedBarFrameStyled && !bar.islandOwnsSelectedBarTop && (bar.selectedBarConfig?.barLengthMode ?? "full") === "percent"
                text: I18n.tr("Percentage")
                resetStore: bar
                resetKeys: ["barLengthPercent"]
                unit: "%"
                minimum: 10
                maximum: 100
                value: bar.selectedBarConfig?.barLengthPercent ?? 80
                onSliderDragFinished: finalValue => SettingsData.updateBarConfig(bar.selectedBarId, {
                        barLengthPercent: finalValue
                    })
            }

            SettingsSliderRow {
                settingKey: "barLengthPadding"
                visible: !bar.selectedBarFrameStyled && !bar.islandOwnsSelectedBarTop && (bar.selectedBarConfig?.barLengthMode ?? "full") === "full"
                text: I18n.tr("Length padding")
                tags: ["bar", "length", "padding", "size", "shorter", "ends"]
                resetStore: bar
                resetKeys: ["barLengthPadding"]
                unit: "px"
                minimum: 0
                maximum: 512
                value: bar.selectedBarConfig?.barLengthPadding ?? 0
                onSliderDragFinished: finalValue => SettingsData.updateBarConfig(bar.selectedBarId, {
                        barLengthPadding: finalValue
                    })
            }

            SettingsSliderRow {
                visible: !bar.selectedBarFrameStyled
                text: I18n.tr("Inset padding")
                tags: ["bar", "padding", "inset", "edge", "corner", "end", "gap"]
                minimumLabel: I18n.tr("Edge to edge", "slider minimum label, bar touches the screen edges")
                resetStore: SettingsData.barInsetPaddingSyncAll ? SettingsData : bar
                resetKeys: SettingsData.barInsetPaddingSyncAll ? ["barInsetPaddingShared"] : ["barInsetPadding"]
                unit: "px"
                minimum: 0
                maximum: 48
                value: bar.insetPadDisplayValue
                onSliderDragFinished: finalValue => {
                    if (SettingsData.barInsetPaddingSyncAll) {
                        SettingsData.set("barInsetPaddingShared", finalValue);
                        return;
                    }
                    SettingsData.updateBarConfig(bar.selectedBarId, {
                        barInsetPadding: finalValue
                    });
                }
            }

            SettingsToggleRow {
                visible: !bar.selectedBarFrameStyled && SettingsData.barConfigs.length > 1
                text: I18n.tr("Sync inset padding")
                tags: ["bar", "padding", "inset", "edge", "sync", "all", "global"]
                resetKeys: ["barInsetPaddingSyncAll"]
                checked: SettingsData.barInsetPaddingSyncAll
                onToggled: checked => SettingsData.set("barInsetPaddingSyncAll", checked)
            }
        }

        SettingsCard {
            iconName: "widgets"
            title: I18n.tr("Satellites", "island settings: satellite widgets card title")
            settingKey: "islandSatellites"
            collapsible: true
            expanded: true
            visible: root.selectedIslandEnabled && !root.isDot

            SettingsToggleRow {
                settingKey: "islandSatellitesEnabled"
                tags: ["island", "satellite", "widgets", "left", "right"]
                resetStore: bar
                resetKeys: ["islandSatellitesEnabled"]
                text: I18n.tr("Show", "island settings: satellite widgets toggle")
                checked: bar.islandSetting("islandSatellitesEnabled")
                onToggled: checked => bar.apply("islandSatellitesEnabled", checked)
            }

            SettingsButtonGroupRow {
                settingKey: "islandSatellitePosition"
                tags: ["island", "satellite", "widgets", "position", "edges", "center"]
                resetStore: bar
                resetKeys: ["islandSatellitePosition"]
                text: I18n.tr("Position", "island settings: position card title")
                model: [I18n.tr("Near island", "island settings: satellites hug the island"), I18n.tr("Display edges", "island settings: satellites sit at screen edges")]
                currentIndex: root.valueIndex(root.satellitePositionValues, bar.islandSetting("islandSatellitePosition"), "island")
                enabled: bar.islandSetting("islandSatellitesEnabled")
                onSelectionChanged: (index, selected) => {
                    if (selected)
                        bar.apply("islandSatellitePosition", root.satellitePositionValues[index] ?? "island");
                }
            }

            SettingsToggleRow {
                settingKey: "islandSatelliteBackground"
                tags: ["island", "satellite", "widgets", "background", "chrome"]
                resetStore: bar
                resetKeys: ["islandSatelliteBackground"]
                text: I18n.tr("Background", "island settings: satellite background toggle")
                checked: bar.islandSetting("islandSatelliteBackground")
                visible: bar.islandSetting("islandSatellitesEnabled")
                onToggled: checked => bar.apply("islandSatelliteBackground", checked)
            }

            SettingsToggleRow {
                settingKey: "islandSatelliteGothCorners"
                tags: ["island", "satellite", "goth", "corners", "wing", "sweep"]
                resetStore: bar
                resetKeys: ["islandSatelliteGothCorners"]
                text: I18n.tr("Goth corners", "island settings: satellite goth corners toggle")
                checked: bar.islandSetting("islandSatelliteGothCorners")
                visible: bar.islandSetting("islandSatellitesEnabled")
                enabled: bar.islandSetting("islandSatelliteBackground")
                onToggled: checked => bar.apply("islandSatelliteGothCorners", checked)
            }

            SettingsSliderRow {
                settingKey: "islandSatelliteSwoopRadius"
                tags: ["island", "satellite", "goth", "corners", "radius", "sweep", "size"]
                resetStore: bar
                resetKeys: ["islandSatelliteSwoopRadius"]
                text: I18n.tr("Goth corner radius", "island settings: satellite goth corner radius slider")
                unit: "px"
                minimum: 4
                maximum: 64
                step: 1
                value: bar.islandSetting("islandSatelliteSwoopRadius")
                visible: bar.islandSetting("islandSatellitesEnabled")
                enabled: bar.islandSetting("islandSatelliteBackground") && bar.islandSetting("islandSatelliteGothCorners")
                onSliderValueChanged: value => bar.apply("islandSatelliteSwoopRadius", value)
            }

            SettingsSliderRow {
                settingKey: "islandSatelliteTransparency"
                tags: ["island", "satellite", "background", "opacity", "transparency", "blur"]
                resetStore: bar
                resetKeys: ["islandSatelliteTransparency"]
                text: I18n.tr("Opacity", "island settings: satellite background opacity slider")
                minimum: 0
                maximum: 100
                step: 1
                value: Math.round(bar.islandSetting("islandSatelliteTransparency") * 100)
                visible: bar.islandSetting("islandSatellitesEnabled")
                enabled: bar.islandSetting("islandSatelliteBackground")
                onSliderValueChanged: value => bar.apply("islandSatelliteTransparency", value / 100)
            }

            SettingsSliderRow {
                settingKey: "islandSatelliteGap"
                tags: ["island", "satellite", "widgets", "gap", "spacing"]
                resetStore: bar
                resetKeys: ["islandSatelliteGap"]
                text: I18n.tr("Gap", "island settings: satellite to island gap slider")
                unit: "px"
                minimum: 4
                maximum: 48
                step: 1
                value: bar.islandSetting("islandSatelliteGap")
                visible: bar.islandSetting("islandSatellitesEnabled")
                enabled: bar.islandSetting("islandSatellitePosition") !== "edges"
                onSliderValueChanged: value => bar.apply("islandSatelliteGap", value)
            }
        }

        SettingsCard {
            iconName: "widgets"
            title: I18n.tr("Widgets")
            settingKey: "barWidgets"
            tags: ["widget", "style", "pills", "segments", "opacity", "padding", "maximize"]
            visible: (bar.selectedBarConfig?.enabled ?? false) && !root.isDot

            SettingsRow {
                settingKey: "barWidgetStyle"
                tags: ["widget", "style", "segments", "pills", "flat", "connected", "group"]
                title: I18n.tr("Widget style")
                enabled: root.widgetBackgroundEnabled
                resetStore: bar
                resetKeys: ["widgetStyle"]

                body: SettingsLayoutPicker {
                    widgetStyle: true
                    choices: [
                        {
                            key: "pills",
                            label: I18n.tr("Pills", "bar widget style option")
                        },
                        {
                            key: "segments",
                            label: I18n.tr("Segments", "bar widget style option")
                        },
                        {
                            key: "flat",
                            label: I18n.tr("Flat", "adjective, bar widget style option")
                        }
                    ]
                    selectedKey: bar.selectedBarConfig?.widgetStyle ?? "pills"
                    onSelected: key => SettingsData.updateBarConfig(bar.selectedBarId, {
                            widgetStyle: key
                        })
                }
            }

            SettingsSliderRow {
                text: I18n.tr("Opacity")
                tags: ["widget", "opacity", "transparency"]
                enabled: root.widgetBackgroundEnabled
                resetStore: bar
                resetKeys: ["widgetTransparency"]
                value: (bar.selectedBarConfig?.widgetTransparency ?? 1.0) * 100
                minimum: 0
                maximum: 100
                onSliderDragFinished: finalValue => SettingsData.updateBarConfig(bar.selectedBarId, {
                        widgetTransparency: finalValue / 100
                    })
            }

            SettingsSliderRow {
                text: I18n.tr("Padding")
                tags: ["widget", "padding", "spacing", "compact", "remove"]
                resetStore: bar
                resetKeys: ["widgetPadding"]
                value: bar.selectedBarConfig?.widgetPadding ?? 8
                minimum: 0
                maximum: 32
                unit: "px"
                onSliderValueChanged: newValue => SettingsData.updateBarConfig(bar.selectedBarId, {
                        widgetPadding: newValue
                    })
            }

            SettingsToggleRow {
                settingKey: "barNoBackground"
                tags: ["transparent", "background", "invisible"]
                text: I18n.tr("Background")
                resetStore: bar
                resetKeys: ["noBackground"]
                checked: !(bar.selectedBarConfig?.noBackground ?? false)
                onToggled: checked => SettingsData.updateBarConfig(bar.selectedBarId, {
                        noBackground: !checked
                    })
            }

            SettingsToggleRow {
                settingKey: "barMaximizeWidgetIcons"
                tags: ["maximize", "icons", "stretch"]
                text: I18n.tr("Maximize widget icons")
                resetStore: bar
                resetKeys: ["maximizeWidgetIcons"]
                checked: bar.selectedBarConfig?.maximizeWidgetIcons ?? false
                onToggled: checked => SettingsData.updateBarConfig(bar.selectedBarId, {
                        maximizeWidgetIcons: checked
                    })
            }

            SettingsToggleRow {
                settingKey: "barMaximizeWidgetText"
                tags: ["maximize", "text", "stretch"]
                text: I18n.tr("Maximize widget text")
                resetStore: bar
                resetKeys: ["maximizeWidgetText"]
                checked: bar.selectedBarConfig?.maximizeWidgetText ?? false
                onToggled: checked => SettingsData.updateBarConfig(bar.selectedBarId, {
                        maximizeWidgetText: checked
                    })
            }
        }

        SettingsToggleCard {
            settingKey: "barWidgetOutline"
            iconName: "highlight"
            title: I18n.tr("Widget outline")
            visible: (bar.selectedBarConfig?.enabled ?? false) && !root.isDot
            enabled: root.widgetBackgroundEnabled
            resetStore: bar
            resetKeys: ["widgetOutlineEnabled"]
            checked: bar.selectedBarConfig?.widgetOutlineEnabled ?? false
            onToggled: checked => SettingsData.updateBarConfig(bar.selectedBarId, {
                    widgetOutlineEnabled: checked
                })

            SettingsButtonGroupRow {
                text: I18n.tr("Color")
                resetStore: bar
                resetKeys: ["widgetOutlineColor"]
                model: root.outlineColorLabels
                currentIndex: {
                    const index = root.outlineColors.indexOf(bar.selectedBarConfig?.widgetOutlineColor || "primary");
                    return index >= 0 ? index : 2;
                }
                onSelectionChanged: (index, selected) => {
                    if (!selected)
                        return;
                    SettingsData.updateBarConfig(bar.selectedBarId, {
                        widgetOutlineColor: root.outlineColors[index]
                    });
                }
            }

            SettingsSliderRow {
                text: I18n.tr("Opacity")
                resetStore: bar
                resetKeys: ["widgetOutlineOpacity"]
                value: (bar.selectedBarConfig?.widgetOutlineOpacity ?? 1.0) * 100
                minimum: 0
                maximum: 100
                onSliderDragFinished: finalValue => SettingsData.updateBarConfig(bar.selectedBarId, {
                        widgetOutlineOpacity: finalValue / 100
                    })
            }

            SettingsSliderRow {
                text: I18n.tr("Thickness")
                resetStore: bar
                resetKeys: ["widgetOutlineThickness"]
                value: bar.selectedBarConfig?.widgetOutlineThickness ?? 1
                minimum: 1
                maximum: 10
                unit: "px"
                onSliderDragFinished: finalValue => SettingsData.updateBarConfig(bar.selectedBarId, {
                        widgetOutlineThickness: finalValue
                    })
            }
        }

        SettingsCard {
            iconName: "format_color_fill"
            title: I18n.tr("Widget colors")
            settingKey: "widgetStyling"
            tags: ["widget", "background", "color", "colorful", "text", "all", "bars"]
            visible: !root.isDot

            WidgetTextStyleRow {}

            WidgetBackgroundRow {
                enabled: root.widgetBackgroundEnabled
            }

            WidgetBackgroundStrengthRow {
                enabled: root.widgetBackgroundEnabled
            }
        }
    }
}
