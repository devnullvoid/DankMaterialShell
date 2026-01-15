import QtQuick
import qs.Common
import qs.Widgets
import qs.Services
import "."

Item {
    id: root

    // Injected by PluginService
    property var pluginService: null
    property string pluginId: "aiAssistant"

    // Logic Component
    AIAssistantService {
        id: aiService
        pluginService: root.pluginService
        pluginId: root.pluginId
    }

    // Slideout
    DankSlideout {
        id: slideout
        modelData: Window.window ? Window.window.screen : null
        title: "AI Assistant"
        slideoutWidth: 480
        expandable: true
        expandedWidthValue: 960

        content: AIAssistant {
            aiService: aiService
            onHideRequested: slideout.hide()
        }
    }

    // Bar Button
    DankActionButton {
        anchors.centerIn: parent
        iconName: "smart_toy"
        iconSize: Theme.iconSize - 4
        iconColor: slideout.isVisible ? Theme.primary : Theme.surfaceText
        backgroundColor: slideout.isVisible ? Theme.withAlpha(Theme.primary, 0.1) : "transparent"
        tooltipText: "AI Assistant"

        onClicked: slideout.toggle()
    }
}
