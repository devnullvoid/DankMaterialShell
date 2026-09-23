import QtQuick
import Quickshell
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Settings.Widgets

Item {
    id: dankBarTab

    LayoutMirroring.enabled: I18n.isRtl
    LayoutMirroring.childrenInherit: true

    property var parentModal: null
    BarSelectionState {
        id: bar
    }

    readonly property var interactionModeValues: ["click", "hybrid"]
    readonly property var routingValues: ["normal", "always", "last-used"]
    readonly property var clockDisplayValues: ["time", "date", "both"]
    readonly property var systemLevelDisplayValues: ["icon", "percentage", "both"]
    readonly property var statusContentValues: ["battery", "connectivity"]
    readonly property bool isDot: SettingsData.isDotBarConfig(bar.selectedBarConfig)
    readonly property bool selectedIslandEnabled: bar.selectedBarIsIsland && (bar.selectedBarConfig?.enabled ?? false)
    readonly property bool selectedIslandFree: bar.selectedBarIsIsland && SettingsData.islandFreePlacement(bar.selectedBarConfig)
    readonly property bool selectedIslandFloating: selectedIslandFree && !isDot
    readonly property int placementIndex: !bar.islandSetting("islandFloating") ? 0 : (bar.islandSetting("islandPlacement") === "free" ? 2 : 1)

    function valueIndex(values, value, fallback) {
        const index = values.indexOf(value);
        return index >= 0 ? index : Math.max(0, values.indexOf(fallback));
    }

    function setBarScreenPreferences(barId, prefs) {
        SettingsData.updateBarConfig(barId, {
            screenPreferences: prefs
        });
        bar.notifyHorizontalBarChange();
    }

    function setBarShowOnLastDisplay(barId, value) {
        SettingsData.updateBarConfig(barId, {
            showOnLastDisplay: value
        });
        if (Quickshell.screens.length === 1)
            bar.notifyHorizontalBarChange();
    }

    SettingsPage {
        id: mainColumn

        SettingsCard {
            iconName: "vertical_align_center"
            title: I18n.tr("Position")
            settingKey: "barPosition"
            visible: bar.selectedBarConfig?.enabled

            SettingsRow {
                iconName: "info"
                iconColor: Theme.surfaceVariantText
                visible: bar.islandShadowedScreenCount > 0
                title: I18n.tr("%1 position", "bar info row title, %1 is the bar edge name").arg(bar.positionLabel(bar.selectedBarConfig?.position ?? SettingsData.Position.Top))
                subtitle: I18n.tr("The Island holds this edge on a display this bar covers, so the bar stays hidden there")
            }

            SettingsButtonGroupRow {
                settingKey: "islandFreeOrientation"
                tags: ["island", "free", "orientation", "horizontal", "vertical"]
                visible: dankBarTab.selectedIslandFloating
                text: I18n.tr("Orientation", "island settings: horizontal or vertical row for a free island")
                model: [I18n.tr("Horizontal", "island settings: free island orientation"), I18n.tr("Vertical", "island settings: free island orientation")]
                currentIndex: SettingsData.islandVertical(bar.selectedBarConfig) ? 1 : 0
                onSelectionChanged: (index, selected) => {
                    if (!selected)
                        return;
                    SettingsData.updateBarConfig(bar.selectedBarId, {
                        position: index === 1 ? SettingsData.Position.Left : SettingsData.Position.Top
                    });
                }
            }

            SettingsLayoutPicker {
                edgePlacement: true
                visible: !dankBarTab.selectedIslandFree
                choices: [SettingsData.Position.Top, SettingsData.Position.Bottom, SettingsData.Position.Left, SettingsData.Position.Right].map(position => ({
                            key: String(position),
                            label: bar.positionLabel(position),
                            enabled: bar.positionChoices.includes(position)
                        }))
                selectedKey: String(bar.selectedBarConfig?.position ?? SettingsData.Position.Top)
                onSelected: key => {
                    SettingsData.updateBarConfig(bar.selectedBarId, {
                        position: Number(key)
                    });
                    bar.notifyHorizontalBarChange();
                }
            }

            SettingsButtonGroupRow {
                settingKey: "islandPlacement"
                tags: ["island", "placement", "docked", "overlay", "floating", "float", "free", "anywhere", "edge", "drag", "exclusive", "reserve"]
                visible: bar.selectedBarIsIsland && !dankBarTab.isDot
                resetStore: bar
                resetKeys: ["islandFloating", "islandPlacement"]
                text: I18n.tr("Placement", "island settings: docked, overlay or floating placement row")
                model: [I18n.tr("Docked", "island settings: island reserves its edge strip"), I18n.tr("Overlay", "island settings: island floats over windows along its edge without reserving space"), I18n.tr("Floating", "island settings: island can be dragged anywhere on the display")]
                currentIndex: dankBarTab.placementIndex
                onSelectionChanged: (index, selected) => {
                    if (!selected)
                        return;
                    const patch = {
                        islandFloating: index > 0
                    };
                    if (index > 0)
                        patch.islandPlacement = index === 2 ? "free" : "edge";
                    SettingsData.updateBarConfig(bar.selectedBarId, patch);
                    bar.notifyHorizontalBarChange();
                }
            }

            SettingsRow {
                visible: dankBarTab.selectedIslandFloating
                body: StyledText {
                    width: parent.width
                    text: I18n.tr("Drag to move, click to open activities", "island settings: free placement hint")
                    color: Theme.surfaceVariantText
                    font.pixelSize: Theme.fontSizeSmall
                    wrapMode: Text.WordWrap
                }
            }

            SettingsDropdownRow {
                id: sharedRouting
                settingKey: "islandSharedRouting"
                tags: ["dot", "island", "routing", "launcher", "dash", "control center", "ipc", "last used"]
                visible: bar.selectedBarIsIsland
                resetStore: bar
                resetKeys: ["islandSharedRouting"]
                text: I18n.tr("Shared shortcuts")
                description: I18n.tr("Routes launcher, dash, control center and notification shortcuts")
                options: [I18n.tr("Normal routing"), I18n.tr("Always here"), I18n.tr("Last used on this screen")]
                dropdownWidth: Theme.smallBreakpoint / 2
                currentValue: options[dankBarTab.valueIndex(dankBarTab.routingValues, SettingsData.islandSharedRoutingMode(bar.selectedBarConfig), "normal")]
                onValueChanged: value => SettingsData.setIslandSharedRouting(bar.selectedBarId, dankBarTab.routingValues[options.indexOf(value)] ?? "normal")
            }

            SettingsSliderRow {
                settingKey: "islandFreeSize"
                tags: ["island", "free", "dot", "size", "diameter"]
                visible: dankBarTab.isDot
                resetStore: bar
                resetKeys: ["islandFreeSize"]
                text: I18n.tr("Dot size", "island settings: free dot diameter slider")
                unit: "px"
                minimum: 24
                maximum: 160
                step: 1
                value: bar.islandSetting("islandFreeSize")
                onSliderValueChanged: value => bar.apply("islandFreeSize", value)
            }

            SettingsSliderRow {
                settingKey: "islandFreeEdgeMargin"
                tags: ["island", "free", "dot", "edge", "margin", "gap"]
                visible: dankBarTab.selectedIslandFree
                resetStore: bar
                resetKeys: ["islandFreeEdgeMargin"]
                text: I18n.tr("Edge margin", "island settings: gap kept from the display edge")
                unit: "px"
                minimum: 0
                maximum: 64
                step: 1
                value: bar.islandSetting("islandFreeEdgeMargin")
                onSliderValueChanged: value => bar.apply("islandFreeEdgeMargin", value)
            }

            SettingsSliderRow {
                settingKey: "islandFreeIdleDelay"
                tags: ["island", "free", "dot", "idle", "delay", "fade", "timeout"]
                visible: dankBarTab.isDot
                resetStore: bar
                resetKeys: ["islandFreeIdleDelay"]
                text: I18n.tr("Idle delay", "island settings: time before the dot fades, 0 disables idling")
                unit: "ms"
                minimum: 0
                maximum: 30000
                step: 500
                value: bar.islandSetting("islandFreeIdleDelay")
                onSliderValueChanged: value => bar.apply("islandFreeIdleDelay", value)
            }

            SettingsSliderRow {
                settingKey: "islandFreeIdleScale"
                tags: ["island", "free", "dot", "idle", "shrink", "scale"]
                visible: dankBarTab.isDot
                resetStore: bar
                resetKeys: ["islandFreeIdleScale"]
                text: I18n.tr("Idle size", "island settings: how far the dot shrinks while idle")
                unit: "%"
                minimum: 20
                maximum: 100
                step: 1
                value: Math.round(bar.islandSetting("islandFreeIdleScale") * 100)
                enabled: bar.islandSetting("islandFreeIdleDelay") > 0
                onSliderValueChanged: value => bar.apply("islandFreeIdleScale", value / 100)
            }
        }

        SettingsCard {
            iconName: "display_settings"
            title: I18n.tr("Displays")
            settingKey: "barDisplay"
            collapsible: true
            expanded: true
            visible: bar.selectedBarConfig?.enabled

            SettingsDisplayPicker {
                displayPreferences: bar.selectedBarConfig?.screenPreferences || ["all"]
                emptyMeansAll: false
                allowEmpty: true
                showLastDisplay: true
                showOnLastDisplay: bar.selectedBarConfig?.showOnLastDisplay ?? true
                onPreferencesChanged: prefs => dankBarTab.setBarScreenPreferences(bar.selectedBarId, prefs)
                onLastDisplayToggled: checked => dankBarTab.setBarShowOnLastDisplay(bar.selectedBarId, checked)
            }
        }

        SettingsCard {
            iconName: "tune"
            title: I18n.tr("Frame")
            settingKey: "frameEnabled"
            tags: ["frame", "mode", "bar", "overview"]
            visible: !dankBarTab.isDot && SettingsData.frameEnabled

            SettingsButtonGroupRow {
                settingKey: "frameModeSelector"
                tags: ["frame", "mode", "connected", "separate", "popout", "flush", "float"]
                resetKeys: ["frameMode"]
                text: I18n.tr("Surfaces")
                model: [I18n.tr("Separate", "adjective, frame surfaces mode option, opposite of connected"), I18n.tr("Connected")]
                currentIndex: SettingsData.frameMode === "connected" ? 1 : 0
                onSelectionChanged: (index, selected) => {
                    if (!selected)
                        return;
                    switch (index) {
                    case 1:
                        SettingsData.set("frameMode", "connected");
                        break;
                    default:
                        SettingsData.set("frameMode", "separate");
                        break;
                    }
                }
            }

            SettingsToggleRow {
                settingKey: "frameShowOnOverview"
                tags: ["frame", "overview", "show", "hide", "niri"]
                text: I18n.tr("Show on overview")
                visible: CompositorService.supportsNativeOverview
                checked: SettingsData.frameShowOnOverview
                onToggled: checked => SettingsData.set("frameShowOnOverview", checked)
            }
        }

        SettingsCard {
            iconName: "blur_linear"
            title: I18n.tr("Connected")
            settingKey: "frameConnectedOptions"
            collapsible: true
            expanded: true
            visible: !dankBarTab.isDot && SettingsData.frameEnabled && SettingsData.frameMode === "connected"

            SettingsToggleRow {
                settingKey: "frameCloseGaps"
                tags: ["frame", "connected", "gap", "edge", "curves", "arcs", "expose", "popout", "notification"]
                text: I18n.tr("Expose the arcs")
                checked: !SettingsData.frameCloseGaps
                onToggled: checked => SettingsData.set("frameCloseGaps", !checked)
            }

            SettingsButtonGroupRow {
                settingKey: "frameLauncherEmergeSide"
                tags: ["frame", "connected", "launcher", "modal", "emerge", "direction", "bottom", "top"]
                text: I18n.tr("Launcher emerge side")
                model: [I18n.tr("Bottom"), I18n.tr("Top")]
                currentIndex: SettingsData.frameLauncherEmergeSide === "top" ? 1 : 0
                onSelectionChanged: (index, selected) => {
                    if (!selected)
                        return;
                    SettingsData.set("frameLauncherEmergeSide", index === 1 ? "top" : "bottom");
                }
            }

            SettingsToggleRow {
                settingKey: "frameLauncherArcExtender"
                tags: ["frame", "connected", "launcher", "arc", "extender", "center"]
                text: I18n.tr("Arc extender")
                checked: SettingsData.frameLauncherArcExtender
                onToggled: checked => SettingsData.set("frameLauncherArcExtender", checked)
            }

            SettingsToggleRow {
                settingKey: "frameLauncherEdgeHover"
                tags: ["frame", "connected", "launcher", "hover", "edge", "reveal"]
                text: I18n.tr("Edge hover reveal")
                checked: SettingsData.frameLauncherEdgeHover
                onToggled: checked => SettingsData.set("frameLauncherEdgeHover", checked)
            }
        }

        SettingsCard {
            iconName: "monitor"
            title: I18n.tr("Frame displays", "settings card title: displays that draw the frame")
            settingKey: "frameDisplays"
            collapsible: true
            expanded: false
            visible: !dankBarTab.isDot && SettingsData.frameEnabled

            SettingsDisplayPicker {
                displayPreferences: SettingsData.frameScreenPreferences
                onPreferencesChanged: prefs => SettingsData.set("frameScreenPreferences", prefs)
            }
        }

        SettingsCard {
            iconName: "visibility"
            title: I18n.tr("Visibility", "settings card title for bar or dock show and hide behavior")
            settingKey: "barVisibility"
            collapsible: true
            expanded: true
            visible: (bar.selectedBarConfig?.enabled ?? false) && !bar.selectedBarIsIsland

            SettingsRow {
                iconName: "info"
                iconColor: Theme.surfaceVariantText
                visible: bar.islandShadowsSelectedBar
                title: I18n.tr("Bar visibility")
                subtitle: I18n.tr("The Island holds this edge on a display this bar covers, so the bar stays hidden there")
            }

            SettingsToggleRow {
                settingKey: "barAutoHide"
                tags: ["autohide", "auto-hide", "reveal", "intellihide"]
                visible: !bar.islandOwnsSelectedBarTop
                text: I18n.tr("Auto-hide", "toggle to automatically hide the bar or dock")
                resetStore: bar
                resetKeys: ["autoHide"]
                checked: bar.selectedBarConfig?.autoHide ?? false
                onToggled: toggled => {
                    SettingsData.updateBarConfig(bar.selectedBarId, {
                        autoHide: toggled
                    });
                    bar.notifyHorizontalBarChange();
                }
            }

            SettingsSliderRow {
                visible: (bar.selectedBarConfig?.autoHide ?? false) && !bar.islandOwnsSelectedBarTop
                text: I18n.tr("Hide delay")
                tags: ["autohide", "delay", "hide"]
                resetStore: bar
                resetKeys: ["autoHideDelay"]
                value: bar.selectedBarConfig?.autoHideDelay ?? 250
                minimum: 0
                maximum: 2000
                unit: "ms"
                onSliderValueChanged: newValue => SettingsData.updateBarConfig(bar.selectedBarId, {
                        autoHideDelay: newValue
                    })
            }

            SettingsToggleRow {
                settingKey: "barAutoHideStrict"
                visible: (bar.selectedBarConfig?.autoHide ?? false) && !bar.islandOwnsSelectedBarTop
                tags: ["autohide", "strict", "popout"]
                text: I18n.tr("Strict auto-hide", "Dank bar setting: hide the bar when the pointer leaves even if a menu or bar popover is still open")
                resetStore: bar
                resetKeys: ["autoHideStrict"]
                checked: bar.selectedBarConfig?.autoHideStrict ?? false
                onToggled: toggled => {
                    SettingsData.updateBarConfig(bar.selectedBarId, {
                        autoHideStrict: toggled
                    });
                    bar.notifyHorizontalBarChange();
                }
            }

            SettingsToggleRow {
                settingKey: "barHideWhenWindowsOpen"
                tags: ["hide", "windows", "empty", "workspace"]
                visible: (bar.selectedBarConfig?.autoHide ?? false) && !bar.islandOwnsSelectedBarTop && CompositorService.supportsBarAutoHideReveal
                text: I18n.tr("Hide when windows open")
                resetStore: bar
                resetKeys: ["showOnWindowsOpen"]
                checked: bar.selectedBarConfig?.showOnWindowsOpen ?? false
                onToggled: toggled => SettingsData.updateBarConfig(bar.selectedBarId, {
                        showOnWindowsOpen: toggled
                    })
            }

            SettingsToggleRow {
                settingKey: "barOpenOnOverview"
                tags: ["bar", "overview", "niri", "show", "frame"]
                visible: CompositorService.supportsNativeOverview && !bar.islandOwnsSelectedBarTop
                text: I18n.tr("Show on overview")
                resetStore: bar.selectedBarFrameStyled ? SettingsData : bar
                resetKeys: bar.selectedBarFrameStyled ? ["frameShowOnOverview"] : ["openOnOverview"]
                checked: bar.selectedBarFrameStyled ? SettingsData.frameShowOnOverview : (bar.selectedBarConfig?.openOnOverview ?? false)
                onToggled: toggled => {
                    if (bar.selectedBarFrameStyled) {
                        SettingsData.set("frameShowOnOverview", toggled);
                        return;
                    }
                    SettingsData.updateBarConfig(bar.selectedBarId, {
                        openOnOverview: toggled
                    });
                }
            }

            SettingsToggleRow {
                settingKey: "barManualVisibility"
                tags: ["manual", "show", "hide", "ipc", "toggle"]
                visible: !bar.islandOwnsSelectedBarTop
                text: I18n.tr("Manual show/hide")
                resetStore: bar
                resetKeys: ["visible"]
                checked: bar.selectedBarConfig?.visible ?? true
                onToggled: toggled => {
                    SettingsData.updateBarConfig(bar.selectedBarId, {
                        visible: toggled
                    });
                    bar.notifyHorizontalBarChange();
                }
            }
        }

        SettingsCard {
            iconName: "touch_app"
            title: I18n.tr("Behavior", "island settings: behavior card title")
            settingKey: "islandInteraction"
            tags: ["island", "interaction", "click", "hybrid", "expand", "hover", "delay"]
            visible: (bar.selectedBarConfig?.enabled ?? false) && bar.selectedBarIsIsland && !dankBarTab.selectedIslandFree

            SettingsButtonGroupRow {
                settingKey: "islandInteractionMode"
                tags: ["island", "interaction", "click", "hybrid", "expand"]
                resetStore: bar
                resetKeys: ["islandInteractionMode"]
                text: I18n.tr("Expansion mode", "island settings: click or hover expansion row")
                model: [I18n.tr("Click", "island settings: click expansion mode"), I18n.tr("Hybrid", "island settings: hover plus click expansion mode")]
                currentIndex: dankBarTab.valueIndex(dankBarTab.interactionModeValues, bar.islandSetting("islandInteractionMode"), "hybrid")
                onSelectionChanged: (index, selected) => {
                    if (selected)
                        bar.apply("islandInteractionMode", dankBarTab.interactionModeValues[index] ?? "hybrid");
                }
            }

            SettingsRow {
                visible: bar.islandSetting("islandInteractionMode") !== "click"
                body: StyledText {
                    width: parent.width
                    text: I18n.tr("Hybrid peeks the current compact face on hover. Click pins a destination so it stays open", "island settings: hybrid mode hint")
                    color: Theme.surfaceVariantText
                    font.pixelSize: Theme.fontSizeSmall
                    wrapMode: Text.WordWrap
                }
            }

            SettingsSliderRow {
                settingKey: "islandHoverOpenDelay"
                tags: ["island", "interaction", "hover", "open", "delay"]
                resetStore: bar
                resetKeys: ["islandHoverOpenDelay"]
                text: I18n.tr("Open delay", "island settings: hover open delay slider")
                unit: "ms"
                minimum: 0
                maximum: 1000
                step: 10
                value: bar.islandSetting("islandHoverOpenDelay")
                visible: bar.islandSetting("islandInteractionMode") !== "click"
                onSliderValueChanged: value => bar.apply("islandHoverOpenDelay", value)
            }

            SettingsSliderRow {
                settingKey: "islandHoverCloseDelay"
                tags: ["island", "interaction", "hover", "close", "delay"]
                resetStore: bar
                resetKeys: ["islandHoverCloseDelay"]
                text: I18n.tr("Hide delay", "island settings: hover hide delay slider")
                unit: "ms"
                minimum: 0
                maximum: 1000
                step: 10
                value: bar.islandSetting("islandHoverCloseDelay")
                visible: bar.islandSetting("islandInteractionMode") !== "click"
                onSliderValueChanged: value => bar.apply("islandHoverCloseDelay", value)
            }

            SettingsToggleRow {
                settingKey: "islandMediaClockVisible"
                tags: ["island", "media", "clock", "compact", "time"]
                resetStore: bar
                resetKeys: ["islandMediaClockVisible"]
                text: I18n.tr("Keep clock with media", "island settings: clock in media face toggle")
                checked: bar.islandSetting("islandMediaClockVisible")
                onToggled: checked => bar.apply("islandMediaClockVisible", checked)
            }
        }

        SettingsCard {
            iconName: "home"
            title: I18n.tr("Home compact", "island settings: home face card title")
            settingKey: "islandActivities"
            visible: dankBarTab.selectedIslandEnabled && !dankBarTab.isDot

            IslandHomeLayoutEditor {
                width: parent.width
                barId: bar.selectedBarIsIsland ? bar.selectedBarId : ""
            }

            SettingsButtonGroupRow {
                settingKey: "islandHomeClockDisplay"
                tags: ["island", "home", "compact", "clock", "time", "date"]
                resetStore: bar
                resetKeys: ["islandHomeClockDisplay"]
                text: I18n.tr("Clock style", "island settings: clock display mode row")
                model: [I18n.tr("Time", "island settings: clock shows time only"), I18n.tr("Date", "island settings: clock shows date only"), I18n.tr("Both", "island settings: clock shows time and date")]
                currentIndex: dankBarTab.valueIndex(dankBarTab.clockDisplayValues, bar.islandSetting("islandHomeClockDisplay"), "both")
                onSelectionChanged: (index, selected) => {
                    if (selected)
                        bar.apply("islandHomeClockDisplay", dankBarTab.clockDisplayValues[index] ?? "both");
                }
            }

            SettingsButtonGroupRow {
                settingKey: "islandHomeVolumeDisplay"
                tags: ["island", "home", "compact", "volume", "icon", "percentage"]
                resetStore: bar
                resetKeys: ["islandHomeVolumeDisplay"]
                text: I18n.tr("Volume style", "island settings: volume display mode row")
                visible: SettingsData.islandHomeGroupEnabled(bar.selectedBarConfig, "volume")
                model: [I18n.tr("Icon", "island settings: level shown as icon only"), I18n.tr("Percentage", "island settings: level shown as percentage only"), I18n.tr("Both", "island settings: level shown as icon and percentage")]
                currentIndex: dankBarTab.valueIndex(dankBarTab.systemLevelDisplayValues, bar.islandSetting("islandHomeVolumeDisplay"), "both")
                onSelectionChanged: (index, selected) => {
                    if (selected)
                        bar.apply("islandHomeVolumeDisplay", dankBarTab.systemLevelDisplayValues[index] ?? "both");
                }
            }

            SettingsButtonGroupRow {
                settingKey: "islandHomeBrightnessDisplay"
                tags: ["island", "home", "compact", "brightness", "icon", "percentage"]
                resetStore: bar
                resetKeys: ["islandHomeBrightnessDisplay"]
                text: I18n.tr("Brightness style", "island settings: brightness display mode row")
                visible: SettingsData.islandHomeGroupEnabled(bar.selectedBarConfig, "brightness")
                model: [I18n.tr("Icon", "island settings: level shown as icon only"), I18n.tr("Percentage", "island settings: level shown as percentage only"), I18n.tr("Both", "island settings: level shown as icon and percentage")]
                currentIndex: dankBarTab.valueIndex(dankBarTab.systemLevelDisplayValues, bar.islandSetting("islandHomeBrightnessDisplay"), "both")
                onSelectionChanged: (index, selected) => {
                    if (selected)
                        bar.apply("islandHomeBrightnessDisplay", dankBarTab.systemLevelDisplayValues[index] ?? "both");
                }
            }

            SettingsButtonGroupRow {
                settingKey: "islandHomeStatusContent"
                tags: ["island", "home", "compact", "status", "battery", "wifi", "bluetooth", "connectivity"]
                text: I18n.tr("Control Center", "island settings: status group content row")
                visible: SettingsData.islandHomeGroupEnabled(bar.selectedBarConfig, "status")
                model: [I18n.tr("Battery", "island settings: status group battery content"), I18n.tr("Wi-Fi & Bluetooth", "island settings: status group connectivity content")]
                currentIndex: dankBarTab.valueIndex(dankBarTab.statusContentValues, SettingsData.islandHomeStatusContent(bar.selectedBarConfig), "battery")
                onSelectionChanged: (index, selected) => {
                    if (selected)
                        bar.apply("islandHomeStatusContent", dankBarTab.statusContentValues[index] ?? "battery");
                }
            }

            SettingsToggleRow {
                settingKey: "islandHomeCompactTight"
                tags: ["island", "home", "compact", "narrow", "width", "height", "clock"]
                resetStore: bar
                resetKeys: ["islandHomeCompactTight"]
                text: I18n.tr("Compact pill", "island settings: tighter home pill toggle")
                checked: bar.islandSetting("islandHomeCompactTight")
                onToggled: checked => bar.apply("islandHomeCompactTight", checked)
            }

            SettingsRow {
                body: Flow {
                    width: parent.width
                    spacing: Theme.spacingS

                    DankButton {
                        text: I18n.tr("Launcher", "island settings: button to launcher tab")
                        iconName: "grid_view"
                        onClicked: {
                            if (!dankBarTab.parentModal)
                                return;
                            SettingsSearchService.navigateToSection("launcherStyle");
                            dankBarTab.parentModal.navigateTo("launcher");
                        }
                    }

                    DankButton {
                        text: I18n.tr("Time & weather", "island settings: button to weather tab")
                        iconName: "cloud"
                        onClicked: {
                            if (!dankBarTab.parentModal)
                                return;
                            SettingsSearchService.navigateToSection("weatherEnabled");
                            dankBarTab.parentModal.navigateTo("time_weather");
                        }
                    }
                }
            }
        }

        SettingsCard {
            iconName: "notifications"
            title: I18n.tr("Notifications", "island settings: notifications card title")
            settingKey: "islandNotifications"
            visible: dankBarTab.selectedIslandEnabled

            SettingsToggleRow {
                settingKey: "islandNotificationPopups"
                tags: ["island", "notifications", "popup", "standard", "bar", "stack", "arrival"]
                resetStore: bar
                resetKeys: ["islandNotificationPopups"]
                text: I18n.tr("Use standard popups", "island settings: show arriving notifications as stacked popups instead of in the island")
                checked: bar.islandSetting("islandNotificationPopups")
                onToggled: checked => bar.apply("islandNotificationPopups", checked)
            }

            SettingsToggleRow {
                settingKey: "islandNotificationExpand"
                tags: ["island", "notifications", "expand", "arrival", "size"]
                resetStore: bar
                resetKeys: ["islandNotificationExpand"]
                text: I18n.tr("Expand by default", "island settings: expanded notification toggle")
                checked: bar.islandSetting("islandNotificationExpand")
                onToggled: checked => bar.apply("islandNotificationExpand", checked)
            }

            SettingsToggleRow {
                settingKey: "islandNotificationBadgeClearOnOpen"
                tags: ["island", "home", "notifications", "badge", "unread", "clear", "dismiss", "open"]
                resetStore: bar
                resetKeys: ["islandNotificationBadgeClearOnOpen"]
                text: I18n.tr("Clear badge on open", "island settings: clear the notification badge when the center opens")
                checked: bar.islandSetting("islandNotificationBadgeClearOnOpen")
                enabled: dankBarTab.isDot || SettingsData.islandHomeGroupEnabled(bar.selectedBarConfig, "notifications")
                onToggled: checked => bar.apply("islandNotificationBadgeClearOnOpen", checked)
            }
        }

        SettingsToggleCard {
            settingKey: "hoverPopouts"
            resetStore: bar
            resetKeys: ["hoverPopouts"]
            tags: ["bar", "hover", "popout", "reveal", "widget", "delay"]
            iconName: "touch_app"
            title: I18n.tr("Hover popouts")
            visible: (bar.selectedBarConfig?.enabled ?? false) && !dankBarTab.isDot
            enabled: !(bar.selectedBarConfig?.clickThrough ?? false)
            opacity: (bar.selectedBarConfig?.clickThrough ?? false) ? 0.5 : 1.0
            checked: bar.selectedBarConfig?.hoverPopouts ?? false
            onToggled: checked => SettingsData.updateBarConfig(bar.selectedBarId, {
                    hoverPopouts: checked
                })

            SettingsSliderRow {
                visible: bar.selectedBarConfig?.hoverPopouts ?? false
                text: I18n.tr("Open delay")
                resetStore: bar
                resetKeys: ["hoverPopoutDelay"]
                value: bar.selectedBarConfig?.hoverPopoutDelay ?? 150
                minimum: 0
                maximum: 1000
                unit: "ms"
                onSliderValueChanged: newValue => {
                    SettingsData.updateBarConfig(bar.selectedBarId, {
                        hoverPopoutDelay: newValue
                    });
                }
            }
        }

        SettingsToggleCard {
            iconName: "mouse"
            settingKey: "barScrollWheel"
            resetStore: bar
            resetKeys: ["scrollEnabled"]
            tags: ["scroll", "wheel", "workspace", "column", "axis"]
            title: I18n.tr("Scroll wheel")
            visible: (bar.selectedBarConfig?.enabled ?? false) && !bar.selectedBarIsIsland
            checked: bar.selectedBarConfig?.scrollEnabled ?? true
            onToggled: checked => SettingsData.updateBarConfig(bar.selectedBarId, {
                    scrollEnabled: checked
                })

            SettingsButtonGroupRow {
                text: I18n.tr("Y axis")
                resetStore: bar
                resetKeys: ["scrollYBehavior"]
                model: CompositorService.isNiri ? [I18n.tr("None"), I18n.tr("Workspace"), I18n.tr("Column", "noun, bar scroll behavior option, niri window column")] : [I18n.tr("None"), I18n.tr("Workspace")]
                buttonPadding: Theme.spacingS
                minButtonWidth: 44
                textSize: Theme.fontSizeSmall
                currentIndex: {
                    switch (bar.selectedBarConfig?.scrollYBehavior || "workspace") {
                    case "none":
                        return 0;
                    case "workspace":
                        return 1;
                    case "column":
                        return 2;
                    default:
                        return 1;
                    }
                }
                onSelectionChanged: (index, selected) => {
                    if (!selected)
                        return;
                    let behavior = "workspace";
                    switch (index) {
                    case 0:
                        behavior = "none";
                        break;
                    case 1:
                        behavior = "workspace";
                        break;
                    case 2:
                        behavior = "column";
                        break;
                    }
                    SettingsData.updateBarConfig(bar.selectedBarId, {
                        scrollYBehavior: behavior
                    });
                }
            }

            SettingsButtonGroupRow {
                text: I18n.tr("X axis")
                resetStore: bar
                resetKeys: ["scrollXBehavior"]
                visible: CompositorService.isNiri
                model: [I18n.tr("None"), I18n.tr("Workspace"), I18n.tr("Column")]
                buttonPadding: Theme.spacingS
                minButtonWidth: 44
                textSize: Theme.fontSizeSmall
                currentIndex: {
                    switch (bar.selectedBarConfig?.scrollXBehavior || "column") {
                    case "none":
                        return 0;
                    case "workspace":
                        return 1;
                    case "column":
                        return 2;
                    default:
                        return 2;
                    }
                }
                onSelectionChanged: (index, selected) => {
                    if (!selected)
                        return;
                    let behavior = "column";
                    switch (index) {
                    case 0:
                        behavior = "none";
                        break;
                    case 1:
                        behavior = "workspace";
                        break;
                    case 2:
                        behavior = "column";
                        break;
                    }
                    SettingsData.updateBarConfig(bar.selectedBarId, {
                        scrollXBehavior: behavior
                    });
                }
            }
        }
    }
}
