pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.Common
import qs.Modules.ControlCenter
import qs.Modules.ControlCenter.Widgets
import qs.Widgets

Item {
    id: root

    LayoutMirroring.enabled: I18n.isRtl
    LayoutMirroring.childrenInherit: true

    property bool editMode: false
    property var toplevels: []
    property bool resetArmed: false

    signal runningAppsRequested
    signal addWidgetRequested
    signal resetRequested
    signal editToggled
    signal cancelRequested

    readonly property var appIds: {
        const ids = [];
        for (const toplevel of toplevels) {
            const id = toplevel?.appId ?? "";
            if (!ids.includes(id))
                ids.push(id);
        }
        return ids;
    }
    readonly property real leadingWidth: Math.max(0, width - trailing.width - CcMetrics.footerGap)

    implicitHeight: CcMetrics.footerHeight

    function cancelConfirmation() {
        resetArmed = false;
    }

    onEditModeChanged: cancelConfirmation()

    StyledButton {
        id: appsChip

        readonly property real iconBox: height - Theme.spacingS * 2

        anchors.left: parent.left
        height: parent.height
        width: Math.min(Theme.spacingS + icons.width + Theme.spacingS + countLabel.implicitWidth + Theme.spacingXS + chevron.width + Theme.spacingM, root.leadingWidth)
        radius: Theme.fullRadius(width, height)
        color: CcMetrics.tileInactiveColor
        border.width: Theme.layerOutlineWidth
        border.color: Theme.outlineMedium
        visible: !root.editMode && root.toplevels.length > 0
        Accessible.name: countLabel.text
        onClicked: root.runningAppsRequested()

        Row {
            id: icons

            anchors.left: parent.left
            anchors.leftMargin: Theme.spacingS
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.spacingXS

            Repeater {
                model: ScriptModel {
                    values: root.appIds.slice(0, CcMetrics.footerMaxAppIcons)
                }

                Rectangle {
                    required property string modelData

                    width: appsChip.iconBox
                    height: width
                    radius: Theme.fullRadius(width, height)
                    color: Theme.surfaceContainerHighest

                    CcAppIcon {
                        anchors.centerIn: parent
                        appId: parent.modelData
                        iconSize: CcMetrics.footerAppIconSize
                    }
                }
            }
        }

        StyledText {
            id: countLabel
            anchors.left: icons.right
            anchors.leftMargin: Theme.spacingS
            anchors.right: chevron.left
            anchors.rightMargin: Theme.spacingXS
            anchors.verticalCenter: parent.verticalCenter
            text: root.toplevels.length === 1 ? I18n.tr("%1 window", "singular, %1 is 1, open windows in the control center footer").arg(1) : I18n.tr("%1 windows", "plural, %1 is a count of open windows in the control center footer").arg(root.toplevels.length)
            font.pixelSize: Theme.fontSizeMedium
            font.weight: Theme.fontWeightMedium
            color: CcMetrics.tileInactiveContent
            elide: Text.ElideRight
        }

        DankIcon {
            id: chevron
            anchors.right: parent.right
            anchors.rightMargin: Theme.spacingM
            anchors.verticalCenter: parent.verticalCenter
            name: I18n.isRtl ? "chevron_left" : "chevron_right"
            size: Theme.iconSizeSmall
            color: Theme.onSurfaceVariant
        }

        FocusRing {
            visible: parent.visualFocus
        }

        StateLayer {
            control: parent
            stateColor: CcMetrics.tileInactiveContent
        }
    }

    Row {
        id: editActions

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.spacingS
        visible: root.editMode

        DankButton {
            id: addButton
            buttonHeight: CcMetrics.footerHeight
            maximumWidth: root.leadingWidth
            iconName: "add"
            text: I18n.tr("Add widget")
            backgroundColor: Theme.secondaryContainer
            textColor: Theme.onSecondaryContainer
            onClicked: {
                root.cancelConfirmation();
                root.addWidgetRequested();
            }
        }

        DankButton {
            buttonHeight: CcMetrics.footerHeight
            maximumWidth: Math.max(0, root.leadingWidth - addButton.width - editActions.spacing)
            readonly property string label: I18n.tr("Defaults", "noun, control center edit button restoring the default layout")
            readonly property string confirmLabel: I18n.tr("Confirm")

            iconName: "settings_backup_restore"
            text: root.resetArmed ? confirmLabel : label
            reserveText: root.resetArmed ? label : confirmLabel
            backgroundColor: root.resetArmed ? Theme.primary : Theme.surfaceContainerHighest
            textColor: root.resetArmed ? Theme.onPrimary : Theme.onSurface
            onClicked: {
                if (!root.resetArmed) {
                    root.resetArmed = true;
                    return;
                }
                root.resetArmed = false;
                root.resetRequested();
            }
        }
    }

    Row {
        id: trailing

        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.spacingS

        DankActionButton {
            buttonSize: CcMetrics.footerHeight
            iconName: "close"
            iconSize: CcMetrics.iconBoxIconSize
            iconColor: CcMetrics.tileInactiveContent
            backgroundColor: CcMetrics.tileInactiveColor
            border.width: Theme.layerOutlineWidth
            border.color: Theme.outlineMedium
            tooltipText: I18n.tr("Discard")
            visible: root.editMode
            onClicked: root.cancelRequested()
        }

        DankActionButton {
            buttonSize: CcMetrics.footerHeight
            iconName: "check"
            iconSize: CcMetrics.iconBoxIconSize
            iconColor: Theme.onPrimary
            backgroundColor: Theme.primary
            tooltipText: I18n.tr("Save")
            visible: root.editMode
            onClicked: root.editToggled()
        }

        DankActionButton {
            buttonSize: CcMetrics.footerHeight
            iconName: "edit"
            iconSize: CcMetrics.iconBoxIconSize
            iconColor: CcMetrics.tileInactiveContent
            backgroundColor: CcMetrics.tileInactiveColor
            border.width: Theme.layerOutlineWidth
            border.color: Theme.outlineMedium
            tooltipText: I18n.tr("Edit")
            visible: !root.editMode
            onClicked: root.editToggled()
        }
    }
}
