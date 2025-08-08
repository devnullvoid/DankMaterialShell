import QtQuick
import QtQuick.Controls
import Quickshell.Io
import qs.Common
import qs.Services
import qs.Widgets

Item {
    id: appearanceTab

    DankFlickable {
        anchors.fill: parent
        anchors.topMargin: Theme.spacingL
        anchors.bottomMargin: Theme.spacingXL
        clip: true
        contentHeight: mainColumn.height
        contentWidth: width
        mouseWheelSpeed: 20
        
        Column {
            id: mainColumn
            width: parent.width
            spacing: Theme.spacingXL
            
            Loader {
                width: parent.width
                sourceComponent: displayComponent
            }
            
            Loader {
                width: parent.width
                sourceComponent: transparencyComponent
            }
            
            Loader {
                width: parent.width
                sourceComponent: themeComponent
            }
            
            Loader {
                width: parent.width
                sourceComponent: systemThemingComponent
            }
        }
    }

    // Display Settings Component
    Component {
        id: displayComponent
        
        StyledRect {
            width: parent.width
            height: displaySection.implicitHeight + Theme.spacingL * 2
            radius: Theme.cornerRadiusLarge
            color: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.3)
            border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
            border.width: 1

            Column {
                id: displaySection

                anchors.fill: parent
                anchors.margins: Theme.spacingL
                spacing: Theme.spacingM

                Row {
                    width: parent.width
                    spacing: Theme.spacingM

                    DankIcon {
                        name: "monitor"
                        size: Theme.iconSize
                        color: Theme.primary
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    StyledText {
                        text: "Display Settings"
                        font.pixelSize: Theme.fontSizeLarge
                        font.weight: Font.Medium
                        color: Theme.surfaceText
                        anchors.verticalCenter: parent.verticalCenter
                    }

                }

                DankToggle {
                    width: parent.width
                    text: "Night Mode"
                    description: "Apply warm color temperature to reduce eye strain"
                    checked: SettingsData.nightModeEnabled
                    onToggled: (checked) => {
                        SettingsData.setNightModeEnabled(checked);
                        if (checked)
                            nightModeEnableProcess.running = true;
                        else
                            nightModeDisableProcess.running = true;
                    }
                }

                DankToggle {
                    width: parent.width
                    text: "Light Mode"
                    description: "Use light theme instead of dark theme"
                    checked: SessionData.isLightMode
                    onToggled: (checked) => {
                        SessionData.setLightMode(checked);
                        Theme.isLightMode = checked;
                        PortalService.setLightMode(checked);
                    }
                }

                DankDropdown {
                    width: parent.width
                    text: "Icon Theme"
                    description: "Select icon theme"
                    currentValue: SettingsData.iconTheme
                    enableFuzzySearch: true
                    popupWidthOffset: 100
                    maxPopupHeight: 400
                    options: {
                        SettingsData.detectAvailableIconThemes();
                        return SettingsData.availableIconThemes;
                    }
                    onValueChanged: (value) => {
                        SettingsData.setIconTheme(value);
                        if (value !== "System Default" && !SettingsData.qt5ctAvailable && !SettingsData.qt6ctAvailable)
                            ToastService.showWarning("qt5ct or qt6ct not found - Qt app themes may not update without these tools");

                    }
                }

                DankDropdown {
                    width: parent.width
                    text: "Font Family"
                    description: "Select system font family"
                    currentValue: {
                        if (SettingsData.fontFamily === SettingsData.defaultFontFamily)
                            return "Default (" + SettingsData.defaultFontFamily + ")";
                        else
                            return SettingsData.fontFamily || "Default (" + SettingsData.defaultFontFamily + ")";
                    }
                    enableFuzzySearch: true
                    popupWidthOffset: 100
                    maxPopupHeight: 400
                    options: {
                        var fonts = ["Default (" + SettingsData.defaultFontFamily + ")"];
                        var availableFonts = Qt.fontFamilies();
                        var rootFamilies = [];
                        var seenFamilies = new Set();
                        for (var i = 0; i < availableFonts.length; i++) {
                            var fontName = availableFonts[i];
                            if (fontName.startsWith("."))
                                continue;

                            if (fontName === SettingsData.defaultFontFamily)
                                continue;

                            var rootName = fontName.replace(/ (Thin|Extra Light|Light|Regular|Medium|Semi Bold|Demi Bold|Bold|Extra Bold|Black|Heavy)$/i, "").replace(/ (Italic|Oblique|Condensed|Extended|Narrow|Wide)$/i, "").replace(/ (UI|Display|Text|Mono|Sans|Serif)$/i, function(match, suffix) {
                                return match;
                            }).trim();
                            if (!seenFamilies.has(rootName) && rootName !== "") {
                                seenFamilies.add(rootName);
                                rootFamilies.push(rootName);
                            }
                        }
                        return fonts.concat(rootFamilies.sort());
                    }
                    onValueChanged: (value) => {
                        if (value.startsWith("Default ("))
                            SettingsData.setFontFamily(SettingsData.defaultFontFamily);
                        else
                            SettingsData.setFontFamily(value);
                    }
                }

                DankDropdown {
                    width: parent.width
                    text: "Font Weight"
                    description: "Select font weight"
                    currentValue: {
                        switch (SettingsData.fontWeight) {
                        case Font.Thin:
                            return "Thin";
                        case Font.ExtraLight:
                            return "Extra Light";
                        case Font.Light:
                            return "Light";
                        case Font.Normal:
                            return "Regular";
                        case Font.Medium:
                            return "Medium";
                        case Font.DemiBold:
                            return "Demi Bold";
                        case Font.Bold:
                            return "Bold";
                        case Font.ExtraBold:
                            return "Extra Bold";
                        case Font.Black:
                            return "Black";
                        default:
                            return "Regular";
                        }
                    }
                    options: ["Thin", "Extra Light", "Light", "Regular", "Medium", "Demi Bold", "Bold", "Extra Bold", "Black"]
                    onValueChanged: (value) => {
                        var weight;
                        switch (value) {
                        case "Thin":
                            weight = Font.Thin;
                            break;
                        case "Extra Light":
                            weight = Font.ExtraLight;
                            break;
                        case "Light":
                            weight = Font.Light;
                            break;
                        case "Regular":
                            weight = Font.Normal;
                            break;
                        case "Medium":
                            weight = Font.Medium;
                            break;
                        case "Demi Bold":
                            weight = Font.DemiBold;
                            break;
                        case "Bold":
                            weight = Font.Bold;
                            break;
                        case "Extra Bold":
                            weight = Font.ExtraBold;
                            break;
                        case "Black":
                            weight = Font.Black;
                            break;
                        default:
                            weight = Font.Normal;
                            break;
                        }
                        SettingsData.setFontWeight(weight);
                    }
                }

                DankDropdown {
                    width: parent.width
                    text: "Monospace Font"
                    description: "Select monospace font for process list and technical displays"
                    currentValue: {
                        if (SettingsData.monoFontFamily === SettingsData.defaultMonoFontFamily)
                            return "Default";

                        return SettingsData.monoFontFamily || "Default";
                    }
                    enableFuzzySearch: true
                    popupWidthOffset: 100
                    maxPopupHeight: 400
                    options: {
                        var fonts = ["Default"];
                        var availableFonts = Qt.fontFamilies();
                        var monoFamilies = [];
                        var seenFamilies = new Set();
                        for (var i = 0; i < availableFonts.length; i++) {
                            var fontName = availableFonts[i];
                            if (fontName.startsWith("."))
                                continue;

                            if (fontName === SettingsData.defaultMonoFontFamily)
                                continue;

                            var lowerName = fontName.toLowerCase();
                            if (lowerName.includes("mono") || lowerName.includes("code") || lowerName.includes("console") || lowerName.includes("terminal") || lowerName.includes("courier") || lowerName.includes("dejavu sans mono") || lowerName.includes("jetbrains") || lowerName.includes("fira") || lowerName.includes("hack") || lowerName.includes("source code") || lowerName.includes("ubuntu mono") || lowerName.includes("cascadia")) {
                                var rootName = fontName.replace(/ (Thin|Extra Light|Light|Regular|Medium|Semi Bold|Demi Bold|Bold|Extra Bold|Black|Heavy)$/i, "").replace(/ (Italic|Oblique|Condensed|Extended|Narrow|Wide)$/i, "").trim();
                                if (!seenFamilies.has(rootName) && rootName !== "") {
                                    seenFamilies.add(rootName);
                                    monoFamilies.push(rootName);
                                }
                            }
                        }
                        return fonts.concat(monoFamilies.sort());
                    }
                    onValueChanged: (value) => {
                        if (value === "Default")
                            SettingsData.setMonoFontFamily(SettingsData.defaultMonoFontFamily);
                        else
                            SettingsData.setMonoFontFamily(value);
                    }
                }

            }
        }
    }

    // Transparency Settings Component
    Component {
        id: transparencyComponent
        
        StyledRect {
            width: parent.width
            height: transparencySection.implicitHeight + Theme.spacingL * 2
            radius: Theme.cornerRadiusLarge
            color: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.3)
            border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
            border.width: 1

            Column {
                id: transparencySection

                anchors.fill: parent
                anchors.margins: Theme.spacingL
                spacing: Theme.spacingM

                Row {
                    width: parent.width
                    spacing: Theme.spacingM

                    DankIcon {
                        name: "opacity"
                        size: Theme.iconSize
                        color: Theme.primary
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    StyledText {
                        text: "Transparency Settings"
                        font.pixelSize: Theme.fontSizeLarge
                        font.weight: Font.Medium
                        color: Theme.surfaceText
                        anchors.verticalCenter: parent.verticalCenter
                    }

                }

                Column {
                    width: parent.width
                    spacing: Theme.spacingS

                    StyledText {
                        text: "Top Bar Transparency"
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceText
                        font.weight: Font.Medium
                    }

                    DankSlider {
                        width: parent.width
                        height: 24
                        value: Math.round(SettingsData.topBarTransparency * 100)
                        minimum: 0
                        maximum: 100
                        unit: ""
                        showValue: true
                        onSliderValueChanged: (newValue) => {
                            SettingsData.setTopBarTransparency(newValue / 100);
                        }
                    }

                }

                Column {
                    width: parent.width
                    spacing: Theme.spacingS

                    StyledText {
                        text: "Top Bar Widget Transparency"
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceText
                        font.weight: Font.Medium
                    }

                    DankSlider {
                        width: parent.width
                        height: 24
                        value: Math.round(SettingsData.topBarWidgetTransparency * 100)
                        minimum: 0
                        maximum: 100
                        unit: ""
                        showValue: true
                        onSliderValueChanged: (newValue) => {
                            SettingsData.setTopBarWidgetTransparency(newValue / 100);
                        }
                    }

                }

                Column {
                    width: parent.width
                    spacing: Theme.spacingS

                    StyledText {
                        text: "Popup Transparency"
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceText
                        font.weight: Font.Medium
                    }

                    DankSlider {
                        width: parent.width
                        height: 24
                        value: Math.round(SettingsData.popupTransparency * 100)
                        minimum: 0
                        maximum: 100
                        unit: ""
                        showValue: true
                        onSliderValueChanged: (newValue) => {
                            SettingsData.setPopupTransparency(newValue / 100);
                        }
                    }

                }

            }
        }
    }

    // Theme Color Component
    Component {
        id: themeComponent
        
        StyledRect {
            width: parent.width
            height: themeSection.implicitHeight + Theme.spacingL * 2
            radius: Theme.cornerRadiusLarge
            color: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.3)
            border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
            border.width: 1

            Column {
                id: themeSection

                anchors.fill: parent
                anchors.margins: Theme.spacingL
                spacing: Theme.spacingM

                Row {
                    width: parent.width
                    spacing: Theme.spacingM

                    DankIcon {
                        name: "palette"
                        size: Theme.iconSize
                        color: Theme.primary
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    StyledText {
                        text: "Theme Color"
                        font.pixelSize: Theme.fontSizeLarge
                        font.weight: Font.Medium
                        color: Theme.surfaceText
                        anchors.verticalCenter: parent.verticalCenter
                    }

                }

                Column {
                    width: parent.width
                    spacing: Theme.spacingS

                    StyledText {
                        text: "Current Theme: " + (Theme.isDynamicTheme ? "Auto" : (Theme.currentThemeIndex < Theme.themes.length ? Theme.themes[Theme.currentThemeIndex].name : "Blue"))
                        font.pixelSize: Theme.fontSizeMedium
                        color: Theme.surfaceText
                        font.weight: Font.Medium
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    StyledText {
                        text: {
                            if (Theme.isDynamicTheme)
                                return "Wallpaper-based dynamic colors";

                            var descriptions = ["Material blue inspired by modern interfaces", "Deep blue inspired by material 3", "Rich purple tones for BB elegance", "Natural green for productivity", "Energetic orange for creativity", "Bold red for impact", "Cool cyan for tranquility", "Vibrant pink for expression", "Warm amber for comfort", "Soft coral for gentle warmth", "Soothing pastel theme for the high-spirited"];
                            return descriptions[Theme.currentThemeIndex] || "Select a theme";
                        }
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceVariantText
                        anchors.horizontalCenter: parent.horizontalCenter
                        wrapMode: Text.WordWrap
                        width: Math.min(parent.width, 400)
                        horizontalAlignment: Text.AlignHCenter
                    }

                }

                Column {
                    spacing: Theme.spacingS
                    anchors.horizontalCenter: parent.horizontalCenter

                    Row {
                        spacing: Theme.spacingM
                        anchors.horizontalCenter: parent.horizontalCenter

                        Repeater {
                            model: 5

                            Rectangle {
                                width: 32
                                height: 32
                                radius: 16
                                color: Theme.themes[index].primary
                                border.color: Theme.outline
                                border.width: (Theme.currentThemeIndex === index && !Theme.isDynamicTheme) ? 2 : 1
                                scale: (Theme.currentThemeIndex === index && !Theme.isDynamicTheme) ? 1.1 : 1

                                Rectangle {
                                    width: nameText.contentWidth + Theme.spacingS * 2
                                    height: nameText.contentHeight + Theme.spacingXS * 2
                                    color: Theme.surfaceContainer
                                    border.color: Theme.outline
                                    border.width: 1
                                    radius: Theme.cornerRadiusSmall
                                    anchors.bottom: parent.top
                                    anchors.bottomMargin: Theme.spacingXS
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    visible: mouseArea.containsMouse

                                    StyledText {
                                        id: nameText

                                        text: Theme.themes[index].name
                                        font.pixelSize: Theme.fontSizeSmall
                                        color: Theme.surfaceText
                                        anchors.centerIn: parent
                                    }

                                }

                                MouseArea {
                                    id: mouseArea

                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        Theme.switchTheme(index, false);
                                    }
                                }

                                Behavior on scale {
                                    NumberAnimation {
                                        duration: Theme.shortDuration
                                        easing.type: Theme.emphasizedEasing
                                    }

                                }

                                Behavior on border.width {
                                    NumberAnimation {
                                        duration: Theme.shortDuration
                                        easing.type: Theme.emphasizedEasing
                                    }

                                }

                            }

                        }

                    }

                    Row {
                        spacing: Theme.spacingM
                        anchors.horizontalCenter: parent.horizontalCenter

                        Repeater {
                            model: Theme.themes.length - 5

                            Rectangle {
                                property int themeIndex: index + 5

                                width: 32
                                height: 32
                                radius: 16
                                color: themeIndex < Theme.themes.length ? Theme.themes[themeIndex].primary : "transparent"
                                border.color: Theme.outline
                                border.width: Theme.currentThemeIndex === themeIndex ? 2 : 1
                                visible: themeIndex < Theme.themes.length
                                scale: Theme.currentThemeIndex === themeIndex ? 1.1 : 1

                                Rectangle {
                                    width: nameText2.contentWidth + Theme.spacingS * 2
                                    height: nameText2.contentHeight + Theme.spacingXS * 2
                                    color: Theme.surfaceContainer
                                    border.color: Theme.outline
                                    border.width: 1
                                    radius: Theme.cornerRadiusSmall
                                    anchors.bottom: parent.top
                                    anchors.bottomMargin: Theme.spacingXS
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    visible: mouseArea2.containsMouse && themeIndex < Theme.themes.length

                                    StyledText {
                                        id: nameText2

                                        text: themeIndex < Theme.themes.length ? Theme.themes[themeIndex].name : ""
                                        font.pixelSize: Theme.fontSizeSmall
                                        color: Theme.surfaceText
                                        anchors.centerIn: parent
                                    }

                                }

                                MouseArea {
                                    id: mouseArea2

                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (themeIndex < Theme.themes.length)
                                            Theme.switchTheme(themeIndex);

                                    }
                                }

                                Behavior on scale {
                                    NumberAnimation {
                                        duration: Theme.shortDuration
                                        easing.type: Theme.emphasizedEasing
                                    }

                                }

                                Behavior on border.width {
                                    NumberAnimation {
                                        duration: Theme.shortDuration
                                        easing.type: Theme.emphasizedEasing
                                    }

                                }

                            }

                        }

                    }

                    Item {
                        width: 1
                        height: Theme.spacingM
                    }

                    Rectangle {
                        width: 120
                        height: 40
                        radius: 20
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: {
                            if (ToastService.wallpaperErrorStatus === "error" || ToastService.wallpaperErrorStatus === "matugen_missing")
                                return Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.12);
                            else
                                return Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.3);
                        }
                        border.color: {
                            if (ToastService.wallpaperErrorStatus === "error" || ToastService.wallpaperErrorStatus === "matugen_missing")
                                return Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.5);
                            else if (Theme.isDynamicTheme)
                                return Theme.primary;
                            else
                                return Theme.outline;
                        }
                        border.width: Theme.isDynamicTheme ? 2 : 1
                        scale: Theme.isDynamicTheme ? 1.1 : (autoMouseArea.containsMouse ? 1.02 : 1)

                        Row {
                            anchors.centerIn: parent
                            spacing: Theme.spacingS

                            DankIcon {
                                name: {
                                    if (ToastService.wallpaperErrorStatus === "error" || ToastService.wallpaperErrorStatus === "matugen_missing")
                                        return "error";
                                    else
                                        return "palette";
                                }
                                size: 16
                                color: {
                                    if (ToastService.wallpaperErrorStatus === "error" || ToastService.wallpaperErrorStatus === "matugen_missing")
                                        return Theme.error;
                                    else
                                        return Theme.surfaceText;
                                }
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            StyledText {
                                text: {
                                    if (ToastService.wallpaperErrorStatus === "error")
                                        return "Error";
                                    else if (ToastService.wallpaperErrorStatus === "matugen_missing")
                                        return "No matugen";
                                    else
                                        return "Auto";
                                }
                                font.pixelSize: Theme.fontSizeMedium
                                color: {
                                    if (ToastService.wallpaperErrorStatus === "error" || ToastService.wallpaperErrorStatus === "matugen_missing")
                                        return Theme.error;
                                    else
                                        return Theme.surfaceText;
                                }
                                font.weight: Font.Medium
                                anchors.verticalCenter: parent.verticalCenter
                            }

                        }

                        MouseArea {
                            id: autoMouseArea

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (ToastService.wallpaperErrorStatus === "matugen_missing")
                                    ToastService.showError("matugen not found - install matugen package for dynamic theming");
                                else if (ToastService.wallpaperErrorStatus === "error")
                                    ToastService.showError("Wallpaper processing failed - check wallpaper path");
                                else
                                    Theme.switchTheme(10, true);
                            }
                        }

                        Rectangle {
                            width: autoTooltipText.contentWidth + Theme.spacingM * 2
                            height: autoTooltipText.contentHeight + Theme.spacingS * 2
                            color: Theme.surfaceContainer
                            border.color: Theme.outline
                            border.width: 1
                            radius: Theme.cornerRadiusSmall
                            anchors.bottom: parent.top
                            anchors.bottomMargin: Theme.spacingS
                            anchors.horizontalCenter: parent.horizontalCenter
                            visible: autoMouseArea.containsMouse && (!Theme.isDynamicTheme || ToastService.wallpaperErrorStatus === "error" || ToastService.wallpaperErrorStatus === "matugen_missing")

                            StyledText {
                                id: autoTooltipText

                                text: {
                                    if (ToastService.wallpaperErrorStatus === "matugen_missing")
                                        return "Install matugen package for dynamic themes";
                                    else
                                        return "Dynamic wallpaper-based colors";
                                }
                                font.pixelSize: Theme.fontSizeSmall
                                color: (ToastService.wallpaperErrorStatus === "error" || ToastService.wallpaperErrorStatus === "matugen_missing") ? Theme.error : Theme.surfaceText
                                anchors.centerIn: parent
                                wrapMode: Text.WordWrap
                                width: Math.min(implicitWidth, 250)
                                horizontalAlignment: Text.AlignHCenter
                            }

                        }

                        Behavior on scale {
                            NumberAnimation {
                                duration: Theme.shortDuration
                                easing.type: Theme.emphasizedEasing
                            }

                        }

                        Behavior on color {
                            ColorAnimation {
                                duration: Theme.mediumDuration
                                easing.type: Theme.standardEasing
                            }

                        }

                        Behavior on border.color {
                            ColorAnimation {
                                duration: Theme.mediumDuration
                                easing.type: Theme.standardEasing
                            }

                        }

                    }

                }

            }
        }
    }

    // System App Theming Component
    Component {
        id: systemThemingComponent
        
        StyledRect {
            width: parent.width
            height: systemThemingSection.implicitHeight + Theme.spacingL * 2
            radius: Theme.cornerRadiusLarge
            color: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.3)
            border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
            border.width: 1
            visible: Theme.isDynamicTheme && Colors.matugenAvailable

            Column {
                id: systemThemingSection

                anchors.fill: parent
                anchors.margins: Theme.spacingL
                spacing: Theme.spacingM

                Row {
                    width: parent.width
                    spacing: Theme.spacingM

                    DankIcon {
                        name: "extension"
                        size: Theme.iconSize
                        color: Theme.primary
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    StyledText {
                        text: "System App Theming"
                        font.pixelSize: Theme.fontSizeLarge
                        font.weight: Font.Medium
                        color: Theme.surfaceText
                        anchors.verticalCenter: parent.verticalCenter
                    }

                }

                DankToggle {
                    width: parent.width
                    text: "Theme GTK Applications"
                    description: Colors.gtkThemingEnabled ? "File managers, text editors, and system dialogs will match your theme" : "GTK theming not available (install gsettings)"
                    enabled: Colors.gtkThemingEnabled
                    checked: Colors.gtkThemingEnabled && SettingsData.gtkThemingEnabled
                    onToggled: function(checked) {
                        SettingsData.setGtkThemingEnabled(checked);
                        if (checked && Theme.isDynamicTheme)
                            Colors.generateGtkThemes();

                    }
                }

                DankToggle {
                    width: parent.width
                    text: "Theme Qt Applications"
                    description: Colors.qtThemingEnabled ? "Qt applications will match your theme colors" : "Qt theming not available (install qt5ct or qt6ct)"
                    enabled: Colors.qtThemingEnabled
                    checked: Colors.qtThemingEnabled && SettingsData.qtThemingEnabled
                    onToggled: function(checked) {
                        SettingsData.setQtThemingEnabled(checked);
                        if (checked && Theme.isDynamicTheme)
                            Colors.generateQtThemes();

                    }
                }

            }
        }
    }

    Process {
        id: nightModeEnableProcess

        command: ["bash", "-c", "if command -v wlsunset > /dev/null; then pkill wlsunset; wlsunset -t 3000 & elif command -v redshift > /dev/null; then pkill redshift; redshift -P -O 3000 & else echo 'No night mode tool available'; fi"]
        running: false
        onExited: (exitCode) => {
            if (exitCode !== 0)
                SettingsData.setNightModeEnabled(true);

        }
    }

    Process {
        id: nightModeDisableProcess

        command: ["bash", "-c", "pkill wlsunset; pkill redshift; if command -v wlsunset > /dev/null; then wlsunset -t 6500 -T 6500 & sleep 1; pkill wlsunset; elif command -v redshift > /dev/null; then redshift -P -O 6500; redshift -x; fi"]
        running: false
        onExited: (exitCode) => {
            if (exitCode !== 0)
                SettingsData.setNightModeEnabled(false);

        }
    }

}
