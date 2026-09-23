import QtQuick
import qs.Common
import qs.Services
import qs.Modules.Settings.Widgets

Item {
    id: root

    LayoutMirroring.enabled: I18n.isRtl
    LayoutMirroring.childrenInherit: true

    readonly property bool isDot: SettingsData.isDotBarConfig(bar.selectedBarConfig)

    BarSelectionState {
        id: bar
    }

    SettingsPage {
        id: mainColumn

        SettingsCard {
            iconName: "tune"
            title: I18n.tr("Behavior")
            settingKey: "barAdvanced"
            tags: ["bar", "advanced", "overlay", "layer", "click", "through", "maximize", "island", "spring", "motion"]
            visible: bar.selectedBarConfig?.enabled ?? false

            SettingsToggleRow {
                settingKey: "barClickThrough"
                resetStore: bar
                resetKeys: ["clickThrough"]
                tags: ["clickthrough", "click", "through", "mouse", "input", "mask", "passthrough"]
                visible: !bar.islandOwnsSelectedBarTop
                text: I18n.tr("Click through")
                checked: bar.selectedBarConfig?.clickThrough ?? false
                onToggled: toggled => SettingsData.updateBarConfig(bar.selectedBarId, {
                        clickThrough: toggled
                    })
            }

            SettingsToggleRow {
                settingKey: "barUseOverlayLayer"
                resetStore: bar
                resetKeys: ["useOverlayLayer"]
                tags: ["bar", "fullscreen", "overlay", "layer"]
                visible: !bar.islandOwnsSelectedBarTop
                text: I18n.tr("Use overlay layer")
                checked: bar.selectedBarConfig?.useOverlayLayer ?? false
                onToggled: toggled => {
                    SettingsData.updateBarConfig(bar.selectedBarId, {
                        useOverlayLayer: toggled
                    });
                    bar.notifyHorizontalBarChange();
                }
            }

            SettingsToggleRow {
                settingKey: "islandUseOverlayLayer"
                tags: ["island", "fullscreen", "overlay", "layer"]
                visible: bar.selectedBarIsIsland && !root.isDot
                resetStore: bar
                resetKeys: ["islandUseOverlayLayer"]
                text: I18n.tr("Use overlay layer")
                checked: bar.islandSetting("islandUseOverlayLayer")
                onToggled: checked => bar.apply("islandUseOverlayLayer", checked)
            }

            SettingsToggleRow {
                settingKey: "islandReducedMotion"
                tags: ["island", "motion", "animation", "reduce", "accessibility", "spring"]
                visible: bar.selectedBarIsIsland
                resetStore: bar
                resetKeys: ["islandReducedMotion"]
                text: I18n.tr("Reduce motion")
                checked: bar.islandSetting("islandReducedMotion")
                onToggled: checked => bar.apply("islandReducedMotion", checked)
            }

            SettingsSliderRow {
                settingKey: "islandSpringStiffness"
                tags: ["island", "motion", "spring", "stiffness", "animation"]
                visible: bar.selectedBarIsIsland
                resetStore: bar
                resetKeys: ["islandSpringStiffness"]
                text: I18n.tr("Spring stiffness", "island settings: spring stiffness slider")
                unit: ""
                minimum: 100
                maximum: 1200
                step: 10
                value: Math.round(bar.islandSetting("islandSpringStiffness"))
                enabled: !bar.islandSetting("islandReducedMotion")
                onSliderValueChanged: value => bar.apply("islandSpringStiffness", value)
            }

            SettingsSliderRow {
                settingKey: "islandSpringDamping"
                tags: ["island", "motion", "spring", "damping", "bounce", "animation"]
                visible: bar.selectedBarIsIsland
                resetStore: bar
                resetKeys: ["islandSpringDamping"]
                text: I18n.tr("Spring damping", "island settings: spring damping slider")
                unit: ""
                minimum: 10
                maximum: 100
                step: 1
                value: Math.round(bar.islandSetting("islandSpringDamping"))
                enabled: !bar.islandSetting("islandReducedMotion")
                onSliderValueChanged: value => bar.apply("islandSpringDamping", value)
            }

            SettingsSliderRow {
                settingKey: "islandSpringMass"
                tags: ["island", "motion", "spring", "mass", "inertia", "animation"]
                visible: bar.selectedBarIsIsland
                resetStore: bar
                resetKeys: ["islandSpringMass"]
                text: I18n.tr("Spring mass", "island settings: spring mass slider")
                minimum: 25
                maximum: 300
                step: 5
                unit: ""
                decimals: 2
                value: Math.round(bar.islandSetting("islandSpringMass") * 100)
                enabled: !bar.islandSetting("islandReducedMotion")
                onSliderValueChanged: value => bar.apply("islandSpringMass", value / 100)
            }

            SettingsToggleRow {
                settingKey: "barMaximizeDetection"
                resetStore: bar
                resetKeys: ["maximizeDetection"]
                tags: ["maximize", "gaps", "border", "fullscreen"]
                visible: CompositorService.supportsBarAutoHideReveal && !root.isDot
                text: I18n.tr("Maximize detection")
                checked: bar.selectedBarConfig?.maximizeDetection ?? true
                onToggled: toggled => SettingsData.updateBarConfig(bar.selectedBarId, {
                        maximizeDetection: toggled
                    })
            }
        }

        SettingsCard {
            iconName: "space_bar"
            title: I18n.tr("Gaps")
            settingKey: "barAppearanceAdvanced"
            tags: ["bar", "advanced", "exclusive", "zone", "popup", "gaps"]
            visible: (bar.selectedBarConfig?.enabled ?? false) && !bar.selectedBarFrameStyled && !root.isDot

            SettingsSliderRow {
                settingKey: "barExclusiveZone"
                tags: ["exclusive", "zone", "reserved", "offset"]
                visible: !bar.islandOwnsSelectedBarTop
                text: I18n.tr("Exclusive zone offset")
                resetStore: bar
                resetKeys: ["bottomGap"]
                value: bar.selectedBarConfig?.bottomGap ?? 0
                minimum: -50
                maximum: 50
                unit: "px"
                onSliderDragFinished: finalValue => SettingsData.updateBarConfig(bar.selectedBarId, {
                        bottomGap: finalValue
                    })
            }

            SettingsToggleRow {
                text: I18n.tr("Auto popup gaps")
                tags: ["popup", "gaps", "auto"]
                resetStore: bar
                resetKeys: ["popupGapsAuto"]
                checked: bar.selectedBarConfig?.popupGapsAuto ?? true
                onToggled: checked => SettingsData.updateBarConfig(bar.selectedBarId, {
                        popupGapsAuto: checked
                    })
            }

            SettingsSliderRow {
                visible: !(bar.selectedBarConfig?.popupGapsAuto ?? true)
                text: I18n.tr("Gap size")
                tags: ["popup", "gaps", "size"]
                resetStore: bar
                resetKeys: ["popupGapsManual"]
                unit: "px"
                value: bar.selectedBarConfig?.popupGapsManual ?? 4
                minimum: 0
                maximum: 50
                onSliderDragFinished: finalValue => SettingsData.updateBarConfig(bar.selectedBarId, {
                        popupGapsManual: finalValue
                    })
            }
        }
    }
}
