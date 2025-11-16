pragma ComponentBehavior: Bound

import QtQuick
import qs.Common
import qs.Services
import qs.Widgets

Rectangle {
    id: root

    property bool isVisible: false
    property bool showLogout: true
    property int selectedIndex: 0
    property int selectedRow: 0
    property int selectedCol: 0
    property var visibleActions: []
    property int gridColumns: 3
    property int gridRows: 2
    property bool useGridLayout: false

    signal closed()

    function updateVisibleActions() {
        const allActions = (typeof SettingsData !== "undefined" && SettingsData.powerMenuActions)
            ? SettingsData.powerMenuActions
            : ["logout", "suspend", "hibernate", "reboot", "poweroff"]
        const hibernateSupported = (typeof SessionService !== "undefined" && SessionService.hibernateSupported) || false
        let filtered = allActions.filter(action => {
            if (action === "hibernate" && !hibernateSupported) return false
            if (action === "lock") return false
            if (action === "restart") return false
            if (action === "logout" && !showLogout) return false
            return true
        })

        visibleActions = filtered

        useGridLayout = (typeof SettingsData !== "undefined" && SettingsData.powerMenuGridLayout !== undefined)
            ? SettingsData.powerMenuGridLayout
            : false
        if (!useGridLayout) return

        const count = visibleActions.length
        if (count === 0) {
            gridColumns = 1
            gridRows = 1
            return
        }

        if (count <= 3) {
            gridColumns = 1
            gridRows = count
            return
        }

        if (count === 4) {
            gridColumns = 2
            gridRows = 2
            return
        }

        gridColumns = 3
        gridRows = Math.ceil(count / 3)
    }

    function getDefaultActionIndex() {
        const defaultAction = (typeof SettingsData !== "undefined" && SettingsData.powerMenuDefaultAction)
            ? SettingsData.powerMenuDefaultAction
            : "suspend"
        const index = visibleActions.indexOf(defaultAction)
        return index >= 0 ? index : 0
    }

    function getActionAtIndex(index) {
        if (index < 0 || index >= visibleActions.length) return ""
        return visibleActions[index]
    }

    function getActionData(action) {
        switch (action) {
        case "reboot":
            return { "icon": "restart_alt", "label": I18n.tr("Reboot"), "key": "R" }
        case "logout":
            return { "icon": "logout", "label": I18n.tr("Log Out"), "key": "X" }
        case "poweroff":
            return { "icon": "power_settings_new", "label": I18n.tr("Power Off"), "key": "P" }
        case "suspend":
            return { "icon": "bedtime", "label": I18n.tr("Suspend"), "key": "S" }
        case "hibernate":
            return { "icon": "ac_unit", "label": I18n.tr("Hibernate"), "key": "H" }
        default:
            return { "icon": "help", "label": action, "key": "?" }
        }
    }

    function selectOption(action) {
        if (!action) return
        if (typeof SessionService === "undefined") return
        hide()
        switch (action) {
        case "logout":
            SessionService.logout()
            break
        case "suspend":
            SessionService.suspend()
            break
        case "hibernate":
            SessionService.hibernate()
            break
        case "reboot":
            SessionService.reboot()
            break
        case "poweroff":
            SessionService.poweroff()
            break
        }
    }

    function show() {
        updateVisibleActions()
        const defaultIndex = getDefaultActionIndex()
        if (useGridLayout) {
            selectedRow = Math.floor(defaultIndex / gridColumns)
            selectedCol = defaultIndex % gridColumns
            selectedIndex = defaultIndex
        } else {
            selectedIndex = defaultIndex
        }
        isVisible = true
        Qt.callLater(() => powerMenuFocusScope.forceActiveFocus())
    }

    function hide() {
        isVisible = false
        closed()
    }

    function handleListNavigation(event) {
        switch (event.key) {
        case Qt.Key_Up:
        case Qt.Key_Backtab:
            selectedIndex = (selectedIndex - 1 + visibleActions.length) % visibleActions.length
            event.accepted = true
            break
        case Qt.Key_Down:
        case Qt.Key_Tab:
            selectedIndex = (selectedIndex + 1) % visibleActions.length
            event.accepted = true
            break
        case Qt.Key_Return:
        case Qt.Key_Enter:
            selectOption(getActionAtIndex(selectedIndex))
            event.accepted = true
            break
        case Qt.Key_N:
            if (event.modifiers & Qt.ControlModifier) {
                selectedIndex = (selectedIndex + 1) % visibleActions.length
                event.accepted = true
            }
            break
        case Qt.Key_P:
            if (!(event.modifiers & Qt.ControlModifier)) {
                selectOption("poweroff")
                event.accepted = true
            } else {
                selectedIndex = (selectedIndex - 1 + visibleActions.length) % visibleActions.length
                event.accepted = true
            }
            break
        case Qt.Key_J:
            if (event.modifiers & Qt.ControlModifier) {
                selectedIndex = (selectedIndex + 1) % visibleActions.length
                event.accepted = true
            }
            break
        case Qt.Key_K:
            if (event.modifiers & Qt.ControlModifier) {
                selectedIndex = (selectedIndex - 1 + visibleActions.length) % visibleActions.length
                event.accepted = true
            }
            break
        case Qt.Key_R:
            selectOption("reboot")
            event.accepted = true
            break
        case Qt.Key_X:
            selectOption("logout")
            event.accepted = true
            break
        case Qt.Key_S:
            selectOption("suspend")
            event.accepted = true
            break
        case Qt.Key_H:
            selectOption("hibernate")
            event.accepted = true
            break
        }
    }

    function handleGridNavigation(event) {
        switch (event.key) {
        case Qt.Key_Left:
            selectedCol = (selectedCol - 1 + gridColumns) % gridColumns
            selectedIndex = selectedRow * gridColumns + selectedCol
            event.accepted = true
            break
        case Qt.Key_Right:
            selectedCol = (selectedCol + 1) % gridColumns
            selectedIndex = selectedRow * gridColumns + selectedCol
            event.accepted = true
            break
        case Qt.Key_Up:
        case Qt.Key_Backtab:
            selectedRow = (selectedRow - 1 + gridRows) % gridRows
            selectedIndex = selectedRow * gridColumns + selectedCol
            event.accepted = true
            break
        case Qt.Key_Down:
        case Qt.Key_Tab:
            selectedRow = (selectedRow + 1) % gridRows
            selectedIndex = selectedRow * gridColumns + selectedCol
            event.accepted = true
            break
        case Qt.Key_Return:
        case Qt.Key_Enter:
            selectOption(getActionAtIndex(selectedIndex))
            event.accepted = true
            break
        case Qt.Key_N:
            if (event.modifiers & Qt.ControlModifier) {
                selectedCol = (selectedCol + 1) % gridColumns
                selectedIndex = selectedRow * gridColumns + selectedCol
                event.accepted = true
            }
            break
        case Qt.Key_P:
            if (!(event.modifiers & Qt.ControlModifier)) {
                selectOption("poweroff")
                event.accepted = true
            } else {
                selectedCol = (selectedCol - 1 + gridColumns) % gridColumns
                selectedIndex = selectedRow * gridColumns + selectedCol
                event.accepted = true
            }
            break
        case Qt.Key_J:
            if (event.modifiers & Qt.ControlModifier) {
                selectedRow = (selectedRow + 1) % gridRows
                selectedIndex = selectedRow * gridColumns + selectedCol
                event.accepted = true
            }
            break
        case Qt.Key_K:
            if (event.modifiers & Qt.ControlModifier) {
                selectedRow = (selectedRow - 1 + gridRows) % gridRows
                selectedIndex = selectedRow * gridColumns + selectedCol
                event.accepted = true
            }
            break
        case Qt.Key_R:
            selectOption("reboot")
            event.accepted = true
            break
        case Qt.Key_X:
            selectOption("logout")
            event.accepted = true
            break
        case Qt.Key_S:
            selectOption("suspend")
            event.accepted = true
            break
        case Qt.Key_H:
            selectOption("hibernate")
            event.accepted = true
            break
        }
    }

    anchors.fill: parent
    color: Qt.rgba(0, 0, 0, 0.5)
    visible: isVisible
    z: 1000

    MouseArea {
        anchors.fill: parent
        onClicked: root.hide()
    }

    FocusScope {
        id: powerMenuFocusScope
        anchors.fill: parent
        focus: root.isVisible

        onVisibleChanged: {
            if (visible) Qt.callLater(() => forceActiveFocus())
        }

        Keys.onEscapePressed: root.hide()
        Keys.onPressed: event => {
            if (useGridLayout) {
                handleGridNavigation(event)
            } else {
                handleListNavigation(event)
            }
        }

        Rectangle {
            anchors.centerIn: parent
            width: useGridLayout
                ? Math.min(550, gridColumns * 180 + Theme.spacingS * (gridColumns - 1) + Theme.spacingL * 2)
                : 320
            height: contentItem.implicitHeight + Theme.spacingL * 2
            radius: Theme.cornerRadius
            color: Theme.surfaceContainer
            border.color: Theme.outlineMedium
            border.width: 1

            Item {
                id: contentItem
                anchors.fill: parent
                anchors.margins: Theme.spacingL
                implicitHeight: headerRow.height + Theme.spacingM + (useGridLayout ? buttonGrid.implicitHeight : buttonColumn.implicitHeight)

                Row {
                    id: headerRow
                    width: parent.width
                    height: 30

                    StyledText {
                        text: I18n.tr("Power Options")
                        font.pixelSize: Theme.fontSizeLarge
                        color: Theme.surfaceText
                        font.weight: Font.Medium
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Item {
                        width: parent.width - 150
                        height: 1
                    }

                    DankActionButton {
                        iconName: "close"
                        iconSize: Theme.iconSize - 4
                        iconColor: Theme.surfaceText
                        onClicked: root.hide()
                    }
                }

                Grid {
                    id: buttonGrid
                    visible: useGridLayout
                    anchors.top: headerRow.bottom
                    anchors.topMargin: Theme.spacingM
                    anchors.horizontalCenter: parent.horizontalCenter
                    columns: root.gridColumns
                    columnSpacing: Theme.spacingS
                    rowSpacing: Theme.spacingS
                    width: parent.width

                    Repeater {
                        model: root.visibleActions

                        Rectangle {
                            required property int index
                            required property string modelData

                            readonly property var actionData: root.getActionData(modelData)
                            readonly property bool isSelected: root.selectedIndex === index
                            readonly property bool showWarning: modelData === "reboot" || modelData === "poweroff"

                            width: (contentItem.width - Theme.spacingS * (root.gridColumns - 1)) / root.gridColumns
                            height: 100
                            radius: Theme.cornerRadius
                            color: {
                                if (isSelected) return Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12)
                                if (mouseArea.containsMouse) return Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.08)
                                return Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.08)
                            }
                            border.color: isSelected ? Theme.primary : "transparent"
                            border.width: isSelected ? 2 : 0

                            Column {
                                anchors.centerIn: parent
                                spacing: Theme.spacingS

                                DankIcon {
                                    name: parent.parent.actionData.icon
                                    size: Theme.iconSize + 8
                                    color: {
                                        if (parent.parent.showWarning && mouseArea.containsMouse) {
                                            return parent.parent.modelData === "poweroff" ? Theme.error : Theme.warning
                                        }
                                        return Theme.surfaceText
                                    }
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }

                                StyledText {
                                    text: parent.parent.actionData.label
                                    font.pixelSize: Theme.fontSizeMedium
                                    color: {
                                        if (parent.parent.showWarning && mouseArea.containsMouse) {
                                            return parent.parent.modelData === "poweroff" ? Theme.error : Theme.warning
                                        }
                                        return Theme.surfaceText
                                    }
                                    font.weight: Font.Medium
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }

                                Rectangle {
                                    width: 20
                                    height: 16
                                    radius: 4
                                    color: Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.1)
                                    anchors.horizontalCenter: parent.horizontalCenter

                                    StyledText {
                                        text: parent.parent.parent.actionData.key
                                        font.pixelSize: Theme.fontSizeSmall - 1
                                        color: Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.6)
                                        font.weight: Font.Medium
                                        anchors.centerIn: parent
                                    }
                                }
                            }

                            MouseArea {
                                id: mouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.selectedRow = Math.floor(index / root.gridColumns)
                                    root.selectedCol = index % root.gridColumns
                                    root.selectOption(modelData)
                                }
                            }
                        }
                    }
                }

                Column {
                    id: buttonColumn
                    visible: !useGridLayout
                    anchors.top: headerRow.bottom
                    anchors.topMargin: Theme.spacingM
                    anchors.left: parent.left
                    anchors.right: parent.right
                    spacing: Theme.spacingS

                    Repeater {
                        model: root.visibleActions

                        Rectangle {
                            required property int index
                            required property string modelData

                            readonly property var actionData: root.getActionData(modelData)
                            readonly property bool isSelected: root.selectedIndex === index
                            readonly property bool showWarning: modelData === "reboot" || modelData === "poweroff"

                            width: parent.width
                            height: 50
                            radius: Theme.cornerRadius
                            color: {
                                if (isSelected) return Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12)
                                if (listMouseArea.containsMouse) return Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.08)
                                return Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.08)
                            }
                            border.color: isSelected ? Theme.primary : "transparent"
                            border.width: isSelected ? 2 : 0

                            Row {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.leftMargin: Theme.spacingM
                                anchors.rightMargin: Theme.spacingM
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: Theme.spacingM

                                DankIcon {
                                    name: parent.parent.actionData.icon
                                    size: Theme.iconSize + 4
                                    color: {
                                        if (parent.parent.showWarning && listMouseArea.containsMouse) {
                                            return parent.parent.modelData === "poweroff" ? Theme.error : Theme.warning
                                        }
                                        return Theme.surfaceText
                                    }
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                StyledText {
                                    text: parent.parent.actionData.label
                                    font.pixelSize: Theme.fontSizeMedium
                                    color: {
                                        if (parent.parent.showWarning && listMouseArea.containsMouse) {
                                            return parent.parent.modelData === "poweroff" ? Theme.error : Theme.warning
                                        }
                                        return Theme.surfaceText
                                    }
                                    font.weight: Font.Medium
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            Rectangle {
                                width: 28
                                height: 20
                                radius: 4
                                color: Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.1)
                                anchors.right: parent.right
                                anchors.rightMargin: Theme.spacingM
                                anchors.verticalCenter: parent.verticalCenter

                                StyledText {
                                    text: parent.parent.actionData.key
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.6)
                                    font.weight: Font.Medium
                                    anchors.centerIn: parent
                                }
                            }

                            MouseArea {
                                id: listMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.selectedIndex = index
                                    root.selectOption(modelData)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Component.onCompleted: updateVisibleActions()
}
