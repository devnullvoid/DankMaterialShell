import QtQuick
import Quickshell
import qs.Common
import qs.Services
import qs.Modules.Settings.DesktopWidgetSettings as DWS
import qs.DankCommon.Common as DC

ShellRoot {
    id: root

    readonly property var instance: SettingsData.desktopWidgetInstances.find(i => i.id === "inst1") ?? null

    Item {
        width: 600
        height: 3000

        DWS.ClockSettings {
            id: clock
            instanceId: "inst1"
            instanceData: root.instance
        }
        DWS.SystemMonitorSettings {
            id: sysmon
            y: 800
            instanceId: "inst1"
            instanceData: root.instance
        }
    }

    Component.onCompleted: {
        Quickshell.watchFiles = false;
        DC.Style.theme = Theme;
        DC.Style.settings = SettingsData;
        DC.I18n.backend = I18n;
        SettingsData.set("desktopWidgetInstances", [
            {
                id: "inst1",
                widgetType: "desktopClock",
                config: {
                    graphInterval: 600,
                    showTopProcesses: true,
                    topProcessCount: 10
                }
            }
        ]);
        SessionData.updateDesktopWidgetInstancePosition("inst1", "DP-1", {
            x: 10,
            y: 20,
            width: 300,
            height: 200
        });
        SessionData.updateDesktopWidgetInstancePosition("inst1", "_synced", {
            x: 0.1,
            y: 0.2,
            width: 300,
            height: 200
        });
    }

    function check(value, message) {
        if (!value)
            throw new Error(message);
    }

    function find(item, predicate) {
        if (predicate(item))
            return item;
        for (const child of item.children ?? []) {
            const found = find(child, predicate);
            if (found)
                return found;
        }
        return null;
    }

    Timer {
        interval: 0
        running: true
        onTriggered: {
            try {
                root.check(root.instance !== null, "fixture instance exists");

                clock.updateConfig("showDate", false);
                root.check(root.instance.config.showDate === false, "updateConfig writes into the instance config");
                root.check(root.instance.config.graphInterval === 600, "updateConfig merges instead of replacing");

                const intervalRow = root.find(sysmon, c => c.intervals !== undefined);
                root.check(intervalRow.intervals[intervalRow.currentIndex] === 600, "stored interval selects its option");
                intervalRow.selectionChanged(1, true);
                root.check(root.instance.config.graphInterval === intervalRow.intervals[1], "selecting an interval saves it");
                intervalRow.selectionChanged(0, false);
                root.check(root.instance.config.graphInterval === intervalRow.intervals[1], "deselection preserves the saved interval");

                SessionData.resetDesktopWidgetInstanceGeometry("inst1", ["x", "y"]);
                let stored = SessionData.desktopWidgetInstancePositions.inst1;
                root.check(stored["DP-1"].x === undefined && stored["DP-1"].y === undefined && stored["DP-1"].width === 300, "reset position clears x/y and keeps size");
                root.check(stored["_synced"].x === undefined && stored["_synced"].width === 300, "reset position also clears the synced entry");
                SessionData.resetDesktopWidgetInstanceGeometry("inst1", ["width", "height"]);
                stored = SessionData.desktopWidgetInstancePositions.inst1;
                root.check(stored["DP-1"].width === undefined && stored["DP-1"].height === undefined, "reset size clears width/height");
                SessionData.resetDesktopWidgetInstanceGeometry("missing", ["x"]);
                root.check(SessionData.desktopWidgetInstancePositions.missing === undefined, "reset on an unknown instance is a no-op");

                console.log("FIXTURE_PASS desktop widget settings: config merge, interval selection, geometry reset");
            } catch (error) {
                console.error("FIXTURE_FAIL", error.message);
            }
            Qt.quit();
        }
    }
}
