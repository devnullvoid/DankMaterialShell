import QtQuick
import qs.Common

Item {
    id: root

    property var pluginService: null
    property string pluginId: ""

    property real widgetWidth: 200
    property real widgetHeight: 200
    property real minWidth: 100
    property real minHeight: 100

    property var pluginData: ({})

    Component.onCompleted: loadPluginData()
    onPluginServiceChanged: loadPluginData()
    onPluginIdChanged: loadPluginData()

    Connections {
        target: pluginService
        function onPluginDataChanged(changedPluginId) {
            if (changedPluginId !== pluginId)
                return;
            loadPluginData();
        }
    }

    function loadPluginData() {
        if (!pluginService || !pluginId) {
            pluginData = {};
            return;
        }
        pluginData = SettingsData.getPluginSettingsForPlugin(pluginId);
    }

    function getData(key, defaultValue) {
        if (!pluginService || !pluginId)
            return defaultValue;
        return pluginService.loadPluginData(pluginId, key, defaultValue);
    }

    function setData(key, value) {
        if (!pluginService || !pluginId)
            return;
        pluginService.savePluginData(pluginId, key, value);
    }
}
