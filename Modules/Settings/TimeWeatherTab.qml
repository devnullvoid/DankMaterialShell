import QtQuick
import QtQuick.Controls
import qs.Common
import qs.Widgets

Item {
    id: timeWeatherTab

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
                sourceComponent: timeComponent
            }
            
            Loader {
                width: parent.width
                sourceComponent: weatherComponent
            }
        }
    }

    // Time Format Component
    Component {
        id: timeComponent
        
        StyledRect {
            width: parent.width
            height: timeSection.implicitHeight + Theme.spacingL * 2
            radius: Theme.cornerRadiusLarge
            color: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.3)
            border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
            border.width: 1

            Column {
                id: timeSection

                anchors.fill: parent
                anchors.margins: Theme.spacingL
                spacing: Theme.spacingM

                Row {
                    width: parent.width
                    spacing: Theme.spacingM

                    DankIcon {
                        name: "schedule"
                        size: Theme.iconSize
                        color: Theme.primary
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    StyledText {
                        text: "Time Format"
                        font.pixelSize: Theme.fontSizeLarge
                        font.weight: Font.Medium
                        color: Theme.surfaceText
                        anchors.verticalCenter: parent.verticalCenter
                    }

                }

                DankToggle {
                    width: parent.width
                    text: "24-Hour Format"
                    description: "Use 24-hour time format instead of 12-hour AM/PM"
                    checked: SettingsData.use24HourClock
                    onToggled: (checked) => {
                        return SettingsData.setClockFormat(checked);
                    }
                }

            }
        }
    }

    // Weather Component
    Component {
        id: weatherComponent
        
        StyledRect {
            width: parent.width
            height: weatherSection.implicitHeight + Theme.spacingL * 2
            radius: Theme.cornerRadiusLarge
            color: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.3)
            border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
            border.width: 1

            Column {
                id: weatherSection

                anchors.fill: parent
                anchors.margins: Theme.spacingL
                spacing: Theme.spacingM

                Row {
                    width: parent.width
                    spacing: Theme.spacingM

                    DankIcon {
                        name: "cloud"
                        size: Theme.iconSize
                        color: Theme.primary
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    StyledText {
                        text: "Weather"
                        font.pixelSize: Theme.fontSizeLarge
                        font.weight: Font.Medium
                        color: Theme.surfaceText
                        anchors.verticalCenter: parent.verticalCenter
                    }

                }

                DankToggle {
                    width: parent.width
                    text: "Enable Weather"
                    description: "Show weather information in top bar and centcom center"
                    checked: SettingsData.weatherEnabled
                    onToggled: (checked) => {
                        return SettingsData.setWeatherEnabled(checked);
                    }
                }

                DankToggle {
                    width: parent.width
                    text: "Fahrenheit"
                    description: "Use Fahrenheit instead of Celsius for temperature"
                    checked: SettingsData.useFahrenheit
                    enabled: SettingsData.weatherEnabled
                    onToggled: (checked) => {
                        return SettingsData.setTemperatureUnit(checked);
                    }
                }

                DankToggle {
                    width: parent.width
                    text: "Auto Location"
                    description: "Allow wttr.in to determine location based on IP address"
                    checked: SettingsData.useAutoLocation
                    enabled: SettingsData.weatherEnabled
                    onToggled: (checked) => {
                        return SettingsData.setAutoLocation(checked);
                    }
                }

                Column {
                    width: parent.width
                    spacing: Theme.spacingXS
                    visible: !SettingsData.useAutoLocation && SettingsData.weatherEnabled

                    StyledText {
                        text: "Location"
                        font.pixelSize: Theme.fontSizeMedium
                        color: Theme.surfaceText
                        font.weight: Font.Medium
                    }

                    DankLocationSearch {
                        width: parent.width
                        currentLocation: SettingsData.weatherLocation
                        placeholderText: "New York, NY"
                        onLocationSelected: (displayName, coordinates) => {
                            SettingsData.setWeatherLocation(displayName, coordinates);
                        }
                    }

                }

            }
        }
    }
}
