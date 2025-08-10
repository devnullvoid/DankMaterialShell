pragma Singleton

pragma ComponentBehavior

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

Singleton {
  id: root

  property var themes: [{
      "name": "Blue",
      "primary": "#74c7ec",
      "primaryText": "#cdd6f4",
      "primaryContainer": "#585b70",
      "secondary": "#89b4fa",
      "surface": "#11111b",
      "surfaceText": "#cdd6f4",
      "surfaceVariant": "#313244",
      "surfaceVariantText": "#a6adc8",
      "surfaceTint": "#74c7ec",
      "background": "#11111b",
      "backgroundText": "#cdd6f4",
      "outline": "#6c7086",
      "surfaceContainer": "#181825",
      "surfaceContainerHigh": "#1e1e2e"
    }, {
      "name": "Deep Blue",
      "primary": "#89b4fa",
      "primaryText": "#cdd6f4",
      "primaryContainer": "#585b70",
      "secondary": "#74c7ec",
      "surface": "#11111b",
      "surfaceText": "#cdd6f4",
      "surfaceVariant": "#313244",
      "surfaceVariantText": "#a6adc8",
      "surfaceTint": "#89b4fa",
      "background": "#11111b",
      "backgroundText": "#cdd6f4",
      "outline": "#6c7086",
      "surfaceContainer": "#181825",
      "surfaceContainerHigh": "#1e1e2e"
    }, {
      "name": "Purple",
      "primary": "#cba6f7",
      "primaryText": "#cdd6f4",
      "primaryContainer": "#585b70",
      "secondary": "#f5c2e7",
      "surface": "#11111b",
      "surfaceText": "#cdd6f4",
      "surfaceVariant": "#313244",
      "surfaceVariantText": "#a6adc8",
      "surfaceTint": "#cba6f7",
      "background": "#11111b",
      "backgroundText": "#cdd6f4",
      "outline": "#6c7086",
      "surfaceContainer": "#181825",
      "surfaceContainerHigh": "#1e1e2e"
    }, {
      "name": "Green",
      "primary": "#a6e3a1",
      "primaryText": "#cdd6f4",
      "primaryContainer": "#585b70",
      "secondary": "#89b4fa",
      "surface": "#11111b",
      "surfaceText": "#cdd6f4",
      "surfaceVariant": "#313244",
      "surfaceVariantText": "#a6adc8",
      "surfaceTint": "#a6e3a1",
      "background": "#11111b",
      "backgroundText": "#cdd6f4",
      "outline": "#6c7086",
      "surfaceContainer": "#181825",
      "surfaceContainerHigh": "#1e1e2e"
    }, {
      "name": "Orange",
      "primary": "#fab387",
      "primaryText": "#cdd6f4",
      "primaryContainer": "#585b70",
      "secondary": "#f9e2af",
      "surface": "#11111b",
      "surfaceText": "#cdd6f4",
      "surfaceVariant": "#313244",
      "surfaceVariantText": "#a6adc8",
      "surfaceTint": "#fab387",
      "background": "#11111b",
      "backgroundText": "#cdd6f4",
      "outline": "#6c7086",
      "surfaceContainer": "#181825",
      "surfaceContainerHigh": "#1e1e2e"
    }, {
      "name": "Red",
      "primary": "#f38ba8",
      "primaryText": "#cdd6f4",
      "primaryContainer": "#585b70",
      "secondary": "#f5c2e7",
      "surface": "#11111b",
      "surfaceText": "#cdd6f4",
      "surfaceVariant": "#313244",
      "surfaceVariantText": "#a6adc8",
      "surfaceTint": "#f38ba8",
      "background": "#11111b",
      "backgroundText": "#cdd6f4",
      "outline": "#6c7086",
      "surfaceContainer": "#181825",
      "surfaceContainerHigh": "#1e1e2e"
    }, {
      "name": "Cyan",
      "primary": "#89dceb",
      "primaryText": "#cdd6f4",
      "primaryContainer": "#585b70",
      "secondary": "#74c7ec",
      "surface": "#11111b",
      "surfaceText": "#cdd6f4",
      "surfaceVariant": "#313244",
      "surfaceVariantText": "#a6adc8",
      "surfaceTint": "#89dceb",
      "background": "#11111b",
      "backgroundText": "#cdd6f4",
      "outline": "#6c7086",
      "surfaceContainer": "#181825",
      "surfaceContainerHigh": "#1e1e2e"
    }, {
      "name": "Pink",
      "primary": "#f5c2e7",
      "primaryText": "#cdd6f4",
      "primaryContainer": "#585b70",
      "secondary": "#cba6f7",
      "surface": "#11111b",
      "surfaceText": "#cdd6f4",
      "surfaceVariant": "#313244",
      "surfaceVariantText": "#a6adc8",
      "surfaceTint": "#f5c2e7",
      "background": "#11111b",
      "backgroundText": "#cdd6f4",
      "outline": "#6c7086",
      "surfaceContainer": "#181825",
      "surfaceContainerHigh": "#1e1e2e"
    }, {
      "name": "Amber",
      "primary": "#f9e2af",
      "primaryText": "#cdd6f4",
      "primaryContainer": "#585b70",
      "secondary": "#fab387",
      "surface": "#11111b",
      "surfaceText": "#cdd6f4",
      "surfaceVariant": "#313244",
      "surfaceVariantText": "#a6adc8",
      "surfaceTint": "#f9e2af",
      "background": "#11111b",
      "backgroundText": "#cdd6f4",
      "outline": "#6c7086",
      "surfaceContainer": "#181825",
      "surfaceContainerHigh": "#1e1e2e"
    }, {
      "name": "Coral",
      "primary": "#f2cdcd",
      "primaryText": "#cdd6f4",
      "primaryContainer": "#585b70",
      "secondary": "#f38ba8",
      "surface": "#11111b",
      "surfaceText": "#cdd6f4",
      "surfaceVariant": "#313244",
      "surfaceVariantText": "#a6adc8",
      "surfaceTint": "#f2cdcd",
      "background": "#11111b",
      "backgroundText": "#cdd6f4",
      "outline": "#6c7086",
      "surfaceContainer": "#181825",
      "surfaceContainerHigh": "#1e1e2e"
    }]
  property var lightThemes: [{
      "name": "Blue Light",
      "primary": "#1e66f5",
      "primaryText": "#4c4f69",
      "primaryContainer": "#acb0be",
      "secondary": "#209fb5",
      "surface": "#e6e9ef",
      "surfaceText": "#4c4f69",
      "surfaceVariant": "#ccd0da",
      "surfaceVariantText": "#6c6f85",
      "surfaceTint": "#1e66f5",
      "background": "#eff1f5",
      "backgroundText": "#4c4f69",
      "outline": "#9ca0b0",
      "surfaceContainer": "#ccd0da",
      "surfaceContainerHigh": "#bcc0cc"
    }, {
      "name": "Deep Blue Light",
      "primary": "#1e66f5",
      "primaryText": "#4c4f69",
      "primaryContainer": "#acb0be",
      "secondary": "#209fb5",
      "surface": "#e6e9ef",
      "surfaceText": "#4c4f69",
      "surfaceVariant": "#ccd0da",
      "surfaceVariantText": "#6c6f85",
      "surfaceTint": "#1e66f5",
      "background": "#eff1f5",
      "backgroundText": "#4c4f69",
      "outline": "#9ca0b0",
      "surfaceContainer": "#ccd0da",
      "surfaceContainerHigh": "#bcc0cc"
    }, {
      "name": "Purple Light",
      "primary": "#8839ef",
      "primaryText": "#4c4f69",
      "primaryContainer": "#acb0be",
      "secondary": "#ea76cb",
      "surface": "#e6e9ef",
      "surfaceText": "#4c4f69",
      "surfaceVariant": "#ccd0da",
      "surfaceVariantText": "#6c6f85",
      "surfaceTint": "#8839ef",
      "background": "#eff1f5",
      "backgroundText": "#4c4f69",
      "outline": "#9ca0b0",
      "surfaceContainer": "#ccd0da",
      "surfaceContainerHigh": "#bcc0cc"
    }, {
      "name": "Green Light",
      "primary": "#40a02b",
      "primaryText": "#4c4f69",
      "primaryContainer": "#acb0be",
      "secondary": "#1e66f5",
      "surface": "#e6e9ef",
      "surfaceText": "#4c4f69",
      "surfaceVariant": "#ccd0da",
      "surfaceVariantText": "#6c6f85",
      "surfaceTint": "#40a02b",
      "background": "#eff1f5",
      "backgroundText": "#4c4f69",
      "outline": "#9ca0b0",
      "surfaceContainer": "#ccd0da",
      "surfaceContainerHigh": "#bcc0cc"
    }, {
      "name": "Orange Light",
      "primary": "#fe640b",
      "primaryText": "#4c4f69",
      "primaryContainer": "#acb0be",
      "secondary": "#df8e1d",
      "surface": "#e6e9ef",
      "surfaceText": "#4c4f69",
      "surfaceVariant": "#ccd0da",
      "surfaceVariantText": "#6c6f85",
      "surfaceTint": "#fe640b",
      "background": "#eff1f5",
      "backgroundText": "#4c4f69",
      "outline": "#9ca0b0",
      "surfaceContainer": "#ccd0da",
      "surfaceContainerHigh": "#bcc0cc"
    }, {
      "name": "Red Light",
      "primary": "#d20f39",
      "primaryText": "#4c4f69",
      "primaryContainer": "#acb0be",
      "secondary": "#ea76cb",
      "surface": "#e6e9ef",
      "surfaceText": "#4c4f69",
      "surfaceVariant": "#ccd0da",
      "surfaceVariantText": "#6c6f85",
      "surfaceTint": "#d20f39",
      "background": "#eff1f5",
      "backgroundText": "#4c4f69",
      "outline": "#9ca0b0",
      "surfaceContainer": "#ccd0da",
      "surfaceContainerHigh": "#bcc0cc"
    }, {
      "name": "Cyan Light",
      "primary": "#179299",
      "primaryText": "#4c4f69",
      "primaryContainer": "#acb0be",
      "secondary": "#1e66f5",
      "surface": "#e6e9ef",
      "surfaceText": "#4c4f69",
      "surfaceVariant": "#ccd0da",
      "surfaceVariantText": "#6c6f85",
      "surfaceTint": "#179299",
      "background": "#eff1f5",
      "backgroundText": "#4c4f69",
      "outline": "#9ca0b0",
      "surfaceContainer": "#ccd0da",
      "surfaceContainerHigh": "#bcc0cc"
    }, {
      "name": "Pink Light",
      "primary": "#ea76cb",
      "primaryText": "#4c4f69",
      "primaryContainer": "#acb0be",
      "secondary": "#8839ef",
      "surface": "#e6e9ef",
      "surfaceText": "#4c4f69",
      "surfaceVariant": "#ccd0da",
      "surfaceVariantText": "#6c6f85",
      "surfaceTint": "#ea76cb",
      "background": "#eff1f5",
      "backgroundText": "#4c4f69",
      "outline": "#9ca0b0",
      "surfaceContainer": "#ccd0da",
      "surfaceContainerHigh": "#bcc0cc"
    }, {
      "name": "Amber Light",
      "primary": "#df8e1d",
      "primaryText": "#4c4f69",
      "primaryContainer": "#acb0be",
      "secondary": "#fe640b",
      "surface": "#e6e9ef",
      "surfaceText": "#4c4f69",
      "surfaceVariant": "#ccd0da",
      "surfaceVariantText": "#6c6f85",
      "surfaceTint": "#df8e1d",
      "background": "#eff1f5",
      "backgroundText": "#4c4f69",
      "outline": "#9ca0b0",
      "surfaceContainer": "#ccd0da",
      "surfaceContainerHigh": "#bcc0cc"
    }, {
      "name": "Coral Light",
      "primary": "#e64553",
      "primaryText": "#4c4f69",
      "primaryContainer": "#acb0be",
      "secondary": "#d20f39",
      "surface": "#e6e9ef",
      "surfaceText": "#4c4f69",
      "surfaceVariant": "#ccd0da",
      "surfaceVariantText": "#6c6f85",
      "surfaceTint": "#e64553",
      "background": "#eff1f5",
      "backgroundText": "#4c4f69",
      "outline": "#9ca0b0",
      "surfaceContainer": "#ccd0da",
      "surfaceContainerHigh": "#bcc0cc"
    }]
  property int currentThemeIndex: 0
  property bool isDynamicTheme: false
  property bool isLightMode: false
  property color primary: isDynamicTheme ? Colors.accentHi : getCurrentTheme(
                                             ).primary
  property color primaryText: isDynamicTheme ? Colors.primaryText : getCurrentTheme(
                                                 ).primaryText
  property color primaryContainer: isDynamicTheme ? Colors.primaryContainer : getCurrentTheme(
                                                      ).primaryContainer
  property color secondary: isDynamicTheme ? Colors.accentLo : getCurrentTheme(
                                               ).secondary
  property color surface: isDynamicTheme ? Colors.surface : getCurrentTheme(
                                             ).surface
  property color surfaceText: isDynamicTheme ? Colors.surfaceText : getCurrentTheme(
                                                 ).surfaceText
  property color surfaceVariant: isDynamicTheme ? Colors.surfaceVariant : getCurrentTheme(
                                                    ).surfaceVariant
  property color surfaceVariantText: isDynamicTheme ? Colors.surfaceVariantText : getCurrentTheme(
                                                        ).surfaceVariantText
  property color surfaceTint: isDynamicTheme ? Colors.surfaceTint : getCurrentTheme(
                                                 ).surfaceTint
  property color background: isDynamicTheme ? Colors.bg : getCurrentTheme(
                                                ).background
  property color backgroundText: isDynamicTheme ? Colors.surfaceText : getCurrentTheme(
                                                    ).backgroundText
  property color outline: isDynamicTheme ? Colors.outline : getCurrentTheme(
                                             ).outline
  property color surfaceContainer: isDynamicTheme ? Colors.surfaceContainer : getCurrentTheme(
                                                      ).surfaceContainer
  property color surfaceContainerHigh: isDynamicTheme ? Colors.surfaceContainerHigh : getCurrentTheme(
                                                          ).surfaceContainerHigh
  property color archBlue: "#1793D1"
  property color success: "#4CAF50"
  property color warning: "#FF9800"
  property color info: "#2196F3"
  property color error: "#F2B8B5"

  // Temperature-specific colors
  property color tempWarning: "#ff9933" // Balanced orange for warm temperatures
  property color tempDanger: "#ff5555" // Balanced red for dangerous temperatures

  property color primaryHover: Qt.rgba(primary.r, primary.g, primary.b, 0.12)
  property color primaryHoverLight: Qt.rgba(primary.r, primary.g,
                                            primary.b, 0.08)
  property color primaryPressed: Qt.rgba(primary.r, primary.g, primary.b, 0.16)
  property color primarySelected: Qt.rgba(primary.r, primary.g, primary.b, 0.3)
  property color primaryBackground: Qt.rgba(primary.r, primary.g,
                                            primary.b, 0.04)

  property color secondaryHover: Qt.rgba(secondary.r, secondary.g,
                                         secondary.b, 0.08)

  property color surfaceHover: Qt.rgba(surfaceVariant.r, surfaceVariant.g,
                                       surfaceVariant.b, 0.08)
  property color surfacePressed: Qt.rgba(surfaceVariant.r, surfaceVariant.g,
                                         surfaceVariant.b, 0.12)
  property color surfaceSelected: Qt.rgba(surfaceVariant.r, surfaceVariant.g,
                                          surfaceVariant.b, 0.15)
  property color surfaceLight: Qt.rgba(surfaceVariant.r, surfaceVariant.g,
                                       surfaceVariant.b, 0.1)
  property color surfaceVariantAlpha: Qt.rgba(surfaceVariant.r,
                                              surfaceVariant.g,
                                              surfaceVariant.b, 0.2)
  property color surfaceTextHover: Qt.rgba(surfaceText.r, surfaceText.g,
                                           surfaceText.b, 0.08)
  property color surfaceTextPressed: Qt.rgba(surfaceText.r, surfaceText.g,
                                             surfaceText.b, 0.12)
  property color surfaceTextAlpha: Qt.rgba(surfaceText.r, surfaceText.g,
                                           surfaceText.b, 0.3)
  property color surfaceTextLight: Qt.rgba(surfaceText.r, surfaceText.g,
                                           surfaceText.b, 0.06)
  property color surfaceTextMedium: Qt.rgba(surfaceText.r, surfaceText.g,
                                            surfaceText.b, 0.7)

  property color outlineLight: Qt.rgba(outline.r, outline.g, outline.b, 0.05)
  property color outlineMedium: Qt.rgba(outline.r, outline.g, outline.b, 0.08)
  property color outlineStrong: Qt.rgba(outline.r, outline.g, outline.b, 0.12)
  property color outlineSelected: Qt.rgba(outline.r, outline.g, outline.b, 0.2)
  property color outlineHeavy: Qt.rgba(outline.r, outline.g, outline.b, 0.3)
  property color outlineButton: Qt.rgba(outline.r, outline.g, outline.b, 0.5)

  property color errorHover: Qt.rgba(error.r, error.g, error.b, 0.12)
  property color errorPressed: Qt.rgba(error.r, error.g, error.b, 0.9)

  property color warningHover: Qt.rgba(warning.r, warning.g, warning.b, 0.12)

  property color shadowLight: Qt.rgba(0, 0, 0, 0.05)
  property color shadowMedium: Qt.rgba(0, 0, 0, 0.08)
  property color shadowDark: Qt.rgba(0, 0, 0, 0.1)
  property color shadowStrong: Qt.rgba(0, 0, 0, 0.3)
  property int shortDuration: 150
  property int mediumDuration: 300
  property int longDuration: 500
  property int extraLongDuration: 1000
  property int standardEasing: Easing.OutCubic
  property int emphasizedEasing: Easing.OutQuart
  property real cornerRadius: typeof SettingsData !== "undefined" ? SettingsData.cornerRadius : 12
  property real spacingXS: 4
  property real spacingS: 8
  property real spacingM: 12
  property real spacingL: 16
  property real spacingXL: 24
  property real fontSizeSmall: 12
  property real fontSizeMedium: 14
  property real fontSizeLarge: 16
  property real fontSizeXLarge: 20
  property real barHeight: 48
  property real iconSize: 24
  property real iconSizeSmall: 16
  property real iconSizeLarge: 32
  property real opacityDisabled: 0.38
  property real opacityMedium: 0.6
  property real opacityHigh: 0.87
  property real opacityFull: 1
  property real panelTransparency: 0.85
  property real widgetTransparency: 0.85
  property real popupTransparency: 0.92

  function onColorsUpdated() {
    if (isDynamicTheme) {
      currentThemeIndex = 10
      isDynamicTheme = true
      if (typeof SettingsData !== "undefined")
        SettingsData.setTheme(currentThemeIndex, isDynamicTheme)
    }
  }

  function switchTheme(themeIndex, isDynamic = false, savePrefs = true) {
    if (isDynamic && themeIndex === 10) {
      isDynamicTheme = true
      if (typeof Colors !== "undefined") {
        Colors.extractColors()
      }
    } else if (themeIndex >= 0 && themeIndex < themes.length) {
      if (isDynamicTheme && typeof Colors !== "undefined") {
        Colors.restoreSystemThemes()
      }
      currentThemeIndex = themeIndex
      isDynamicTheme = false
    }
    if (savePrefs && typeof SettingsData !== "undefined")
      SettingsData.setTheme(currentThemeIndex, isDynamicTheme)
  }

  function toggleLightMode(savePrefs = true) {
    isLightMode = !isLightMode
    if (savePrefs && typeof SessionData !== "undefined")
      SessionData.setLightMode(isLightMode)
  }

  function getCurrentThemeArray() {
    return isLightMode ? lightThemes : themes
  }

  function getCurrentTheme() {
    var themeArray = getCurrentThemeArray()
    return currentThemeIndex < themeArray.length ? themeArray[currentThemeIndex] : themeArray[0]
  }

  function getPopupBackgroundAlpha() {
    return popupTransparency
  }

  function getContentBackgroundAlpha() {
    return popupTransparency
  }

  function popupBackground() {
    return Qt.rgba(surfaceContainer.r, surfaceContainer.g, surfaceContainer.b,
                   popupTransparency)
  }

  function contentBackground() {
    return Qt.rgba(surfaceContainer.r, surfaceContainer.g, surfaceContainer.b,
                   popupTransparency)
  }

  function panelBackground() {
    return Qt.rgba(surfaceContainer.r, surfaceContainer.g, surfaceContainer.b,
                   panelTransparency)
  }

  function widgetBackground() {
    return Qt.rgba(surfaceContainer.r, surfaceContainer.g, surfaceContainer.b,
                   widgetTransparency)
  }

  function getBatteryIcon(level, isCharging, batteryAvailable) {
    if (!batteryAvailable)
      return _getBatteryPowerProfileIcon()

    if (isCharging) {
      if (level >= 90)
        return "battery_charging_full"

      if (level >= 80)
        return "battery_charging_90"

      if (level >= 60)
        return "battery_charging_80"

      if (level >= 50)
        return "battery_charging_60"

      if (level >= 30)
        return "battery_charging_50"

      if (level >= 20)
        return "battery_charging_30"

      return "battery_charging_20"
    } else {
      if (level >= 95)
        return "battery_full"

      if (level >= 85)
        return "battery_6_bar"

      if (level >= 70)
        return "battery_5_bar"

      if (level >= 55)
        return "battery_4_bar"

      if (level >= 40)
        return "battery_3_bar"

      if (level >= 25)
        return "battery_2_bar"

      if (level >= 10)
        return "battery_1_bar"

      return "battery_alert"
    }
  }

  function _getBatteryPowerProfileIcon() {
    if (typeof PowerProfiles === "undefined")
      return "balance"

    switch (PowerProfiles.profile) {
    case PowerProfile.PowerSaver:
      return "energy_savings_leaf"
    case PowerProfile.Performance:
      return "rocket_launch"
    default:
      return "balance"
    }
  }

  function getPowerProfileIcon(profile) {
    switch (profile) {
    case PowerProfile.PowerSaver:
      return "battery_saver"
    case PowerProfile.Balanced:
      return "battery_std"
    case PowerProfile.Performance:
      return "flash_on"
    default:
      return "settings"
    }
  }

  function getPowerProfileLabel(profile) {
    switch (profile) {
    case PowerProfile.PowerSaver:
      return "Power Saver"
    case PowerProfile.Balanced:
      return "Balanced"
    case PowerProfile.Performance:
      return "Performance"
    default:
      return profile.charAt(0).toUpperCase() + profile.slice(1)
    }
  }

  function getPowerProfileDescription(profile) {
    switch (profile) {
    case PowerProfile.PowerSaver:
      return "Extend battery life"
    case PowerProfile.Balanced:
      return "Balance power and performance"
    case PowerProfile.Performance:
      return "Prioritize performance"
    default:
      return "Custom power profile"
    }
  }

  Component.onCompleted: {
    if (typeof Colors !== "undefined")
    Colors.colorsUpdated.connect(root.onColorsUpdated)

    if (typeof SettingsData !== "undefined") {
      if (SettingsData.popupTransparency !== undefined)
      root.popupTransparency = SettingsData.popupTransparency

      if (SettingsData.topBarWidgetTransparency !== undefined)
      root.widgetTransparency = SettingsData.topBarWidgetTransparency

      if (SettingsData.popupTransparencyChanged)
      SettingsData.popupTransparencyChanged.connect(function () {
        if (typeof SettingsData !== "undefined"
            && SettingsData.popupTransparency !== undefined)
          root.popupTransparency = SettingsData.popupTransparency
      })

      if (SettingsData.topBarWidgetTransparencyChanged)
      SettingsData.topBarWidgetTransparencyChanged.connect(function () {
        if (typeof SettingsData !== "undefined"
            && SettingsData.topBarWidgetTransparency !== undefined)
          root.widgetTransparency = SettingsData.topBarWidgetTransparency
      })
    }
  }
}