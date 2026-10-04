import QtQuick
import qs.Common
import qs.Modules.Settings.Widgets
import qs.Modules.Settings.DesktopWidgetSettings

DesktopWidgetInstanceSettings {
    id: root

    readonly property var styles: ["horizontal", "vertical", "expressive", "analog"]
    readonly property var styleLabels: [I18n.tr("Horizontal", "lock screen clock style option"), I18n.tr("Vertical", "lock screen clock style option"), I18n.tr("Expressive"), I18n.tr("Analog")]
    readonly property string style: cfg.style ?? "expressive"
    readonly property bool textStyle: style === "horizontal" || style === "vertical"

    showAppearance: false

    SettingsDropdownRow {
        text: I18n.tr("Clock style")
        options: root.styleLabels
        currentValue: root.styleLabels[Math.max(0, root.styles.indexOf(root.style))]
        onValueChanged: value => {
            const idx = root.styleLabels.indexOf(value);
            if (idx >= 0)
                root.updateConfig("style", root.styles[idx]);
        }
    }

    SettingsSliderRow {
        visible: root.textStyle
        text: I18n.tr("Weight")
        minimum: 0
        maximum: 900
        step: 100
        minimumLabel: I18n.tr("Default")
        value: root.cfg.weight ?? 0
        onSliderValueChanged: newValue => root.updateConfig("weight", newValue)
    }

    SettingsFontDropdownRow {
        visible: root.textStyle
        text: I18n.tr("Font")
        currentFont: root.cfg.fontFamily ?? ""
        defaultFamily: SettingsData.lockScreenFontFamily || Theme.defaultFontFamily
        onFontSelected: family => root.updateConfig("fontFamily", family)
    }

    SettingsToggleRow {
        visible: root.style === "horizontal"
        text: I18n.tr("Italic")
        checked: root.cfg.italic ?? false
        onToggled: checked => root.updateConfig("italic", checked)
    }

    SettingsToggleRow {
        visible: root.style === "horizontal" || root.style === "expressive"
        text: I18n.tr("Accent minutes", "lock screen clock colors")
        checked: root.cfg.twoTone ?? true
        onToggled: checked => root.updateConfig("twoTone", checked)
    }

    SettingsToggleRow {
        text: I18n.tr("Automatic placement", "lock screen clock placement")
        description: I18n.tr("Choose a clear area of the background. Drag the clock to place it yourself.", "lock screen automatic clock placement")
        checked: root.cfg.autoPosition ?? true
        onToggled: checked => {
            if (checked)
                SessionData.resetDesktopWidgetInstanceGeometry(root.instanceId, ["x", "y"]);
            root.updateConfig("autoPosition", checked);
        }
    }

    SettingsToggleRow {
        visible: root.style === "analog"
        text: I18n.tr("Show hour numbers")
        checked: root.cfg.showAnalogNumbers ?? false
        onToggled: checked => root.updateConfig("showAnalogNumbers", checked)
    }

    SettingsToggleRow {
        visible: root.style === "analog"
        text: I18n.tr("Show seconds")
        checked: root.cfg.showAnalogSeconds ?? true
        onToggled: checked => root.updateConfig("showAnalogSeconds", checked)
    }

    SettingsColorPicker {
        showDefault: true
        colorMode: root.cfg.colorMode ?? "default"
        customColor: root.cfg.customColor ?? "#ffffff"
        onColorModeSelected: mode => root.updateConfig("colorMode", mode)
        onCustomColorSelected: selectedColor => root.updateConfig("customColor", selectedColor.toString())
    }
}
