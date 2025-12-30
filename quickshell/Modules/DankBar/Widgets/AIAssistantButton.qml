import QtQuick
import Quickshell.Hyprland
import qs.Common
import qs.Modules.Plugins
import qs.Services
import qs.Widgets

BasePill {
    id: root

    readonly property string focusedScreenName: (
        CompositorService.isHyprland && typeof Hyprland !== "undefined" && Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.monitor ? (Hyprland.focusedWorkspace.monitor.name || "") :
        CompositorService.isNiri && typeof NiriService !== "undefined" && NiriService.currentOutput ? NiriService.currentOutput : ""
    )

    function resolveAiInstance() {
        if (typeof aiAssistantSlideoutVariants === "undefined" || !aiAssistantSlideoutVariants || !aiAssistantSlideoutVariants.instances) {
            return null
        }

        const targetScreen = focusedScreenName
        if (targetScreen) {
            for (var i = 0; i < aiAssistantSlideoutVariants.instances.length; i++) {
                var slideout = aiAssistantSlideoutVariants.instances[i]
                if (slideout.modelData && slideout.modelData.name === targetScreen) {
                    return slideout
                }
            }
        }

        return aiAssistantSlideoutVariants.instances.length > 0 ? aiAssistantSlideoutVariants.instances[0] : null
    }

    readonly property var aiInstance: resolveAiInstance()
    readonly property bool isActive: aiInstance?.isVisible ?? false

    content: Component {
        Item {
            implicitWidth: root.widgetThickness - root.horizontalPadding * 2
            implicitHeight: root.widgetThickness - root.horizontalPadding * 2

            DankIcon {
                anchors.centerIn: parent
                name: "smart_toy"
                size: Theme.barIconSize(root.barThickness, -4)
                color: root.isActive ? Theme.primary : Theme.surfaceText
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        onPressed: {
            const inst = root.aiInstance
            if (inst) {
                inst.toggle()
            }
        }
    }
}
