import QtQuick
import Quickshell
import qs.Common
import qs.Services
import qs.Modules.Plugins
import qs.Modules.BuiltinDesktopPlugins

Variants {
    id: root
    model: Quickshell.screens

    QtObject {
        id: screenDelegate

        required property var modelData

        readonly property var screen: modelData

        function shouldShowOnScreen(prefs) {
            if (!Array.isArray(prefs) || prefs.length === 0 || prefs.includes("all"))
                return true;
            return prefs.some(p => p.name === modelData.name);
        }

        readonly property bool showBuiltinClock: SettingsData.desktopClockEnabled && shouldShowOnScreen(SettingsData.desktopClockDisplayPreferences)

        readonly property bool showSystemMonitor: SettingsData.systemMonitorEnabled && shouldShowOnScreen(SettingsData.systemMonitorDisplayPreferences)

        readonly property var visibleSystemMonitorVariants: {
            if (!SettingsData.systemMonitorEnabled)
                return [];
            const variants = SettingsData.systemMonitorVariants || [];
            return variants.filter(v => shouldShowOnScreen(v.config?.displayPreferences));
        }

        property var _pluginComponents: PluginService.pluginDesktopComponents
        property var _pluginTrigger: 0

        readonly property var visiblePlugins: {
            void _pluginTrigger;
            return Object.keys(_pluginComponents).filter(id => {
                const prefs = PluginService.loadPluginData(id, "displayPreferences", ["all"]);
                return shouldShowOnScreen(prefs);
            });
        }

        property var pluginServiceConnections: Connections {
            target: PluginService
            function onPluginDataChanged(pluginId) {
                screenDelegate._pluginTrigger++;
            }
            function onPluginLoaded(pluginId) {
                const plugin = PluginService.availablePlugins[pluginId];
                if (plugin?.type === "desktop")
                    screenDelegate._pluginTrigger++;
            }
            function onPluginUnloaded(pluginId) {
                screenDelegate._pluginTrigger++;
            }
        }

        property Loader clockLoader: Loader {
            active: screenDelegate.showBuiltinClock
            sourceComponent: Component {
                DesktopPluginWrapper {
                    pluginId: "desktopClock"
                    pluginComponent: clockComponent
                    screen: screenDelegate.screen
                }
            }
        }

        property Component clockComponent: Component {
            DesktopClockWidget {}
        }

        property Loader systemMonitorLoader: Loader {
            active: screenDelegate.showSystemMonitor
            sourceComponent: Component {
                DesktopPluginWrapper {
                    pluginId: "systemMonitor"
                    pluginComponent: systemMonitorComponent
                    screen: screenDelegate.screen
                }
            }
        }

        property Component systemMonitorComponent: Component {
            SystemMonitorWidget {}
        }

        property Instantiator sysMonVariantInstantiator: Instantiator {
            model: screenDelegate.visibleSystemMonitorVariants

            DesktopPluginWrapper {
                required property var modelData

                pluginId: "systemMonitor"
                variantId: modelData.id
                variantData: modelData
                pluginComponent: screenDelegate.systemMonitorComponent
                screen: screenDelegate.screen
            }
        }

        property Instantiator pluginInstantiator: Instantiator {
            model: screenDelegate.visiblePlugins

            DesktopPluginWrapper {
                required property string modelData

                pluginId: modelData
                pluginComponent: PluginService.pluginDesktopComponents[modelData]
                pluginService: PluginService
                screen: screenDelegate.screen
            }
        }
    }
}
